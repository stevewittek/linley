#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
match_binary="$(mktemp -d /tmp/linley-match-check.XXXXXX)"
trap 'rm -rf "$match_binary"' EXIT
xcrun swiftc -O -parse-as-library Linley/Features/Games/ChaseEngine.swift Linley/Features/Games/MatchEngine.swift Linley/Features/Games/DressUp/DressUpCatalog.swift Linley/Features/Games/QuestStore.swift scripts/VerifyMatchThree.swift -o "$match_binary/verify-match"
"$match_binary/verify-match"
