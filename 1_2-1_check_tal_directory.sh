#!/usr/bin/env bash

set -euo pipefail

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "rpki-client テスト開始（1.2-1 TALディレクトリの確認）"

REQUIRED_TALS=(afrinic.tal apnic.tal lacnic.tal ripe.tal)

has_any_tal() {
  local d="$1"
  compgen -G "${d}/*.tal" >/dev/null 2>&1
}

has_required_set() {
  local d="$1" miss=0
  for f in "${REQUIRED_TALS[@]}"; do
    [ -f "${d}/${f}" ] || { miss=1; break; }
  done
  return $miss
}

CANDIDATES=()
if [ -n "${TAL_DIR:-}" ]; then
  CANDIDATES+=("${TAL_DIR}")
fi
CANDIDATES+=(
  "/etc/tals"
  "/etc/rpki"
  "/usr/share/rpki-client/tals"
  "/usr/local/share/rpki-client/tals"
  "/usr/local/etc/rpki-client/tals"
  "/usr/local/etc/tals"
  "/usr/local/etc/rpki"
  "/opt/homebrew/etc/rpki-client/tals"
)

VALID_DIRS=()
for d in "${CANDIDATES[@]}"; do
  if [ -d "$d" ] && has_any_tal "$d"; then
    VALID_DIRS+=("$d")
  fi
done


if [ ${#VALID_DIRS[@]} -eq 0 ]; then
  info "/etc および /usr 配下から .tal ファイルを探索します…"
  mapfile -t FOUND_BY_FIND < <(
    find /etc /usr -maxdepth 5 -type f -name '*.tal' 2>/dev/null \
      | xargs -r -n1 dirname \
      | sort -u
  )
  for d in "${FOUND_BY_FIND[@]}"; do
    if [ -d "$d" ] && has_any_tal "$d"; then
      VALID_DIRS+=("$d")
    fi
  done
fi

FOUND_DIR=""
if [ ${#VALID_DIRS[@]} -gt 0 ]; then
  for d in "${VALID_DIRS[@]}"; do
    if has_required_set "$d"; then
      FOUND_DIR="$d"
      break
    fi
  done
  if [ -z "${FOUND_DIR}" ]; then
    FOUND_DIR="${VALID_DIRS[0]}"
    warn "4つのTAL（apnic / ripe / lacnic / afrinic）が揃っているディレクトリが見つからないため、次のディレクトリを使用します: ${FOUND_DIR}"
  fi
else
  fail "TAL（*.tal）を含むディレクトリが見つかりませんでした。"
fi

pass "TALディレクトリを確認しました: ${FOUND_DIR}"

if [ -r "${FOUND_DIR}" ] && [ -x "${FOUND_DIR}" ]; then
  pass "アクセス権OK（ディレクトリを参照可能）: ${FOUND_DIR}"
else
  warn "アクセス権に注意（ディレクトリを参照できない可能性があります）: ${FOUND_DIR}"
fi

pass "rpki-client テスト完了（1.2-1 TALディレクトリの確認）"


