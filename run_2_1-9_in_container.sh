#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 2_1-9_check_ntp_sync_failure_detection.sh を実行します."

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

docker run --rm \
  -e HOME=/tmp \
  --cap-add NET_ADMIN \
  --cap-add SYS_TIME \
  --entrypoint /bin/bash \
  -e EXPECTED_NTP_SERVERS="${EXPECTED_NTP_SERVERS:-ntp.nict.jp}" \
  -e NTP_TIMEOUT_SEC="${NTP_TIMEOUT_SEC:-10}" \
  -e NTP_LOG_FILE="${NTP_LOG_FILE:-/work/2_1-9_ntp_failure_detection.log}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  -lc "bash /work/2_1-9_check_ntp_sync_failure_detection.sh && chown ${HOST_UID}:${HOST_GID} /work/2_1-9_ntp_failure_detection.log 2>/dev/null || true"

