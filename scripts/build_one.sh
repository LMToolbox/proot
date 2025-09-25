#!/bin/sh

# Generic build script for a single package based on pkg.json and patches
# Usage: ./build_one.sh <package_dir>
# Handles download (git/curl), patching, configure/build, and export.


set -e


PKGDIR="$1"
if [ -z "$PKGDIR" ]; then
  echo "Usage: $0 <package_dir>" >&2
  exit 1
fi

cd "$PKGDIR"


# Download sources if 'download' section exists
if [ -f pkg.json ]; then
  DOWNLOADS=$(jq -c '.download[]?' pkg.json)
  if [ -n "$DOWNLOADS" ]; then
    for entry in $DOWNLOADS; do
      url=$(echo "$entry" | jq -r '.url // .')
      branch=$(echo "$entry" | jq -r '.branch // empty')
      fname=$(basename "$url")
      if echo "$url" | grep -q '\\.git$'; then
        # Git repo
        if [ -n "$branch" ] && [ "$branch" != "null" ]; then
          echo "Cloning $url (branch: $branch)"
          git clone --depth 1 -b "$branch" "$url"
        else
          echo "Cloning $url (default branch)"
          git clone --depth 1 "$url"
        fi
      else
        # File download
        echo "Downloading $url"
        curl -LO "$url"
        # Unpack if archive
        case "$fname" in
          *.tar.gz|*.tgz) tar xzf "$fname" ; ;;
          *.tar.bz2) tar xjf "$fname" ; ;;
          *.tar.xz) tar xJf "$fname" ; ;;
          *.zip) unzip "$fname" ; ;;
        esac
      fi
    done
  fi
fi

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
