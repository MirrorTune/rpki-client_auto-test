#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします..."
BUILD_ARGS=()
if [[ -n "${RPKI_CLIENT_VERSION:-}" ]]; then
  BUILD_ARGS+=(--build-arg "RPKI_CLIENT_VERSION=${RPKI_CLIENT_VERSION}")
fi
echo "[INFO] RPKI_CLIENT_VERSION=${RPKI_CLIENT_VERSION:-<empty>}"

docker build "${BUILD_ARGS[@]}" -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 2_2-3_check_crl_validation.sh を実行します..."

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e RPKI_TAL_DIR="${RPKI_TAL_DIR:-/usr/local/etc/rpki}" \
  -e WARMUP_TIMEOUT="${WARMUP_TIMEOUT:-900}" \
  -e MAX_ATTEMPTS="${MAX_ATTEMPTS:-50}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  -lc "bash /work/2_2-3_check_crl_validation.sh"

