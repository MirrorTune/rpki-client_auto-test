#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします."
BUILD_ARGS=()
if [[ -n "${RPKI_CLIENT_VERSION:-}" ]]; then
  BUILD_ARGS+=(--build-arg "RPKI_CLIENT_VERSION=${RPKI_CLIENT_VERSION}")
fi
docker build "${BUILD_ARGS[@]}" -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 3_1-4_check_prefix_correctness.sh を実行します."

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -e RPKI_CACHE_DIR="${RPKI_CACHE_DIR:-/work/rrdp-cache}" \
  -e RPKI_OUT_DIR="${RPKI_OUT_DIR:-/work/csv-out}" \
  -e RPKI_LOG_FILE="${RPKI_LOG_FILE:-/work/3_1-4_check_prefix_correctness.log}" \
  -e RPKI_CSV_FILE="${RPKI_CSV_FILE:-/work/csv-out/csv}" \
  -e EXPECTED_1_PREFIX="${EXPECTED_1_PREFIX:-1.1.1.0/24}" \
  -e EXPECTED_1_ASN="${EXPECTED_1_ASN:-13335}" \
  -e EXPECTED_2_PREFIX="${EXPECTED_2_PREFIX:-8.8.8.0/24}" \
  -e EXPECTED_2_ASN="${EXPECTED_2_ASN:-15169}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  -lc "bash /work/3_1-4_check_prefix_correctness.sh"

