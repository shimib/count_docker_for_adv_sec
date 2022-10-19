#!/bin/bash

check_for_exec() {
        if ! [ -x "$(command -v $1)" ]; then
           echo "Error: $1 is not installed." >&2
           exit 1
        fi
}

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}

CLI="jf"
if [[ "$1" == "legacy" ]]; then 
        CLI="jfrog"
fi

for i in "$CLI" "jq" 
do
   check_for_exec "$i"
done


REPOS=`$CLI rt curl /api/repositories --silent | jq '.[] | select(.packageType == "Docker" and .type != "VIRTUAL") | .key'`
if [[ "${REPOS}" == "" ]]; then
        echo "No Docker repositories to scan"
        exit 0
fi

TOTAL=`echo "$REPOS" | wc -l |  cut -w -f 2`
echo "Going through ${TOTAL} Docker repositories"
COUNT=0
itCount=0
while IFS= read -r line; do
    AQL1='items.find ({'
    AQL2="\"repo\":$line"
    AQL3=',"type":"file", "created":{"$last":"3mo"}, "name":"manifest.json" }).include("sha256")'
    AQL="$AQL1$AQL2$AQL3"
    RES=`$CLI rt curl -XPOST -H "Content-Type: text/plain" -d "$AQL" api/search/aql --silent | jq .range.total`
    COUNT=$((COUNT+RES))
    itCount=$((itCount+1))
    ProgressBar ${itCount} ${TOTAL}
done <<< "$REPOS"
echo 
echo "Docker images through last 3 months: ${COUNT}"
