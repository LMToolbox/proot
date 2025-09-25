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
      DOWNLOADS=$(jq -c '.download[]?' "$PKGDIR/pkg.json")
      if [ -n "$DOWNLOADS" ]; then
        for entry in $DOWNLOADS; do
          url=$(echo "$entry" | jq -r '.url // empty')
          branch=$(echo "$entry" | jq -r '.branch // empty')
          if [ -n "$url" ] && [ "$url" != "null" ]; then
            fname=$(basename "$url")
            if echo "$url" | grep -q '\.git$'; then
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
          else
            echo "Skipping non-url download entry: $entry"
          fi
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
