#!/bin/sh
# Executes the actual production storage/catalog sources on macOS; no simulator needed.
set -eu
cd "$(dirname "$0")/.."
binary="$(mktemp -d /tmp/linley-storage.XXXXXX)"
trap 'rm -rf "$binary"' EXIT
xcrun swiftc -parse-as-library Linley/Models/MediaStore.swift Linley/Models/DemoCatalog.swift scripts/StorageSmoke.swift -o "$binary/test-storage"
"$binary/test-storage"
