#!/bin/sh

# Get Alfreds query parameter from CLI arguments:
query=$1

# Read config.json & prepare:
config=`cat ./config.json`
user=`echo $config | jsawk -n 'out(this.user)'`
password=`echo $config | jsawk -n 'out(this.password)'`
host=`echo $config | jsawk -n 'out(this.jiraUrl)'`
maxResults=`echo $config | jsawk -n 'out(this.maxResults)'`
fields="id,key,project,issuetype,summary"

if [ -z "$query" ]; then
	queryJql=`echo $config | jsawk -n 'out(this.emptySearchJql)'`
else
	queryJql=`echo $config | jsawk -n 'out(this.searchJql)'`
fi
queryJql=`echo $queryJql | sed s/{query}/$query/g`

# Call API & Generate XML Items for Alfred:
xmlItems=`curl -s -u $user:$password -G -H "Content-Type: application/json" --data-urlencode "jql=$queryJql" --data-urlencode "maxResults=$maxResults" --data "validateQuery=false" --data "fields=$fields" "$host/rest/api/2/search" \
	| jsawk 'return this.issues' \
	| jsawk -n 'out("<item uid=\"" + this.key + "\" valid=\"yes\" arg=\"'$host'/browse/" + this.key + "\"><title><![CDATA[" + this.fields.summary + "]]></title><subtitle><![CDATA[" + this.key + " (" + this.fields.issuetype.name + ", " + this.fields.project.name + ")]]></subtitle><icon>icons/" + this.fields.issuetype.iconUrl.substr(this.fields.issuetype.iconUrl.lastIndexOf("/")+1) + "</icon></item>")'`

echo "<?xml version=\"1.0\"?><items>$xmlItems</items>"
