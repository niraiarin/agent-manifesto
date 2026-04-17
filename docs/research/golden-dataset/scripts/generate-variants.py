#!/usr/bin/env python3
"""generate-variants.py — 入力データのバリエーションを生成する

既存の metrics/trace 入力をベースに、プロジェクト状態の
多様なバリエーションを合理的に生成する。

Usage:
    python3 generate-variants.py --type metrics --count 25
    python3 generate-variants.py --type trace --count 25
    python3 generate-variants.py --type all --count 50
"""
import json, copy, random, argparse, os
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
DATASET_DIR = SCRIPT_DIR.parent
INPUTS_DIR = DATASET_DIR / "inputs"

random.seed(42)  # 再現性のため


def load_base(type_prefix: str) -> dict:
    """最初の入力ファイルをベースとしてロード"""
    base_file = INPUTS_DIR / f"{type_prefix}-input-001.json"
    with open(base_file) as f:
        return json.load(f)


# === Metrics Variants ===

# プロジェクト状態のプロファイル
METRICS_PROFILES = [
    # (name, description, modifications)
    ("healthy-stable", "全指標良好、安定成長", {
        "sorry": (0, 0), "warnings": (0, 2), "failed": (0, 0),
        "theorems": (470, 500), "axioms": (53, 56),
        "streak": (0, 1), "halt": False,
        "non_triviality": "productive",
    }),
    ("healthy-growing", "急成長フェーズ", {
        "sorry": (0, 0), "warnings": (0, 1), "failed": (0, 0),
        "theorems": (480, 520), "axioms": (54, 58),
        "streak": (0, 0), "halt": False,
        "non_triviality": "productive",
    }),
    ("warning-stagnant", "停滞中、halt推奨", {
        "sorry": (0, 2), "warnings": (0, 5), "failed": (0, 3),
        "theorems": (460, 490), "axioms": (53, 55),
        "streak": (3, 6), "halt": True,
        "non_triviality": "trivial",
    }),
    ("warning-sorry", "sorry残存が主問題", {
        "sorry": (3, 8), "warnings": (2, 6), "failed": (0, 2),
        "theorems": (450, 480), "axioms": (52, 55),
        "streak": (0, 2), "halt": False,
        "non_triviality": "productive",
    }),
    ("warning-hypothesis", "仮説エラー多発", {
        "sorry": (0, 1), "warnings": (0, 3), "failed": (0, 1),
        "theorems": (465, 490), "axioms": (53, 55),
        "streak": (1, 3), "halt": False,
        "non_triviality": "trivial",
    }),
    ("degraded-multi", "複数問題が同時発生", {
        "sorry": (5, 12), "warnings": (5, 15), "failed": (8, 20),
        "theorems": (400, 450), "axioms": (48, 53),
        "streak": (4, 8), "halt": True,
        "non_triviality": "trivial",
    }),
    ("degraded-tests", "テスト大量失敗", {
        "sorry": (0, 3), "warnings": (3, 10), "failed": (15, 40),
        "theorems": (440, 470), "axioms": (52, 55),
        "streak": (2, 5), "halt": True,
        "non_triviality": "trivial",
    }),
    ("recovery", "degradedからの回復途中", {
        "sorry": (1, 3), "warnings": (1, 4), "failed": (1, 5),
        "theorems": (455, 475), "axioms": (53, 55),
        "streak": (0, 1), "halt": False,
        "non_triviality": "productive",
    }),
]

STALE_FILE_POOL = [
    ".claude/skills/evolve/SKILL.md",
    "docs/design-development-foundation.md",
    "lean-formalization/Manifest/V7Metrics.lean",
    ".claude/skills/verify/SKILL.md",
    ".claude/skills/research/SKILL.md",
    "lean-formalization/Manifest/Ontology.lean",
    "tests/phase5/test-refs-integrity.sh",
    ".claude/rules/p3-governed-learning.md",
]


def generate_metrics_variant(base: dict, idx: int) -> dict:
    """metrics 入力のバリエーションを生成"""
    data = copy.deepcopy(base)
    profile_name, desc, mods = random.choice(METRICS_PROFILES)

    data["meta"]["id"] = f"metrics-input-{idx:03d}"
    data["meta"]["timestamp"] = f"2026-04-{random.randint(10, 17):02d}T{random.randint(0,23):02d}:{random.randint(0,59):02d}:00Z"
    data["meta"]["git_rev"] = f"{random.randint(0, 0xfffffff):07x}"

    d = data["data"]

    # Lean
    lo, hi = mods["theorems"]
    d["lean"]["theorems"] = random.randint(lo, hi)
    lo, hi = mods["axioms"]
    d["lean"]["axioms"] = random.randint(lo, hi)
    lo, hi = mods["sorry"]
    d["lean"]["sorry"] = random.randint(lo, hi)
    d["lean"]["modules"] = random.randint(30, 36)
    lo, hi = mods["warnings"]
    d["lean"]["warnings"] = random.randint(lo, hi)
    d["lean"]["compression_ratio"] = random.randint(780, 900)
    d["lean"]["de_bruijn_factor"] = random.randint(650, 760)

    # Tests
    lo, hi = mods["failed"]
    d["tests"]["failed"] = random.randint(lo, hi)
    d["tests"]["passed"] = random.randint(720, 780) - d["tests"]["failed"]

    # Stale files
    n_stale = random.choices([0, 1, 2, 3, 4], weights=[3, 3, 2, 1, 1])[0]
    d["stale_files"] = random.sample(STALE_FILE_POOL, min(n_stale, len(STALE_FILE_POOL)))

    # Evolve history — valueless change streak
    if "evolve_history" in d:
        streak = random.randint(*mods["streak"])
        d["evolve_history"]["valueless_change"] = {
            "current_streak": streak,
            "halt_recommended": mods["halt"],
            "max_streak": max(streak, random.randint(streak, streak + 3)),
        }

    # V1 non_triviality
    if "v1_skill_quality" in d:
        d["v1_skill_quality"]["non_triviality"] = mods["non_triviality"]
    elif "lean" in d:
        # non_triviality をトップレベルで表現
        pass

    # Hypothesis errors — vary counts
    if "evolve_history" in d:
        eh = d["evolve_history"]
        if "phases_totals" in eh:
            base_errors = eh["phases_totals"].get("hypothesis_errors", 40)
            eh["phases_totals"]["hypothesis_errors"] = max(0, base_errors + random.randint(-20, 30))

    return data


# === Trace Variants ===

def generate_trace_variant(base: dict, idx: int) -> dict:
    """trace 入力のバリエーションを生成

    カバレッジ率、証拠の有無、アーティファクト数をバリエーションする
    """
    data = copy.deepcopy(base)

    data["meta"]["id"] = f"trace-input-{idx:03d}"
    data["meta"]["timestamp"] = f"2026-04-{random.randint(10, 17):02d}T{random.randint(0,23):02d}:{random.randint(0,59):02d}:00Z"
    data["meta"]["git_rev"] = f"{random.randint(0, 0xfffffff):07x}"

    props = data["data"].get("propositions", [])
    if not props:
        return data

    # バリエーションタイプを選択
    variant_type = random.choice([
        "full-coverage",      # 全命題カバー、証拠多い
        "evidence-gap",       # カバレッジ100%だが証拠が少ない
        "coverage-gap",       # 一部命題が未カバー
        "mixed-gaps",         # カバレッジと証拠の両方にギャップ
        "early-stage",        # 開発初期段階（アーティファクト少）
    ])

    for prop in props:
        artifacts = prop.get("artifacts", [])
        evidence = prop.get("evidence", [])
        derivations = prop.get("derivations", [])

        if variant_type == "full-coverage":
            # 証拠を追加
            if not evidence and random.random() < 0.7:
                prop["evidence"] = [{"type": "test_result", "source": f"tests/auto-generated-{random.randint(1,100)}.sh"}]

        elif variant_type == "evidence-gap":
            # 証拠を削除（確率的に）
            if random.random() < 0.6:
                prop["evidence"] = []

        elif variant_type == "coverage-gap":
            # アーティファクトを削除（一部命題から）
            if random.random() < 0.2:
                prop["artifacts"] = []
                prop["evidence"] = []

        elif variant_type == "mixed-gaps":
            if random.random() < 0.15:
                prop["artifacts"] = []
            if random.random() < 0.5:
                prop["evidence"] = []

        elif variant_type == "early-stage":
            # アーティファクトを大幅削減
            if artifacts:
                keep = max(1, len(artifacts) // 3)
                prop["artifacts"] = random.sample(artifacts, min(keep, len(artifacts)))
            if random.random() < 0.7:
                prop["evidence"] = []
            if random.random() < 0.4:
                prop["derivations"] = []

    # メタデータ更新
    total_artifacts = sum(len(p.get("artifacts", [])) for p in props)
    data["data"]["meta"]["total_artifacts"] = total_artifacts

    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--type", choices=["metrics", "trace", "all"], default="all")
    parser.add_argument("--count", type=int, default=50, help="Total number of inputs to generate")
    args = parser.parse_args()

    if args.type == "all":
        m_count = args.count // 2
        t_count = args.count - m_count
    elif args.type == "metrics":
        m_count = args.count
        t_count = 0
    else:
        m_count = 0
        t_count = args.count

    # 既存ファイルの最大 ID を取得
    existing_m = sorted(INPUTS_DIR.glob("metrics-input-*.json"))
    existing_t = sorted(INPUTS_DIR.glob("trace-input-*.json"))
    max_m_id = max([int(f.stem.split("-")[-1]) for f in existing_m], default=0)
    max_t_id = max([int(f.stem.split("-")[-1]) for f in existing_t], default=0)

    if m_count > 0:
        base_m = load_base("metrics")
        print(f"Generating {m_count} metrics variants (starting from {max_m_id + 1:03d})...")
        for i in range(m_count):
            idx = max_m_id + 1 + i
            variant = generate_metrics_variant(base_m, idx)
            out_path = INPUTS_DIR / f"metrics-input-{idx:03d}.json"
            with open(out_path, "w") as f:
                json.dump(variant, f, indent=2, ensure_ascii=False)
        print(f"  Created {m_count} files: metrics-input-{max_m_id+1:03d} to metrics-input-{max_m_id+m_count:03d}")

    if t_count > 0:
        base_t = load_base("trace")
        print(f"Generating {t_count} trace variants (starting from {max_t_id + 1:03d})...")
        for i in range(t_count):
            idx = max_t_id + 1 + i
            variant = generate_trace_variant(base_t, idx)
            out_path = INPUTS_DIR / f"trace-input-{idx:03d}.json"
            with open(out_path, "w") as f:
                json.dump(variant, f, indent=2, ensure_ascii=False)
        print(f"  Created {t_count} files: trace-input-{max_t_id+1:03d} to trace-input-{max_t_id+t_count:03d}")

    total = len(list(INPUTS_DIR.glob("*.json")))
    print(f"\nTotal inputs: {total}")


if __name__ == "__main__":
    main()
