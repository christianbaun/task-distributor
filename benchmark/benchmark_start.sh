#!/bin/bash
#
# title:        benchmark_start.sh
# description:  This script starts the benchmark runs of Task-Distributor.
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         Oktober 12th 2015
# version:      1.6
# bash_version: 4.2.37(1)-release
# requires:     
# notes: 
# ----------------------------------------------------------------------------

RAW_DATA_PATH="Measurements_Raspberry_Pi2_900MHz_POV-Ray_2015" 

# Check if the directory for the results does not already exist  
if [ ! -d ${RAW_DATA_PATH} ]; then  
  mkdir ${RAW_DATA_PATH}                
fi

# Path of the folder (on a distributed file system) where the workers 
# store the povray files
PATH_FS="/glusterfs8repl/povray" 

# Path of the lockfile on a file system, which can be accessed by all nodes
LOCKFILE="/glusterfs8repl/povray/lockfile"

# Check if the lockfile already exists
if [ -e ${LOCKFILE} ] ; then
  # Terminate the script, in case the lockfile already exists
  echo "File ${LOCKFILE} already exists!" && exit 1
fi

for x in 600 800 1024 1280 1600 3200 4800 6400 9600
do
  if [ $x -eq 400 ]  ; then y=300  ; fi
  if [ $x -eq 800 ]  ; then y=600  ; fi
  if [ $x -eq 1024 ] ; then y=768  ; fi
  if [ $x -eq 1280 ] ; then y=960  ; fi
  if [ $x -eq 1600 ] ; then y=1200 ; fi  
  if [ $x -eq 3200 ] ; then y=2400 ; fi
  if [ $x -eq 4800 ] ; then y=3600 ; fi
  if [ $x -eq 6400 ] ; then y=4800 ; fi  
  if [ $x -eq 9600 ] ; then y=7200 ; fi
for i in 1 2 4 8
  do
    ./task-distributor-master.sh -n ${i} -x ${x} -y ${y} -p ${PATH_FS} -c > ${RAW_DATA_PATH}/${x}x${y}_${i}_Nodes_`date +%Y_%m_%d_%H:%M:%S`.txt 2>&1
    sleep 10
  done
done

