#!/bin/bash
#
# title:        task-distributor-worker.sh
# description:  This script starts the POV-ray render job according to the 
#               instructions of the master node and stores the resulting
#               image part on a distributed file system
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         August 6th 2014
# version:      1.0
# bash_version: 4.2.37(1)-release
# requires:     POV-Ray 3.7, ImageMagick 6.7.7, bc 1.06.95
# notes: 
# ----------------------------------------------------------------------------

# $1 = Number of nodes
# $2 = Path of the POV-file (input)
# $3 = File name of the POV-file (input)
# $4 = Data type of the desired image (output)
# $5 = Image width of the desired image
# $6 = Image height of the desired image
# $7 = Output directory
# $8 = First row of the image part to be calculated by this worker
# $9 = Final row of the image part to be calculated by this worker

# Raytrace $2$3 to local storage (=> lesser network traffic)
# Direct all output messages to local storage
/opt/povray/bin/povray_3.7 $2$3 $4 $5 $6 $7 $8 $9 1>/dev/null 2>/tmp/povraymessages

# Cut away the first 3 characters "+SR" from parameter $8 to obtain the
# number of rows as integer
SIZE_TEMP=`echo $8 | cut -c 4-`
SIZE_RESULT=`expr $SIZE_TEMP - 1`

# Cut away the first 2 characters "+H" from parameter $6 to obtain the
# number of rows as integer
IMG_HEIGHT=`echo $6 | cut -c 3-`
# Cut away the first 2 characters "+W" from parameter $5 to obtain the
# number of rows as integer
IMG_WIDTH=`echo $5 | cut -c 3-`
# Calculate the number of rows, each worker node will calculate
ROW_SIZE=`expr ${IMG_HEIGHT} / ${1}`

# Remove the black rows from the image part to reduce the network traffic 
# and the amount of data which needs the master to process finally for 
# creating the final image
convert -set colorspace RGB -define png:size=${IMG_WIDTH}x${IMG_HEIGHT} -extract ${IMG_WIDTH}x${ROW_SIZE}+0+${SIZE_RESULT} /tmp/`echo $3 | cut -f1 -d'.'`.png /tmp/`echo $3 | cut -f1 -d'.'`.png

# Move the generated image part to a distributed file system which can be
# accessed by the master node
mv /tmp/`echo $3 | cut -f1 -d'.'`.png /glusterfs/povray/`hostname`.png

# Write the hostname of the worker node into the lockfile to inform the
# master node that the image part of this worker node is now available
echo "`hostname`" >> /glusterfs/povray/lockfile
