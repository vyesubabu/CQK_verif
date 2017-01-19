#!/bin/sh
#
# NOTE: This script is to analyze track and intensity error
#       for a set of model forecasts with the basin-wide
#       input that contains many models and cycles (a-deck)
#
# INPUT: 1. An input file "diag_namelist.txt" contains the full
#           path to the a-deck files
#        2. A best track data analysis file (observation)
#        These 2 inputs have to be linked to this home dir
#
# OUTPUT: multiple output files in grads format and track file 
#         in the text format for plotting.
#
# HIST: Nov 03, 2011: created
#
# AUTHOR: Chanh Kieu, EMC (chanh.kieu@noaa.gov)
#
#=================================================================
home="/state/partition1/home/kieuc/bio/ncep/programs"
models="HWRF"                             # forecast models
ahome="${home}/Statistics/abdeck_nhc"     # path to adeck
bhome="${home}/Statistics/abdeck_nhc"     # path to bdeck
error_1day="70"                           # 1d-threshold err(km)
error_2day="90"                           # 2d-threshold err(km)
error_3day="120"                           # 3d-threshold err(km)
#
# create first a forecast lead time from the actf hist file 
#
for model in `echo ${models}`
do
 if [ -s ./diag_statistics_${model}.dat ]; then
  echo "./diag_statistics_${model}.dat exits. Run diag_mean.exe now"
  echo "$error_1day $error_2day $error_3day" > fort.12
  echo "diag_statistics_${model}.dat" >> fort.12
  ofile="./diag_output_${model}_${error_1day}_${error_2day}_${error_3day}.txt"
  ./diag_mean.exe < fort.12 > ./output/log.diag_mean
  mv statistics_model.dat $ofile
  exit 0
 fi
done
. ./func_cal_time2.sh
rm -rf fort.* ./output/tmp.*
icycle=1
while read adeck
do
  storm_id=`echo "${adeck}" | cut -c2-9`
  bdeck="${bhome}/b${storm_id}.dat"
  if [ -s $ahome/$adeck ] && [ -s $bdeck ]; then
   echo "adeck and bdeck files exist, move on"
  else
   echo "$ahome/$adeck does not exist, or"
   echo "$bdeck does not exist... exit 1"
   exit 1
  fi 
  for model in `echo ${models}`
  do
   echo "Working with model = $model; adeck = $adeck; bdeck = $bdeck"
#
# first pick out the forecast of each model from the adeck
#
   tmp_file="./output/tmp.${model}.${storm_id}.dat"
   rm -rf ./output/tmp.${model}
   grep ${model} ${ahome}/${adeck}> ${tmp_file}   
#
# next pick out the cycles of each model forecast, one cycle
# per file
#
   prefix="./output/tmp.${model}.${storm_id}.c"
   rm -rf ${prefix}*.dat
   icount=1
   itime=1
   while read inline
   do
    time_input="$inline"
    in_string=`echo ${time_input} | cut -c9-18`
    if [ "${icount}" -eq "1" ]; then
     echo "${inline}" > ${prefix}${itime}.dat
    else
     if [ "${in_string}" -eq "${save_string}" ]; then
      echo "${inline}" >> ${prefix}${itime}.dat
     else
      itime=$(($itime + 1))
      echo "${inline}" >> ${prefix}${itime}.dat
     fi
    fi
    save_string=${in_string}
    icount=$(($icount+1))
   done < ${tmp_file}
#
# advance time step in each cycle to match with observation
#
   for ifile in `ls ${prefix}*.dat`
   do
    echo "Doing statistics at cycle $ifile"
    rm -rf fort.10 
    while read line
    do
     time_input="$line"
     in_string=`echo ${time_input} | cut -c9-18`
     fsct_time=`echo ${line} | awk '{print $6}' | sed 's/,//g' | awk '{print $0+0}'`
     addh ${in_string} ${fsct_time} E_YEAR E_MONTH E_DAY E_HOUR
     fsc_time="${E_YEAR}${E_MONTH}${E_DAY}${E_HOUR}" 
     new_line=`echo "$line" | sed "s/${in_string}/${fsc_time}/"`
     echo "$new_line" ${in_string} >> fort.10
    done < ${ifile}
    cp ./fort.10 ${ifile}
#
# call an external fortran code to do statistics for each cycle
# per each mode
# 
    ln -sf ${bdeck} ./fort.11
    ls fort.10 > in.txt
    ls fort.11 >> in.txt
    ./diag_core.exe < in.txt > ./output/log.diag_core
    cycle_id=`echo ${ifile} | sed "s/\.\/output\/tmp//"`
    mv fsct_error.dat ./output/diag_fsct_error${cycle_id}
    mv grads.dat ./output/diag_grads${cycle_id}
    mv track_fst.dat ./output/diag_track_fst${cycle_id}
    mv track_obs.dat ./output/diag_track_obs${cycle_id}
   done 
  done
done < diag_namelist.txt
#
# Finally combine all kind of errors into a single file, one
# for each model
#
for model in `echo ${models}`
do
 diag_err="./diag_statistics_${model}.dat"
 rm -rf $diag_err
 for ifile in `ls ./output/diag_fsct*${model}*.dat`
 do
  cat ${ifile} >> ${diag_err}
 done
done  
#
# calling the last step to compute the yearly mean for 
# with some good track criteria
#
echo "$error_1day $error_2day $error_3day" > fort.12
echo "diag_statistics_${model}.dat" >> fort.12
./diag_mean.exe < fort.12
mv statistics_model.dat ./diag_output_${model}_${error_1day}_${error_2day}_${error_3day}.txt
rm -f fort* in.txt 
