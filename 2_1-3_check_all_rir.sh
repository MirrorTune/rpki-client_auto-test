#!/usr/bin/env bash

set -euo pipefail

: "${RPKI_CLIENT_BIN:=rpki-client}"
: "${RPKI_CACHE_DIR:=/work/rrdp-cache}"
: "${RPKI_OUT_DIR:=/work/rrdp-out}"
: "${RPKI_LOG_FILE:=/work/2_1-3_check_all_rir.log}"

pass() { printf '\e[32m[PASS]\e[0m %s\n' "$*"; }
fail() { printf '\e[31m[FAIL]\e[0m %s\n' "$*"; exit 1; }
info() { printf '\e[36m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }

info "テスト開始（2.1-3 各RIRリポジトリからのデータダウンロード確認）"

if command -v "${RPKI_CLIENT_BIN}" >/dev/null 2>&1; then
  BIN_PATH="$(command -v "${RPKI_CLIENT_BIN}")"
  pass "rpki-client 実行ファイルを確認しました: ${BIN_PATH}"
else
  fail "rpki-client の実行ファイルが見つかりません（RPKI_CLIENT_BIN='${RPKI_CLIENT_BIN}'）PATH や指定パスを確認してください。"
fi

mkdir -p "${RPKI_CACHE_DIR}" "${RPKI_OUT_DIR}"

OUT_JSON="${RPKI_OUT_DIR}/json"
OUT_METRICS="${RPKI_OUT_DIR}/metrics"

rm -f "${OUT_JSON}" "${OUT_METRICS}" "${RPKI_LOG_FILE}"

if id _rpki-client >/dev/null 2>&1; then
  chown -R _rpki-client "${RPKI_CACHE_DIR}" "${RPKI_OUT_DIR}" 2>/dev/null || true
fi

info "キャッシュディレクトリ: ${RPKI_CACHE_DIR}"
info "出力ディレクトリ     : ${RPKI_OUT_DIR}"
info "ログファイル         : ${RPKI_LOG_FILE}"

cache_hint=0
if find "${RPKI_CACHE_DIR}" -type f -print -quit 2>/dev/null | grep -q .; then
  cache_hint=1
fi
if [ "${cache_hint}" -ne 0 ]; then
  pass "キャッシュを検出しました。"
else
  warn "キャッシュが見つかりませんでした。"
fi

info "rpki-client を実行します: -j -m -vv -d \"${RPKI_CACHE_DIR}\" \"${RPKI_OUT_DIR}\""

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

if [ ! -f "${OUT_JSON}" ]; then
  fail "JSON 出力ファイルが見つかりません: ${OUT_JSON}"
elif [ ! -s "${OUT_JSON}" ]; then
  fail "JSON 出力ファイルは存在しますが、中身が空です: ${OUT_JSON}"
fi
pass "JSON 出力ファイルを確認しました: ${OUT_JSON}"

if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 が見つかりません。テストの実行には python3 が必要です。"
fi

info "JSON 内の Trust Anchor の情報から、各RIRのデータ取得状況を確認します。"

TMP_OUTPUT="$(mktemp)"
set +e
python3 <<PY > "${TMP_OUTPUT}"
import json
from pathlib import Path
import sys

json_path = Path("${OUT_JSON}")
print(f"JSON ファイル: {json_path}")

if not json_path.is_file():
    print("JSON ファイルが存在しません")
    sys.exit(1)

text = json_path.read_text(encoding="utf-8")
if not text.strip():
    print("JSON ファイルの内容が空です")
    sys.exit(1)

try:
    data = json.loads(text)
except Exception as e:
    print(f"JSON のパースに失敗しました: {e}")
    sys.exit(1)

roas = data.get("roas")
if roas is None:
    roas = data.get("vrps", [])

if not isinstance(roas, list):
    print("JSON 内の roas / vrps フィールドが配列ではありません")
    sys.exit(1)

tas = set()
for v in roas:
    if not isinstance(v, dict):
        continue
    ta = v.get("ta")
    if not ta:
        continue
    tas.add(str(ta).upper())

required = {"AFRINIC", "APNIC", "ARIN", "LACNIC", "RIPE"}

if tas:
    print("JSON 内で検出した Trust Anchor:", ", ".join(sorted(tas)))
else:
    print("JSON 内に Trust Anchor 情報が見つかりませんでした")

missing = required - tas
if missing:
    print("不足している可能性がある RIR:", ", ".join(sorted(missing)))
    sys.exit(1)
else:
    print("全ての RIR (APNIC / ARIN / RIPE / LACNIC / AFRINIC) から VRP が取得できています")
    sys.exit(0)
PY
PY_RC=$?
set -e

cat "${TMP_OUTPUT}"
rm -f "${TMP_OUTPUT}"

if [ "${PY_RC}" -ne 0 ]; then
  fail "JSON 内の Trust Anchor 情報から、全ての RIR のデータ取得を確認できませんでした"
fi

pass "各RIRからの VRP 取得を確認しました"
pass "テスト完了（2.1-3 各RIRリポジトリからのデータダウンロード確認）"

