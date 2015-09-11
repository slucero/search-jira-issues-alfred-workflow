#!/bin/sh

response=$1
config=`cat ./config.json | jq -r .`
user=`jq -r -M .user <<< $config`
password=`jq -r -M .password <<< $config`

# Cache project icons for items found.

convertImages=`jq -r -M .convertImages <<< $config`
projectIconData=`echo $response | jq '.issues[]' | jq -r '.fields.project.avatarUrls."48x48" + "|" + .fields.project.key'`
mkdir -p ./project_icons
for piData in $projectIconData; do
  url=$(echo $piData | cut -d"|" -f1)
  key=$(echo $piData | cut -d"|" -f2)
  file="./project_icons/$key"
  if [ ! -f $file ]; then
    curl -s -u $user:$password $url > $file
    if [ "$convertImages" = "true" ]; then
      convert $file "$file.png"
    fi
  fi
done

# Give XML response back.

echo $response | jq '.issues[]' \
  | jq --argfile config ./config.json '[
    .key,
    $config.jiraUrl + "/browse/" + .key,
    "[" + .key + "]" + " " + .fields.summary,
    .fields.project.name + " - " + .fields.issuetype.name,
    .fields.project.key]' \
  | jq -r -j '
  "<item uid=\"" + .[0] + "\" valid=\"yes\" arg=\"" + .[1] + "\">" +
    "<title><![CDATA[" + .[2] + "]]></title>" +
    "<subtitle><![CDATA[" + .[3] + "]]></subtitle>" +
    "<icon>project_icons/" + .[4] + ".png</icon>" +
  "</item>"'
