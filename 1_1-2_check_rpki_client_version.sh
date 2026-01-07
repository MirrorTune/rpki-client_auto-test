#!/usr/bin/env bash

set -euo pipefail

: "${RPKI_CLIENT_BIN:=rpki-client}"
: "${EXPECTED_RPKICLIENT_VERSION:=}"     # バージョンを指定

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "rpki-client テスト開始（1.1-2 バージョン情報の確認）"

if command -v "${RPKI_CLIENT_BIN}" >/dev/null 2>&1; then
  BIN_PATH="$(command -v "${RPKI_CLIENT_BIN}")"
  info "rpki-client 実行ファイルを確認しました: ${BIN_PATH}"
else
  fail "rpki-client の実行ファイルが見つかりません。（RPKI_CLIENT_BIN='${RPKI_CLIENT_BIN}'）バージョン情報を確認できません。"
fi

set +e
VERSION_OUT="$("${RPKI_CLIENT_BIN}" -V 2>&1)"
RC=$?
set -e

if [ "${RC}" -ne 0 ]; then
  fail "rpki-client -V の実行に失敗しました。（終了コード=${RC}）出力: ${VERSION_OUT}"
fi

if [ -z "${VERSION_OUT}" ]; then
  fail "rpki-client -V の出力を取得できませんでした。"
fi

if ! printf '%s\n' "${VERSION_OUT}" | grep -Eiq '^rpki-client(-portable)?[[:space:]]+[0-9]'; then
  fail "rpki-client -V の出力形式が想定外です: ${VERSION_OUT}"
fi

pass "バージョンを取得しました: ${VERSION_OUT}"

if [ -n "${EXPECTED_RPKICLIENT_VERSION}" ]; then
  if printf '%s\n' "${VERSION_OUT}" | grep -Fq "${EXPECTED_RPKICLIENT_VERSION}"; then
    pass "指定されたバージョンと一致しました: ${EXPECTED_RPKICLIENT_VERSION}"
  else
    fail "指定されたバージョンと一致しません。指定のバージョン=${EXPECTED_RPKICLIENT_VERSION}, 実際のバージョン='${VERSION_OUT}'"
  fi
else
  info "EXPECTED_RPKICLIENT_VERSION が指定されていないため、バージョンの一致確認は実施しません。"
fi

pass "rpki-client テスト完了（1.1-2 バージョン情報の確認）"


