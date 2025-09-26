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

# Set default PREFIX if not set
if [ -z "$PREFIX" ]; then
  mkdir -p "$ROOTDIR/dependencies/install"
  export PREFIX="$(realpath "$ROOTDIR/dependencies/install")"
fi
# Set default ARCH if not set
if [ -z "$ARCH" ]; then
  export ARCH="unknown"
fi
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  PKGDIR="$BUILDDIR/$pkg"
  if [ -d "$PKGDIR" ]; then
    echo "\n===== Building $pkg ====="
    export ARCH
    export PREFIX
    "$SCRIPTSDIR/build_one.sh" "$PKGDIR"
  else
    echo "Package directory $PKGDIR does not exist, skipping."
  fi
done < "$QUEUE"
