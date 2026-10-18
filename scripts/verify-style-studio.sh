#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
style_binary="$(mktemp -d /tmp/linley-style-check.XXXXXX)"
trap 'rm -rf "$style_binary"' EXIT
xcrun swiftc -O -parse-as-library Linley/Features/Games/ChaseEngine.swift Linley/Features/Games/MatchEngine.swift Linley/Features/Games/DressUp/DressUpCatalog.swift Linley/Features/Games/DressUp/DressUpStore.swift Linley/Features/Games/QuestStore.swift scripts/VerifyStyleStudio.swift -o "$style_binary/verify-style"
"$style_binary/verify-style"
