#!/bin/sh

# Get Alfreds query parameter from CLI arguments:

query=$1

# Read config.json & prepare:

config=`cat ./config.json | jq -r .`
user=`jq -r -M .user <<< $config`
password=`jq -r -M .password <<< $config`
host=`jq -r -M .jiraUrl <<< $config`
maxResults=`jq -r -M .maxResults <<< $config`
fields="id,key,project,issuetype,summary"

if [ -z "$query" ]; then
  queryJql=`jq -r -M .emptySearchJql <<< $config`
else
  queryJql=`jq -r -M .searchJql <<< $config`
fi
queryJql=`echo $queryJql | sed "s/{query}/$query/g"`

# Call API & Generate XML Items for Alfred:

response=`curl -s -u $user:$password -G -H "Content-Type: application/json" --data-urlencode "jql=$queryJql" --data-urlencode "maxResults=$maxResults" --data "validateQuery=false" --data "fields=$fields" "$host/rest/api/2/search"`
xmlItems=`./buildXMLItems.sh "${response}"`

echo "<?xml version=\"1.0\"?><items>$xmlItems</items>"
