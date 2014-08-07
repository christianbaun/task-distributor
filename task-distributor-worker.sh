#!/bin/bash

# $1 = Number of Nodes
# $2 = Image Width
# $3 = Image Height

# Raytrace $4$5 to local storage (=> lesser network traffic)
# Direct all output messages to local storage
/opt/povray/bin/povray_3.7 $4$5 $6 $7 $8 $9 ${10} ${11} 1>/dev/null 2>/tmp/povraymessages

SIZE_TEMP=`echo ${10} | cut -c 4-`
SIZE_RESULT=`expr $SIZE_TEMP - 1`

ROW_SIZE=`expr ${3} / ${1}`

convert -set colorspace RGB -define png:size=${2}x${3} -extract ${2}x${ROW_SIZE}+0+${SIZE_RESULT} /tmp/`echo $5 | cut -f1 -d'.'`.png /tmp/`echo $5 | cut -f1 -d'.'`.png

mv /tmp/`echo $5 | cut -f1 -d'.'`.png /glusterfs/povray/`hostname`.png

echo "`hostname`" >> /glusterfs/povray/lockfile
