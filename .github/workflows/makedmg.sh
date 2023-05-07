#!/bin/bash
# v 0.1

APP_NAME=Radiola
MAKE_DMG=1
CERT_IDENTITY="Developer ID Application: Alex Sokolov (635H9TYSZJ)"

#--------------------

set -Eeuo pipefail
#set -x

TAR="${APP_NAME}.app.tar"

if [[ ! -e ${TAR} ]]; then
    echo "${TAR} file not found" >&2
    exit 1
fi

BUNDLE_NAME="${APP_NAME}.app"
BUNDLE_PATH="./${BUNDLE_NAME}"

rm -rf ${BUNDLE_PATH}
tar xf ${TAR}

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ${BUNDLE_PATH}/Contents/Info.plist)
DMG_NAME="./${APP_NAME}-${VERSION}.dmg"

echo "***********************************"
echo "* App     ${APP_NAME}"
echo "* Version ${VERSION}"
echo "* DMG     ${MAKE_DMG}"
echo "***********************************"

echo "Sign and verify ..............................."
codesign --force --deep --verify --sign  "${CERT_IDENTITY}" "${BUNDLE_PATH}"
codesign --all-architectures -v --strict --deep --verbose=1 "${BUNDLE_PATH}"
spctl --assess --type execute "${BUNDLE_PATH}"
echo "  OK"
echo ""

echo "Verify signature .............................."
codesign --all-architectures -v --strict --deep --verbose=1 "${BUNDLE_PATH}"
spctl --assess --type execute "${BUNDLE_PATH}"
echo "  OK"
echo ""

if [[ MAKE_DMG ]]; then
    create-dmg \
        --volname ${APP_NAME} \
        --volicon ${BUNDLE_PATH}/Contents/Resources/AppIcon.icns \
        --window-size 500 300 \
        --icon-size 96 \
        --icon ${BUNDLE_NAME} 135 102 \
        --hide-extension ${BUNDLE_NAME} \
        --app-drop-link 365 102 \
        ${DMG_NAME} \
        ${BUNDLE_PATH}
fi
