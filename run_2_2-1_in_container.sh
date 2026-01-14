#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします..."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 2_2-1_check_cert_chain_validation.sh を実行します..."

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e RPKI_LOG_FILE="${RPKI_LOG_FILE:-/work/2_2-1_check_cert_chain_validation.log}" \
  -e RPKI_ARTIFACT_DIR="${RPKI_ARTIFACT_DIR:-/work/2_2-1_cert_chain_artifacts}" \
  -e TAL_DIR="${TAL_DIR:-}" \
  -e RPKI_WARMUP_TIMEOUT="${RPKI_WARMUP_TIMEOUT:-1800}" \
  -e RPKI_WARMUP_OUTPUT_DIR="${RPKI_WARMUP_OUTPUT_DIR:-/work/2_2-1_warmup_output}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  2_2-1_check_cert_chain_validation.sh

