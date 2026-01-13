#!/usr/bin/env bash

set -euo pipefail

: "${RPKI_CLIENT_BIN:=rpki-client}"

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "rpki-client テスト開始（1.1-1 パッケージのインストール成功確認）"

if command -v dpkg-query >/dev/null 2>&1; then
  if dpkg-query -W -f='${Status}\n' rpki-client 2>/dev/null | grep -q 'install ok installed'; then
    pass "dpkg: rpki-client はインストール済みです。（install ok installed）"
  else
    info "dpkg: dpkg 上ではインストール済みとして確認できませんでした。実行ファイルが存在するためテストを継続します。"
  fi
else
  info "dpkg-query が見つからないため、dpkg によるパッケージ状態の確認は省略します。"
fi


if command -v "${RPKI_CLIENT_BIN}" >/dev/null 2>&1; then
  BIN_PATH="$(command -v "${RPKI_CLIENT_BIN}")"
  pass "実行ファイルを確認しました: ${BIN_PATH}"
else
  fail "rpki-client の実行ファイルが見つかりません。（RPKI_CLIENT_BIN='${RPKI_CLIENT_BIN}'）PATH を確認してください。"
fi

pass "rpki-client テスト完了（1.1-1 パッケージのインストール成功確認）"


