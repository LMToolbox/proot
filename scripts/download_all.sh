#!/bin/sh
# Download all sources for packages in build/ according to queue.txt and pkg.json
# Usage: ./download_all.sh

set -e

ROOTDIR="$(realpath "$(dirname "$0")/..")"
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
    cd "$PKGDIR"

    if [ -f pkg.json ]; then
      url=$(jq -r '.download.url // empty' pkg.json)
      branch=$(jq -r '.download.branch // empty' pkg.json)

      if [ -n "$url" ]; then
        fname=$(basename "$url")

        if echo "$url" | grep -q '\.git$'; then
          if [ -n "$branch" ]; then
            echo "Cloning $url (branch: $branch)"
            git clone --depth 1 -b "$branch" "$url" pkg
          else
            echo "Cloning $url (default branch)"
            git clone --depth 1 "$url" pkg
          fi
        else
          echo "Downloading $url"
          curl -LO "$url"
          case "$fname" in
            *.tar.gz|*.tgz) tar xzf "$fname" ;;
            *.tar.bz2) tar xjf "$fname" ;;
            *.tar.xz) tar xJf "$fname" ;;
            *.zip) unzip "$fname" ;;
          esac

          new_dirs=$(find . -mindepth 1 -maxdepth 1 -type d | grep -v '^\./\.git$')
          if [ "$(echo "$new_dirs" | wc -l)" -eq 1 ]; then
            onlydir=$(echo "$new_dirs")
            if [ "$onlydir" != "." ] && [ "$onlydir" != "$PKGDIR" ]; then
              echo "Flattening $onlydir into $PKGDIR/pkg..."
              mkdir -p pkg
              mv "$onlydir"/* ./pkg 2>/dev/null || true
              mv "$onlydir"/.[!.]* ./pkg 2>/dev/null || true
              rmdir "$onlydir"
            fi
          fi
        fi
      else
        echo "No valid 'url' in pkg.json for $pkg"
      fi
    else
      echo "No pkg.json found in $PKGDIR, skipping download commands."
    fi
  else
    echo "Package directory $PKGDIR does not exist, skipping."
  fi
done < "$QUEUE"
