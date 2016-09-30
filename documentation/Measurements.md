This page contains information about the measurements which were carried out with the Task-Distributor script and it contains some of the results.

The measurements were carried out on a cluster of 8 [Raspberry Pi](http://www.raspberrypi.org/) Model B single-board computers. Each node was overclocked to 800 MHz, connected to a 100 Mbps Ethernet switch and equipped with a 16 GB SanDisk Ultra Class 10 SDHC card. The operating system used [Raspbian](http://www.raspbian.org/) (image date: 2014-06-20) containing [Linux kernel](https://www.kernel.org/) version 3.12.

# Procedure #

Measurements were carried out automatically with this script **benchmark\_start.sh**.

```
#!/bin/bash
#
# title:        benchmark_start.sh
# description:  This script starts the benchmark runs of Task-Distributor.
# author:       Dr. Christian Baun --- http://www.christianbaun.de
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         August 24th 2014
# version:      1.3
# bash_version: 4.2.37(1)-release
# requires:     
# notes: 
# ----------------------------------------------------------------------------

RAW_DATA_PATH="Measurements_Raspberry_Pi_800MHz_POV-Ray" 

# Check if the directory for the results does not already exist  
if [ ! -d ${RAW_DATA_PATH} ]; then  
  mkdir ${RAW_DATA_PATH}                
fi

for x in 800 1600 3200 6400
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
```

This script **benchmark\_analyze.sh** collects the results from the measurement files, sums them up and prints them in a way which is easy to read.

```
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
# url:          https://code.google.com/p/task-distributor/
# license:      GPLv2
# date:         August 18th 2014
# version:      1.2.1
# bash_version: 4.2.37(1)-release
# requires:     bc 1.06.95
# notes: 
# ----------------------------------------------------------------------------

RAW_DATA_PATH="Measurements_Raspberry_Pi_800MHz_POV-Ray"
RESULTS_FILE="results.csv"

# If a CSV file with the results already exists => erase it
if [ -e ${RESULTS_FILE} ] ; then
  rm ${RESULTS_FILE}
fi

# Print out the headline of the CSV file
echo "X-Resolution Y-Resolution Nodes DurSeqPart1 DurSeqPart2 DurParPart EntireDurSum ParPort SeqPort" >> "${RESULTS_FILE}"

for X in 800 1600 3200 6400
do
  if [ $X -eq 800 ]  ; then Y=600  ; fi
  if [ $X -eq 1600 ] ; then Y=1200 ; fi
  if [ $X -eq 3200 ] ; then Y=2400 ; fi
  if [ $X -eq 6400 ] ; then Y=4800 ; fi
  for N in 1 2 4 8
  do
    # It is important here to not check the existence of files via
    # [ -e <filesname_with_wildcard> ] 
    # Otherwise we get an error "binary operator expected" when more than
    # just a single file meets the test criteria.
    ls ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt > /dev/null 2>&1
    # "$?" contains the return code of the last command executed.
    if [ "$?" = "0" ] ; then
      echo "Resolution:                     ${X}x${Y}"
      echo "Nodes:                          ${N}"
      echo "Number of raw data files fount: `ls -l ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | wc -l`"
      SEQ1=`tail --lines=3 ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | grep 1st | awk '{ SUM += $9} END { print SUM/NR }'`
      echo "Duration 1st sequential part:   ${SEQ1} s"
      SEQ2=`tail --lines=3 ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | grep 2nd | awk '{ SUM += $9} END { print SUM/NR }'`
      echo "Duration 2nd sequential part:   ${SEQ2} s"
      PAR=`tail --lines=3 ${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt | grep parallel | awk '{ SUM += $8} END { print SUM/NR }'`
      echo "Duration parallel Part:         ${PAR} s"
      SUM=`echo "${SEQ1} + ${SEQ2} + ${PAR}" | bc`    
      echo "Entire duration (sum):          ${SUM} s"
      PARPOR=`echo "scale = 4 ; (${PAR} / ${SUM})/1" | bc`
      PARPORFINAL=`echo "scale = 2 ; (${PARPOR} * 100)/1" | bc`
      echo "Parallel portion:               ${PARPORFINAL} %"
      # The sed command ensures that results < 1 have a leading 0 before the "."
      SEQPOR=`echo "scale = 2 ; ((1 - ${PARPOR}) * 100)/1" | bc | sed 's/^\./0./'`
      echo "Sequential portion:             ${SEQPOR} %"  

      echo "${X} ${Y} ${N} ${SEQ1} ${SEQ2} ${PAR} ${SUM} ${PARPORFINAL} ${SEQPOR}" >> results.csv

      # This is just an empty line at the end of each block.
      echo ""
    else
      echo "${RAW_DATA_PATH}/${X}x${Y}_${N}_Nodes_*.txt does not exist."
      # This is just an empty line at the end of each block.
      echo ""
    fi
  done
done
```

# Results #

```
$ ./benchmark_analyze.sh
Resolution:                     800x600
Nodes:                          1
Number of raw data files fount: 10
Duration 1st sequential part:   0.2055 s
Duration 2nd sequential part:   0.1938 s
Duration parallel Part:         34.9172 s
Entire duration (sum):          35.3165 s
Parallel portion:               98.86 %
Sequential portion:             1.14 %

Resolution:                     800x600
Nodes:                          2
Number of raw data files fount: 10
Duration 1st sequential part:   0.2066 s
Duration 2nd sequential part:   1.5514 s
Duration parallel Part:         21.1664 s
Entire duration (sum):          22.9244 s
Parallel portion:               92.33 %
Sequential portion:             7.67 %

Resolution:                     800x600
Nodes:                          4
Number of raw data files fount: 10
Duration 1st sequential part:   0.2027 s
Duration 2nd sequential part:   1.6316 s
Duration parallel Part:         14.9445 s
Entire duration (sum):          16.7788 s
Parallel portion:               89.06 %
Sequential portion:             10.94 %

Resolution:                     800x600
Nodes:                          8
Number of raw data files fount: 10
Duration 1st sequential part:   0.242 s
Duration 2nd sequential part:   1.8385 s
Duration parallel Part:         12.7261 s
Entire duration (sum):          14.8066 s
Parallel portion:               85.94 %
Sequential portion:             14.06 %

Resolution:                     1600x1200
Nodes:                          1
Number of raw data files fount: 10
Duration 1st sequential part:   0.2051 s
Duration 2nd sequential part:   0.2044 s
Duration parallel Part:         132.84 s
Entire duration (sum):          133.2495 s
Parallel portion:               99.69 %
Sequential portion:             0.31 %

Resolution:                     1600x1200
Nodes:                          2
Number of raw data files fount: 10
Duration 1st sequential part:   0.2165 s
Duration 2nd sequential part:   4.6648 s
Duration parallel Part:         73.4805 s
Entire duration (sum):          78.3618 s
Parallel portion:               93.77 %
Sequential portion:             6.23 %

Resolution:                     1600x1200
Nodes:                          4
Number of raw data files fount: 10
Duration 1st sequential part:   0.2421 s
Duration 2nd sequential part:   4.6244 s
Duration parallel Part:         48.7796 s
Entire duration (sum):          53.6461 s
Parallel portion:               90.92 %
Sequential portion:             9.08 %

Resolution:                     1600x1200
Nodes:                          8
Number of raw data files fount: 10
Duration 1st sequential part:   0.2034 s
Duration 2nd sequential part:   4.8014 s
Duration parallel Part:         32.4577 s
Entire duration (sum):          37.4625 s
Parallel portion:               86.64 %
Sequential portion:             13.36 %

Resolution:                     3200x2400
Nodes:                          1
Number of raw data files fount: 10
Duration 1st sequential part:   0.2411 s
Duration 2nd sequential part:   0.233 s
Duration parallel Part:         609.427 s
Entire duration (sum):          609.9011 s
Parallel portion:               99.92 %
Sequential portion:             0.08 %

Resolution:                     3200x2400
Nodes:                          2
Number of raw data files fount: 10
Duration 1st sequential part:   0.2026 s
Duration 2nd sequential part:   15.2428 s
Duration parallel Part:         331.059 s
Entire duration (sum):          346.5044 s
Parallel portion:               95.54 %
Sequential portion:             4.46 %

Resolution:                     3200x2400
Nodes:                          4
Number of raw data files fount: 10
Duration 1st sequential part:   0.2297 s
Duration 2nd sequential part:   15.1452 s
Duration parallel Part:         209.375 s
Entire duration (sum):          224.7499 s
Parallel portion:               93.15 %
Sequential portion:             6.85 %

Resolution:                     3200x2400
Nodes:                          8
Number of raw data files fount: 10
Duration 1st sequential part:   0.2171 s
Duration 2nd sequential part:   15.5424 s
Duration parallel Part:         131.78 s
Entire duration (sum):          147.5395 s
Parallel portion:               89.31 %
Sequential portion:             10.69 %

Resolution:                     6400x4800
Nodes:                          1
Number of raw data files fount: 9
Duration 1st sequential part:   0.215444 s
Duration 2nd sequential part:   0.473444 s
Duration parallel Part:         2435.72 s
Entire duration (sum):          2436.408888 s
Parallel portion:               99.97 %
Sequential portion:             0.03 %

Resolution:                     6400x4800
Nodes:                          2
Number of raw data files fount: 10
Duration 1st sequential part:   0.2093 s
Duration 2nd sequential part:   120.858 s
Duration parallel Part:         1320.53 s
Entire duration (sum):          1441.5973 s
Parallel portion:               91.60 %
Sequential portion:             8.40 %

Resolution:                     6400x4800
Nodes:                          4
Number of raw data files fount: 9
Duration 1st sequential part:   0.214 s
Duration 2nd sequential part:   120.432 s
Duration parallel Part:         819.666 s
Entire duration (sum):          940.312 s
Parallel portion:               87.16 %
Sequential portion:             12.84 %

Resolution:                     6400x4800
Nodes:                          8
Number of raw data files fount: 9
Duration 1st sequential part:   0.208667 s
Duration 2nd sequential part:   120.139 s
Duration parallel Part:         509.656 s
Entire duration (sum):          630.003667 s
Parallel portion:               80.89 %
Sequential portion:             19.11 %
```