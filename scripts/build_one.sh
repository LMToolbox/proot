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

cd "$PKGDIR"

# Apply all patches if present
echo "Applying patches in $PKGDIR..."
for p in *.patch; do
  [ -f "$p" ] || continue
  echo "Applying patch $p"
  patch -p0 < "$p"
done

# Read configure and build instructions from pkg.json if present
if [ -f pkg.json ]; then
  # Run configure commands first (expects a 'configure' array of shell commands)
  CONFIGURE_CMDS=$(jq -r '.configure[]?' pkg.json)
  if [ -n "$CONFIGURE_CMDS" ]; then
    echo "$CONFIGURE_CMDS" | while IFS= read -r cmd; do
      echo "> $cmd"
      sh -c "$cmd"
    done
  fi

  # Then run build commands (expects a 'build' array of shell commands)
  BUILD_CMDS=$(jq -r '.build[]?' pkg.json)
  if [ -n "$BUILD_CMDS" ]; then
    echo "$BUILD_CMDS" | while IFS= read -r cmd; do
      echo "> $cmd"
      sh -c "$cmd"
    done
  else
    echo "No build commands found in pkg.json for $PKGDIR"
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
  echo "No pkg.json found in $PKGDIR, skipping configure, build, and export commands."
fi
