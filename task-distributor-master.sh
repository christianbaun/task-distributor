#!/bin/bash
#
# title:        task-distributor-master.sh
# description:  This script splits a POV-ray render job to multiple nodes,
#               checks the progress and composes the image parts to create the
#               desired image
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         August 12th 2014
# version:      1.1
# bash_version: 4.2.37(1)-release
# requires:     POV-Ray 3.7, ImageMagick 6.7.7, bc 1.06.95
# notes: 
# ----------------------------------------------------------------------------

# Start of the 1st sequential part
SEQUENTIAL_TIME1_START=`date +%s.%N`

function usage
{
echo "$SCRIPT -n nodes -x width -y height -p path [-f] [-c]

This script splits a POV-ray render job to multiple nodes, checks the 
progress and composes the image parts to create the desired image

Arguments:
-h : show this message on screen
-n : number of nodes (2, 4, 8, 16, ...)
-x : image width (800, 1600, 3200, ...)
-y : image height (600, 1200, 2400, ...)
-p : path for the lockfile and the image parts
-f : force (if lockfile exists => erase and proceed)
-c : clean up (remove image parts and lockfile afterwards)
"
exit 0
}

SCRIPT=${0##*/}
IMG_WIDTH=
IMG_HEIGHT=
NUM_NODES=
LOCKFILE=
IMAGE_PARTS_PATH=
CLEAN_UP=0

# Path of the remote script which executes POV-Ray on the nodes
REMOTE_SCRIPT='/home/pi/task-distributor-worker.sh'

IMG_PATH=/opt/povray/share/povray-3.7/scenes/objects/
IMG_FILE=blob.pov
OUTPUT_DIR=/tmp/
# Array with the hostnames (the first entry has index number 1 here)
HOSTS_ARRAY=([1]=pi31 pi32 pi33 pi34 pi35 pi36 pi37 pi38)

while getopts "hn:x:y:fcp:" Arg ; do
  case $Arg in
    h) usage ;;
    n) NUM_NODES=$OPTARG ;;
    x) IMG_WIDTH=$OPTARG ;;
    y) IMG_HEIGHT=$OPTARG ;;
    p) IMAGE_PARTS_PATH=$OPTARG ;;
    # If lockfile exists => erase it an proceed
    f) if [ -e ${LOCKFILE} ] ; then rm ${LOCKFILE} ; fi  ;;
    # If the flag has been set => $CLEAN_UP gets value 1
    c) CLEAN_UP=1 ;;
    \?) echo "Invalid option: $OPTARG" >&2
        exit 1
        ;;
  esac
done

# Path of the lockfile on a file system, which can be accessed by all nodes
LOCKFILE=`echo "${IMAGE_PARTS_PATH}"/lockfile`

if [ "$NUM_NODES" -eq 0 ] || [ "$IMG_WIDTH" -eq 0 ] || [ "$IMG_HEIGHT" -eq 0 ] || [ -z "$IMAGE_PARTS_PATH" ] ; then
   usage
   exit 1
fi

# Check if the lockfile already exists
if [ -e ${LOCKFILE} ] ; then
  # Terminate the script, in case the lockfile already exists
  echo "File ${LOCKFILE} already exists!" && exit 1
else
  if touch ${LOCKFILE} ; then
    # Create the lockfile if it does not exist
    echo "${LOCKFILE} has been created."
  else
    echo "Unable to create the ${LOCKFILE}." && exit 1
  fi
fi

# End of the 1st sequential part
SEQUENTIAL_TIME1_END=`date +%s.%N`
# Duration of the 1st sequential part
# The "/1" is stupid, but it is required to get the "scale" working.
# Otherwise the "scale" is just ignored
# The sed command ensures that results < 1 have a leading 0 before the "."
SEQUENTIAL_TIME1=`echo "scale=3 ; (${SEQUENTIAL_TIME1_END} - ${SEQUENTIAL_TIME1_START})/1" | bc | sed 's/^\./0./'`

# The first image part starts with row number 1
START=1
# This is the height (number of rows) of an image part
END=`expr ${IMG_HEIGHT} / ${NUM_NODES}`

# Start of the parallel part
PARALLEL_TIME_START=`date +%s.%N`

for ((i=1; i<=${NUM_NODES}; i+=1))
do
  ssh pi@${HOSTS_ARRAY[$i]} ${REMOTE_SCRIPT} ${NUM_NODES} ${IMG_PATH} ${IMG_FILE} +FN +W${IMG_WIDTH} +H${IMG_HEIGHT} +O${OUTPUT_DIR} +SR${START} +ER${END} &
  START=`expr ${START} + ${IMG_HEIGHT} / ${NUM_NODES}`
  END=`expr ${END} + ${IMG_HEIGHT} / ${NUM_NODES}`
done

# Check if the nodes have finished the calculation of the image parts
for ((i=1; i<=${NUM_NODES}; i+=1))
do
  while true
  do
    if [ -f /glusterfs/povray/lockfile ] && grep ${HOSTS_ARRAY[$i]} /glusterfs/povray/lockfile ; then
      echo "${HOSTS_ARRAY[$i]} has been finished." && break
    else
      echo "Wait for ${HOSTS_ARRAY[$i]} in lockfile." 
    fi
    # Without the "sleep" command, a lot of CPU cycles are wasted and
    # the execution time of the script raises a lot
    sleep 1
  done            
done

# End of the parallel part
PARALLEL_TIME_END=`date +%s.%N`
# Duration of the parallel part
# The "/1" is stupid, but it is required to get the "scale" working.
# Otherwise the "scale" is just ignored
# The sed command ensures that results < 1 have a leading 0 before the "."
PARALLEL_TIME=`echo "scale=3 ; (${PARALLEL_TIME_END} - ${PARALLEL_TIME_START})/1" | bc | sed 's/^\./0./'`
# Start of the 2nd sequential part
SEQUENTIAL_TIME2_START=`date +%s.%N`

# if the number of nodes is 1
if [ "$NUM_NODES" -eq 1 ] ; then
  # Only a single node was be used => no image parts need to be composed.
  # Just copy the final image.
  if cp /glusterfs/povray/pi*.png /tmp/test.png ; then
    echo "Image has been copied."
  else
    echo "Unable to copy the image." && exit 1
  fi
# if the number of nodes is > 1
elif [ "$NUM_NODES" -gt 1 ] ; then
  # More than a single node was used 
  # Compose image parts to create the final image
  if convert -set colorspace RGB `ls /glusterfs/povray/pi*.png` -append /tmp/test.png ; then
    echo "Image parts have been composed."
  else
    echo "Unable to compose the image parts." && exit 1
  fi
# if the number of nodes is not 1 and not > 1 than we have an error
else
    echo "An error occurred because the value of ${1} is not 0 and not greater 
than 1." && exit 1
fi

# If the "clean up" flag has been set, erase the lockfile
if [ "$CLEAN_UP" -eq 1 ] ; then
  if rm ${LOCKFILE} ; then
    # Erase the lockfile
    echo "${LOCKFILE} has been erased."
  else
    echo "Unable to erase the ${LOCKFILE}." && exit 1
  fi
fi

# If the "clean up" flag has been set, erase the image parts
if [ "$CLEAN_UP" -eq 1 ] ; then
  if rm ${IMAGE_PARTS_PATH}/*.png ; then
    # Erase the image parts
    echo "Image parts have been erased."
  else
    echo "Unable to erase the image parts." && exit 1
  fi
fi

# End of the 1st sequential part
SEQUENTIAL_TIME2_END=`date +%s.%N`
# Duration of the 2nd sequential part
# The "/1" is stupid, but it is required to get the "scale" working.
# Otherwise the "scale" is just ignored
# The sed command ensures that results < 1 have a leading 0 before the "."
SEQUENTIAL_TIME2=`echo "scale=3 ; (${SEQUENTIAL_TIME2_END} - ${SEQUENTIAL_TIME2_START})/1" | bc | sed 's/^\./0./'`

echo 'Required time to process the 1st sequential part:    '${SEQUENTIAL_TIME1}s
echo 'Required time to process the parallel part:          '${PARALLEL_TIME}s
echo 'Required time to process the 2nd sequential part:    '${SEQUENTIAL_TIME2}s

