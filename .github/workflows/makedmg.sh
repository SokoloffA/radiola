#!/bin/bash
# v 0.1

APP_NAME=Radiola
MAKE_DMG=true
CERT_IDENTITY="Developer ID Application: Alex Sokolov (635H9TYSZJ)"
KEYCHAIN_PROFILE="NotaryTool"

#--------------------

set -Eeuo pipefail
#set -x

TAR=$(find . -name "${APP_NAME}-*.tar" | sort | tail -n 1)
if [[ -z ${TAR} ]]; then
    echo "Tar file not found" >&2
    exit 1
fi

BUNDLE_NAME="${APP_NAME}.app"
BUNDLE_PATH="./${BUNDLE_NAME}"

rm -rf ${BUNDLE_PATH}
tar xf ${TAR}

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ${BUNDLE_PATH}/Contents/Info.plist)
DMG_NAME="./${APP_NAME}-${VERSION}.dmg"
ZIP_NAME="./${APP_NAME}-${VERSION}.zip"

echo "***********************************"
echo "* App     ${APP_NAME}"
echo "* Version ${VERSION}"
echo "* DMG     ${MAKE_DMG}"
echo "***********************************"

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

echo " Notarize ....................................."
ditto -c -k --keepParent "${BUNDLE_PATH}" "${ZIP_NAME}"
xcrun notarytool submit --wait --keychain-profile "${KEYCHAIN_PROFILE}" "${ZIP_NAME}" | tee notarytool-submit.log
echo "  OK"
echo ""

echo "Verify notarization ..........................."
spctl -a -vvv -t install "${BUNDLE_PATH}"

if [[ "$MAKE_DMG" == "true" ]]; then
    echo "Create DMG file .............................."
    dmgbuild -s dmg_settings.json "${BUNDLE_PATH}" "${DMG_NAME}"
    echo "  OK"
fi
