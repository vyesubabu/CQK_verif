#!/bin/bash
#
# NOTE: this script is to plot the correlation of the first 6-h change of
#       hurricane Pmin and Vmax, given an adeck file and bdeck file, and 
#       the forecast hour that you want to compute tendency
#
# HOW TO RUN: TO run this script, you only need to edit
#       1. pw_corelation.sh: (one time) change the path to adeck/bdeck 
#       2. pw_namelist.txt: select the adeck files (storms) you want to
#          run. 
#        After that, run:
#       ./pw_corelation.sh model HH
#       You should see a text file: pw_out_$model_$HH.txt after the script
#       finished. The file lists the 6-h change of vmax and pmin for all
#       forecast cycles of all storms listed on the namelist.txt  
#
# HIST: Jan, 24 2012: created by CK  
#
# AUTHOR: Chanh Kieu (chanh.kieu@noaa.gov)   
#
#=======================================================================
#set -x
home_path="/mnt/lfs2/projects/hwrfv3/Chanh.Kieu/programs"
#adeck_path="$home_path/Statistics/baseline_FY2014/clean"
#bdeck_path="$home_path/Statistics/baseline_FY2014"
adeck_path="/mnt/lfs2/projects/hwrfv3/Chanh.Kieu/programs/Statistics/baseline_FY2014/BLND/"
bdeck_path="/mnt/lfs2/projects/hwrfv3/Chanh.Kieu/programs/Statistics/baseline_FY2014/BLND/"
if [ $# == 2 ];  then
 model=$1
 hour_fsct=$2
 ifile=1
 rm -f fort* out_*.txt
 while read afile 
 do
  storm_id=`echo ${afile:1:8}`
  storm_name=`echo "${storm_id}" | cut -c3-4`
  storm_basin=`echo "${storm_id}" | cut -c1-2`
  storm_year=`echo "${storm_id}" | cut -c5-8`
  if [ "$model" == "BEST" ]; then
   adeck="${adeck_path}/b${storm_id}.dat"
  else
   adeck="${adeck_path}/a${storm_id}.dat"
  fi
  bdeck="${bdeck_path}/b${storm_id}.dat"
  echo "working with afile = $afile; storm_id = ${storm_id}"
#
# First, check for the validity of the inputs
#
  check_model=`grep ${model} ${adeck} | grep ${storm_name} | awk '{print $2}'`
  if [ "$check_model" == "" ]; then
   echo "$model does not exist in adeck/bdeck..."
   exit 2
  else
   echo "$model is validated. Continue ..."
  fi
#
# next grep the initial time and the fsct time and then advance the time
# step 1 up to match with obs time
# 
  grep ${model} ${adeck} | awk '($6=="0,")||($6=="00,")||($6=="000,") {print $0}' > fort.10
  grep ${model} ${adeck} | awk '($6=="'${hour_fsct}',")||($6=="0'${hour_fsct}',") \
                                          ||($6=="00'${hour_fsct}',") {print $0}' > fort.11 
  . ./func_cal_time2.sh
  while read line
  do
   time_input="$line"
   in_year=`echo "${time_input}" | cut -c9-12`
   in_month=`echo "${time_input}" | cut -c13-14`
   in_day=`echo "${time_input}" | cut -c15-16`
   in_hour=`echo "${time_input}" | cut -c17-18`
   temp=`echo "${time_input}" | cut -c31-33`
   fsct_time=`echo ${fsct_time} | sed 's/^0*//'`
   if [ "${fsct_time}" == ""  ]; then
    fsct_time=0
   fi
   fsct_time=`echo ${fsct_time} | tr -s " "`
   in_string="${in_year}${in_month}${in_day}${in_hour}"
   addh ${in_string} ${fsct_time} E_YEAR E_MONTH E_DAY E_HOUR
   #echo "${in_string} ${fsct_time} ${E_YEAR}${E_MONTH}${E_DAY}${E_HOUR}"
   fsc_time="${E_YEAR}${E_MONTH}${E_DAY}${E_HOUR}"
   new_line=`echo "$line" | sed "s/${in_string}/${fsc_time}/"`
   echo "${new_line:0:96}" ${in_string} >> fort.12
  done < fort.11
  ln -sf ${bdeck} ./fort.13
#
# finally run the program to compute the 6-tendency (fort.11) or 6-h
# error (fort.12). Note here that
# - fort.14: text file contains the inputs file for  pw_corelation_step1.exe
# - fort.11: atcf file contains 6-h forecast
# - fort.10: atcf file contains initial condition for fort.11
# - fort.12: the same as fort.11 but the time stamp has been shifted 6-h 
#            in advance to match with obs in fort.13
# - fort.13: best track
#
  ls fort.11 > fort.14
  ls fort.13 >> fort.14
  ls fort.10 >> fort.14
  ./pw_corelation_step1.exe < fort.14 >& fort.log
  mv out.txt out_${ifile}.txt
  ifile=$(($ifile+1))
  #echo "done at $ifile...sleep now"
  #sleep 10
 done < pw_namelist.txt 
 echo $(($ifile-1)) > fort.15
 ./pw_corelation_step2.exe < fort.15
 mv pw_out.txt pw_out_${model}_${hour_fsct}.txt
 mv fort* ./output/
 mv out_*.txt ./output/
else
 echo "Wrong input. Please run the script as follows:"
 echo "./pw_correlation.sh model hour_fsct"
 echo "E.g: pw_correlation.sh HWRF 6" 
fi
