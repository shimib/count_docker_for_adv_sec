#!/bin/bash

# Used to check for existence of pre-requisites
check_for_exec() {
        if ! [ -x "$(command -v $1)" ]; then
           echo "Error: $1 is not installed." >&2
           exit 1
        fi
}

# A simple progress bar
function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}
# Will accumulate results from the AQL batches
OUTPUT_FILE="docker_images_sha.txt"
# Clearing previous results
echo "" > $OUTPUT_FILE

# Run a single batch. Params are starting index (inclusive), end index (exclusive) and the entire array of repository names.
# Results will be written to OUTPUT_FILE
function RunBatch {
   _start=${1}
   _end=${2}
   shift
   shift
   _arr=("$@")
   AQL1='items.find ({"$or":[{'
   AQL2=""
   if [[ "$_start" == "$_end" ]]; then
           return
   fi
   for (( i2=$_start; i2<$_end; i2++ ))
   do
       AQL2="${AQL2}\"repo\":${_arr[i2]},"
   done 
   AQL2=`echo ${AQL2} | rev | cut -c2- | rev`
   AQL3='}],"type":"file", "created":{"$last":"3mo"}, "name":"manifest.json" }).include("sha256")'
   AQL="$AQL1$AQL2$AQL3"
   #echo "AQL: ${AQL}"
   RES=`$CLI rt curl -XPOST -H "Content-Type: text/plain" -d "$AQL" api/search/aql --silent`
   #echo $RES
   RES=`echo "$RES" | jq -r '.results[] | .sha256'`
   echo ${RES} >> $OUTPUT_FILE
}

min() {
    printf "%s\n" "${@:2}" | sort "$1" | head -n1
}

CLI="jf"
# Testing whether we should use 'jfrog' and not 'jf'
if [[ "$1" == "legacy" ]]; then 
        CLI="jfrog"
fi

for i in "$CLI" "jq" 
do
   check_for_exec "$i"
done

# Retrieve all repositories of type Docker which are not Virtual
REPOS=`$CLI rt curl /api/repositories --silent | jq '.[] | select(.packageType == "Docker" and .type != "VIRTUAL") | .key'`
if [[ "${REPOS}" == "" ]]; then
        echo "No Docker repositories to scan"
        exit 0
fi

TOTAL=`echo "$REPOS" | wc -l |  cut -w -f 2`
echo "Going through ${TOTAL} Docker repositories"

#echo "$REPOS"
# Convert the lines into an array
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
arr2=($REPOS)
IFS=$SAVEIFS   # Restore original IFS

BATCH_SIZE=122
BATCH_COUNT=$((TOTAL/BATCH_SIZE+1))
#echo "TOTAL: ${TOTAL}"
#echo "BATCH SIZE: ${BATCH_SIZE}"
#echo "BATCH COUNT: ${BATCH_COUNT}"
for (( i=0; i<$BATCH_COUNT; i++ ))
do
        sPos=$((i*BATCH_SIZE)) 
        ePos=$(((i+1)*BATCH_SIZE))
        ePos=`min -g $ePos $TOTAL`
        #echo "from: $sPos to: $ePos"
        ProgressBar $i $((BATCH_COUNT-1))
        RunBatch $sPos $ePos "${arr2[@]}" 
done
# Now need just the unique count of the SHAs
FINAL_RES=`cat $OUTPUT_FILE | tr ' ' '\n' | sort | uniq | wc -l | cut -w -f 2`
echo
echo "Docker images through last 3 months: ${FINAL_RES}"
