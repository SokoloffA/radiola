#!/bin/bash

set -e
#set -x

CONF_PATH=${HOME}/Library/Containers/com.github.SokoloffA.Radiola/Data/Library/Preferences/com.github.SokoloffA.Radiola.plist

echo $CONF_PATH

if [ "$#" -eq 1 ]; then
    plutil -p ${CONF_PATH}
    exit
fi

FILTER=$(IFS='|'; echo "$*")
echo $FILTER

plutil -p ${CONF_PATH} | grep -E "$FILTER"

