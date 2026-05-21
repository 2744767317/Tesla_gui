#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-"$ROOT_DIR/build/tests/map_data_service"}"
QMAKE_BIN="${QMAKE:-qmake}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

"$QMAKE_BIN" "$ROOT_DIR/tests/map_data_service_tests.pro"
make -j"$JOBS"
./map_data_service_tests
