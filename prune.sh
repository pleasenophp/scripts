#!/bin/sh

# Supported arguments: <folder path> <days for daily prune> <days for monthly prune
# e.g. "prune.sh Builds 3 30" will for all folders/files that are older than 3 days keep only one last per day, and for all files that are older than 30 days keep only one last per month.
# Pass the last argument "--test" if you wish to only run it in test mode but not actually delete


FOLDER_NAME=$1
D_DAYS=$2
M_DAYS=$3
TEST=$4

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
FILES=($(ls $FOLDER_NAME | sort | grep install))

SNOW=$(date +%Y-%m-%d)
PREV_FILE=''
PREV_DATE=''

for i in ${!FILES[@]}; do
	FNAME=${FILES[$i]}
	SDATE=`echo $FNAME | egrep -o '\d{4}-\d{2}-\d{2}'`
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


