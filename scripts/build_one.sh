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

# Set PREFIX if not set
if [ -z "$PREFIX" ]; then
  export PREFIX="$PKGDIR/install"
fi
export PREFIX=$(realpath "$PREFIX")

# Apply all patches if present
echo "Applying patches in $PKGDIR..."
for p in *.patch; do
  [ -f "$p" ] || continue
  echo "Applying patch $p"
  patch -p0 < "$p"
done

# Read build instructions from pkg.json if present
if [ -f pkg.json ]; then
  BUILD_TYPE=$(jq -r '.build | type' pkg.json 2>/dev/null || echo "none")
  if [ "$BUILD_TYPE" = "object" ]; then
    for key in $(jq -r '.build | keys[]' pkg.json); do
      CMDS=$(jq -r --arg k "$key" '.build[$k][]?' pkg.json)
      if [ -n "$CMDS" ]; then
        echo "# $key phase"
        echo "$CMDS" | while IFS= read -r cmd; do
          [ -z "$cmd" ] && continue
          echo "> $cmd"
          sh -c "$cmd"
        done
      fi
    done
  elif [ "$BUILD_TYPE" = "array" ]; then
    BUILD_CMDS=$(jq -r '.build[]?' pkg.json)
    if [ -n "$BUILD_CMDS" ]; then
      echo "$BUILD_CMDS" | while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        echo "> $cmd"
        sh -c "$cmd"
      done
    else
      echo "No build commands found in pkg.json for $PKGDIR"
    fi
  else
    echo "No build section found in pkg.json for $PKGDIR"
  fi

  # Export artifacts if 'export' section exists
  EXPORT_CMDS=$(jq -r '.export[]?' pkg.json)
  if [ -n "$EXPORT_CMDS" ]; then
    # Use $ARCH and $WORKDIR if set, else fallback
    ARCHDIR="${ARCH:-unknown}"
    WORKDIR="${WORKDIR:-$(pwd)}"
    DIST_DIR="$WORKDIR/dist/$ARCHDIR"
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
