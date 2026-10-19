#!/usr/bin/env bash
set -euo pipefail

readonly VERSION="1.25.3"
readonly PREFIX="${HOME}/.local/opt/conky-${VERSION}"
readonly WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/conky-build.XXXXXXXX")"
readonly ARCHIVE="${WORK_DIR}/conky-${VERSION}.tar.gz"
readonly SOURCE_DIR="${WORK_DIR}/source"
readonly BUILD_DIR="${WORK_DIR}/build"
readonly BUILD_JOBS="${CONKY_BUILD_JOBS:-4}"

cleanup() {
    rm -rf -- "${WORK_DIR}"
}
trap cleanup EXIT

for command in cmake ninja curl tar; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        printf 'Required build command is missing: %s\n' "${command}" >&2
        exit 1
    fi
done

curl --fail --location --silent --show-error \
    "https://github.com/brndnmtthws/conky/archive/refs/tags/v${VERSION}.tar.gz" \
    --output "${ARCHIVE}"
mkdir -p "${SOURCE_DIR}"
tar -xzf "${ARCHIVE}" --strip-components=1 -C "${SOURCE_DIR}"

cmake -S "${SOURCE_DIR}" -B "${BUILD_DIR}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DRELEASE=ON \
    -DBUILD_X11=ON \
    -DBUILD_WAYLAND=OFF \
    -DBUILD_IMLIB2=ON \
    -DBUILD_LUA_CAIRO=ON \
    -DBUILD_LUA_CAIRO_XLIB=OFF \
    -DBUILD_LUA_IMLIB2=OFF \
    -DBUILD_LUA_RSVG=OFF \
    -DBUILD_LUA_TEXT=OFF \
    -DBUILD_COLOUR_NAME_MAP=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_EXTRAS=OFF \
    -DBUILD_MPD=OFF \
    -DBUILD_MOC=OFF \
    -DBUILD_CMUS=OFF \
    -DBUILD_APCUPSD=OFF \
    -DBUILD_OPENSOUNDSYS=OFF \
    -DBUILD_PULSEAUDIO=OFF \
    -DBUILD_CURL=OFF \
    -DBUILD_RSS=OFF \
    -DBUILD_NVIDIA=OFF

cmake --build "${BUILD_DIR}" --parallel "${BUILD_JOBS}"
cmake --install "${BUILD_DIR}"

if ! "${PREFIX}/bin/conky" -v | grep -Fq "conky ${VERSION} compiled"; then
    printf 'Installed Conky does not report the expected version %s\n' "${VERSION}" >&2
    exit 1
fi

printf 'Installed Conky %s at %s/bin/conky\n' "${VERSION}" "${PREFIX}"
