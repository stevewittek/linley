#!/bin/sh
# Solve every authored board using the production engine; no simulator or account.
set -eu
cd "$(dirname "$0")/.."
chase_check_dir="$(mktemp -d /tmp/linley-chase-check.XXXXXX)"
trap 'rm -rf "$chase_check_dir"' EXIT
xcrun swiftc -O -parse-as-library Linley/Features/Games/ChaseEngine.swift scripts/SolvePuzzleChase.swift -o "$chase_check_dir/solve"
"$chase_check_dir/solve"
