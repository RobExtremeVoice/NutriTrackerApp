#!/bin/sh
set -e

export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

if ! command -v xcodegen &>/dev/null; then
    brew install xcodegen
fi

echo "OPENAI_API_KEY =" > "$CI_PRIMARY_REPOSITORY_PATH/Config.xcconfig"

cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate
