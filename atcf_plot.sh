#!/bin/bash
#
# NOTE: This script is for pulling the track data from an ATCF file and
#       plot either tracks for an ensemble of models (ensemble mode) or
#       tracks for a composite of a single storm (composite mode).
#
# INPUT:  1. adeck and bdeck files for plotting the track and intensity
#            composie or ensemble
#         2. two base map files (basemap.ctl and basemap.dat)
#         3. some env setup as dictated in the namelist section below
#
# OUTPUT: all figures are stored in ./figures, and text files that were 
#         used to plot the figs are stored in ./output   
#
# HOW TO RUN: To run this script, you first need to edit this main 
#         script with some proper environmental setting and graphic
#         options (see below). Then run:
#         1. Composite plots of 1 single storm with all forecast cycles:
#
#         ./atcf_plot.sh composite YYYYMMDDHH YYYYMMDDHH model STORM_NAME alNNYYYY HH
#
#         2. ensemble plots of many models for one cycle
#          
#         ./atcf_plot.sh ensemble YYYYMMDDHH YYYYMMDDHH STORM_NAME alNNYYYY atcf_namelist.txt
#                
# DEPENDENCE:
#         1. atcf_plot_composite_track.gs: this script plots ensemble
#            of track. It will call atcf_plot_all_track as the main
#            plotting fucntion and then draw some background information
#         2. atcf_plot_composite_intensity/vmax.gs: plot the pmin/vmax 
#            composite plot
#         3. func_cal_time2.sh: computing time/date for each cycle
#
# HISTORY: - Jan 06, 2012: created 
#          - Jan 11, 2012: added pmin/vmax capability
#          - Jan 16, 2012: added ensemble of models capability
#          - APr 10, 2012: update the multi-cycle for ensemble option
#       
# AUTHOR: Chanh Kieu (chanh.kieu@noaa.gov, NOAA/NWS/NCEP/EMC)
#
#======================================================================
#
# NAMELSIT to setup environment and Grads graphic
#
home_path="/mnt/lfs2/projects/hwrfv3/Chanh.Kieu/programs/"  # home path
adeck_path="${home_path}/Statistics/baseline_FY2014/"
bdeck_path="${home_path}/Statistics/baseline_FY2014/"       # path to bdeck
#adeck_path="/lfs1/projects/hwrf-vd/hwrf-input/DECKS/"
#bdeck_path="/lfs1/projects/hwrf-vd/hwrf-input/DECKS/"
atcf_hour=6                                                 # atcf hour interval 
#
# 1. Option for plotting the composite of track/intensity
#
. ./func_cal_time2.sh
if [ "$1" == "composite" ] && [ $# == 7 ];  then
 date_start=$2
 date_end=$3
 model=$4
 storm_name=$5
 storm=$6
 file_interval=$7
 yyyy=`echo $date_start | cut -c1-4`
 adeck="${adeck_path}/a${storm}.dat"
 bdeck="${bdeck_path}/b${storm}.dat"
 echo "Starting date for composite plot is: $date_start"
 echo "Ending date for composite plot is: $date_end"
 echo "Adeck file is: $adeck"
 echo "Bdeck file is: $bdeck"
 check_bdeck=`grep $date_start $bdeck | head -n 1`
 check_time1=`grep $date_start $adeck | grep $model | head -n 1` 
 check_time2=`grep $date_end $adeck | grep $model | head -n 1`
 if [ "$check_bdeck" == "" ] || [ "$check_time1" == "" ] \
 || [ "$check_time2" == "" ]; then
  echo "Starting/ending date for composite plot donot exist in adeck..."
  exit 2
 else
  echo "Starting/ending date are validated. Continue ..."
 fi
 rm -f ./output/* 
#
# create a set of track text file for Grads plots. Each cycle correspnonds
# to a track file named track_mem_x.txt
#
 fcount=1
 marktype=1              # mark type for plotting each cycle/member
 marksize=0.2            # mark size at each atcf hour
 markcolor=2             # color of line/mark for each cycle/member
 markthick=13            # thickness of plotting line (Grads)
 markstyle=1             # style of plotting line in GRADS convention
 pmin1=9999              # default lower bound for pmin Grads plot
 pmin2=1010              # upper bound for pmin Grads plot
 vmax1=0                 # lower bound for vmax Grads plot
 vmax2=150               # upper bound for vmax Grads plot
 lat_min=999
 lat_max=-999
 lon_min=999
 lon_max=-999
 ftime_max=0
 time_to_process=${date_start}
 while [ "$time_to_process" -le "${date_end}" ];
 do
  echo "Extracting the track forecast of $model at $time_to_process"
  grep $time_to_process $adeck | grep "${model}," | awk '{print $6}'      | sed 's/,//g' | awk '{if($1<=126) print $1}' > fort.9
  grep $time_to_process $adeck | grep "${model}," | awk '{print $6" "$7}' | sed 's/,//g' | awk '{if($1<=126) print $2}' > fort.10
  grep $time_to_process $adeck | grep "${model}," | awk '{print $6" "$8}' | sed 's/,//g' | awk '{if($1<=126) print $2}' > fort.11
  grep $time_to_process $adeck | grep "${model}," | awk '{print $6" "$9}' | sed 's/,//g' | awk '{if($1<=126) print $2}' > fort.20
  grep $time_to_process $adeck | grep "${model}," | awk '{print $6" "$10}' | sed 's/,//g'| awk '{if($1<=126) print $2}' > fort.21
  p_min=`awk '{if(pm=="")(pm=$1); if($1<pm)(pm=$1)} END {print pm}' fort.21`
  rc=`echo "$p_min < $pmin1" | bc`
  if [ $rc == 1 ]; then
   pmin1=${p_min}
  fi
#  if [[ $p_min < $pmin1 ]]; then
#   pmin1=${p_min}
#  fi 
  lat_sign=`cat fort.10 | grep N | head -n 1`
  lon_sign=`cat fort.11 | grep W | head -n 1`
  if [ "$lat_sign" != "" ]; then
   cat fort.10 | sed 's/N//' | awk '{print $1/10}' > fort.12
  else
   cat fort.10 | sed 's/N//' | awk '{print -1*$1/10}' > fort.12
  fi
  if [ "$lon_sign" != "" ]; then
   cat fort.11 | sed 's/N//' | awk '{print -1*$1/10}' > fort.13
  else
   cat fort.11 | sed 's/N//' | awk '{print $1/10}' > fort.13
  fi 
  track_file="track_mem_${fcount}.txt"
  echo "Track forecast of $model for cycle $time_to_process" > ${track_file}
  echo "$marktype $marksize" >> ${track_file}
  echo "$markcolor $markstyle $markthick" >> ${track_file}
  echo "0 ${atcf_hour}" >> ${track_file}
  intensity_file="intensity_mem_${fcount}.txt"
  echo "Intensity forecast of $model for cycle $time_to_process" > ${intensity_file}
  echo "$marktype $marksize" >> ${intensity_file}
  echo "$markcolor $markstyle $markthick" >> ${intensity_file}
  echo "0 ${atcf_hour}" >> ${intensity_file}
  i=1
  while read ilon
  do
   ftime=`head -n ${i} fort.9 | tail -1`
   ilat=`head -n ${i} fort.12 | tail -1`
   vmax=`head -n ${i} fort.20 | tail -1`
   pmin=`head -n ${i} fort.21 | tail -1`
   ftime_intensity=`echo "$ftime + ($fcount -1)*${file_interval}" | bc`
   ftime_track=`echo $ftime | sed 's/^0*//'`
   if [ "${ftime_track}" == ""  ]; then
    ftime_track="0"
   fi
   if [ "${ftime}" != "${ftime_old}" ]; then
    echo "${ftime_track} $ilon $ilat" >> ${track_file}
    echo "${ftime_intensity} $pmin $vmax" >> ${intensity_file}
    rc=`echo "$lat_min > $ilat" | bc` 
    if [ $rc == 1 ]; then 
     lat_min=$ilat 
    fi
    rc=`echo "$lon_min > $ilon" | bc`
    if [ $rc == 1 ]; then
     lon_min=$ilon 
    fi
    rc=`echo "$lat_max < $ilat" | bc`
    if [ $rc == 1 ]; then  
     lat_max=$ilat 
    fi
    rc=`echo "$lon_max < $ilon" | bc`
    if [ $rc == 1 ]; then
     lon_max=$ilon 
    fi
   fi
   ftime_old=$ftime
   i=$(($i+1)) 
  done < fort.13
  if [[ "$ftime_max" -lt "$ftime_intensity" ]]; then
   ftime_max=$ftime_intensity
  fi
  addh ${time_to_process} ${file_interval} E_YEAR E_MONTH E_DAY E_HOUR
  time_to_process="${E_YEAR}${E_MONTH}${E_DAY}${E_HOUR}" 
  markcolor=$(($markcolor+1))
  if [ "$markcolor" == "16" ]; then
   markcolor=2
  fi
  if [ "$markcolor" == "6" ]; then
   markcolor=7
  fi
  fcount=$(($fcount+1))
 done
 lat_min=`echo "$lat_min-5" | bc`
 lon_min=`echo "$lon_min-5" | bc`
 lat_max=`echo "$lat_max+5" | bc`
 lon_max=`echo "$lon_max+5" | bc`
 echo "${model} forecast: ${storm_name} (${storm})" > fort.14
 echo "$lat_min $lat_max $lon_min $lon_max" >> fort.14
 echo "$fcount" >> fort.14
 echo "$ftime_max" >> fort.14
#
# create the best track file finally
#
 echo "Extracting the best track "
 start_line=`grep -n $date_start $bdeck | awk '{print $1}' | head -1 | sed 's/[A-Z]//g;s/://g;s/,//g'`
 grep -A999 $date_start $bdeck | awk '{print $3}' | sed 's/,//g' > fort.9
 grep -A999 $date_start $bdeck | awk '{print $7}' | sed 's/,//g' > fort.10
 grep -A999 $date_start $bdeck | awk '{print $8}' | sed 's/,//g' > fort.11
 grep -A999 $date_start $bdeck | awk '{print $9}' | sed 's/,//g' > fort.20
 grep -A999 $date_start $bdeck | awk '{print $10}' | sed 's/,//g' > fort.21
 lat_sign=`cat fort.10 | grep N | head -n 1`
 lon_sign=`cat fort.11 | grep W | head -n 1`
 if [ "$lat_sign" != "" ]; then
  cat fort.10 | sed 's/N//' | awk '{print $1/10}' > fort.12
 else 
  cat fort.10 | sed 's/N//' | awk '{print -1*$1/10}' > fort.12
 fi 
 if [ "$lon_sign" != "" ]; then
  cat fort.11 | sed 's/N//' | awk '{print -1*$1/10}' > fort.13
 else 
  cat fort.11 | sed 's/N//' | awk '{print $1/10}' > fort.13
 fi 
 track_file="track_mem_${fcount}.txt"
 echo "Observed track of the $storm for BEST" > ${track_file}
 echo "$marktype $marksize" >> ${track_file}
 echo "1 $markstyle 9" >> ${track_file}
 echo "0 ${atcf_hour}" >> ${track_file}  
 intensity_file="intensity_mem_${fcount}.txt"
 echo "Observed intensity of the $storm for BEST" > ${intensity_file}
 echo "$marktype $marksize" >> ${intensity_file}
 echo "1 $markstyle 9" >> ${intensity_file}
 echo "0 ${atcf_hour}" >> ${intensity_file}
 i=1
 j=1
 while read ilon
 do
  ftime=`head -n ${i} fort.9 | tail -1`
  ilat=`head -n ${i} fort.12 | tail -1`
  vmax=`head -n ${i} fort.20 | tail -1`
  pmin=`head -n ${i} fort.21 | tail -1`
  if [ "${ftime}" != "${ftime_old}" ]; then
   otime=$((($j-1)*$atcf_hour))
   echo "$otime $ilon $ilat" >> ${track_file}
   echo "$otime $pmin $vmax" >> ${intensity_file}
   ftime_old=$ftime
   j=$(($j+1))
  fi
  i=$(($i+1))
 done < fort.13
 pmin1=`echo "$pmin1 - 5" | bc`
 if [[ "$pmin1" < "850" ]]; then
  pmin1=850
 fi
 if [[ "$vmax2" > "180" ]]; then
  vmax2=180
 fi
 echo "$otime" >> fort.14
 echo "$vmax1" >> fort.14
 echo "$vmax2" >> fort.14
 echo "$pmin1" >> fort.14
 echo "$pmin2" >> fort.14
 echo "Going to plot with following options"
 more fort.14
# echo -n "You can edit fort.14 for better plot now. Want to edit? <y/n> "
# read edit_flag
 edit_flag="n"
 if [ "$edit_flag" == "y" ]; then
  echo "Ctrl+z for editting, otherwise will plot after 10s"
  sleep 10
 fi
 grads -xlbc atcf_plot_composite_track.gs >& fort.track
 grads -xlbc atcf_plot_composite_vmax.gs >& fort.vmax
 grads -xlbc atcf_plot_composite_pmin.gs >& fort.pmin
 mv fig_track.png fig_${storm_name}_${model}_${yyyy}_track.png
 mv fig_vmax.png fig_${storm_name}_${model}_${yyyy}_vmax.png
 mv fig_pmin.png fig_${storm_name}_${model}_${yyyy}_pmin.png
 mv fort* ./output/
 mv *_mem*.txt ./output/
 mv fig*.png ./figures/
 echo "DONE COMPOSITE PLOTTING FOR: $model ${storm} ${date_start}-${date_end}"
#
# 2. Option for plotting the ensemble of track/intensity for a given cycle
#
elif [ "$1" == "ensemble" ] && [ $# == 6 ];  then
 date_start=$2
 date_end=$3
 storm_name=$4
 storm=$5
 input_file=$6
 yyyy=`echo $date_start | cut -c1-4`
 adeck="${adeck_path}/a${storm}.dat"
 bdeck="${bdeck_path}/b${storm}.dat"
 echo "Starting date for the ensemble plot is: $date_start"
 echo "Ending date for the ensemble plot is: $date_end"
 echo "adeck file is: $adeck"
 echo "bdeck file is: $bdeck"
 echo "input namelist is $input_file"
#
# First, check for the validity of the inputs
#
 time_to_process=$date_start
 while [ "$time_to_process" -le "$date_end" ]; 
 do
  model_list=`grep list: ./${input_file} | awk '{print $2}'`
  flag=1
  for model in $( echo ${model_list})
  do
   if [ "$model" == "BEST" ]; then
    check_time=`grep $time_to_process $bdeck | grep $model | head -n 1`
   else
    check_time=`grep $time_to_process $adeck | grep $model | head -n 1`
   fi
   if [ "$check_time" == "" ]; then
    echo "Date ($time_to_process) for $model does not exist in adeck/bdeck..."
    flag=0
   else
    echo "Working date ($time_to_process) is validated for $model. Continue ..."
   fi
  done
  rm -f ./output/*
#
# create a set of track text file for Grads plots. Each cycle correspnonds
# to a track file named track_mem_x.txt
#
  if [ "$flag" == "1" ]; then
   marktype=1              # mark type for plotting each cycle/member
   marksize=0.2            # mark size at each atcf hour
   markcolor=2             # color of line/mark for each cycle/member
   markthick=13            # thickness of plotting line (Grads)
   markstyle=1             # style of plotting line in GRADS convention
   pmin1=9999              # default lower bound for pmin Grads plot
   pmin2=1018              # upper bound for pmin Grads plot
   vmax1=0                 # lower bound for vmax Grads plot
   vmax2=150               # upper bound for vmax Grads plot
   fcount=1
   lat_min=999
   lat_max=-999
   lon_min=999
   lon_max=-999
   for model in $( echo ${model_list})
   do
    if [ "$model" != "BEST" ]; then
     echo "Extracting the track forecast of $model at $time_to_process"
     grep $time_to_process $adeck | grep $model | awk '{print $6}'       | \
          sed 's/,//g' | awk '{if($1==0 || $1==6 || $1==12 || $1==24 ||    \
          $1==36 || $1==42 || $1==48 || $1==54 || $1==60 || $1==66 || $1== 72 \
          || $1==78 || $1==84 || $1==90 || $1==96 || $1==102 || $1==108    \
          || $1==112 || $1<=120) print $1}' > fort.9
     grep $time_to_process $adeck | grep $model | awk '{print $6" "$7}'  | \
          sed 's/,//g' | awk '{if($1==0 || $1==6 || $1==12 || $1==24 ||    \
          $1==36 || $1==42 || $1==48 || $1==54 || $1==60 || $1==66 || $1== 72 \
          || $1==78 || $1==84 || $1==90 || $1==96 || $1==102 || $1==108    \
          || $1==112 || $1<=120) print $2}' > fort.10
     grep $time_to_process $adeck | grep $model | awk '{print $6" "$8}'  | \
          sed 's/,//g' | awk '{if($1==0 || $1==6 || $1==12 || $1==24 ||    \
          $1==36 || $1==42 || $1==48 || $1==54 || $1==60 || $1==66 || $1== 72 \
          || $1==78 || $1==84 || $1==90 || $1==96 || $1==102 || $1==108    \
          || $1==112 || $1<=120) print $2}' > fort.11
     grep $time_to_process $adeck | grep $model | awk '{print $6" "$9}'  | \
          sed 's/,//g' | awk '{if($1==0 || $1==6 || $1==12 || $1==24 ||    \
          $1==36 || $1==42 || $1==48 || $1==54 || $1==60 || $1==66 || $1== 72 \
          || $1==78 || $1==84 || $1==90 || $1==96 || $1==102 || $1==108    \
          || $1==112 || $1<=120) print $2}' > fort.20
     grep $time_to_process $adeck | grep $model | awk '{print $6" "$10}' | \
          sed 's/,//g' | awk '{if($1==0 || $1==6 || $1==12 || $1==24 ||    \
          $1==36 || $1==42 || $1==48 || $1==54 || $1==60 || $1==66 || $1== 72 \
          || $1==78 || $1==84 || $1==90 || $1==96 || $1==102 || $1==108    \
          || $1==112 || $1<=120) print $2}' > fort.21
     p_min=`awk '{if(pm=="")(pm=$1); if($1<pm)(pm=$1)} END {print pm}' fort.21`
     if [[ "$p_min" < "$pmin1" ]]; then 
      pmin1=${p_min}
     fi  
     lat_sign=`cat fort.10 | grep N | head -n 1`
     lon_sign=`cat fort.11 | grep W | head -n 1`
     if [ "$lat_sign" != "" ]; then
      cat fort.10 | sed 's/N//' | awk '{print $1/10}' > fort.12
     else
      cat fort.10 | sed 's/N//' | awk '{print -1*$1/10}' > fort.12
     fi
     if [ "$lon_sign" != "" ]; then
      cat fort.11 | sed 's/N//' | awk '{print -1*$1/10}' > fort.13
     else
      cat fort.11 | sed 's/N//' | awk '{print $1/10}' > fort.13
     fi
     track_file="track_mem_${fcount}.txt"
     echo "Track forecast of $model for cycle $time_to_process" > ${track_file}
     echo "$marktype $marksize" >> ${track_file}
     echo "$markcolor $markstyle $markthick" >> ${track_file}
     echo "0 ${atcf_hour}" >> ${track_file}
     intensity_file="intensity_mem_${fcount}.txt"
     echo "Intensity forecast of $model for cycle $time_to_process" > ${intensity_file}
     echo "$marktype $marksize" >> ${intensity_file}
     echo "$markcolor $markstyle $markthick" >> ${intensity_file}
     echo "0 ${atcf_hour}" >> ${intensity_file}
     i=1
     otime=0
     while read ilon
     do
      ftime=`head -n ${i} fort.9 | tail -1`
      ilat=`head -n ${i} fort.12 | tail -1`
      vmax=`head -n ${i} fort.20 | tail -1`
      pmin=`head -n ${i} fort.21 | tail -1`
      ftime_intensity=`echo "$ftime + 0" | bc`
      ftime_track=`echo $ftime | sed 's/^0*//'`
      if [ "${ftime_track}" == ""  ]; then
       ftime_track="0"
      fi 
      if [ "${ftime}" != "${ftime_old}" ]; then
       echo "${otime} $ilon $ilat" >> ${track_file}
       echo "${ftime_intensity} $pmin $vmax" >> ${intensity_file}
       rc=`echo "$lat_min > $ilat" | bc` 
       if [ $rc == 1 ]; then 
        lat_min=$ilat 
       fi
       rc=`echo "$lon_min > $ilon" | bc`
       if [ $rc == 1 ]; then
        lon_min=$ilon  
       fi
       rc=`echo "$lat_max < $ilat" | bc`
       if [ $rc == 1 ]; then
        lat_max=$ilat
       fi
       rc=`echo "$lon_max < $ilon" | bc`
       if [ $rc == 1 ]; then
        lon_max=$ilon
       fi
       otime=$(($otime+$atcf_hour))
      fi
      ftime_old=$ftime
      i=$(($i+1))
     done < fort.13
     markcolor=$(($markcolor+1))
     if [ "$markcolor" == "16" ]; then
      markcolor=2
     fi
     if [ "$markcolor" == "6" ]; then
      markcolor=7
     fi
     fcount=$(($fcount+1)) 
    fi
   done
   lat_min=`echo "$lat_min-5" | bc`
   lon_min=`echo "$lon_min-5" | bc`
   lat_max=`echo "$lat_max+5" | bc`
   lon_max=`echo "$lon_max+5" | bc`
   echo "HWRF Forecast of ${storm_name} at ${time_to_process}" > fort.14
   echo "$lat_min $lat_max $lon_min $lon_max" >> fort.14
   echo "$fcount" >> fort.14
   echo "$ftime_intensity" >> fort.14
#
# create the best track file finally
#
   echo "Extracting the best track "
   addh ${time_to_process} 126 E_YEAR E_MONTH E_DAY E_HOUR
   end_to_process="${E_YEAR}${E_MONTH}${E_DAY}${E_HOUR}"
   ista=`grep -n $time_to_process $bdeck | head -n 1 | awk '{print $1}' | cut -d ':' -f 1`
   iend=`grep -n $end_to_process $bdeck | head -n 1 | awk '{print $1}' | cut -d ':' -f 1`
   ieof=`cat -n $bdeck | tail -n 1 | awk '{print $1}'`
   if [ "$ista" == "" ]; then
    ista=1
   fi
   if [ "$iend" == "" ]; then
    iend=$ieof
   fi
   echo "Line of bdeck to start is $ista, and end line is $iend eof is $ieof"
   sed -n ${ista},${iend}p $bdeck | awk '{print $3}' | sed 's/,//g' > fort.9
   sed -n ${ista},${iend}p $bdeck | awk '{print $7}' | sed 's/,//g' > fort.10
   sed -n ${ista},${iend}p $bdeck | awk '{print $8}' | sed 's/,//g' > fort.11
   sed -n ${ista},${iend}p $bdeck | awk '{print $9}' | sed 's/,//g' > fort.20
   sed -n ${ista},${iend}p $bdeck | awk '{print $10}' | sed 's/,//g' > fort.21
   lat_sign=`cat fort.10 | grep N | head -n 1`
   lon_sign=`cat fort.11 | grep W | head -n 1`
   if [ "$lat_sign" != "" ]; then
    cat fort.10 | sed 's/N//' | awk '{print $1/10}' > fort.12
   else 
    cat fort.10 | sed 's/N//' | awk '{print -1*$1/10}' > fort.12
   fi 
   if [ "$lon_sign" != "" ]; then
    cat fort.11 | sed 's/N//' | awk '{print -1*$1/10}' > fort.13
   else 
    cat fort.11 | sed 's/N//' | awk '{print $1/10}' > fort.13
   fi 
   track_file="track_mem_${fcount}.txt"
   echo "Observed track - BEST $storm " > ${track_file}
   echo "$marktype $marksize" >> ${track_file}
   echo "1 $markstyle 18" >> ${track_file}
   echo "0 ${atcf_hour}" >> ${track_file}
   intensity_file="intensity_mem_${fcount}.txt"
   echo "Observed intensity - BEST $storm " > ${intensity_file}
   echo "$marktype $marksize" >> ${intensity_file}
   echo "1 $markstyle 18" >> ${intensity_file}
   echo "0 ${atcf_hour}" >> ${intensity_file}
   i=1
   j=1
   while read ilon
   do
    ftime=`head -n ${i} fort.9 | tail -1`
    ilat=`head -n ${i} fort.12 | tail -1`
    vmax=`head -n ${i} fort.20 | tail -1`
    pmin=`head -n ${i} fort.21 | tail -1`
    if [ "${ftime}" != "${ftime_old}" ]; then
     otime=$((($j-1)*$atcf_hour))
     echo "$otime $ilon $ilat" >> ${track_file}
     echo "$otime $pmin $vmax" >> ${intensity_file}
     ftime_old=$ftime
     j=$(($j+1))
    fi
    i=$(($i+1))
   done < fort.13
   pmin1=`echo "$pmin1 - 5" | bc`
   echo "126" >> fort.14
   echo "$vmax1" >> fort.14
   echo "$vmax2" >> fort.14
   echo "910" >> fort.14
   echo "$pmin2" >> fort.14
   echo "Going to plot with following options"
   more fort.14
   echo -n "You can edit fort.14 for better plot now by ctr+z. Want to edit? <y/n> "
   #read edit_flag
   #edit_flag="n"
   #if [ "$edit_flag" == "y" ]; then
   # echo "Ctrl+z for editting, otherwise will plot after 10s"
   # sleep 10
   #fi
   grads -xlbc atcf_plot_ensemble_track.gs >& fort.track
   grads -xlbc atcf_plot_ensemble_vmax.gs >& fort.vmax
   grads -xlbc atcf_plot_ensemble_pmin.gs >& fort.pmin
   mv fig_track.png fig_${storm_name}_${time_to_process}_track.png
   mv fig_vmax.png fig_${storm_name}_${time_to_process}_vmax.png
   mv fig_pmin.png fig_${storm_name}_${time_to_process}_pmin.png
   mv fort* ./output/
   mv *_mem*.txt ./output/
   mv fig*.png ./figures/
   echo "DONE ENSEMBLE PLOTTING FOR: ${storm} ${time_to_process}"
   echo ""
  fi
  addh ${time_to_process} 6 E_YEAR E_MONTH E_DAY E_HOUR
  time_to_process="${E_YEAR}${E_MONTH}${E_DAY}${E_HOUR}"
 done
else
 echo "Script syntax is not correct. Please enter either:"
 echo "./atcf_plot.sh composite YYYYMMDDHH YYYYMMDDHH model STORM_NAME alNNYYYY HH"
 echo "or"
 echo "./atcf_plot.sh ensemble YYYYMMDDHH YYYYMMDDHH STORM_NAME alNNYYYY atcf_namelist.txt"
 exit 1
fi
