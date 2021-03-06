#!/bin/bash
#
# title:        benchmark_analyze.sh
# description:  This script analyzes the results of Task-Distributor runs.
#               The script searches for result files in the path which is 
#               stored in the variable $RAW_DATA_PATH.
#               This script outputs the results in the shell and it creats a
#               file results.csv too which contains the results for further
#               analyzing with gnuplot or any other tool.
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://github.com/christianbaun/task-distributor
# license:      GPLv2
# date:         October 9th 2016
# version:      1.4.1
# bash_version: 4.2.37(1)-release
# requires:     bc 1.06.95
# notes: 
# ----------------------------------------------------------------------------

RAW_DATA_PATH="Measurements_Raspberry_Pi_800MHz_POV-Ray"
RESULTS_FILE="results2015_V3.csv"

# If a CSV file with the results already exists => erase it
if [ -e ${RESULTS_FILE} ] ; then
  rm ${RESULTS_FILE}
fi

# Print out the headline of the CSV file
echo "X-Resolution Y-Resolution Nodes DurSeqPart1 DurSeqPart2 DurParPart EntireDurSum ParPort SeqPort" >> "${RESULTS_FILE}"

for X in 200 400 800 1024 1280 1600 3200 4800 6400 9600
do
  if [ $X -eq 200 ]  ; then Y=150  ; fi
  if [ $X -eq 400 ]  ; then Y=300  ; fi
  if [ $X -eq 800 ]  ; then Y=600  ; fi
  if [ $X -eq 1024 ] ; then Y=768  ; fi
  if [ $X -eq 1280 ] ; then Y=960  ; fi
  if [ $X -eq 1600 ] ; then Y=1200 ; fi
  if [ $X -eq 3200 ] ; then Y=2400 ; fi
  if [ $X -eq 4800 ] ; then Y=3600 ; fi
  if [ $X -eq 6400 ] ; then Y=4800 ; fi
  if [ $X -eq 9600 ] ; then Y=7200 ; fi
  for N in 1 2 4 8
  do
    # It is important here to not check the existence of files via
    # [ -e <filesname_with_wildcard> ] 
    # Otherwise we get an error "binary operator expected" when more than
    # just a single file meets the test criteria.
    ls ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt > /dev/null 2>&1
    # "$?" contains the return code of the last command executed.
    if [ "$?" = "0" ] ; then
      echo "Resolution:                         ${X}x${Y}"
      echo "Nodes = CPUs:                       ${N}"
      echo "Number of raw data files fount:     `ls -l ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | wc -l`"
      SEQ1=`tail --lines=3 ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | grep 1st | awk '{ SUM += $9} END { print SUM/NR }'`
      echo "Duration 1st sequential part:       ${SEQ1} s"
      SEQ2=`tail --lines=3 ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | grep 2nd | awk '{ SUM += $9} END { print SUM/NR }'`
      echo "Duration 2nd sequential part:       ${SEQ2} s"
      PAR=`tail --lines=3 ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | grep parallel | awk '{ SUM += $8} END { print SUM/NR }'`
      echo "Duration parallel Part:             ${PAR} s"
      SUM=`echo "${SEQ1} + ${SEQ2} + ${PAR}" | bc`    
      echo "Entire duration (sum):              ${SUM} s"
      PARPOR=`echo "scale = 4 ; (${PAR} / ${SUM})/1" | bc`
      PARPORFINAL=`echo "scale = 2 ; (${PARPOR} * 100)/1" | bc`
      echo "Parallel portion:                   ${PARPORFINAL} %"
      # The sed command ensures that results < 1 have a leading 0 before the "."
      SEQPOR=`echo "scale = 2 ; ((1 - ${PARPOR}) * 100)/1" | bc | sed 's/^\./0./'`
      echo "Sequential portion:                 ${SEQPOR} %"  
   
      # If the number of nodes = 1, we need to save the entire duration (SUM) to calculate the speedup.
      if [ "${N}" = "1" ] ; then
         SUM_ONE_NODE=${SUM}
      fi
      # Calculate the speedup
      SPEEDUP=`echo "scale = 2 ;(${SUM_ONE_NODE} / ${SUM})/1" | bc`
      echo "Speedup = (time_1_CPU/time_N_CPUs): ${SPEEDUP}"
      
      echo "${X} ${Y} ${N} ${SEQ1} ${SEQ2} ${PAR} ${SUM} ${PARPORFINAL} ${SEQPOR} ${SPEEDUP}" >> ${RESULTS_FILE}

      # This is just an empty line at the end of each block.
      echo ""
    else
      echo "${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt does not exist."
      # This is just an empty line at the end of each block.
      echo ""
    fi
  done
done
