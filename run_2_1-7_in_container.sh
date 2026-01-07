#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 2_1-7_check_vrp_entries_under_network_errors.sh を実行します."

docker run --rm \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e RPKI_OUT_DIR="${RPKI_OUT_DIR:-/work/rrdp-out}" \
  -e RPKI_LOG_FILE="${RPKI_LOG_FILE:-/work/2_1-7_check_vrp_entries_under_network_errors.log}" \
  -e RPKI_BASELINE_FILE="${RPKI_BASELINE_FILE:-/work/rrdp-out/2_1-7_baseline_vrp_entries.txt}" \
  -e RPKI_VRP_MIN_RATIO="${RPKI_VRP_MIN_RATIO:-0.90}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  2_1-7_check_vrp_entries_under_network_errors.sh

