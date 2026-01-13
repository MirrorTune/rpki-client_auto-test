#!/usr/bin/env bash

set -euo pipefail

: "${RPKI_CLIENT_BIN:=rpki-client}"

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "rpki-client テスト開始（1.1-3 必要な依存関係の充足確認）"

if command -v "${RPKI_CLIENT_BIN}" >/dev/null 2>&1; then
  BIN_PATH="$(command -v "${RPKI_CLIENT_BIN}")"
  info "rpki-client 実行ファイルを確認しました: ${BIN_PATH}"
else
  fail "rpki-client の実行ファイルが見つかりません。（RPKI_CLIENT_BIN='${RPKI_CLIENT_BIN}'） 依存関係を確認できません。"
fi

if command -v ldd >/dev/null 2>&1; then
  LDD_OUT="$(ldd "${BIN_PATH}" 2>&1 || true)"

  if printf '%s\n' "${LDD_OUT}" | grep -qi 'not a dynamic executable'; then
    info "ldd: この rpki-client は共有ライブラリを使わない形式であるため、ライブラリの依存確認は省略します。"
  else
    MISSING_LIBS="$(printf '%s\n' "${LDD_OUT}" | awk '/not found/{print $1}' || true)"
    if [ -n "${MISSING_LIBS}" ]; then
      fail "共有ライブラリが不足しています: ${MISSING_LIBS}"
    else
      pass "共有ライブラリの依存関係に問題はありません。（ldd）"

      # 追加: 依存している共有ライブラリ名を列挙（ライブラリ名のみ）
      LIB_LIST="$(printf '%s\n' "${LDD_OUT}" | awk '/=>/ {print $1}' | sort -u || true)"
      if [ -n "${LIB_LIST}" ]; then
        info "依存している共有ライブラリ一覧:"
        while IFS= read -r lib; do
          [ -n "${lib}" ] && printf '  - %s\n' "${lib}"
        done <<< "${LIB_LIST}"
      else
        info "依存している共有ライブラリ一覧: （検出なし）"
      fi
    fi
  fi
else
  info "ldd が見つからないため、共有ライブラリの確認は省略します。"
fi

if command -v rsync >/dev/null 2>&1; then
  pass "rsync の存在を確認しました: $(command -v rsync)"
elif command -v openrsync >/dev/null 2>&1; then
  pass "OpenRsync の存在を確認しました: $(command -v openrsync)"
else
  warn "rsync / openrsync が見つかりません。rsync での取得は実行できません。（RRDP のみで動作）"
fi

pass "rpki-client テスト完了（1.1-3 必要な依存関係の充足確認）"

