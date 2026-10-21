#!/usr/bin/env bash
# Populates the dist/ folders of the workspace packages the demo depends on
# with the published npm builds. Building scramjet core from source requires a
# Rust nightly + wasm-bindgen/wasm-opt/wasm-snip toolchain, which isn't
# available on hosted CI such as Netlify.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/../.."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for pkg in core controller utils; do
	dir="$PACKAGES_DIR/$pkg"
	if [ -d "$dir/dist" ]; then
		echo "$pkg: dist/ already present, skipping"
		continue
	fi
	name="$(node -p "require('$dir/package.json').name")"
	version="$(node -p "require('$dir/package.json').version")"
	echo "$pkg: fetching $name@$version"
	tarball="$(cd "$TMP_DIR" && npm pack "$name@$version" --silent)"
	mkdir -p "$TMP_DIR/$pkg"
	tar -xzf "$TMP_DIR/$tarball" -C "$TMP_DIR/$pkg"
	cp -r "$TMP_DIR/$pkg/package/dist" "$dir/dist"
done
