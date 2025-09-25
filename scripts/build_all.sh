#!/bin/sh
# Build all packages in build/ according to queue.txt, using build_one.sh
# Usage: ./build_all.sh

set -e

ROOTDIR="$(dirname "$0")/.."
BUILDDIR="$ROOTDIR/build"
QUEUE="$BUILDDIR/queue.txt"
SCRIPTSDIR="$ROOTDIR/scripts"

if [ ! -f "$QUEUE" ]; then
  echo "queue.txt not found in $BUILDDIR" >&2
  exit 1
fi

SETENV="$SCRIPTSDIR/set-env.sh"
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  PKGDIR="$BUILDDIR/$pkg"
  if [ -d "$PKGDIR" ]; then
    echo "\n===== Building $pkg ====="
    if [ -f "$SETENV" ]; then
      # shellcheck source=/dev/null
      . "$SETENV"
    fi
    "$SCRIPTSDIR/build_one.sh" "$PKGDIR"
  else
    echo "Package directory $PKGDIR does not exist, skipping."
  fi
done < "$QUEUE"
