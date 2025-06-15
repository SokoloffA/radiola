#!/bin/bash
# v 0.1

[[ "${GITHUB_REF_TYPE}" = "tag" ]] || exit

VER=${GITHUB_REF_NAME:1}


echo "Upgrade to version ${VER}"
sed -i '' "s|CURRENT_PROJECT_VERSION.*|CURRENT_PROJECT_VERSION = ${VER};|" $1
