#!/bin/sh
# Download all sources for packages in build/ according to queue.txt and pkg.json
# Usage: ./download_all.sh

set -e

ROOTDIR="$(dirname "$0")/.."
BUILDDIR="$ROOTDIR/build"
QUEUE="$BUILDDIR/queue.txt"

if [ ! -f "$QUEUE" ]; then
  echo "queue.txt not found in $BUILDDIR" >&2
  exit 1
fi

while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  PKGDIR="$BUILDDIR/$pkg"
  if [ -d "$PKGDIR" ]; then
    echo "\n===== Downloading $pkg ====="
    if [ -f "$PKGDIR/pkg.json" ]; then
      DOWNLOAD_CMDS=$(jq -r '.download[]?' "$PKGDIR/pkg.json")
      if [ -n "$DOWNLOAD_CMDS" ]; then
        echo "$DOWNLOAD_CMDS" | while IFS= read -r cmd; do
          echo "> $cmd"
          sh -c "$cmd"
        done
      else
        echo "No download commands found in pkg.json for $pkg"
      fi
    else
      echo "No pkg.json found in $PKGDIR, skipping download commands."
    fi
  else
    echo "Package directory $PKGDIR does not exist, skipping."
  fi
done < "$QUEUE"
