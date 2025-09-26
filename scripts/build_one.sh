#!/bin/sh

# Generic build script for a single package based on pkg.json and patches
# Usage: ./build_one.sh <package_dir>
# Handles patching, configure/build, and export.

set -e

PKGDIR="$1"
if [ -z "$PKGDIR" ]; then
  echo "Usage: $0 <package_dir>" >&2
  exit 1
fi

# Ensure PKGDIR is absolute
PKGDIR=$(realpath "$PKGDIR")
cd "$PKGDIR"

SETENV="$SCRIPTSDIR/set-env.sh"

# Set PREFIX if not set
if [ -z "$PREFIX" ]; then
  export PREFIX="$PKGDIR/install"
fi
mkdir -p "$PREFIX"
export PREFIX=$(realpath "$PREFIX")

# Apply all patches if present
for p in *.patch; do
  [ -f "$p" ] || continue
  echo "Applying patch $p"
  patch -p0 -d pkg < "$p"
  done

# Read build instructions from pkg.json if present
if [ -f pkg.json ]; then
  BUILD_TYPE=$(jq -r '.build | type' pkg.json 2>/dev/null || echo "none")

  if [ "$BUILD_TYPE" = "object" ]; then
    for key in $(jq -r '.build | keys[]' pkg.json); do
      CMD=$(jq -r --arg k "$key" '.build[$k][]?' pkg.json | paste -sd " " -)
      [ -z "$CMD" ] && continue
      echo "# $key phase (merged)"
      echo "> $CMD"
      (cd pkg && eval "$CMD")
    done

  elif [ "$BUILD_TYPE" = "array" ]; then
    CMD=$(jq -r '.build[]?' pkg.json | paste -sd " " -)
    [ -z "$CMD" ] && continue
    echo "# build phase (merged)"
    echo "> $CMD"
    if [ -f "$SETENV" ] && [ ! -f env_off ]; then
      # shellcheck source=/dev/null
      echo "Auto-configuring build env"
      . "$SETENV"
    fi
    (cd pkg && eval "$CMD")

  else
    echo "No build section found in pkg.json for $PKGDIR"
  fi

  # Export artifacts if 'export' section exists
  EXPORT_CMDS=$(jq -r '.export[]?' pkg.json)
  if [ -n "$EXPORT_CMDS" ]; then
    ARCHDIR="${ARCH:-unknown}"
    ROOTDIR="$(realpath "$PKGDIR/../..")"
    DIST_DIR="$ROOTDIR/dist/$ARCHDIR"
    mkdir -p "$DIST_DIR"
    echo "$EXPORT_CMDS" | while IFS= read -r f; do
      if [ -e "$f" ]; then
        echo "Exporting $f to $DIST_DIR/"
        cp -a "$f" "$DIST_DIR/"
      else
        echo "Export file $f not found, skipping."
      fi
    done
  fi

else
  echo "No pkg.json found in $PKGDIR, skipping build and export commands."
fi
