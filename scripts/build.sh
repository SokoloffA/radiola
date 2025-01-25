#!/bin/bash

APP_NAME=Radiola
CERT_IDENTITY="Developer ID Application: Alex Sokolov (635H9TYSZJ)"
SRC_DIR="./SRC"
BUNDLE_PATH=`pwd`"/${APP_NAME}.app"
BUILD_TYPE=Release

set -e
#set -x

REPO_DIR=$(dirname $(dirname "${BASH_SOURCE[0]}"))
echo "Script directory: $REPO_DIR"

echo "***********************************"
echo "* App     ${APP_NAME}"
echo "* Source  ${REPO_DIR}"
echo "***********************************"

rm -rf "${SRC_DIR}"
rm -rf ${BUNDLE_PATH}

rsync -a --files-from=<(git --git-dir="${REPO_DIR}/.git" --work-tree="${REPO_DIR}" ls-files) "${REPO_DIR}" "${SRC_DIR}"

xcodebuild \
    clean \
    build \
    -quiet \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -project "${SRC_DIR}/${APP_NAME}.xcodeproj" \
    -scheme ${APP_NAME} \
    -configuration ${BUILD_TYPE} \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath ./build

echo "*************************************:"
echo "* The project was successfully built"
echo "*************************************:"

cp -a ./build/Build/Products/${BUILD_TYPE}/${APP_NAME}.app "${BUNDLE_PATH}"


echo "Remove quarantine flag ........................"
xattr -r -d com.apple.quarantine "${BUNDLE_PATH}"
echo "  OK"

echo "Sign .........................................."
codesign --force --options runtime --deep --verify --sign  "${CERT_IDENTITY}" "${BUNDLE_PATH}"
echo "  OK"
echo ""

echo "Verify signature .............................."
codesign --all-architectures -v --strict --deep --verbose=1 "${BUNDLE_PATH}"
spctl --assess --type execute "${BUNDLE_PATH}"
echo "  OK"
echo ""
