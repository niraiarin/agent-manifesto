#!/usr/bin/env bash
# L1 Safety Check — PreToolUse: Bash
#
# PoC 4 で検証済みのパターン:
# - stdin から JSON を読み、tool_input.command を取得
# - 危険パターンを検出したら stderr にメッセージ + exit 2
# - 安全なら exit 0（stdout 不要）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- L1: 破壊的操作 ---
# 直接実行と間接実行（bash -c, sh -c, eval 等）の両方を検査
FULL_CHECK="$COMMAND"

# 破壊的ファイル操作
if echo "$FULL_CHECK" | grep -qE 'rm\s+-(r|f|rf|fr)\s+(/|\.|\*|\$)'; then
  echo "L1: Destructive file operation blocked (rm with dangerous target)" >&2
  exit 2
fi

# 破壊的 git 操作
if echo "$FULL_CHECK" | grep -qE 'git\s+(push\s+(-f|--force)|reset\s+--hard|clean\s+-(f|fd))'; then
  echo "L1: Destructive git operation blocked" >&2
  exit 2
fi

# 権限昇格
if echo "$FULL_CHECK" | grep -qE '(sudo|chmod\s+777|chown\s+root)'; then
  echo "L1: Privilege escalation blocked" >&2
  exit 2
fi

# --- L1: 認証情報の外部送信 ---
if echo "$FULL_CHECK" | grep -qE 'curl.*(-d|--data).*(TOKEN|KEY|SECRET|PASSWORD|CREDENTIAL)'; then
  echo "L1: Potential credential exfiltration blocked" >&2
  exit 2
fi

# --- L1: プロンプトインジェクション ---
if echo "$FULL_CHECK" | grep -qiE '(ignore previous instructions|ignore all previous|disregard your|you are now|system prompt override)'; then
  echo "L1: Potential prompt injection pattern blocked" >&2
  exit 2
fi

# --- L1: 秘密情報の git add ---
# PoC 3 の教訓: deny rules は間接実行をバイパスする。Hook で直接検査。
if echo "$FULL_CHECK" | grep -qE 'git\s+add'; then
  # ステージ対象に秘密ファイルがないかチェック
  SECRET_PATTERNS='\.env|\.env\.|credentials|secret|\.pem$|\.key$|id_rsa|id_ed25519'
  # git add の引数からファイルパスを抽出（簡易）
  ADD_TARGETS=$(echo "$FULL_CHECK" | sed 's/.*git add//' | tr -s ' ')
  if echo "$ADD_TARGETS" | grep -qiE "$SECRET_PATTERNS"; then
    echo "L1: Staging secret/credential file blocked" >&2
    exit 2
  fi
  # git add -A / git add . の場合、ステージ済みファイルを確認
  if echo "$ADD_TARGETS" | grep -qE '^\s*(-A|\.|--all)'; then
    STAGED=$(git diff --cached --name-only 2>/dev/null || true)
    if echo "$STAGED" | grep -qiE "$SECRET_PATTERNS"; then
      echo "L1: git add -A would stage secret files. Use specific file names." >&2
      exit 2
    fi
  fi
fi

exit 0
