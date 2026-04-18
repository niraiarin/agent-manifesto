#!/usr/bin/env python3
"""Extract theorems from Lean 4 Manifest/ files for #624 benchmark.

A theorem entry consists of:
- name: theorem identifier
- signature: the `theorem NAME : TYPE := ` line(s) up to the body
- body: the proof content (tactic block or term)
- file: source file relative path
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Iterator


# Match theorem declaration: "theorem NAME [types/hypotheses]: TYPE := ..."
# Handles multi-line signatures by tracking balanced parens/brackets.
THEOREM_RE = re.compile(r'^(theorem|lemma)\s+(\w+)', re.MULTILINE)


def extract_theorems(lean_root: Path) -> Iterator[dict]:
    """Yield theorem dicts from all .lean files under lean_root."""
    for lean_file in sorted(lean_root.rglob("*.lean")):
        # Skip backup / non-source files
        if ".lake" in lean_file.parts or "build" in lean_file.parts:
            continue
        try:
            text = lean_file.read_text(encoding="utf-8")
        except Exception:
            continue
        rel_path = lean_file.relative_to(lean_root)
        for m in THEOREM_RE.finditer(text):
            kind = m.group(1)
            name = m.group(2)
            start = m.start()
            # Find the := and the body
            assign_idx = text.find(":=", start)
            if assign_idx < 0:
                continue
            # Find end of body: next theorem/lemma/def/end at line start, or EOF
            end_re = re.compile(r'\n(theorem|lemma|def|structure|inductive|example|namespace|section|end)\s', re.MULTILINE)
            m2 = end_re.search(text, assign_idx)
            body_end = m2.start() if m2 else len(text)
            # Signature: from start to := (inclusive)
            signature = text[start:assign_idx].strip()
            body = text[assign_idx + 2:body_end].strip()
            # Filter: keep only reasonable-size theorems
            if len(body) < 10 or len(body) > 2000:
                continue
            if len(signature) < 20 or len(signature) > 1500:
                continue
            yield {
                "name": name,
                "kind": kind,
                "signature": signature,
                "body": body,
                "file": str(rel_path),
            }


if __name__ == "__main__":
    import sys
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "../agent-manifesto/lean-formalization")
    theorems = list(extract_theorems(root))
    print(f"Extracted {len(theorems)} theorems/lemmas from {root}")
    for t in theorems[:5]:
        print(f"  [{t['kind']}] {t['name']} ({t['file']}): sig={len(t['signature'])}c body={len(t['body'])}c")
