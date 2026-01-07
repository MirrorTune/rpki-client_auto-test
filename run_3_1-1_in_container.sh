#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 3_1-1_output_csv.sh を実行します."

docker run --rm \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e RPKI_OUT_DIR="${RPKI_OUT_DIR:-/work/csv-out}" \
  -e RPKI_LOG_FILE="${RPKI_LOG_FILE:-/work/3_1-1_output_csv.log}" \
  -e RPKI_CSV_FILE="${RPKI_CSV_FILE:-/work/csv-out/vrp.csv}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  -lc "bash /work/3_1-1_output_csv.sh"

