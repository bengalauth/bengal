#!/bin/bash
set -e

BINARY=/tmp/BengalLoginUI_Test
#BASEDIR="${0:a:h}"
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RESOURCES_DIR="$(dirname "$BINARY")/Resources"

echo "compiling present login UI..."
swiftc ${BASEDIR}/../AuthorizationBundle/src/LoginUI.swift ${BASEDIR}/test_login_ui.swift \
    ${BASEDIR}/../app_src/SettingsManager.swift \
    -framework OpenDirectory \
    -o "$BINARY"

mkdir -p "$RESOURCES_DIR"
cp ${BASEDIR}/../AuthorizationBundle/Resources/Comfortaa-*.ttf "$RESOURCES_DIR/"

echo "done, running login UI"
"$BINARY"
