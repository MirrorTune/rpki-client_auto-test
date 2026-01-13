#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 3_1-3_output_openbgpd.sh を実行します."

docker run --rm \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e RPKI_OUT_DIR="${RPKI_OUT_DIR:-/work/openbgpd-out}" \
  -e RPKI_LOG_FILE="${RPKI_LOG_FILE:-/work/3_1-3_output_openbgpd.log}" \
  -e RPKI_OPENBGPD_OUT_FILE="${RPKI_OPENBGPD_OUT_FILE:-/work/openbgpd-out/openbgpd}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  -lc "bash /work/3_1-3_output_openbgpd.sh"

