#!/usr/bin/env python3
"""
train.py — Causal LM router 分類器の学習.

multilingual-e5-small で embedding 生成 → logistic regression で 4-way 分類.
軽量 + 高速 (embedding 8ms + LR <1ms = total 10ms 以下)
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


LABEL_TO_ID = {
    "local_confident": 0,
    "local_probable": 1,
    "cloud_required": 2,
    "hybrid": 3,
    "unknown": 4,
}
ID_TO_LABEL = {v: k for k, v in LABEL_TO_ID.items()}


def load_jsonl(path: Path) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", type=Path, required=True)
    parser.add_argument("--eval", type=Path, required=True)
    parser.add_argument("--model-out", type=Path, required=True)
    parser.add_argument("--encoder", type=str, default="intfloat/multilingual-e5-small")
    args = parser.parse_args()

    from sentence_transformers import SentenceTransformer
    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import classification_report, confusion_matrix
    import joblib
    import numpy as np

    print(f"[train] loading encoder {args.encoder}")
    encoder = SentenceTransformer(args.encoder)

    train = load_jsonl(args.train)
    evaluation = load_jsonl(args.eval)
    print(f"[train] train={len(train)} eval={len(evaluation)}")

    # e5 models prefix convention
    def encode(texts):
        prefixed = [f"query: {t}" for t in texts]
        return encoder.encode(prefixed, convert_to_numpy=True, batch_size=16)

    X_tr = encode([e["prompt"] for e in train])
    y_tr = np.array([LABEL_TO_ID[e["label"]] for e in train])
    X_ev = encode([e["prompt"] for e in evaluation])
    y_ev = np.array([LABEL_TO_ID[e["label"]] for e in evaluation])

    clf = LogisticRegression(max_iter=1000, class_weight="balanced", random_state=42)
    clf.fit(X_tr, y_tr)

    train_acc = clf.score(X_tr, y_tr)
    eval_acc = clf.score(X_ev, y_ev)
    print(f"[train] train_acc={train_acc:.4f} eval_acc={eval_acc:.4f}")

    y_pred = clf.predict(X_ev)
    label_names = [ID_TO_LABEL[i] for i in sorted(ID_TO_LABEL)]
    print("\n[eval] classification report:")
    print(classification_report(y_ev, y_pred, target_names=label_names, zero_division=0))

    print("[eval] confusion matrix (rows=actual, cols=pred):")
    present = sorted(set(y_ev.tolist()) | set(y_pred.tolist()))
    present_names = [ID_TO_LABEL[i] for i in present]
    cm = confusion_matrix(y_ev, y_pred, labels=present)
    print("       " + "  ".join(f"{l:>16}" for l in present_names))
    for i, row in enumerate(cm):
        print(f"{present_names[i]:<16} " + "  ".join(f"{v:>16}" for v in row))

    args.model_out.mkdir(parents=True, exist_ok=True)
    joblib.dump(clf, args.model_out / "clf.joblib")
    (args.model_out / "metadata.json").write_text(json.dumps({
        "encoder": args.encoder,
        "label_map": LABEL_TO_ID,
        "train_acc": float(train_acc),
        "eval_acc": float(eval_acc),
        "n_train": len(train),
        "n_eval": len(evaluation),
    }, indent=2))
    print(f"[train] saved to {args.model_out}")


if __name__ == "__main__":
    main()
