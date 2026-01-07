#!/usr/bin/env bash
set -euo pipefail

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

: "${RPKI_CLIENT_BIN:=rpki-client}"
: "${RPKI_CACHE_DIR:=/work/rrdp-cache}"
: "${RPKI_OUT_DIR:=/work/json-out}"
: "${RPKI_LOG_FILE:=/work/3_1-2_output_json.log}"
: "${RPKI_JSON_OUT_FILE:=/work/json-out/json}"

info "テスト開始（3.1-2 JSON形式での出力テスト）"

if command -v "${RPKI_CLIENT_BIN}" >/dev/null 2>&1; then
  BIN_PATH="$(command -v "${RPKI_CLIENT_BIN}")"
  pass "rpki-client 実行ファイルを確認しました: ${BIN_PATH}"
else
  fail "rpki-client が見つかりません: ${RPKI_CLIENT_BIN}"
fi

mkdir -p "${RPKI_CACHE_DIR}" "${RPKI_OUT_DIR}"

if id -u _rpki-client >/dev/null 2>&1; then
  chown -R _rpki-client "${RPKI_CACHE_DIR}" "${RPKI_OUT_DIR}" 2>/dev/null || true
fi

info "キャッシュディレクトリ: ${RPKI_CACHE_DIR}"
info "出力ディレクトリ     : ${RPKI_OUT_DIR}"
info "ログファイル         : ${RPKI_LOG_FILE}"
info "JSON成果物ファイル   : ${RPKI_JSON_OUT_FILE}"

cache_hint=0
if find "${RPKI_CACHE_DIR}" -type f -print -quit 2>/dev/null | grep -q .; then
  cache_hint=1
fi

if [ "${cache_hint}" -ne 0 ]; then
  pass "既存キャッシュを検出しました（ダウンロード無しで進む可能性があります）"
else
  warn "既存キャッシュが見つかりませんでした（初回取得が発生するため時間がかかります）"
fi

rm -f "${RPKI_LOG_FILE}" 2>/dev/null || true
rm -f "${RPKI_JSON_OUT_FILE}" 2>/dev/null || true

info "rpki-client を JSON 出力指定（-j）で実行します: -j -m -vv -d \"${RPKI_CACHE_DIR}\" \"${RPKI_OUT_DIR}\""

set +e
"${RPKI_CLIENT_BIN}" -j -m -vv \
  -d "${RPKI_CACHE_DIR}" \
  "${RPKI_OUT_DIR}" \
  > /dev/null 2> "${RPKI_LOG_FILE}"
RC=$?
set -e

if [ "${RC}" -ne 0 ]; then
  fail "rpki-client の実行が正常に終了しませんでした（終了コード=${RC}）ログを確認してください: ${RPKI_LOG_FILE}"
fi
pass "rpki-client の実行が正常に完了しました（終了コード0）"

if grep -qi 'not all files processed' "${RPKI_LOG_FILE}"; then
  fail "rpki-client が 'not all files processed' を出力しました。処理が完遂していません。ログ: ${RPKI_LOG_FILE}"
fi

if [ ! -s "${RPKI_JSON_OUT_FILE}" ]; then
  fail "JSON成果物が見つからない、または空です: ${RPKI_JSON_OUT_FILE}（ログ: ${RPKI_LOG_FILE}）"
fi
pass "JSON成果物ファイルを確認しました: ${RPKI_JSON_OUT_FILE}"

first_char="$(head -c 1 "${RPKI_JSON_OUT_FILE}" 2>/dev/null || true)"
if [ "${first_char}" = "{" ] || [ "${first_char}" = "[" ]; then
  pass "JSON形式の先頭を確認しました（先頭が '{' または '['）"
else
  fail "JSON先頭が想定と異なります（先頭文字='${first_char}'）: ${RPKI_JSON_OUT_FILE}"
fi

if command -v python3 >/dev/null 2>&1; then
  set +e
  python3 -m json.tool "${RPKI_JSON_OUT_FILE}" >/dev/null 2>&1
  JRC=$?
  set -e
  if [ "${JRC}" -ne 0 ]; then
    fail "JSONとしてパースできませんでした: ${RPKI_JSON_OUT_FILE}"
  fi
  pass "JSONとしてパース可能であることを確認しました"
else
  warn "python3 が見つからないため、JSONパース検証はスキップします"
fi

pass "テスト完了（3.1-2 JSON形式での出力テスト）"

