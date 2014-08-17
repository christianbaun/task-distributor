#!/bin/bash
#
# title:        benchmark_start.sh
# description:  This script starts the benchmark runs of Task-Distributor.
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         August 17th 2014
# version:      1.2
# bash_version: 4.2.37(1)-release
# requires:     
# notes: 
# ----------------------------------------------------------------------------

RAW_DATA_PATH="Measurements_Raspberry_Pi_800MHz_POV-Ray" 

#for x in 800 1600 3200 6400
for x in 3200
do
  if [ $x -eq 800 ]  ; then y=600  ; fi
  if [ $x -eq 1600 ] ; then y=1200 ; fi  
  if [ $x -eq 3200 ] ; then y=2400 ; fi
  if [ $x -eq 6400 ] ; then y=4800 ; fi  
  for i in 1 2 4 8
  do
    ./task-distributor-master.sh -n ${i} -x ${x} -y ${y} -p /glusterfs/povray -c > ${RAW_DATA_PATH}/${x}x${y}_${i}_Nodes_`date +%Y_%m_%d_%H:%M:%S`.txt 2>&1
    sleep 10
  done
done

