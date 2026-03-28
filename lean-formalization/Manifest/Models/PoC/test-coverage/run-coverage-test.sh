#!/usr/bin/env bash
# run-coverage-test.sh — Phase 0-3 一気通貫カバレッジテストのオーケストレーター
#
# セッションを跨いでも同じテストを再現可能にする。
#
# Usage:
#   # Step 1: バッチプロンプトを生成（LLM に渡すプロンプトファイル群）
#   bash run-coverage-test.sh generate --range 301-500 --batch-size 10
#
#   # Step 2: 生成されたプロンプトを LLM エージェントに実行させる（手動 or 自動）
#   #   各プロンプトは prompts/batch-31.prompt として出力される
#   #   LLM の出力は batch-31.json として保存する
#
#   # Step 3: バリデーション + パイプライン実行
#   bash run-coverage-test.sh validate --range 301-500
#   bash run-coverage-test.sh pipeline --range 301-500 --out-dir coverage-round2
#
#   # 全工程を一括表示
#   bash run-coverage-test.sh status --range 301-500
#
set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
MODELS_DIR="$(cd "$THIS_DIR/../.." && pwd)"
PROMPT_DIR="$THIS_DIR/prompts"
DOMAIN_FILE="$THIS_DIR/domains.txt"

usage() {
  cat <<'USAGE'
Usage:
  run-coverage-test.sh generate  --range START-END [--batch-size N]
  run-coverage-test.sh validate  --range START-END
  run-coverage-test.sh pipeline  --range START-END [--out-dir DIR]
  run-coverage-test.sh status    --range START-END

Commands:
  generate   Generate per-batch prompt files from template + domain list
  validate   Validate all batch JSON files (schema + id range)
  pipeline   Run monotonicity check + Lean generation + lake build
  status     Show overall status (generated / validated / built)

Options:
  --range START-END   Scenario ID range (e.g. 301-500)
  --batch-size N      Scenarios per batch (default: 10)
  --out-dir DIR       Output directory for pipeline results (default: coverage-roundN)
USAGE
  exit 2
}

# ============================================================
# ドメインリスト（200+ のユニークなプロジェクトドメイン）
# ============================================================
ensure_domain_file() {
  if [[ -f "$DOMAIN_FILE" ]]; then return; fi
  cat > "$DOMAIN_FILE" <<'DOMAINS'
自動運転バス安全管理|transport
遠隔医療プラットフォーム|medical
スマートグリッド電力管理|energy
不正取引検知システム|finance
精密農業ドローン制御|agriculture
災害避難支援 AI|government
半導体欠陥検査システム|manufacturing
オンライン試験監督 AI|education
港湾コンテナ最適化|transport
森林火災早期検知|energy
侵入検知セキュリティシステム|security
適応型学習プラットフォーム|education
航空管制支援 AI|transport
食品安全トレーサビリティ|manufacturing
契約書レビュー AI|legal
太陽光発電予測|energy
ICU 患者モニタリング|medical
暗号資産リスク評価|finance
建物構造健全性モニタリング|realestate
漁獲量予測|agriculture
ドローン配送管理|transport
ゲノム解析パイプライン|medical
交通信号最適化|transport
保険査定自動化|finance
水質モニタリング AI|energy
予知保全システム|manufacturing
フェイクニュース検知|media
犯罪予測パトロール|government
EV 充電網管理|transport
創薬候補スクリーニング|medical
原子力安全監視システム|energy
アルゴリズム取引プラットフォーム|finance
手術ロボット制御|medical
5G 基地局配置最適化|telecom
地震波解析 AI|science
マルウェア分類システム|security
自転車シェアリング管理|transport
学習障害早期検知|education
カーボンクレジット追跡|energy
溶接ロボット品質制御|manufacturing
電子カルテ統合|medical
信用スコアリング AI|finance
鉄道運行管理|transport
化学プラント安全管理|manufacturing
脆弱性スキャナ|security
カリキュラム最適化 AI|education
風力発電配置最適化|energy
判例検索 AI|legal
不動産価格予測|realestate
天体観測スケジューリング|science
感染症拡散モデリング|medical
住宅ローン審査 AI|finance
渋滞予測システム|transport
品質管理統計|manufacturing
アクセス制御ポリシー管理|security
語学学習チャットボット|education
大気汚染予測|energy
採用スクリーニング AI|legal
施工進捗管理|realestate
粒子加速器制御|science
リハビリ支援ロボット|medical
マネーロンダリング検知|finance
MaaS プラットフォーム|transport
サプライチェーン最適化|manufacturing
DDoS 緩和システム|security
入試公平性監査|education
廃棄物分類ロボット|energy
ハラスメント報告分析|legal
室内環境最適化|realestate
気象予報モデル|science
医療画像診断 AI|medical
為替リスクヘッジ|finance
宇宙デブリ追跡|transport
3D プリンティング品質管理|manufacturing
ログ異常検知|security
教師負荷分散|education
ダム放流制御|energy
勤怠異常検知|legal
地盤リスク評価|realestate
タンパク質構造予測|science
臨床試験マッチング|medical
ESG 投資評価|finance
船舶衝突回避システム|transport
在庫最適化|manufacturing
ゼロトラスト認証|security
STEM 実験シミュレーション|education
地熱発電管理|energy
知的財産調査 AI|legal
ビル管理自動化|realestate
量子化学シミュレーション|science
在宅介護見守り AI|medical
中小企業融資審査|finance
物流ルート最適化|transport
建設現場安全管理|manufacturing
データ匿名化|security
学生メンタルヘルス支援|education
蓄電池劣化予測|energy
人事評価バイアス検出|legal
都市再開発シミュレーション|realestate
古文書 OCR|science
精神健康スクリーニング|medical
リアルタイム決済|finance
パーキング管理|transport
繊維染色最適化|manufacturing
インシデント対応自動化|security
図書館蔵書推薦|education
海洋プラスチック追跡|energy
労務リスク予測|legal
耐震診断支援|realestate
考古学遺跡発掘支援|science
歯科矯正シミュレーション|medical
デリバティブ価格算定|finance
空飛ぶクルマ運航管理|transport
鋳造欠陥予測|manufacturing
フィッシング検知|security
オンライン試験監督|education
農業用水管理|energy
コンプライアンス研修 AI|legal
スマートホーム制御|realestate
深海探査ロボット|science
血液検査自動解析|medical
顧客離反予測|finance
自動翻訳品質管理|media
組立ライン最適化|manufacturing
暗号鍵管理|security
プログラミング教育 AI|education
CO2 回収効率最適化|energy
退職予測 AI|legal
構造健全性モニタリング|realestate
材料特性予測|science
救急トリアージ支援|medical
規制報告自動化|finance
コンテンツ推薦 AI|media
危険物取扱管理|manufacturing
コンプライアンス監査|security
自動採点 AI|education
再生可能エネルギー証書|energy
特許出願支援 AI|legal
建物エネルギー診断|realestate
DNA データバンク管理|science
妊婦遠隔モニタリング|medical
年金運用最適化|finance
ゲーム AI バランス調整|media
設備投資判断支援|manufacturing
SBOM 管理|security
河川氾濫予測|energy
映像監視分析|government
ネットワーク障害予測|telecom
アレルギー予測 AI|medical
音楽生成 AI|media
スポーツ戦術分析|media
養殖場管理 AI|agriculture
土壌分析 AI|agriculture
収穫時期予測|agriculture
食品鮮度管理|agriculture
農薬散布最適化|agriculture
品種改良シミュレーション|agriculture
灌漑自動制御|agriculture
フードロス予測|agriculture
帯域幅最適化|telecom
衛星通信スケジューリング|telecom
光ファイバー敷設計画|telecom
エッジコンピューティング配置|telecom
通信品質モニタリング|telecom
SLA 違反予測|telecom
周波数割当最適化|telecom
海底ケーブル保守|telecom
選挙投票システム|government
公共施設予約 AI|government
生活保護審査支援|government
土地利用計画|government
人口動態予測|government
公共交通バリアフリー|government
緊急通報分類|government
税務申告支援 AI|government
都市騒音マッピング|government
ごみ収集最適化|government
公営住宅配分|government
義肢制御インターフェース|medical
病院物流最適化|medical
ペット健康管理 AI|medical
映画レーティング予測|media
ライブ配信品質最適化|media
広告ターゲティング AI|media
著作権侵害検知|media
バーチャルアシスタント|media
eスポーツ分析|media
VPN 性能最適化|telecom
AR ナビゲーション|transport
IoT デバイス認証|security
クラウドセキュリティ|security
防災備蓄管理|government
マンション管理組合支援|realestate
配管劣化診断|realestate
クラウドコスト最適化|security
遺伝カウンセリング支援|medical
工場排水管理|manufacturing
学校給食管理|education
スマート農場管理|agriculture
仮想通貨ウォレット|finance
DOMAINS
  echo "Created $DOMAIN_FILE ($(wc -l < "$DOMAIN_FILE") domains)"
}

# ============================================================
# generate: バッチプロンプトを生成
# ============================================================
cmd_generate() {
  local range_start="${RANGE_START}"
  local range_end="${RANGE_END}"
  local batch_size="${BATCH_SIZE:-10}"

  ensure_domain_file
  mkdir -p "$PROMPT_DIR"

  local total=$((range_end - range_start + 1))
  local num_batches=$(( (total + batch_size - 1) / batch_size ))
  local first_batch=$(( (range_start - 1) / batch_size + 1 ))

  echo "Generating $num_batches batch prompts for S${range_start}-S${range_end}..."

  # ドメインリストを配列に読み込み
  local -a domains
  mapfile -t domains < "$DOMAIN_FILE"

  for ((b=0; b<num_batches; b++)); do
    local batch_num=$((first_batch + b))
    local sid_start=$((range_start + b * batch_size))
    local sid_end=$((sid_start + batch_size - 1))
    if [[ $sid_end -gt $range_end ]]; then sid_end=$range_end; fi
    local count=$((sid_end - sid_start + 1))

    # このバッチのドメイン一覧
    local domain_list=""
    for ((s=sid_start; s<=sid_end; s++)); do
      local idx=$((s - range_start))
      if [[ $idx -lt ${#domains[@]} ]]; then
        local domain_name=$(echo "${domains[$idx]}" | cut -d'|' -f1)
        domain_list="${domain_list}
- S${s}: ${domain_name}"
      else
        domain_list="${domain_list}
- S${s}: （自由選択）"
      fi
    done

    local prompt_file="$PROMPT_DIR/batch-${batch_num}.prompt"
    cat > "$prompt_file" <<PROMPT
あなたは model-questioner エージェントのパフォーマンステストを実行するテストハーネスです。

## **出力する scenario_id の範囲: ${sid_start}-${sid_end}（${count} 件）**

**重要**: 必ず上記の範囲の scenario_id を持つシナリオを **正確に ${count} 件** 出力してください。

## タスク

以下の手順で、scenario_id ${sid_start} から ${sid_end} までの ${count} 件のプロジェクトシナリオについて、
Phase 0 → Phase 1 → Phase 2 → ModelSpec JSON 出力を行ってください。

### 各シナリオの手順

1. **Phase 0**: 独自のプロジェクトのビジョンを考える（Q1: 何を作るか、Q2: 誰のためか、Q3: 最も大事なこと）
2. **Phase 1**: そのプロジェクトについて質問を 3-5 個生成し、合理的な回答をシミュレート
3. **Phase 2**:
   - Step 2.1: C（人間の設計判断）の抽出（3-7 個）
   - Step 2.2: H（LLM の推論）の導出（3-8 個、反証条件付き）
   - Step 2.3: 層の推論（EpistemicLayerClass の制約: ≥2層, 単射, 有界, bottom存在）
   - 命題の定義と割り当て（5-20 個）
   - 依存関係の設計（命題間の依存を現実的に設計）
4. **ModelSpec JSON 出力**: \`propositions\` フィールド付きのスタンドアロン形式

### ドメインの指定
${domain_list}

### 出力フォーマット（厳守）

最終出力は JSON 配列のみ（説明文なし）。
**この構造は自動バリデーションされます。フィールド名の変更や省略は検出されます。**

\`\`\`json
[
  {
    "scenario_id": ${sid_start},
    "project": "プロジェクト名",
    "num_c": 5,
    "num_h": 4,
    "num_layers": 4,
    "num_props": 12,
    "num_deps": 8,
    "model_spec": {
      "namespace": "TestCoverage.S${sid_start}",
      "layers": [
        {"name": "LayerName", "ordValue": 4, "definition": "層の定義", "derivedFrom": ["C1", "H1"]}
      ],
      "propositions": [
        {"id": "s${sid_start}_p01", "layerName": "LayerName", "justification": ["C1"], "dependencies": [".other_prop_id"]}
      ]
    }
  }
]
\`\`\`

**必須フィールド**:
- トップレベル: \`scenario_id\`(integer), \`project\`(string), \`model_spec\`(object)
- model_spec: \`namespace\`(string), \`layers\`(array, ≥2), \`propositions\`(array, ≥1)
- layers[]: \`name\`(string), \`ordValue\`(integer ≥1)
- propositions[]: \`id\`(string), \`layerName\`(string, layers[].name と一致)
- dependencies の参照先は \`.\` プレフィックス付き

**制約**:
- 層数は 2-7 の範囲で多様に
- 命題数は 5-20 の範囲で多様に
- ${count} 件中 1-2 件は意図的に単調性違反を含めること（テスト用）
PROMPT

    echo "  Created $prompt_file (S${sid_start}-S${sid_end})"
  done

  echo ""
  echo "Done. Next steps:"
  echo "  1. Run each prompt through an LLM agent"
  echo "  2. Save output as batch-{N}.json in this directory"
  echo "  3. bash run-coverage-test.sh validate --range ${range_start}-${range_end}"
  echo "  4. bash run-coverage-test.sh pipeline --range ${range_start}-${range_end}"
}

# ============================================================
# validate: バッチ JSON のバリデーション
# ============================================================
cmd_validate() {
  local range_start="${RANGE_START}"
  local range_end="${RANGE_END}"

  echo "=== Validating S${range_start}-S${range_end} ==="

  # ディレクトリスキャン
  bash "$THIS_DIR/validate-batch-output.sh" --scan-dir "$THIS_DIR" --total-range "${range_start}-${range_end}"
  local scan_exit=$?

  echo ""

  # 個別バッチのスキーマチェック
  local batch_size="${BATCH_SIZE:-10}"
  local first_batch=$(( (range_start - 1) / batch_size + 1 ))
  local num_batches=$(( (range_end - range_start + 1 + batch_size - 1) / batch_size ))
  local errors=0

  for ((b=0; b<num_batches; b++)); do
    local batch_num=$((first_batch + b))
    local batch_file="$THIS_DIR/batch-${batch_num}.json"
    local sid_start=$((range_start + b * batch_size))
    local sid_end=$((sid_start + batch_size - 1))
    if [[ $sid_end -gt $range_end ]]; then sid_end=$range_end; fi

    if [[ ! -f "$batch_file" ]]; then
      echo "MISSING: batch-${batch_num}.json (S${sid_start}-S${sid_end})"
      errors=$((errors + 1))
      continue
    fi

    if ! bash "$THIS_DIR/validate-batch-output.sh" -f "$batch_file" --range "${sid_start}-${sid_end}" > /dev/null 2>&1; then
      echo "FAIL: batch-${batch_num}.json"
      bash "$THIS_DIR/validate-batch-output.sh" -f "$batch_file" --range "${sid_start}-${sid_end}" 2>&1 | grep "ERROR"
      errors=$((errors + 1))
    else
      local count=$(jq '. | length' "$batch_file")
      echo "OK: batch-${batch_num}.json (${count} scenarios)"
    fi
  done

  echo ""
  if [[ $errors -eq 0 ]]; then
    echo "All batches validated successfully."
  else
    echo "ERRORS: $errors batches failed validation."
    return 1
  fi
}

# ============================================================
# pipeline: monotonicity + Lean 生成 + lake build
# ============================================================
cmd_pipeline() {
  local range_start="${RANGE_START}"
  local range_end="${RANGE_END}"
  local out_dir="${OUT_DIR:-$THIS_DIR/coverage-round2}"

  mkdir -p "$out_dir"

  echo "=== Pipeline: S${range_start}-S${range_end} → $out_dir ==="

  local batch_size="${BATCH_SIZE:-10}"
  local first_batch=$(( (range_start - 1) / batch_size + 1 ))
  local num_batches=$(( (range_end - range_start + 1 + batch_size - 1) / batch_size ))

  local total_pass=0 total_fail=0 total_violations=0 total_ms=0

  for ((b=0; b<num_batches; b++)); do
    local batch_num=$((first_batch + b))
    local batch_file="$THIS_DIR/batch-${batch_num}.json"

    if [[ ! -f "$batch_file" ]]; then
      echo "SKIP: batch-${batch_num}.json not found"
      continue
    fi

    echo ""
    echo "--- batch-${batch_num} ---"
    # process-batch.sh の出力をパースして集計
    local output
    output=$(bash "$THIS_DIR/process-batch.sh" "$batch_file" "$out_dir" 2>&1)
    echo "$output"

    # サマリ行をパース
    local pass=$(echo "$output" | grep "^PASS:" | grep -o '[0-9]*' | head -1)
    local fail=$(echo "$output" | grep "^FAIL:" | grep -o '[0-9]*' | head -1)
    local violations=$(echo "$output" | grep "^VIOLATIONS:" | grep -o '[0-9]*' | head -1)

    total_pass=$((total_pass + ${pass:-0}))
    total_fail=$((total_fail + ${fail:-0}))
    total_violations=$((total_violations + ${violations:-0}))
  done

  echo ""
  echo "======================================"
  echo "OVERALL RESULTS"
  echo "======================================"
  echo "Total PASS: $total_pass"
  echo "Total FAIL: $total_fail"
  echo "Total VIOLATIONS: $total_violations"
  local total=$((total_pass + total_fail + total_violations))
  if [[ $total -gt 0 ]]; then
    local rate=$((total_pass * 100 / total))
    echo "Pass rate: ${rate}%"
  fi
}

# ============================================================
# status: 全体の進捗表示
# ============================================================
cmd_status() {
  local range_start="${RANGE_START}"
  local range_end="${RANGE_END}"
  local batch_size="${BATCH_SIZE:-10}"
  local first_batch=$(( (range_start - 1) / batch_size + 1 ))
  local num_batches=$(( (range_end - range_start + 1 + batch_size - 1) / batch_size ))

  echo "=== Coverage Test Status: S${range_start}-S${range_end} ==="
  echo ""

  local prompts_ok=0 batches_ok=0 validated_ok=0

  for ((b=0; b<num_batches; b++)); do
    local batch_num=$((first_batch + b))
    local sid_start=$((range_start + b * batch_size))
    local sid_end=$((sid_start + batch_size - 1))
    if [[ $sid_end -gt $range_end ]]; then sid_end=$range_end; fi

    local prompt_status="  "
    local batch_status="  "
    local valid_status="  "

    if [[ -f "$PROMPT_DIR/batch-${batch_num}.prompt" ]]; then
      prompt_status="✓ "
      prompts_ok=$((prompts_ok + 1))
    fi

    if [[ -f "$THIS_DIR/batch-${batch_num}.json" ]]; then
      batch_status="✓ "
      batches_ok=$((batches_ok + 1))

      if bash "$THIS_DIR/validate-batch-output.sh" -f "$THIS_DIR/batch-${batch_num}.json" --range "${sid_start}-${sid_end}" > /dev/null 2>&1; then
        valid_status="✓ "
        validated_ok=$((validated_ok + 1))
      else
        valid_status="✗ "
      fi
    fi

    printf "  batch-%02d (S%d-S%d): prompt[%s] json[%s] valid[%s]\n" \
      "$batch_num" "$sid_start" "$sid_end" "$prompt_status" "$batch_status" "$valid_status"
  done

  echo ""
  echo "Summary: prompts=$prompts_ok/$num_batches  json=$batches_ok/$num_batches  valid=$validated_ok/$num_batches"
}

# ============================================================
# Argument parsing
# ============================================================
CMD="${1:-}"
shift || true

RANGE_START=""
RANGE_END=""
BATCH_SIZE=10
OUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --range)      RANGE_START="${2%-*}"; RANGE_END="${2#*-}"; shift 2 ;;
    --batch-size) BATCH_SIZE="$2"; shift 2 ;;
    --out-dir)    OUT_DIR="$2"; shift 2 ;;
    *)            echo "Unknown: $1" >&2; usage ;;
  esac
done

if [[ -z "$RANGE_START" ]] || [[ -z "$RANGE_END" ]]; then
  echo "ERROR: --range required" >&2
  usage
fi

case "$CMD" in
  generate) cmd_generate ;;
  validate) cmd_validate ;;
  pipeline) cmd_pipeline ;;
  status)   cmd_status ;;
  *)        usage ;;
esac
