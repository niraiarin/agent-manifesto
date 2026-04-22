#!/usr/bin/env python3
"""
label_data.py — routing label 付き学習データ生成.

3 ソースを 4 ラベル (local_confident / local_probable / cloud_required / hybrid) に
mapping する:
1. taxonomy §4 の 24 tasks × 3-5 prompt variants (手動 seed + LLM paraphrase)
2. phase1 domain (M-interp, T-interp 55件) → local_probable
3. HelpSteer3 sample → hybrid (汎用 Q&A として扱う)

出力: label-data/train.jsonl (80%), label-data/eval.jsonl (20%)
"""

from __future__ import annotations

import json
import random
import sys
from pathlib import Path

random.seed(42)


# taxonomy §4 から抽出した 24 tasks × 代表プロンプト
# ラベル: local_confident / local_probable / cloud_required / hybrid
TASK_SEED_PROMPTS: list[tuple[str, str, str]] = [
    # (task, label, prompt)

    # --- Local confident (6 tasks × 3-5 variants = ~18 entries) ---
    ("paperize-outline", "local_confident",
     "以下の idea.md と experimental_log.md から outline.json を生成してください。章立てと各章の論点を構造化。"),
    ("paperize-outline", "local_confident",
     "manifest.json の内容に基づき、論文の章構成を JSON schema に従って生成。"),
    ("paperize-outline", "local_confident",
     "outline-prompt.md のフォーマットに従って、5 セクションの論文構成を提案。"),

    ("paperize-litreview", "local_confident",
     "commits.md と sources.md から internal citation graph を構築。PR/issue/commit SHA で引用化。"),
    ("paperize-litreview", "local_confident",
     "evidence/ の references.md を元に、内部引用を hash 付きで整理。"),
    ("paperize-litreview", "local_confident",
     "このコミット一覧を timeline 形式に整理し、主要な pivot を抽出。"),

    ("handoff", "local_confident",
     "現在のセッション状態を resume.md に出力。intent, progress, next_steps を含む。"),
    ("handoff", "local_confident",
     "skill 実行中の checkpoint を json 化し、次セッションで再開可能な形にまとめる。"),
    ("handoff", "local_confident",
     "context compaction 前の最重要情報を handoff 形式で永続化。"),

    ("summarize", "local_confident",
     "以下の長い会話を 3 行で要約してください。"),
    ("summarize", "local_confident",
     "この commit log を「なぜ」「何を」「次に」の 3 項目で圧縮。"),
    ("summarize", "local_confident",
     "/compact 用に context を 50% に削減。重要情報を保持。"),

    ("schema-inference", "local_confident",
     "このサンプルデータから JSON schema を生成。optional field も推定。"),
    ("schema-inference", "local_confident",
     "API response 例 3 件から OpenAPI 定義の type 部分を作成。"),
    ("schema-inference", "local_confident",
     "このエントリから YAML schema を推定し、validator 用に整形。"),

    ("verifier-local", "local_confident",
     "proposal_a と proposal_b を与えられた criteria で pairwise 比較し logprob でスコア化。"),
    ("verifier-local", "local_confident",
     "この trace と criteria から tournament 形式で順位付け。"),
    ("verifier-local", "local_confident",
     "verifier_local.py に渡す JSON を整形。problem, proposals, criteria を含む。"),

    # --- Local probable (6 tasks × 3-5 variants = ~18 entries) ---
    ("observer-v1v7", "local_probable",
     "V1-V7 メトリクスを観察して構造化レポートを出力。判断・提案はしない、観察のみ。"),
    ("observer-v1v7", "local_probable",
     "observe.sh の出力 JSON から V1-V7 の現在値と停滞シグナルを列挙。"),
    ("observer-v1v7", "local_probable",
     "failure_patterns と scope_balance を読み取って、Lean 構造の変化を報告。"),

    ("trace-interp", "local_probable",
     "manifest-trace json の coverage と deviations を解釈し、D13 影響波及の観点で分析。"),
    ("trace-interp", "local_probable",
     "T-interp: トレーサビリティレポートから改善優先度順にアクションを 3 件提案。"),
    ("trace-interp", "local_probable",
     "partial_order の edges から構造的ギャップを特定。"),

    ("metrics-interp", "local_probable",
     "M-interp: V1-V7 メトリクスから HEALTHY/WARNING/DEGRADED を判定。根拠を示す。"),
    ("metrics-interp", "local_probable",
     "valueless_change streak と non_triviality から halt_recommended の要否を判断。"),
    ("metrics-interp", "local_probable",
     "メトリクス JSON を読み、最優先の改善アクションを 3 件に絞る。"),

    ("paperize-writing", "local_probable",
     "outline と evidence から Method セクションを single-pass で執筆。内部 citation は 8-char SHA 付き。"),
    ("paperize-writing", "local_probable",
     "このアイデアと実験ログから Findings セクションを書く。未検証事実は [UNVERIFIED] タグ付与。"),
    ("paperize-writing", "local_probable",
     "paper.tex の Motivation パートを執筆。ページ予算 2 pages。"),

    ("model-questioner", "local_probable",
     "プロジェクトビジョンから C/H assumption を抽出し、L1-L6 層に分類。"),
    ("model-questioner", "local_probable",
     "ユーザーが書いた要求文から要件・仮定・open question を構造化 JSON で返す。"),
    ("model-questioner", "local_probable",
     "このビジョンから EpistemicLayerClass のインスタンス候補を列挙。"),

    ("adjust-action-space", "local_probable",
     "V4/V5 データから行動空間の拡張 or 縮小の提案を生成。permissions の変更を人間に提案。"),
    ("adjust-action-space", "local_probable",
     "gate pass rate 99% で blocked 106 件。action space 縮小すべきか観察結果から判断。"),
    ("adjust-action-space", "local_probable",
     "auto-merge 有効化の是非を V4/V5 実績で評価し推奨レベルを出す。"),

    # --- Cloud required (10 tasks × 2-4 variants = ~25 entries) ---
    ("verifier-review", "cloud_required",
     "このコード変更を独立検証してください。L1 safety 違反、マニフェスト逸脱をチェック。"),
    ("verifier-review", "cloud_required",
     "この Lean 定理の証明が正しいか確認。axiom 依存と sorry 有無を報告。"),
    ("verifier-review", "cloud_required",
     "PR 差分のセキュリティ問題を 3-pass で独立レビュー。"),

    ("verify-skill", "cloud_required",
     "/verify skill で P2 独立検証を実施。リスクレベル critical の場合は human review を推奨。"),
    ("verify-skill", "cloud_required",
     "このコード変更の evaluator_independent 検証を K=3 ラウンドで実施。"),

    ("evolve-orchestration", "cloud_required",
     "/evolve スキル全体の orchestration。Observer→Hypothesizer→Verifier→Integrator を回す。"),
    ("evolve-orchestration", "cloud_required",
     "breaking change 候補の compatibility 判定と integration 判断。"),

    ("research-workflow", "cloud_required",
     "/research Step 5 の実験実施。Gate 基準を満たすか多段推論で判定。"),
    ("research-workflow", "cloud_required",
     "Sub-Issue の Gate 判定。CONDITIONAL の場合は子 issue を再帰的に起票。"),

    ("formal-derivation", "cloud_required",
     "Γ ⊢ φ の導出手順を Lean 4 で構成。公理衛生とギャップ検証を含む。"),
    ("formal-derivation", "cloud_required",
     "この要件から Lean の formal spec を生成。axiom を最小化して theorem で組み立てる。"),
    ("formal-derivation", "cloud_required",
     "/formal-derivation Phase 2 の derivation composition。エラー時は Phase 3 で fix loop。"),

    ("code-generation", "cloud_required",
     "この仕様から Python クラスを実装。型ヒント完備、テストも書く。"),
    ("code-generation", "cloud_required",
     "React component を TypeScript で新規作成。props の型と CSS Module を含む。"),
    ("code-generation", "cloud_required",
     "この SQL スキーマから CRUD API を FastAPI で実装。"),

    ("tool-selection", "cloud_required",
     "この長い複雑な要求を実行するのに、どのツールをどの順序で呼ぶべきか計画。"),
    ("tool-selection", "cloud_required",
     "エラー発生後のリカバリフローで次に呼ぶべきツールを判断。"),

    ("hypothesizer", "cloud_required",
     "Observer report から改善仮説を 5 件設計。各 change_specs + compatibility class 付き。"),
    ("hypothesizer", "cloud_required",
     "この失敗パターンから仮説化。Lean で形式化可能な命題に変換。"),

    ("integrator", "cloud_required",
     "検証済み改善を main に統合。互換性分類を commit message に含める。"),
    ("integrator", "cloud_required",
     "Lean build + 全テスト実行後に PR を作成し、merge 可否を判断。"),

    ("ground-axiom", "cloud_required",
     "この axiom の数学的根拠を検証。関連定理を Lean で形式化して降格可能か判定。"),
    ("ground-axiom", "cloud_required",
     "manifesto の公理 5 件について先行研究との対応を調査し Axiom Card を更新。"),

    # --- Hybrid (2 tasks × 3-5 variants = ~10 entries) ---
    ("judge", "hybrid",
     "この proposals に GQM 基準で discrete score を付与。根拠を理由付きで。"),
    ("judge", "hybrid",
     "logprob pairwise で winner 判定。K=3 rounds の統計も出力。"),
    ("judge", "hybrid",
     "この artifact を G1-G5 軸で 5 段階評価。addressable 減点を分類。"),

    ("qa-free", "hybrid",
     "Python の asyncio と threading の違いを説明。"),
    ("qa-free", "hybrid",
     "この本の感想を書いて。"),
    ("qa-free", "hybrid",
     "今日の天気はどう？"),
    ("qa-free", "hybrid",
     "このコードはどこがバグっていますか？"),
    ("qa-free", "hybrid",
     "機械学習でクラス分類する時、F1 スコアと accuracy の使い分けは？"),
]


def load_phase1_domain(path: Path) -> list[dict]:
    """Phase 1 domain data (M-interp/T-interp prompts) → local_probable ラベル。"""
    if not path.exists():
        return []
    out = []
    with open(path) as f:
        for line in f:
            if not line.strip():
                continue
            entry = json.loads(line)
            prompt = entry.get("prompt") or entry.get("input_data", {}).get("prompt") or ""
            if not prompt:
                continue
            out.append({
                "task": entry.get("task_type", "phase1-domain"),
                "label": "local_probable",
                "prompt": prompt[:2000],
                "source": "phase1-domain",
            })
    return out


def load_helpsteer3_as_hybrid(path: Path, limit: int = 500) -> list[dict]:
    """HelpSteer3 → hybrid ラベル（汎用 Q&A）。先頭 N 件サンプリング。"""
    if not path.exists():
        return []
    out = []
    with open(path) as f:
        for i, line in enumerate(f):
            if i >= limit:
                break
            if not line.strip():
                continue
            entry = json.loads(line)
            prompt = entry.get("prompt", "")
            if not prompt:
                continue
            out.append({
                "task": f"helpsteer3-{entry.get('domain', 'general')}",
                "label": "hybrid",
                "prompt": prompt[:2000],
                "source": "helpsteer3",
            })
    return out


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=Path("../label-data"))
    parser.add_argument("--phase1-path", type=Path,
                        default=Path("/Users/nirarin/work/agent-manifesto/docs/research/golden-dataset/routellm/preference-data-threshold-0.3.jsonl"))
    parser.add_argument("--helpsteer3-path", type=Path, default=None,
                        help="optional, omit → skip helpsteer3")
    parser.add_argument("--helpsteer3-limit", type=int, default=500)
    parser.add_argument("--balance", action="store_true",
                        help="Downsample hybrid to match other classes")
    parser.add_argument("--oversample-taxonomy", type=int, default=1,
                        help="Repeat taxonomy prompts N times for class balance")
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    # Seed from taxonomy (with optional oversampling for balance)
    seed = [{"task": t, "label": l, "prompt": p, "source": "taxonomy-manual"}
            for t, l, p in TASK_SEED_PROMPTS] * args.oversample_taxonomy

    phase1 = load_phase1_domain(args.phase1_path)
    help3 = load_helpsteer3_as_hybrid(args.helpsteer3_path, args.helpsteer3_limit) if args.helpsteer3_path else []

    # Optional: downsample hybrid to approximately match other classes
    if args.balance and help3:
        from collections import Counter
        seed_label_counts = Counter(e["label"] for e in seed)
        non_hybrid_avg = sum(seed_label_counts.values()) // max(3, len(seed_label_counts) - (1 if "hybrid" in seed_label_counts else 0))
        target = max(50, non_hybrid_avg)
        help3 = help3[:target]
        print(f"[balance] hybrid downsampled to {len(help3)} (target={target})")

    all_data = seed + phase1 + help3
    random.shuffle(all_data)

    # 80/20 split
    n = len(all_data)
    n_train = int(n * 0.8)
    train = all_data[:n_train]
    evaluation = all_data[n_train:]

    (args.output_dir / "train.jsonl").write_text(
        "\n".join(json.dumps(e, ensure_ascii=False) for e in train) + "\n"
    )
    (args.output_dir / "eval.jsonl").write_text(
        "\n".join(json.dumps(e, ensure_ascii=False) for e in evaluation) + "\n"
    )

    from collections import Counter
    label_dist = Counter(e["label"] for e in all_data)
    source_dist = Counter(e["source"] for e in all_data)
    print(f"[label] total={n} train={len(train)} eval={len(evaluation)}")
    print(f"[label] by label: {dict(label_dist)}")
    print(f"[label] by source: {dict(source_dist)}")


if __name__ == "__main__":
    main()
