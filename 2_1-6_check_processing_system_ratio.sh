#!/usr/bin/env bash

set -euo pipefail

: "${RPKI_CLIENT_BIN:=rpki-client}"
: "${RPKI_CACHE_DIR:=/work/rrdp-cache}"
: "${RPKI_OUT_DIR:=/work/2_1-6_processing_out}"
: "${RPKI_LOG_FILE:=/work/2_1-6_check_processing_system_ratio.log}"
: "${RPKI_MAX_SYSTEM_RATIO:=0.10}"

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "テスト開始（2.1-6 処理時間・system比率の確認）"

if command -v "${RPKI_CLIENT_BIN}" >/dev/null 2>&1; then
  BIN_PATH="$(command -v "${RPKI_CLIENT_BIN}")"
  pass "rpki-client 実行ファイルを確認しました: ${BIN_PATH}"
else
  fail "rpki-client が見つかりません（RPKI_CLIENT_BIN='${RPKI_CLIENT_BIN}'）"
fi

if [ ! -d "${RPKI_CACHE_DIR}" ]; then
  fail "キャッシュディレクトリが存在しません: ${RPKI_CACHE_DIR}"
fi

if ! find "${RPKI_CACHE_DIR}" -type f -mindepth 1 -print -quit | grep -q .; then
  fail "キャッシュが空です（2.1-2 を先に実行してキャッシュを作成してください）: ${RPKI_CACHE_DIR}"
fi

mkdir -p "${RPKI_OUT_DIR}"
rm -f "${RPKI_LOG_FILE}"
rm -f "${RPKI_OUT_DIR}/json" "${RPKI_OUT_DIR}/metrics" 2>/dev/null || true

if id _rpki-client >/dev/null 2>&1; then
  chown -R _rpki-client "${RPKI_OUT_DIR}" 2>/dev/null || true
fi

info "キャッシュディレクトリ: ${RPKI_CACHE_DIR}"
info "出力ディレクトリ     : ${RPKI_OUT_DIR}"
info "ログファイル         : ${RPKI_LOG_FILE}"
info "許容される最大system比率: ${RPKI_MAX_SYSTEM_RATIO}"

set +e
"${RPKI_CLIENT_BIN}" -j -m -vv \
  -d "${RPKI_CACHE_DIR}" \
  "${RPKI_OUT_DIR}" \
  > "${RPKI_LOG_FILE}" 2>&1
RC=$?
set -e

if [ "${RC}" -ne 0 ]; then
  fail "rpki-client の実行が正常に終了しませんでした（終了コード=${RC}）ログを確認してください: ${RPKI_LOG_FILE}"
fi
pass "rpki-client の実行が正常に完了しました"

if [ ! -s "${RPKI_LOG_FILE}" ]; then
  fail "ログファイルが空か存在しません: ${RPKI_LOG_FILE}"
fi

PROC_LINE="$(grep -E 'Processing time [0-9]+ seconds' "${RPKI_LOG_FILE}" | tail -n 1 || true)"

if [ -z "${PROC_LINE}" ]; then
  fail "ログ内に Processing time 行を検出できませんでした: ${RPKI_LOG_FILE}"
fi

TOTAL_SEC="$(printf '%s\n' "${PROC_LINE}" | sed -n 's/.*Processing time \([0-9][0-9]*\) seconds.*/\1/p')"
USER_SEC="$(printf '%s\n' "${PROC_LINE}" | sed -n 's/.*(\([0-9][0-9]*\) seconds user.*/\1/p')"
SYSTEM_SEC="$(printf '%s\n' "${PROC_LINE}" | sed -n 's/.*,[[:space:]]*\([0-9][0-9]*\) seconds system).*/\1/p')"

if [ -z "${TOTAL_SEC}" ] || [ -z "${USER_SEC}" ] || [ -z "${SYSTEM_SEC}" ]; then
  fail "Processing time 行のパースに失敗しました: ${PROC_LINE}"
fi

case "${TOTAL_SEC}${USER_SEC}${SYSTEM_SEC}" in
  *[!0-9]*)
    fail "Processing time の数値が想定外です: total=${TOTAL_SEC}, user=${USER_SEC}, system=${SYSTEM_SEC}"
    ;;
esac

info "処理時間: ${TOTAL_SEC} 秒（user=${USER_SEC} 秒, system=${SYSTEM_SEC} 秒）"

RATIO="$(awk -v u="${USER_SEC}" -v s="${SYSTEM_SEC}" 'BEGIN{t=u+s; if(t<=0){printf "0.000000"} else {printf "%.6f", s/t}}')"
info "system 比率（system / (user+system)）: ${RATIO}"

if awk -v r="${RATIO}" -v max="${RPKI_MAX_SYSTEM_RATIO}" 'BEGIN{exit !(r <= max)}'; then
  pass "system比率が許容範囲内です（比率=${RATIO}, 閾値=${RPKI_MAX_SYSTEM_RATIO}）"
else
  fail "system比率が閾値を超えています（比率=${RATIO}, 閾値=${RPKI_MAX_SYSTEM_RATIO}）"
fi

pass "テスト完了（2.1-6 処理時間・system比率の確認）"

