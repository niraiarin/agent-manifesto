#!/usr/bin/env bash
# Step 6c.1/6d: 半順序関係に基づく Gate 結果伝播 (deterministic 成分)
# TaskAutomationClass: deterministic → structural enforcement
# 根拠: deterministic_must_be_structural, mixed_task_decomposition (TaskClassification.lean)
# @traces D13, P4
#
# judgmental 成分（前提変化の影響判定、修正内容の決定）は LLM が担当。
# このスクリプトは deterministic 成分のみを実行する:
#   - 半順序関係（依存グラフ）の抽出と走査
#   - 後続 Issue の列挙
#   - 親 Issue テーブルの更新
#   - 前提情報の突合表示
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  propagate.sh successor-list  <parent-issue> <completed-issue>
  propagate.sh update-parent   <parent-issue> <child-issue> <gate-result>
  propagate.sh check-premises  <parent-issue> <completed-issue>
  propagate.sh validate        <parent-issue>
  propagate.sh cascade-next    <parent-issue> <completed-issue>

Subcommands:
  validate       全 Sub-Issue の依存セクションが machine-readable か検証する。
                 各 Issue の「## 依存」セクションが「なし」または「#N」形式のみで
                 構成されているか確認。フリーテキスト混入をブロックする。
                 cascade-next の冒頭で自動実行される。
  successor-list   半順序関係で <completed-issue> の後続にあたる全 Issue をトポロジカル順に列挙する。
                   Parent Issue の Sub-Issues テーブルと各 Sub-Issue の依存セクションから
                   依存グラフを構築し、Kahn's algorithm でソートして出力する。

  update-parent    親 Issue の Sub-Issues テーブルを更新する。
                   <child-issue> の状態列を <gate-result> (PASS/CONDITIONAL/FAIL) に書き換え、
                   gh issue edit で反映する。

  check-premises   <completed-issue> の Gate 結果コメントと、後続 Issue の依存・背景セクションを
                   突合表示する。LLM が「前提が変化したか」を判定するための入力を生成する。

  cascade-next     ステートフルなカスケード伝播。呼び出すたびに次の1件を表示する。
                   状態ファイルで進捗を追跡し、全件完了まで同じコマンドを繰り返す。
                   LLM は judgmental 判定のみ担当。順序制御は構造的に強制。
                   これが Step 6d の推奨エントリポイント。

Examples:
  propagate.sh successor-list 577 578
  propagate.sh update-parent 577 578 PASS
  propagate.sh check-premises 577 578
  propagate.sh validate 577             # 依存セクションのフォーマット検証
  propagate.sh cascade-next 577 578    # 1件目を表示（validate 自動実行）
  propagate.sh cascade-next 577 578    # 2件目を表示（同じコマンド）
  propagate.sh cascade-next 577 578    # 全件完了 → DONE
USAGE
  exit 1
}

[[ $# -lt 2 ]] && usage

ACTION="$1"

# --- Helper functions ---

# 依存セクションのフォーマットを検証する。
# 許容形式: 「なし」「none」「N/A」または「#N」のカンマ区切り（+ HTML コメント）
# 返り値: 0 = valid, 1 = invalid（エラーメッセージを stderr に出力）
validate_dependency_format() {
  local issue="$1"
  local body
  body=$(gh issue view "$issue" --json body --jq '.body' 2>/dev/null) || return 0

  # 「## 依存」セクションを抽出
  local dep_section
  dep_section=$(echo "$body" | sed -n '/^## 依存/,/^## /{ /^## 依存/d; /^## /d; p; }')

  # HTML コメントと空行を除去
  local content
  content=$(echo "$dep_section" | sed 's/<!--.*-->//g' | sed '/^\s*$/d')

  if [[ -z "$content" ]]; then
    echo "  #${issue}: ERROR — 依存セクションが空（「なし」も「#N」もない）" >&2
    return 1
  fi

  # 「なし」「none」「N/A」のみの場合は OK
  if echo "$content" | grep -qiE '^\s*(なし|none|N/A)\s*$'; then
    return 0
  fi

  # 各非空行が「#N」パターン（カンマ/スペース区切り）のみで構成されているか検証
  # 許容: "#123", "#123, #456", "- #123", "- #123, #456"
  local line
  local has_error=false
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # 行頭のリストマーカー「- 」を除去
    local cleaned
    cleaned=$(echo "$line" | sed 's/^\s*-\s*//')
    # #N パターンと区切り文字（カンマ、スペース）以外の文字が含まれていないか
    local stripped
    # Use [0-9][0-9]* (POSIX BRE, portable) instead of [0-9]\+ (GNU extension, fails on BSD sed / macOS)
    stripped=$(echo "$cleaned" | sed 's/#[0-9][0-9]*//g' | sed 's/[,[:space:]]//g')
    if [[ -n "$stripped" ]]; then
      echo "  #${issue}: ERROR — 依存セクションにフリーテキスト混入: \"${line}\"" >&2
      echo "           許容形式: 「なし」または「#N」のカンマ区切り" >&2
      echo "           理由の記述は「依存の理由」セクションに移動すること" >&2
      has_error=true
    fi
  done <<< "$content"

  if $has_error; then
    return 1
  fi
  return 0
}

# 全 Sub-Issue の依存セクションを検証する。
# 返り値: 0 = 全件 valid, 1 = 1件以上 invalid
validate_all_dependencies() {
  local parent="$1"
  local all_subs
  all_subs=$(extract_sub_issues "$parent")

  if [[ -z "$all_subs" ]]; then
    echo "WARNING: Sub-Issue なし（Parent #${parent}）"
    return 0
  fi

  local errors=0
  local total=0
  echo "=== 依存セクション検証: Parent #${parent} ==="
  while IFS= read -r sub; do
    total=$((total + 1))
    if ! validate_dependency_format "$sub"; then
      errors=$((errors + 1))
    else
      echo "  #${sub}: OK"
    fi
  done <<< "$all_subs"

  echo ""
  if [[ $errors -gt 0 ]]; then
    echo "FAIL: ${errors}/${total} 件の Sub-Issue で依存セクションのフォーマットエラー"
    echo "修正後に再実行: propagate.sh validate ${parent}"
    return 1
  else
    echo "PASS: 全 ${total} 件の依存セクションが machine-readable"
    return 0
  fi
}

# Parent Issue body から Sub-Issues テーブルを抽出し、issue 番号リストを返す
extract_sub_issues() {
  local parent="$1"
  gh issue view "$parent" --json body --jq '.body' \
    | grep -oE '#[0-9]+' \
    | grep -v "^#${parent}$" \
    | sed 's/^#//' \
    | sort -un
}

# Sub-Issue body の「依存」セクションから依存先 issue 番号を抽出する
extract_dependencies() {
  local issue="$1"
  local body
  body=$(gh issue view "$issue" --json body --jq '.body' 2>/dev/null) || return 0

  # 「## 依存」セクションを抽出（次の ## まで）
  local dep_section
  dep_section=$(echo "$body" | sed -n '/^## 依存/,/^## /{ /^## 依存/d; /^## /d; p; }')

  # 空白行を除去した実質内容で判定
  local trimmed
  trimmed=$(echo "$dep_section" | sed '/^\s*$/d')

  # 実質空、または「なし」「none」のみの場合
  if [[ -z "$trimmed" ]] || echo "$trimmed" | grep -qiE '^\s*なし\s*$|^\s*none\s*$'; then
    return 0
  fi

  # issue 番号を抽出
  echo "$dep_section" | grep -oE '#[0-9]+' | sed 's/^#//' | sort -un
}

# Sub-Issue body の「依存」「背景」「目的」セクションを抽出（前提情報）
extract_premise_sections() {
  local issue="$1"
  local body
  body=$(gh issue view "$issue" --json body --jq '.body' 2>/dev/null) || return 0

  echo "=== #${issue} 前提情報 ==="
  echo ""

  for section in "目的" "背景" "依存" "方法"; do
    local content
    content=$(echo "$body" | sed -n "/^## ${section}/,/^## /{ /^## ${section}/d; /^## /d; p; }")
    if [[ -n "$content" ]]; then
      echo "--- ${section} ---"
      echo "$content"
      echo ""
    fi
  done
}

# Issue の最新 Gate 判定コメントを抽出
extract_gate_comment() {
  local issue="$1"
  gh issue view "$issue" --json comments \
    --jq '[.comments[] | select(.body | test("Gate:.*PASS|Gate:.*CONDITIONAL|Gate:.*FAIL"))] | last | .body // "（Gate 判定コメントなし）"'
}

# 依存グラフを構築し、指定 issue の推移的後続をトポロジカル順で列挙
# Kahn's algorithm: 半順序関係を保持した順序で出力する
# 出力: 後続 issue 番号（1行1件、トポロジカル順）
compute_successors() {
  local parent="$1"
  local completed="$2"

  # 全 sub-issue を取得
  local all_subs
  all_subs=$(extract_sub_issues "$parent")

  if [[ -z "$all_subs" ]]; then
    echo "（Sub-Issue なし）" >&2
    return 0
  fi

  # Phase 1: 全 sub-issue の依存関係を収集し、影響範囲（reachable set）を特定
  # completed から推移的に到達可能なノードのみが対象
  local -A dep_map=()    # issue → "dep1 dep2 dep3" (スペース区切り)
  local -A in_degree=()  # issue → 影響範囲内での入次数

  while IFS= read -r sub; do
    [[ "$sub" == "$completed" ]] && continue
    local deps
    deps=$(extract_dependencies "$sub")
    dep_map["$sub"]="${deps:-}"
  done <<< "$all_subs"

  # Phase 2: completed から到達可能なノードを BFS で特定
  local -a reachable=()
  local -a bfs_queue=()

  # completed の直接後続を seed にする
  for sub in "${!dep_map[@]}"; do
    if [[ -n "${dep_map[$sub]}" ]] && echo "${dep_map[$sub]}" | grep -qx "$completed"; then
      bfs_queue+=("$sub")
      reachable+=("$sub")
    fi
  done

  # BFS で推移的後続を探索
  local -a bfs_visited=("${reachable[@]+"${reachable[@]}"}")
  while [[ ${#bfs_queue[@]} -gt 0 ]]; do
    local current="${bfs_queue[0]}"
    bfs_queue=("${bfs_queue[@]:1}")

    for sub in "${!dep_map[@]}"; do
      # 既に発見済みならスキップ
      local found=false
      for v in "${bfs_visited[@]+"${bfs_visited[@]}"}"; do
        [[ "$v" == "$sub" ]] && found=true && break
      done
      $found && continue

      if [[ -n "${dep_map[$sub]}" ]] && echo "${dep_map[$sub]}" | grep -qx "$current"; then
        bfs_queue+=("$sub")
        bfs_visited+=("$sub")
        reachable+=("$sub")
      fi
    done
  done

  if [[ ${#reachable[@]} -eq 0 ]]; then
    return 0
  fi

  # Phase 3: reachable set 内でトポロジカルソート（Kahn's algorithm）
  # in_degree = reachable set 内の依存元のうち、reachable set に含まれるもの + completed
  for sub in "${reachable[@]}"; do
    local count=0
    if [[ -n "${dep_map[$sub]}" ]]; then
      while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        if [[ "$dep" == "$completed" ]]; then
          # completed は既に処理済みなので入次数に数えない
          continue
        fi
        # dep が reachable set 内にあるか
        for r in "${reachable[@]}"; do
          if [[ "$r" == "$dep" ]]; then
            count=$((count + 1))
            break
          fi
        done
      done <<< "${dep_map[$sub]}"
    fi
    in_degree["$sub"]=$count
  done

  # 入次数 0 のノードをキューに投入
  local -a topo_queue=()
  for sub in "${reachable[@]}"; do
    if [[ "${in_degree[$sub]}" -eq 0 ]]; then
      topo_queue+=("$sub")
    fi
  done

  # トポロジカル順に出力
  while [[ ${#topo_queue[@]} -gt 0 ]]; do
    local node="${topo_queue[0]}"
    topo_queue=("${topo_queue[@]:1}")
    echo "$node"

    # node に依存する reachable ノードの入次数を減らす
    for sub in "${reachable[@]}"; do
      if [[ -n "${dep_map[$sub]}" ]] && echo "${dep_map[$sub]}" | grep -qx "$node"; then
        in_degree["$sub"]=$(( ${in_degree[$sub]} - 1 ))
        if [[ "${in_degree[$sub]}" -eq 0 ]]; then
          topo_queue+=("$sub")
        fi
      fi
    done
  done
}

# --- Subcommands ---

case "$ACTION" in
  validate)
    PARENT="${2:?parent-issue required}"
    validate_all_dependencies "$PARENT"
    ;;

  successor-list)
    PARENT="${2:?parent-issue required}"
    COMPLETED="${3:?completed-issue required}"

    echo "=== 半順序関係: #${COMPLETED} の後続 Issue ==="
    echo "Parent: #${PARENT}"
    echo ""

    successors=$(compute_successors "$PARENT" "$COMPLETED")

    if [[ -z "$successors" ]]; then
      echo "後続 Issue: なし（#${COMPLETED} に依存する Issue はない）"
      echo ""
      echo "ACTION: Step 6d 省略可能（後続なし）"
    else
      echo "後続 Issue:"
      while IFS= read -r s; do
        local_title=$(gh issue view "$s" --json title --jq '.title' 2>/dev/null || echo "(取得失敗)")
        local_state=$(gh issue view "$s" --json state --jq '.state' 2>/dev/null || echo "?")
        echo "  #${s} [${local_state}] ${local_title}"
      done <<< "$successors"
      echo ""
      echo "ACTION: 上記の各 Issue について、#${COMPLETED} の Gate 結果を踏まえて"
      echo "        前提が変化したか判定すること（judgmental: LLM）"
      echo ""
      echo "次のステップ: propagate.sh check-premises ${PARENT} ${COMPLETED}"
    fi
    ;;

  update-parent)
    PARENT="${2:?parent-issue required}"
    CHILD="${3:?child-issue required}"
    GATE_RESULT="${4:?gate-result required (PASS/CONDITIONAL/FAIL)}"

    # gate-result のバリデーション
    case "$GATE_RESULT" in
      PASS|CONDITIONAL|FAIL) ;;
      *) echo "ERROR: gate-result は PASS/CONDITIONAL/FAIL のいずれか" >&2; exit 1 ;;
    esac

    echo "=== 親 Issue #${PARENT} の Sub-Issues テーブル更新 ==="
    echo "対象: #${CHILD} → ${GATE_RESULT}"
    echo ""

    # 現在の body を取得
    current_body=$(gh issue view "$PARENT" --json body --jq '.body')

    # Sub-Issues テーブル内の該当行を更新
    # パターン: | N | #CHILD ... | 状態 | → 状態を GATE_RESULT に
    # 複数のテーブル形式に対応するため、#CHILD を含む行の最後のセル/テキストを更新
    updated_body=$(echo "$current_body" | sed -E "s/(#${CHILD}[^|]*\|[^|]*\|)[^|]*/\1 **${GATE_RESULT}** /")

    if [[ "$current_body" == "$updated_body" ]]; then
      # sed で更新できなかった場合、より柔軟なパターンを試行
      # 「| ... #CHILD ... | 任意テキスト |」の最後のセルを更新
      updated_body=$(echo "$current_body" | sed -E "s/(.*#${CHILD}.*\| *)([^|]*?)( *\|[[:space:]]*$)/\1**${GATE_RESULT}**\3/")
    fi

    if [[ "$current_body" == "$updated_body" ]]; then
      echo "WARNING: #${CHILD} のテーブル行が見つかりませんでした。"
      echo "手動で親 Issue の Sub-Issues テーブルを更新してください。"
      exit 1
    fi

    # 更新を適用
    echo "$updated_body" | gh issue edit "$PARENT" --body-file -
    echo "DONE: #${PARENT} の Sub-Issues テーブルを更新しました。"
    echo ""

    # 全子ノードの状態を確認
    echo "=== 全子ノードの状態確認 ==="
    all_subs=$(extract_sub_issues "$PARENT")
    local_all_final=true
    local_has_conditional=false
    local_has_fail=false

    while IFS= read -r sub; do
      sub_state=$(gh issue view "$sub" --json state --jq '.state' 2>/dev/null || echo "?")
      sub_title=$(gh issue view "$sub" --json title --jq '.title' 2>/dev/null || echo "?")

      if [[ "$sub_state" == "OPEN" ]]; then
        local_all_final=false
        echo "  #${sub} [OPEN] ${sub_title} — 未完了"
      else
        echo "  #${sub} [CLOSED] ${sub_title}"
      fi
    done <<< "$all_subs"

    echo ""
    if $local_all_final; then
      echo "STATUS: 全子ノードが最終状態。親 #${PARENT} の Gate 判定を実行可能。"
    else
      echo "STATUS: 未完了の子ノードあり。親 #${PARENT} は保留。"
    fi
    ;;

  check-premises)
    PARENT="${2:?parent-issue required}"
    COMPLETED="${3:?completed-issue required}"

    echo "=== 前提突合: #${COMPLETED} の Gate 結果 vs 後続 Issue の前提 ==="
    echo ""

    # 完了 Issue の Gate 結果を取得
    echo "--- #${COMPLETED} Gate 結果 ---"
    extract_gate_comment "$COMPLETED"
    echo ""
    echo "============================================"
    echo ""

    # 後続 Issue の前提を取得
    successors=$(compute_successors "$PARENT" "$COMPLETED")

    if [[ -z "$successors" ]]; then
      echo "後続 Issue: なし"
      echo "ACTION: 前提突合不要"
    else
      while IFS= read -r s; do
        extract_premise_sections "$s"
        echo "============================================"
        echo ""
      done <<< "$successors"

      echo "JUDGMENT REQUIRED (LLM):"
      echo "  上記の各後続 Issue について、#${COMPLETED} の Gate 結果を踏まえて:"
      echo "  1. 前提が変化したか？"
      echo "  2. 変化した場合、どのセクション（目的/背景/方法/Gate基準）を修正すべきか？"
      echo "  3. Issue 自体が不要になったか？"
      echo ""
      echo "  判定結果は各 Issue にコメントとして記録すること。"
    fi
    ;;

  cascade-next)
    PARENT="${2:?parent-issue required}"
    COMPLETED="${3:?completed-issue required}"

    # 初回のみ validate を実行（状態ファイルが存在しない = 初回）
    REPO_ROOT_CHECK="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    if [[ ! -f "${REPO_ROOT_CHECK}/.cascade-state/${PARENT}-${COMPLETED}.done" ]]; then
      if ! validate_all_dependencies "$PARENT"; then
        echo ""
        echo "BLOCKED: 依存セクションのフォーマットエラーを修正してから再実行してください。"
        exit 1
      fi
      echo ""
    fi

    # 状態ファイル: どの Issue まで処理済みかを追跡
    # プロジェクトルートの .cascade-state/ に保持（.gitignore 推奨）
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    STATE_DIR="${REPO_ROOT}/.cascade-state"
    mkdir -p "$STATE_DIR"
    STATE_FILE="${STATE_DIR}/${PARENT}-${COMPLETED}.done"

    # トポロジカル順で全後続を取得
    successors=$(compute_successors "$PARENT" "$COMPLETED")

    if [[ -z "$successors" ]]; then
      echo "後続 Issue: なし（#${COMPLETED} に依存する Issue はない）"
      echo "STATUS: DONE"
      echo "ACTION: Step 6d 完了。Step 6c.1 へ進む:"
      echo "  propagate.sh update-parent ${PARENT} ${COMPLETED} <PASS|CONDITIONAL|FAIL>"
      rm -f "$STATE_FILE"
      exit 0
    fi

    total=$(echo "$successors" | wc -l | tr -d ' ')

    # 処理済み Issue リストを読み込み
    touch "$STATE_FILE"
    processed_count=$(wc -l < "$STATE_FILE" | tr -d ' ')

    # 次の未処理 Issue を見つける
    next_issue=""
    step=0
    while IFS= read -r candidate; do
      step=$((step + 1))
      if ! grep -qx "$candidate" "$STATE_FILE"; then
        next_issue="$candidate"
        break
      fi
    done <<< "$successors"

    if [[ -z "$next_issue" ]]; then
      echo "=== Step 6d: 全 ${total} 件の後続 Issue 処理完了 ==="
      echo "STATUS: DONE"
      echo ""
      echo "ACTION: Step 6c.1（上方集約）を実行:"
      echo "  propagate.sh update-parent ${PARENT} ${COMPLETED} <PASS|CONDITIONAL|FAIL>"
      rm -f "$STATE_FILE"
      exit 0
    fi

    current_title=$(gh issue view "$next_issue" --json title --jq '.title' 2>/dev/null || echo "(取得失敗)")
    current_state=$(gh issue view "$next_issue" --json state --jq '.state' 2>/dev/null || echo "?")

    echo "=== Step 6d: 半順序カスケード [${step}/${total}] ==="
    echo "Parent: #${PARENT} | 完了: #${COMPLETED} | 処理済み: ${processed_count}/${total}"
    echo ""
    echo ">>> #${next_issue} [${current_state}] ${current_title}"
    echo ""

    # 初回のみ Gate 結果を表示
    if [[ "$processed_count" -eq 0 ]]; then
      echo "--- #${COMPLETED} Gate 結果 ---"
      extract_gate_comment "$COMPLETED"
      echo ""
      echo "============================================"
      echo ""
    fi

    # この Issue の前提情報を表示（最新版を取得 → 前ステップの修正が反映される）
    extract_premise_sections "$next_issue"

    echo "------------------------------------------------------------"
    echo "JUDGMENT (LLM):"
    echo "  1. 前提が変化したか？"
    echo "  2. 変化 → gh issue edit で修正 + コメント記録"
    echo "  3. 不要 → gh issue close"
    echo "------------------------------------------------------------"
    echo ""
    echo "判定後、同じコマンドを再実行:"
    echo "  propagate.sh cascade-next ${PARENT} ${COMPLETED}"

    # この Issue を処理済みとしてマーク
    # 注: sandbox 環境ではスクリプト内からの >> が silent fail する場合がある。
    # その場合は手動で実行: echo <issue> >> .cascade-state/<parent>-<completed>.done
    echo "$next_issue" | tee -a "$STATE_FILE" > /dev/null 2>&1 || \
      echo "WARNING: 状態ファイルへの書き込みに失敗。手動で実行: echo ${next_issue} >> ${STATE_FILE}"
    ;;

  *)
    usage
    ;;
esac
