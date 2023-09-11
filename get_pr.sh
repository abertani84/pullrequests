#!/bin/bash
CWD="/home/ec2-user"
pat="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"
repo="https://api.github.com/repos/microsoft/promptflow/pulls"
to_email="alejandro.bertanill@gmail.com"
from_email="alejandro.bertanill@gmail.com"
date=`date +%Y-%m-%d -d "-7 days"`
echo "Getting pull requests from ${repo}"
curl -s -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${pat}" -H "X-GitHub-Api-Version: 2022-11-28" ${repo} > ${CWD}/pulls.json

readarray -t url < <( cat pulls.json | jq '.[].url' | tr -d '"' )
readarray -t number < <( cat pulls.json | jq '.[].number' | tr -d '"' )
readarray -t state < <( cat pulls.json | jq '.[].state' | tr -d '"' )
readarray -t title < <( cat pulls.json | jq '.[].title' | tr -d '"' )
readarray -t body < <( cat pulls.json | jq '.[].body' | tr -d '"' )
readarray -t created_at < <( cat pulls.json | jq --arg date "$date" '.[].created_at | select(. > $date)' | tr -d '"' )
readarray -t draft < <( cat pulls.json | jq '.[].draft' | tr -d '"' )

no_pr=${#created_at[@]}
echo "Number of PR is" ${no_pr}

for (( i=0; i< ${no_pr}; i++ ));
do
  echo "${url[$i]}"@"${number[$i]}"@"${state[$i]}"@"${title[$i]}"@"${body[$i]}"@"${created_at[$i]}"@"${draft[$i]}"
done > ${CWD}/csv_pr.csv
	
awk -F@ 'BEGIN { 
print "<!DOCTYPE html>\n<html>\n<head>\n<style>\ntable,th,td\n{\nborder:2px solid black ;font-family:"Verdana", "sans-serif";   \nborder-collapse:collapse;\n}\n</style>\n</head>\n<Body><p>This report provides all the pull requests for the last 7 days</p>\n<table>"
print "<tr bgcolor=\"#C0C0C0\">\n<td>PR URL</td><td>Number</td><td>State</td><td>Title</td><td>Description</td><td>Created at</td><td>Draft</td>\n</tr>" 
} 
{
print "<tr bgcolor=\"#FFEBCD\">\n<td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td><td>"$7"</td>\n</tr>"
}
END {
print "</table>"
}' ${CWD}/csv_pr.csv > ${CWD}/report.html

s-nail -v -M "text/html" -r ${from_email} -s "Pull Requests Report" -.  ${to_email} < ${CWD}/report.html
