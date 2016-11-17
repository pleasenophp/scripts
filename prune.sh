#!/bin/bash

# Supported arguments: <folder path> <days for daily prune> <days for monthly prunei> <filter> [--test]
# filter is part of file name that must be present, e.g. take only file names that contain "build" word
# e.g. "prune.sh Builds 3 30" will for all folders/files that are older than 3 days keep only one last per day, and for all files that are older than 30 days keep only one last per month.
# Pass the last argument "--test" if you wish to only run it in test mode but not actually delete

# The script assumes that the files/folders are named in format "<text-prefix>yyyy-mm-dd<text-postfix>" where text-prefix and text-postfix can be any text, just not starting with digits, 
# and the text-prefix is the same for all the files in the folder.

# The subfolders are supported as well


FOLDER_NAME=$1
D_DAYS=$2
M_DAYS=$3
FILTER=$4
TEST=$5

function getDateFromName {
	if [[ "$OSTYPE" == "linux-gnu" ]]; then
		# Linux
		echo $1 | grep -o -P '\d{4}-\d{2}-\d{2}'
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		# OSX
		echo $1 | egrep -o '\d{4}-\d{2}-\d{2}'
	elif [[ "$OSTYPE" == "cygwin" ]]; then
		# POSIX compatibility layer and Linux environment emulation for Windows
		echo $1 | grep -o -P '\d{4}-\d{2}-\d{2}'
	else
		echo "OS $OSTYPE is not supported! Try cygwin if you are on Windows."; exit 1;
	fi
}

function getDayDiff {
	echo `ruby -rdate -e "puts Date.parse('$1').mjd - Date.parse('$2').mjd"`
}

function getMonthDiff {
	echo `ruby -rdate -e "d1=Date.parse('$1'); d2=Date.parse('$2'); puts d1.year*12+d1.month - d2.year*12-d2.month"`
}

function deleteFile {
	echo "This is deleted ^^^^^";

	if [[ $TEST != "--test" ]]; then
		rm -rf $FOLDER_NAME/$1
	fi
}

if [ -z $FOLDER_NAME ]; then
	echo "Folder name is not provided"; exit 1;
fi

if [ -z $D_DAYS ]; then
	echo "Days for daily prune are not specified"; exit 1;
fi

if [ -z $M_DAYS ]; then
	echo "Days for monthly prune are not specified"; exit 1;
fi

echo "Will prune folder $FOLDER_NAME by keeping only 1 last entry per day for all the entries older than $D_DAYS days and 1 last entry per month for all the entries older than $M_DAYS days"

# Taking all the files that contain install (not taking features)
if [ -z $FILTER ]; then
	FILES=($(ls $FOLDER_NAME | sort))
else
	FILES=($(ls $FOLDER_NAME | sort | grep $FILTER))
fi

SNOW=$(date +%Y-%m-%d)
PREV_FILE=''
PREV_DATE=''

for i in ${!FILES[@]}; do
	FNAME=${FILES[$i]}
	SDATE=$(getDateFromName $FNAME)
	SDIFF=$(getDayDiff $SNOW $SDATE)

	if [ ! -z $PREV_FILE ]; then 

		# Calculating the difference in days betweeb dates
		SPREV_DIFF=$(getDayDiff $SDATE $PREV_DATE)

		# Calculating the difference in month value between dates (ignoring days)
		SPREV_M_DIFF=$(getMonthDiff $SDATE $PREV_DATE)

		# Deleting the previous file if it's older then M_DAYS and if the SPREV_M_DIFF == 0
		if (( $SDIFF >= $M_DAYS && $SPREV_M_DIFF == 0 )); then
			deleteFile $PREV_FILE
		# Deleting the previous file if it's older then D_DAYS and if the SPREV_DIFF == 0
		elif (( $SDIFF >= $D_DAYS && $SPREV_DIFF == 0 )); then
			deleteFile $PREV_FILE
		fi
		echo ""
	fi

	PREV_FILE=$FNAME
	PREV_DATE=$SDATE

	echo "Item$i = $FNAME; Date: $SDATE; DIFF: $SDIFF"

done


