#!/bin/bash

check_for_exec() {
        if ! [ -x "$(command -v $1)" ]; then
           echo "Error: $1 is not installed." >&2
           exit 1
        fi
}

CLI="jf"
if [[ "$1" == "legacy" ]]; then 
        CLI="jfrog"
fi

for i in "$CLI" "jq" 
do
   check_for_exec "$i"
done


REPOS=`$CLI rt curl /api/repositories | jq '.[] | select(.packageType == "Docker" and .type != "VIRTUAL") | .key'`
COUNT=0

while IFS= read -r line; do
    AQL1='items.find ({'
    AQL2="\"repo\":$line"
    AQL3=',"type":"file", "created":{"$last":"3mo"}, "name":"manifest.json" }).include("sha256")'
    AQL="$AQL1$AQL2$AQL3"
    RES=`$CLI rt curl -XPOST -H "Content-Type: text/plain" -d "$AQL" api/search/aql | jq .range.total`
    COUNT=$((COUNT+RES))
done <<< "$REPOS"

echo "Docker images through last 3 months: ${COUNT}"
