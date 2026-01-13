#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします..."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 2_2-4_check_manifest_validation.sh を実行します..."

docker run --rm \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e TAL_DIR="${TAL_DIR:-/usr/local/etc/rpki}" \
  -e ARTIFACT_DIR="${ARTIFACT_DIR:-/work/2_2-4_mft_artifacts}" \
  -e WARMUP_OUTPUT_DIR="${WARMUP_OUTPUT_DIR:-/work/2_2-4_warmup_output}" \
  -e MAX_CANDIDATES="${MAX_CANDIDATES:-5000}" \
  -e MAX_ATTEMPTS="${MAX_ATTEMPTS:-50}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  2_2-4_check_manifest_validation.sh

