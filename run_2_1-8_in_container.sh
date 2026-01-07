#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 2_1-8_check_ntp_time_synchronization.sh を実行します."

docker run --rm \
  --cap-add SYS_TIME \
  --entrypoint /bin/bash \
  -e EXPECTED_NTP_SERVERS="${EXPECTED_NTP_SERVERS:-ntp.nict.jp}" \
  -e MAX_NTP_ABS_OFFSET_SEC="${MAX_NTP_ABS_OFFSET_SEC:-1.0}" \
  -e NTP_TIMEOUT_SEC="${NTP_TIMEOUT_SEC:-10}" \
  -e NTP_LOG_FILE="${NTP_LOG_FILE:-/work/2_1-8_ntp_sync.log}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  2_1-8_check_ntp_time_synchronization.sh

