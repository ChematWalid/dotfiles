#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
library_dir="${HOME:?HOME is not set}/.local/lib"
output="${library_dir}/libportal-remember-dir.so"

mkdir -p "$library_dir"
cc -shared -fPIC -O2 -Wall -Wextra \
    $(pkg-config --cflags gtk+-3.0) \
    "${source_dir}/portal-remember-dir.c" \
    -o "$output" \
    $(pkg-config --libs gtk+-3.0) -ldl
chmod 755 "$output"
printf 'Built %s\n' "$output"
