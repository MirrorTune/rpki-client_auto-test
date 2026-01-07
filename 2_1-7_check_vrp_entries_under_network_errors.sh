#!/usr/bin/env bash

set -euo pipefail

: "${RPKI_CLIENT_BIN:=rpki-client}"
: "${RPKI_CACHE_DIR:=/work/rrdp-cache}"
: "${RPKI_OUT_DIR:=/work/rrdp-out}"
: "${RPKI_LOG_FILE:=/work/2_1-7_check_vrp_entries_under_network_errors.log}"
: "${RPKI_BASELINE_FILE:=/work/rrdp-out/2_1-7_baseline_vrp_entries.txt}"
: "${RPKI_VRP_MIN_RATIO:=0.90}"

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "テスト開始（2.1-7 ネットワークエラー発生時の VRP Entriesチェック）"

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

info "キャッシュディレクトリ: ${RPKI_CACHE_DIR}"
info "出力ディレクトリ     : ${RPKI_OUT_DIR}"
info "ログファイル         : ${RPKI_LOG_FILE}"
info "基準VRPファイル       : ${RPKI_BASELINE_FILE}"
info "許容下限比率          : ${RPKI_VRP_MIN_RATIO}"

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

VRP_LINE="$(grep -E 'VRP Entries' "${RPKI_LOG_FILE}" | tail -n 1 || true)"
if [ -z "${VRP_LINE}" ]; then
  fail "ログ内に VRP Entries 行を検出できませんでした: ${RPKI_LOG_FILE}"
fi

VRP_ENTRIES_RAW="$(printf '%s\n' "${VRP_LINE}" | sed -n 's/.*VRP Entries[[:space:]]*:[[:space:]]*\([0-9,][0-9,]*\).*/\1/p')"
VRP_ENTRIES="$(printf '%s\n' "${VRP_ENTRIES_RAW}" | tr -d ',' || true)"

if [ -z "${VRP_ENTRIES}" ]; then
  fail "VRP Entries の値を取得できませんでした: ${VRP_LINE}"
fi

case "${VRP_ENTRIES}" in
  *[!0-9]*)
    fail "VRP Entries の数値が想定外です: ${VRP_ENTRIES}"
    ;;
esac

info "VRP Entries: ${VRP_ENTRIES}"

NETWORK_ERROR_COUNT="$(grep -Eai '(rrdp|rsync|tls|name resolution|could not connect|connection limit|socket|dns)' "${RPKI_LOG_FILE}" | wc -l | tr -d ' ' || true)"
case "${NETWORK_ERROR_COUNT}" in
  *[!0-9]*)
    NETWORK_ERROR_COUNT="0"
    ;;
esac

if [ "${NETWORK_ERROR_COUNT}" -gt 0 ]; then
  info "ネットワーク関連のエラー行数: ${NETWORK_ERROR_COUNT}"
else
  info "ネットワーク関連のエラー行数: 0"
fi

BASELINE_ENTRIES=""
if [ -n "${RPKI_BASELINE_VRP_ENTRIES:-}" ]; then
  BASELINE_ENTRIES="${RPKI_BASELINE_VRP_ENTRIES}"
fi

if [ -z "${BASELINE_ENTRIES}" ] && [ -f "${RPKI_BASELINE_FILE}" ]; then
  BASELINE_ENTRIES="$(tr -d ' \t\r\n' < "${RPKI_BASELINE_FILE}" || true)"
fi

if [ -n "${BASELINE_ENTRIES}" ]; then
  case "${BASELINE_ENTRIES}" in
    *[!0-9]*)
      fail "基準VRP Entries の数値が想定外です: ${BASELINE_ENTRIES}"
      ;;
  esac
  info "基準VRP Entries: ${BASELINE_ENTRIES}"
else
  warn "基準VRP Entries が未設定です"
fi

if [ -z "${BASELINE_ENTRIES}" ]; then
  printf '%s\n' "${VRP_ENTRIES}" > "${RPKI_BASELINE_FILE}"
  pass "基準VRP Entries を保存しました: ${VRP_ENTRIES}"
  pass "テスト完了（2.1-7 ネットワークエラー発生時の VRP Entriesチェック）"
  exit 0
fi

if [ "${NETWORK_ERROR_COUNT}" -eq 0 ]; then
  pass "ネットワークエラーは検出されませんでした（チェック対象外）"
  pass "テスト完了（2.1-7 ネットワークエラー発生時の VRP Entriesチェック）"
  exit 0
fi

THRESHOLD="$(awk -v b="${BASELINE_ENTRIES}" -v r="${RPKI_VRP_MIN_RATIO}" 'BEGIN{printf "%.0f", b*r}')"
info "判定しきい値: ${THRESHOLD}"

if awk -v cur="${VRP_ENTRIES}" -v th="${THRESHOLD}" 'BEGIN{exit !(cur >= th)}'; then
  pass "ネットワークエラーが発生しても VRP Entries は基準の ${RPKI_VRP_MIN_RATIO} 以上です（${VRP_ENTRIES} >= ${THRESHOLD}）"
else
  fail "ネットワークエラー発生時に VRP Entries が基準未満です（${VRP_ENTRIES} < ${THRESHOLD}）"
fi

pass "テスト完了（2.1-7 ネットワークエラー発生時の VRP Entriesチェック）"

