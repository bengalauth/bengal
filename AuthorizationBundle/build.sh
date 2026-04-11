#!/bin/bash
set -e

#BASEDIR="${0:a:h}"
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "building authorization plugin..."

BUNDLE_NAME="BengalLogin.bundle"
BUILD_DIR="${BASEDIR}/build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources"

cp ${BASEDIR}/Info.plist "$BUILD_DIR/$BUNDLE_NAME/Contents/"

# copy all resources (fonts, bg, avatar, settings)
cp -rf ${BASEDIR}/Resources/* "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources/"

# compile into dynamic library (bundle)
swiftc -emit-library -o "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS/BengalLogin" \
    ${BASEDIR}/src/AuthorizationPlugin.swift \
    ${BASEDIR}/src/Mechanism.swift \
    ${BASEDIR}/src/LoginUI.swift \
    ${BASEDIR}/../app_src/SettingsManager.swift \
    -Xlinker -bundle

echo "login UI built successfully: $BUILD_DIR/$BUNDLE_NAME"
echo ""
echo "run scripts/install_bundle.sh to install login UI"
echo "or install with:"
echo "  sudo cp -R $BUILD_DIR/$BUNDLE_NAME /Library/Security/SecurityAgentPlugins/"
echo ""
echo "to test, run scripts/test_login_ui.sh"
