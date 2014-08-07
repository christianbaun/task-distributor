#!/bin/bash
#
# title:        task-distributor-master.sh
# description:  This script splits a POV-ray render job to multiple nodes,
#               checks the progress and composes the image parts to create the
#               desired image
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         August 6th 2014
# version:      0.1
# bash_version: 4.2.37(1)-release
# requires:     POV-Ray 3.7, ImageMagick 6.7.7
# notes: 
# ----------------------------------------------------------------------------


function usage
{
echo "$SCRIPT -n nodes -x width -y height

This script splits a POV-ray render job to multiple nodes, checks the 
progress and composes the image parts to create the desired image

Arguments:
-h : show this message on screen
-n : number of nodes
-x : image width
-y : image height
"
exit 0
}

# These variables are of type integer
typeset -i NUM_NODES IMG_WIDTH IMG_HEIGHT

SCRIPT=${0##*/}
IMG_WIDTH=
IMG_HEIGHT=
NUM_NODES=

while getopts "hn:x:y:" Arg ; do
  case $Arg in
    h) usage ;;
    n) NUM_NODES=$OPTARG ;;
    x) IMG_WIDTH=$OPTARG ;;
    y) IMG_HEIGHT=$OPTARG ;;
    \?) echo "Invalid option: $OPTARG" >&2
        exit 1
        ;;
  esac
done

if [ "$NUM_NODES" -eq 0 ] || [ "$IMG_WIDTH" -eq 0 ] || [ "$IMG_HEIGHT" -eq 0 ] ; then
   usage
   exit 1
fi

# Path of the lockfile on a file system, which can be accessed by all nodes
LOCKFILE='/glusterfs/povray/lockfile'
# Path of the image parts on a file system, which can be accessed by all nodes
IMAGE_PARTS_PATH='/glusterfs/povray'

# Path of the remote script which executes POV-Ray on the nodes
REMOTE_SCRIPT='/home/pi/task-distributor-worker.sh'

IMG_PATH=/opt/povray/share/povray-3.7/scenes/objects/
IMG_FILE=blob.pov
OUTPUT_DIR=/tmp/
# Array with the hostnames (the first entry has index number 1 here)
HOSTS_ARRAY=([1]=pi31 pi32 pi33 pi34 pi35 pi36 pi37 pi38)

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

# The variables $START and $END are of type integer
typeset -i START END
# The first image part starts with row number 1
START=1
# This is the height (number of rows) of an image part
END=`expr ${IMG_HEIGHT} / ${NUM_NODES}`

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
  done            
done

if convert -set colorspace RGB `ls /glusterfs/povray/pi*.png` -append /tmp/test.png ; then
  # Compose image parts to create the final image
  echo "Image parts have been composed."
else
  echo "Unable to compose the image parts." && exit 1
fi

if rm ${LOCKFILE} ; then
  # Erase the lockfile
  echo "${LOCKFILE} has been erased."
else
  echo "Unable to erase the ${LOCKFILE}." && exit 1
fi

if rm ${IMAGE_PARTS_PATH}/*.png ; then
  # Erase the image parts
  echo "Image parts have been erased."
else
  echo "Unable to erase the image parts." && exit 1
fi
