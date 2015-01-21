#!/bin/sh
url=$1
echo `echo $url | sed 's#.*/##'`