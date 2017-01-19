#!/bin/bash
#
# NOTE: This script is for tracing the history of the numbered and invest 
#       from a given input SYNDAT data file, storm name, and year
#
# HOW TO RUN: Just simply type: ./vital_trace.sh storm_id year 
#
# HIST: - 2013 Nov 7: created by Chanh Kieu
#       - 2003 Nov 8: redicted some of the output to text files for 
#                     later archiving and tracing. 
#========================================================================
#
# define first an internal function for comparing the difference
#
function abs_compare {
d=`expr $1 - $2`
if [ $d -lt 0 ]; then
    diff=$(( -1 * $d))
else
    diff=$d
fi
if [ $diff -lt $3 ]; then
    echo 0
else
    echo 1
fi
}
#
# start searching from here by pulling first some input parameters
#
#set -x
syndata_path="/lfs1/projects/hwrf-vd/hwrf-input/SYNDAT-PLUS/"
if [ $# -eq 2 ]; then
    storm_id=$1
    year=$2
else
    echo "Wrong input syntax... try again. E.g."
    echo "./vital_trace.sh 17W 2013"
    exit 1
fi
syndata_file="${syndata_path}/syndat_tcvitals.${year}"
if [ -f "$syndata_file" ]; then
    echo "SYNDAT data to work with is: $syndata_file"
else
    echo "$syndata_file is not exisiting .... exit 1"
    exit 1
fi
#
# grep date/time information of the storm
#
test_invest=`echo $storm_id | cut -c 1`
test_basin=`echo $storm_id | cut -c 3-3`
if [ "$test_invest" == "9" ]; then
    echo "Storm id looks like an invest ${storm_id}...stop searching"
    exit 1
fi
storm_name=`grep $storm_id $syndata_file | awk -v a="${storm_id}" '{if($2==a) print $0}'  \
            | tail -n 1 | awk '{print $3}'`
if [ "$storm_name" == "" ]; then
    echo "There is no storm name associated with the $storm_id in year $year"
    exit 1
fi
storm_date=`grep $storm_name $syndata_file | grep $storm_id | head -n 1 | awk '{print $4}'`
storm_hour=`grep $storm_name $syndata_file | grep $storm_id | head -n 1 | awk '{print $5}' \
            | head -c +2`
storm_lat=`grep $storm_name $syndata_file  | grep $storm_id | head -n 1 | awk '{print $6}' \
            | sed 's/N//g' | sed 's/S//g'`
storm_lon=`grep $storm_name $syndata_file  | grep $storm_id | head -n 1 | awk '{print $7}' \
            | sed 's/E//g' | sed 's/W//g'`
storm_time=${storm_date}${storm_hour}
previous_time=`ndate -6 $storm_time`
if [ "$previous_time" == ""  ]; then
    echo "ndate retturn null string. Test ndate = $(ndate)... exit 1"
    exit 1
fi
#
# searching the previous numbered or invest cycle
#
previous_date=`echo $previous_time | cut -c 1-8`
previous_time="$(echo $previous_time | cut -c 9-10)00"
previous_number=`grep $previous_date $syndata_file | grep $storm_id | \
                 grep $previous_time | head -n 1 | awk '{print $3}'`
if [ "$previous_number" != "" ]; then
    echo "Numbered storm of $storm_name is $previous_number"
    echo "Searching now an INVEST associated with $previous_number"
    number_start_date=`grep $previous_number $syndata_file | grep ${storm_id} | head -n 1 \
                       | awk '{print $4}'`
    number_start_hour=`grep $previous_number $syndata_file | grep ${storm_id} | head -n 1 \
                       | awk '{print $5}' | head -c +2`
    number_start_lat=`grep $previous_number $syndata_file  | grep ${storm_id} | head -n 1 \
                       | awk '{print $6}' | sed 's/N//g' | sed 's/S//g'`
    number_start_lon=`grep $previous_number $syndata_file  | grep ${storm_id} | head -n 1 \
                       | awk '{print $7}' | sed 's/W//g' | sed 's/E//g'`
    number_start_time=${number_start_date}${number_start_hour}
#
#   finally searching for all invests 6-h earlier. Note the search for invest
#   will include all invest within - 1-day from the date of the numbered cycle
#   only. Any invest that 1-day apart from the numbered cycle will be discarded.  
#
    invest_previous_time=`ndate -6 $number_start_time`
    invest_date=`echo $invest_previous_time | cut -c 1-8`
    invest_time="$(echo $invest_previous_time | cut -c 9-10)00"
    grep INVEST $syndata_file | grep $invest_date | sort -u > ./invest_list.txt
    rm -rf ./vital_list.txt; touch ./vital_list.txt
    while read iline
    do 
        check_invest=`echo $iline | awk '{print $2}'`
        check_basin=`echo $check_invest | cut -c 3-3`
        check_lat=`echo $iline | awk '{print $6}' | sed 's/N//g' | sed 's/S//g'`
        check_lon=`echo $iline | awk '{print $7}' | sed 's/W//g' | sed 's/E//g'`
        test_lat=`abs_compare ${check_lat} ${number_start_lat} 18`
        test_lon=`abs_compare ${check_lon} ${number_start_lon} 18`
        if [ "$test_lat" == "0" ] && [ "$test_lon" == "0"  ] && [ ${check_basin} == ${test_basin} ]; then
            echo "$check_invest" >> ./vital_list.txt
            previous_invest_number=$check_invest
        fi 
    done < ./invest_list.txt
    if [ "${previous_invest_number}" == "" ] && [ "$previous_number" == "" ]; then
        flag_search=0
    elif [ "${previous_invest_number}" == "" ] && [ "$previous_number" != "" ]; then
        flag_search=1
    else
        flag_search=3
    fi
else
#
#   searching now for an invest that is assocaited with the input numbered storm 
#
    echo "Previous numbered name assocaited with $storm_name is not existing"
    echo "Should be associated with an INVEST"
    grep INVEST $syndata_file | grep $previous_date | sort -u > ./invest_list.txt
    rm -rf ./vital_list.txt; touch ./vital_list.txt
    while read iline
    do
        check_invest=`echo $iline | awk '{print $2}'`
        check_basin=`echo $check_invest | cut -c 3-3`
        check_lat=`echo $iline | awk '{print $6}' | sed 's/N//g' | sed 's/S//g'`
        check_lon=`echo $iline | awk '{print $7}' | sed 's/W//g' | sed 's/E//g'`
        test_lat=`abs_compare ${check_lat} ${storm_lat} 18`
        test_lon=`abs_compare ${check_lon} ${storm_lon} 18`
        if [ "$test_lat" == "0" ] && [ "$test_lon" == "0"  ] && [ ${check_basin} == ${test_basin} ]; then
            echo "$check_invest" >> ./vital_list.txt
            previous_invest_number=$check_invest
        fi
    done < ./invest_list.txt
    if [ "${previous_invest_number}" == "" ]; then
        flag_search=0
    else
        flag_search=2
    fi
fi
#
# adding special cases that have human-errors, which prevent the script for 
# searching. This list is only for special cases in the HISTORY mode. In the 
# real-time mode, users have to live with such errors.
#
if [ "$storm_id" == "10W" ] && [ "$year" == "2012"  ]; then
    flag_search=2
    previous_invest_number="93W"
fi
#
# Print out searching summmary
#
if [ "$flag_search" == "3" ]; then
    echo "Searching returned $storm_name${storm_id} ${previous_number}${storm_id} INVEST${previous_invest_number}"
elif [ "$flag_search" == "2" ]; then
    echo "Searching returned $storm_name${storm_id} INVEST${previous_invest_number}"
elif [ "$flag_search" == "1" ]; then
    echo "Searching returned $storm_name${storm_id} ${previous_number}${storm_id}"
else
    echo "Cannot find any previous numbered or invest for storm $storm_name${storm_id}"
fi
