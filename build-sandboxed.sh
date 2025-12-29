#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Radiola"
SRC_DIR="."
BUILD_DIR="./build"
TEAM_ID="${TEAM_ID:-635H9TYSZJ}"
CODE_SIGN_IDENTITY="Developer ID Application: Alex Sokolov (635H9TYSZJ)"
NOTARY_KEYCHAIN_PROFILE="NotaryTool"
PROVISIONING_PROFILE="com.github.SokoloffA.Radiola"

##############################
SCHEME="${APP_NAME}"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"
CONFIGURATION="Release"
EXPORT_OPTIONS_PLIST="${BUILD_DIR}/ExportOptions.plist"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"

function getVersion() {
    if [[ "${GITHUB_REF_TYPE-}"  = "tag" ]]; then
        #VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ${APP_PATH}/Contents/Info.plist)
        echo ${GITHUB_REF_NAME:1}
    else
        date +%Y.%m.%d_%H.%M.%S
    fi
}

function prepare() {
    ##############################
    # Ensure build dir
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
}

function archive() {
    echo ""
    echo "***********************************"
    echo "** Archiving project..."
    echo "***********************************"

    ARGS=(
        -project "./${APP_NAME}.xcodeproj"
        -scheme "${APP_NAME}"
        -configuration "${CONFIGURATION}"
        -archivePath "${ARCHIVE_PATH}"
        ONLY_ACTIVE_ARCH=NO
    )

    if [ "${GITHUB_ACTIONS-}" = "true" ]; then
        ARGS+=(
            DEVELOPMENT_TEAM="${TEAM_ID}"
            CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"
            CODE_SIGN_STYLE=Manual
            PROVISIONING_PROFILE_SPECIFIER="com.github.SokoloffA.Radiola"
        )
    fi

    xcodebuild clean archive "${ARGS[@]}" | tee "${BUILD_DIR}/01-archive.log"
}

function genExportOptions() {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    echo '<plist version="1.0">'
    echo '<dict>'
    echo '<key>method</key>'
    echo '<string>developer-id</string>'

    if [ "${GITHUB_ACTIONS-}" = "true" ]; then
        echo '<key>signingCertificate</key>'
        echo '<string>'${CODE_SIGN_IDENTITY}'</string>'

        echo '<key>teamID</key>'
        echo '<string>'${TEAM_ID}'</string>'

        echo '<key>signingStyle</key>'
        echo '<string>manual</string>'

        echo '<key>provisioningProfiles</key>'
        echo '<dict>'
        echo '    <key>'${PROVISIONING_PROFILE}'</key>'
        echo '    <string>'${PROVISIONING_PROFILE}'</string>'
        echo '</dict>'
    fi

    echo '<key>stripSwiftSymbols</key>'
    echo '<true/>'

    echo '<key>compileBitcode</key>'
    echo '<false/>'

    echo '<key>destination</key>'
    echo '<string>export</string>'

    echo '<key>manageAppVersionAndBuildNumber</key>'
    echo '<false/>'
    echo '</dict>'
    echo '</plist>'
}

function exportArchive() {
    echo ""
    echo "***********************************"
    echo "** Exporting to ${APP_PATH}..."
    echo "***********************************"

    genExportOptions > "${EXPORT_OPTIONS_PLIST}"

    ARGS=(
        -archivePath "${ARCHIVE_PATH}"
        -exportPath "${BUILD_DIR}"
        -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}"
    )

    xcodebuild -exportArchive "${ARGS[@]}" | tee "${BUILD_DIR}/02-export-archive.log"
}

function verifyCodesign() {
    echo ""
    echo "***********************************"
    echo "** Verifying codesign and entitlements..."
    echo "***********************************"
    codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

    echo ""
    echo "** VERIFICATION SUCCEEDED **"
}

function createDmg() {
    echo ""
    echo "***********************************"
    echo "** Build DMG file"
    echo "***********************************"

    VERSION=$(getVersion)
    DMG_NAME="${APP_NAME}-${VERSION}.dmg"

    cat "${SRC_DIR}/.github/workflows/dmg_settings.json" > "${BUILD_DIR}/dmg_settings.json"
    cp  "${SRC_DIR}/.github/workflows/dmgbuild" "${BUILD_DIR}/dmgbuild"
    (cd "${BUILD_DIR}" && ./dmgbuild -s dmg_settings.json "${APP_NAME}" "${DMG_NAME}")

    echo ""
    echo "** DMG CREATION SUCCEEDED ${DMG_NAME} **"
}

function notarize() {
    echo ""
    echo "***********************************"
    echo "Submitting to Apple notary service..."
    echo "***********************************"

    DMG_PATH=$(ls ${BUILD_DIR}/*.dmg)
    echo "DMG FILE: ${DMG_PATH}"

    ARGS=(
        --wait
        --output-format json
    )

    if [ "${GITHUB_ACTIONS-}" = "true" ]; then
        ARGS+=(
            --key "./AuthKey.p8"
            --key-id "${AC_KEY_ID}"
            --issuer "${AC_ISSUER_ID}"
        )
    else
        ARGS+=(
            --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}"
        )
    fi

    xcrun notarytool submit "${ARGS[@]}" "${DMG_PATH}" | tee "${BUILD_DIR}/03-notarize.log"

    echo ""
    echo "** WAITING RESULT .... **"
    xcrun stapler staple "${DMG_PATH}"

    echo ""
    echo "***********************************"
    echo "** Verifying..."
    echo "***********************************"
    spctl -a -vvv -t install "${APP_PATH}" || spctl --assess --type execute --verbose=4 "${APP_PATH}"

    echo ""
    echo "** NOTARIZATION SUCCEEDED **"
}

DEFAULT_STEPS=""
DEFAULT_STEPS+=" prepare"
DEFAULT_STEPS+=" archive"
DEFAULT_STEPS+=" exportArchive"
DEFAULT_STEPS+=" verifyCodesign"
DEFAULT_STEPS+=" createDmg"
DEFAULT_STEPS+=" notarize"

args="${@:-${DEFAULT_STEPS}}"
for func in $args; do
    $func
done
