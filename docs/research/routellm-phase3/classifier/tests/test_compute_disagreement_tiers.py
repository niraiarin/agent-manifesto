#!/usr/bin/env python3
"""
test_compute_disagreement_tiers.py — unit tests for active-learning tier
classification.

Synthetic input data exercises:
  - tier 0 (3-way agreement)
  - tier 1 (2-vs-1, minority on each model in turn)
  - tier 2 (3-way disagreement, all unique)
  - drop path (missing model in default mode)
  - degraded path (allow_missing=True)
  - mixed real-world distribution (smoke test)

Runtime: in-process, no subprocess except the CLI smoke, no I/O outside tempdir.
Usage: /tmp/arena-venv/bin/python3 tests/test_compute_disagreement_tiers.py
"""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
CLASSIFIER_DIR = THIS_DIR.parent

sys.path.insert(0, str(CLASSIFIER_DIR))
import importlib.util
spec = importlib.util.spec_from_file_location(
    "compute_disagreement_tiers",
    CLASSIFIER_DIR / "compute_disagreement_tiers.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _write_jsonl(path: Path, entries: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        for e in entries:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")


def test_classify_tier_basic() -> None:
    # tier 0: all 3 agree
    r = mod.classify_tier({"qwen35b": "local_confident", "qwen27b": "local_confident", "mdeberta": "local_confident"})
    assert r["tier"] == 0, f"expected tier 0, got {r}"
    assert r["agreement_count"] == 3
    assert r["majority_label"] == "local_confident"
    assert r["minority_models"] is None

    # tier 1: 2 agree, 1 dissents (minority = mdeberta)
    r = mod.classify_tier({"qwen35b": "cloud_required", "qwen27b": "cloud_required", "mdeberta": "hybrid"})
    assert r["tier"] == 1
    assert r["agreement_count"] == 2
    assert r["majority_label"] == "cloud_required"
    assert r["minority_models"] == ["mdeberta"]

    # tier 1: 2 agree, 1 dissents (minority = qwen35b)
    r = mod.classify_tier({"qwen35b": "hybrid", "qwen27b": "cloud_required", "mdeberta": "cloud_required"})
    assert r["tier"] == 1
    assert r["minority_models"] == ["qwen35b"]

    # tier 2: all 3 disagree
    r = mod.classify_tier({"qwen35b": "local_confident", "qwen27b": "cloud_required", "mdeberta": "hybrid"})
    assert r["tier"] == 2
    assert r["agreement_count"] == 1
    assert r["majority_label"] is None

    print("PASS classify_tier basic (4 sub-cases)")


def test_classify_tier_missing_model() -> None:
    # 2 valid + 1 missing (None) → tier 1 if those 2 agree
    r = mod.classify_tier({"qwen35b": "hybrid", "qwen27b": "hybrid", "mdeberta": None})
    assert r["tier"] == 1, f"expected tier 1 with degraded majority, got {r}"
    assert r["agreement_count"] == 2
    assert r["majority_label"] == "hybrid"
    assert r["minority_models"] == ["mdeberta"]

    # 2 valid + 1 missing, the 2 disagree → tier 2 (no majority)
    r = mod.classify_tier({"qwen35b": "hybrid", "qwen27b": "cloud_required", "mdeberta": None})
    assert r["tier"] == 2

    # 1 valid + 2 missing → tier 2 degraded
    r = mod.classify_tier({"qwen35b": "hybrid", "qwen27b": None, "mdeberta": None})
    assert r["tier"] == 2

    # 0 valid → tier 2 with agreement_count=0
    r = mod.classify_tier({"qwen35b": None, "qwen27b": None, "mdeberta": None})
    assert r["tier"] == 2
    assert r["agreement_count"] == 0

    print("PASS classify_tier missing-model (4 sub-cases)")


def test_extract_label_field_fallbacks() -> None:
    # Single-field cases
    assert mod.extract_label({"label": "local_confident"}) == "local_confident"
    assert mod.extract_label({"predicted_label": "cloud_required"}) == "cloud_required"
    assert mod.extract_label({"gt_label": "hybrid"}) == "hybrid"
    assert mod.extract_label({"label": "invalid_label"}) is None
    assert mod.extract_label({}) is None

    # Priority: gt_label wins over predicted_label.
    # Qwen output preserves input's `predicted_label` (mDeBERTa) AND adds its
    # own `gt_label` (Qwen). Reading a Qwen file must surface the Qwen label.
    qwen_style = {"gt_label": "cloud_required", "predicted_label": "hybrid"}
    assert mod.extract_label(qwen_style) == "cloud_required", \
        "gt_label must win over predicted_label for Qwen-style records"

    # Candidates-style: gt_label=null → fall through to predicted_label
    candidates_style = {"gt_label": None, "predicted_label": "local_probable"}
    assert mod.extract_label(candidates_style) == "local_probable", \
        "null gt_label must fall through to predicted_label"

    # `label` middle priority: present + no gt_label → wins over predicted_label
    middle = {"label": "unknown", "predicted_label": "hybrid"}
    assert mod.extract_label(middle) == "unknown"

    print("PASS extract_label field fallbacks (8 sub-cases)")


def test_compute_tiers_end_to_end() -> None:
    # Synthetic: 5 prompts crossing all tiers
    qwen35b = {
        "p1": {"id": "p1", "prompt": "ok", "label": "local_confident"},
        "p2": {"id": "p2", "prompt": "verify", "label": "cloud_required"},
        "p3": {"id": "p3", "prompt": "what is X", "label": "hybrid"},
        "p4": {"id": "p4", "prompt": "deploy?", "label": "local_confident"},
        "p5": {"id": "p5", "prompt": "off-topic", "label": "unknown"},
    }
    qwen27b = {
        "p1": {"id": "p1", "label": "local_confident"},
        "p2": {"id": "p2", "label": "cloud_required"},
        "p3": {"id": "p3", "label": "cloud_required"},
        "p4": {"id": "p4", "label": "cloud_required"},
        "p5": {"id": "p5", "label": "unknown"},
    }
    mdeberta = {
        "p1": {"id": "p1", "predicted_label": "local_confident"},
        "p2": {"id": "p2", "predicted_label": "cloud_required"},
        "p3": {"id": "p3", "predicted_label": "local_probable"},
        "p4": {"id": "p4", "predicted_label": "hybrid"},
        "p5": {"id": "p5", "predicted_label": "unknown"},
    }

    out = mod.compute_tiers(qwen35b, qwen27b, mdeberta)
    by_id = {e["id"]: e for e in out}
    assert len(out) == 5

    # p1 / p2 / p5: 3-way agreement → tier 0
    assert by_id["p1"]["tier"] == 0
    assert by_id["p1"]["majority_label"] == "local_confident"
    assert by_id["p2"]["tier"] == 0
    assert by_id["p5"]["tier"] == 0

    # p3: qwen35b=hybrid, qwen27b=cloud_required, mdeberta=local_probable → all unique → tier 2
    assert by_id["p3"]["tier"] == 2

    # p4: qwen35b=local_confident, qwen27b=cloud_required, mdeberta=hybrid → all unique → tier 2
    assert by_id["p4"]["tier"] == 2
    assert by_id["p4"]["majority_label"] is None

    # prompt is preserved from the first model that has it
    assert by_id["p1"]["prompt"] == "ok"
    assert by_id["p3"]["prompt"] == "what is X"

    print("PASS compute_tiers end-to-end (5-prompt synthetic)")


def test_compute_tiers_drop_vs_allow_missing() -> None:
    # qwen27b is missing p2; default mode drops with stderr
    qwen35b = {"p1": {"id": "p1", "label": "hybrid"}, "p2": {"id": "p2", "label": "hybrid"}}
    qwen27b = {"p1": {"id": "p1", "label": "hybrid"}}  # p2 absent
    mdeberta = {"p1": {"id": "p1", "predicted_label": "hybrid"}, "p2": {"id": "p2", "predicted_label": "hybrid"}}

    out = mod.compute_tiers(qwen35b, qwen27b, mdeberta, allow_missing=False)
    assert len(out) == 1, f"expected 1 entry (p2 dropped), got {len(out)}"
    assert out[0]["id"] == "p1"

    out = mod.compute_tiers(qwen35b, qwen27b, mdeberta, allow_missing=True)
    assert len(out) == 2
    by_id = {e["id"]: e for e in out}
    assert by_id["p2"]["model_labels"]["qwen27b"] is None
    # p2 has 2 labels (qwen35b=hybrid, mdeberta=hybrid, qwen27b=None) → tier 1, qwen35b+mdeberta majority
    assert by_id["p2"]["tier"] == 1
    assert by_id["p2"]["majority_label"] == "hybrid"
    assert "qwen27b" in by_id["p2"]["minority_models"]

    print("PASS compute_tiers drop vs allow-missing")


def test_write_jsonl_roundtrip() -> None:
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "subdir" / "out.jsonl"
        entries = [
            {"id": "p1", "tier": 0, "model_labels": {"qwen35b": "x"}},
            {"id": "p2", "tier": 2, "model_labels": {"qwen35b": "y"}},
        ]
        mod.write_jsonl(path, entries)
        text = path.read_text(encoding="utf-8")
        lines = [json.loads(l) for l in text.splitlines() if l.strip()]
        assert lines == entries
    print("PASS write_jsonl roundtrip")


def test_summary_counts_format() -> None:
    entries = [
        {"id": "p1", "tier": 0},
        {"id": "p2", "tier": 0},
        {"id": "p3", "tier": 1},
        {"id": "p4", "tier": 2},
    ]
    s = mod.summary_counts(entries)
    assert "tier 0" in s and "all-agree" in s
    assert "tier 1" in s and "2-vs-1" in s
    assert "tier 2" in s and "all-disagree" in s
    assert "total" in s
    print("PASS summary_counts format")


def test_cli_smoke() -> None:
    """End-to-end CLI: write 3 input JSONLs to tempdir, invoke main."""
    import subprocess

    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        _write_jsonl(tdp / "q35.jsonl", [
            {"id": "p1", "prompt": "/verify foo", "label": "cloud_required"},
            {"id": "p2", "prompt": "ok", "label": "local_confident"},
        ])
        _write_jsonl(tdp / "q27.jsonl", [
            {"id": "p1", "label": "cloud_required"},
            {"id": "p2", "label": "local_confident"},
        ])
        _write_jsonl(tdp / "md.jsonl", [
            {"id": "p1", "predicted_label": "hybrid"},
            {"id": "p2", "predicted_label": "local_confident"},
        ])
        out = tdp / "tiers.jsonl"
        rc = subprocess.run(
            [
                sys.executable,
                str(CLASSIFIER_DIR / "compute_disagreement_tiers.py"),
                "--qwen35b", str(tdp / "q35.jsonl"),
                "--qwen27b", str(tdp / "q27.jsonl"),
                "--mdeberta", str(tdp / "md.jsonl"),
                "--output", str(out),
                "--summary",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        assert rc.returncode == 0, f"CLI failed rc={rc.returncode} stderr={rc.stderr}"
        assert "tier distribution" in rc.stderr
        results = [json.loads(l) for l in out.read_text().splitlines() if l.strip()]
        assert len(results) == 2
        by_id = {r["id"]: r for r in results}
        # p1: q35=cloud_required, q27=cloud_required, md=hybrid → tier 1
        assert by_id["p1"]["tier"] == 1
        # p2: all 3 → local_confident → tier 0
        assert by_id["p2"]["tier"] == 0
    print("PASS CLI smoke")


def main() -> int:
    test_classify_tier_basic()
    test_classify_tier_missing_model()
    test_extract_label_field_fallbacks()
    test_compute_tiers_end_to_end()
    test_compute_tiers_drop_vs_allow_missing()
    test_write_jsonl_roundtrip()
    test_summary_counts_format()
    test_cli_smoke()
    print("\nALL PASS — compute_disagreement_tiers.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
