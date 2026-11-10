#!/bin/sh
# Xcode Cloud runs this after cloning: the same setup as bootstrap.sh, and the Apple Team ID from the workflow's
# environment variable AKHI_DEVELOPMENT_TEAM.

set -eu

cd "${CI_PRIMARY_REPOSITORY_PATH:-$(dirname "$0")/../..}"

if ! command -v node >/dev/null 2>&1; then
    brew install node
fi

git submodule update --init --recursive
sh ./bootstrap.sh firefox

if [ -n "${AKHI_DEVELOPMENT_TEAM:-}" ]; then
    echo "AKHI_DEVELOPMENT_TEAM = ${AKHI_DEVELOPMENT_TEAM}" > firefox-ios/Client/Configuration/AkhiSigning.xcconfig
fi
