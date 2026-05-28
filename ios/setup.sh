#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQLITE_DIR="$SCRIPT_DIR/sqlite3"

if [ -f "$SQLITE_DIR/sqlite3.c" ] && [ -f "$SQLITE_DIR/sqlite3.h" ]; then
    echo "SQLite amalgamation already present."
    exit 0
fi

echo "Downloading SQLite amalgamation..."
SQLITE_VERSION="3460000"
SQLITE_URL="https://www.sqlite.org/2024/sqlite-amalgamation-${SQLITE_VERSION}.zip"

TMPDIR=$(mktemp -d)
curl -sL "$SQLITE_URL" -o "$TMPDIR/sqlite.zip"
unzip -q "$TMPDIR/sqlite.zip" -d "$TMPDIR"
cp "$TMPDIR/sqlite-amalgamation-${SQLITE_VERSION}/sqlite3.c" "$SQLITE_DIR/"
cp "$TMPDIR/sqlite-amalgamation-${SQLITE_VERSION}/sqlite3.h" "$SQLITE_DIR/"
rm -rf "$TMPDIR"

echo "SQLite amalgamation downloaded to $SQLITE_DIR"

# Generate Xcode project if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "Generating Xcode project..."
    cd "$SCRIPT_DIR"
    xcodegen generate
    echo "Xcode project generated."
else
    echo "Install xcodegen to generate the Xcode project: brew install xcodegen"
fi
