#!/bin/bash

set -e
#set -x

BOOKMARK_PATH="${HOME}/Library/Application Support/com.github.SokoloffA.Radiola/bookmarks.opml"

echo ${BOOKMARK_PATH} >&2

cat "${BOOKMARK_PATH}"
echo
