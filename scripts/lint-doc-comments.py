#!/usr/bin/env python3
"""
Lean doc comment linter for agent-manifesto.

Rules are derived from Verso's constraints (Parser.lean, Slug.lean, Html.lean),
NOT from the current Lean file patterns.

Exit code 0 = all checks pass, 1 = violations found.
"""

import re
import sys
import os
from pathlib import Path

MANIFEST_DIR = Path(__file__).parent.parent / "lean-formalization" / "Manifest"
CORE_FILES = [
    "Ontology.lean", "Axioms.lean", "EmpiricalPostulates.lean",
    "Principles.lean", "Observable.lean", "DesignFoundation.lean",
]


class Violation:
    def __init__(self, file, line, rule, severity, message):
        self.file = file
        self.line = line
        self.rule = rule
        self.severity = severity  # error, warning, info
        self.message = message

    def __str__(self):
        return f"{self.file}:{self.line}: [{self.rule}] {self.message}"


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.readlines()


def sluggify(text):
    """Simulate Verso's Slug.lean:asSlug + mangle replacements."""
    # Named replacements from Verso's mangle function
    MANGLE = {
        '<': '_LT_', '>': '_GT_', ';': '_SEMI_', '‹': '_LSAQUO_', '›': '_RSAQUO_',
        '⊢': '_VDASH_', '→': '_ARR_', '←': '_LARR_', '(': '_LPAR_', ')': '_RPAR_',
        ',': '_COMMA_', '.': '_DOT_', '!': '_BANG_', '?': '_QMARK_', '/': '_SLASH_',
        '\\': '_BSLASH_', '+': '_PLUS_', '=': '_EQ_', '&': '_AMP_', '@': '_AT_',
        '#': '_HASH_', '%': '_PERC_', '^': '_CARET_', '~': '_TILDE_', ':': '_COLON_',
        "'": '_APOS_', '"': '_QUOT_', '|': '_PIPE_',
    }
    result = []
    for ch in text:
        if ch.isascii() and (ch.isalnum() or ch in '_-'):
            result.append(ch)
        elif ch == ' ':
            result.append('-')
        elif ch in MANGLE:
            result.append(MANGLE[ch])
        else:
            result.append('___')
    return ''.join(result)


def lint_file(filepath):
    violations = []
    filename = os.path.basename(filepath)
    lines = read_file(filepath)

    in_module_doc = False
    in_decl_doc = False
    in_code_block = False
    module_doc_start = 0
    decl_doc_start = 0
    decl_doc_lines = []
    first_module_doc_checked = False

    # For H3: slug uniqueness across the file
    all_slugs = {}  # slug → (text, line_number)

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Track code blocks
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            continue

        # ── Module doc comment: /-! ... -/ ──

        if stripped.startswith("/-!"):
            in_module_doc = True
            module_doc_start = i
            continue

        if in_module_doc and "-/" in stripped:
            in_module_doc = False
            continue

        if in_module_doc:
            m = re.match(r'^(#{1,6})\s+(.*)', stripped)
            if m:
                level = len(m.group(1))
                text = m.group(2)
                slug = sluggify(text)

                # H1: First module doc must start with # (L1)
                if not first_module_doc_checked:
                    first_module_doc_checked = True
                    if level != 1:
                        violations.append(Violation(
                            filename, i, "H1", "error",
                            f"最初のモジュール doc の見出しは # (L1) であること (実際: {'#' * level})"
                        ))

                # H2: Only # and ## in module docs
                if level >= 3:
                    violations.append(Violation(
                        filename, i, "H2", "error",
                        f"モジュール doc 内は # と ## のみ: {'#' * level} {text}"
                    ))

                # H5b: No special characters in headings that produce ugly slugs
                bad_chars = re.findall(r'[:()\§—–₀₁₂₃]', text)
                if bad_chars:
                    violations.append(Violation(
                        filename, i, "H5", "error",
                        f"Heading contains chars that produce ugly URL slugs: "
                        f"{''.join(set(bad_chars))} in: {text[:50]}"
                    ))

                # H3: Slug uniqueness
                if slug in all_slugs:
                    prev_text, prev_line = all_slugs[slug]
                    violations.append(Violation(
                        filename, i, "H3", "error",
                        f"見出しスラグ衝突: '{text}' (slug: {slug[:40]}) "
                        f"← '{prev_text}' (line {prev_line}) と同一スラグ"
                    ))
                else:
                    all_slugs[slug] = (text, i)

            # H5: CJK characters in doc comments (math symbols, Greek, box-drawing allowed)
            cjk = re.findall(r'[\u3000-\u9FFF\uFF00-\uFFEF]', stripped)
            if cjk:
                violations.append(Violation(
                    filename, i, "H5", "warning",
                    f"Doc comment に CJK 文字: {''.join(cjk[:10])} in: {stripped[:50]}"
                ))

            # T3: Table separator minimum hyphens
            if re.match(r'\|[\-\s|:]+\|$', stripped):
                cols = stripped.strip('|').split('|')
                for col in cols:
                    hyphens = col.strip().replace(':', '').replace(' ', '')
                    if 0 < len(hyphens) < 3:
                        violations.append(Violation(
                            filename, i, "T3", "warning",
                            f"テーブルセパレータは各列 3 ハイフン以上: '{col.strip()}'"
                        ))

            # T4: Orphan separator row (no header before it)
            # Detected implicitly by the generation script; not easily linted here
            continue

        # ── Declaration doc comment: /-- ... -/ ──

        if stripped.startswith("/--"):
            in_decl_doc = True
            decl_doc_start = i
            decl_doc_lines = [stripped]

            # P2: Blank line before /-- (top-level only)
            if not line[0].isspace():  # top-level (not indented)
                if i > 1:
                    prev = lines[i - 2].strip()
                    if prev != "" and not prev.startswith("-- ====") and not prev.endswith("-/"):
                        violations.append(Violation(
                            filename, i, "P2", "warning",
                            f"/-- の前に空行がない (前の行: '{prev[:50]}')"
                        ))
            continue

        if in_decl_doc:
            decl_doc_lines.append(stripped)
            if "-/" in stripped:
                in_decl_doc = False
                doc_text = "\n".join(decl_doc_lines)

                # H4: No headings in declaration doc comments
                for dl in decl_doc_lines:
                    if re.match(r'^#{1,6}\s+', dl):
                        violations.append(Violation(
                            filename, decl_doc_start, "H4", "error",
                            f"宣言 doc 内に見出しがある: {dl[:40]}"
                        ))

                # H5: CJK characters in declaration doc comments
                for dl in decl_doc_lines:
                    cjk = re.findall(r'[\u3000-\u9FFF\uFF00-\uFFEF]', dl)
                    if cjk:
                        violations.append(Violation(
                            filename, decl_doc_start, "H5", "warning",
                            f"Doc comment に CJK 文字: {''.join(cjk[:10])} in: {dl[:50]}"
                        ))
                        break  # one warning per doc block is enough

                # P1: No blank line between -/ and declaration keyword
                if i < len(lines):
                    next_stripped = lines[i].strip()  # line after -/
                    if next_stripped == "" and i + 1 < len(lines):
                        after = lines[i + 1].strip()
                        if re.match(r'(?:noncomputable\s+)?(?:axiom|theorem|def|opaque|structure|inductive|abbrev|instance|class|lemma)\s', after):
                            violations.append(Violation(
                                filename, i, "P1", "error",
                                f"-/ と宣言の間に空行: 宣言が文書から脱落する"
                            ))

                # A1/A2/A3: Axiom card checks
                if "[Axiom Card]" in doc_text:
                    for field in ["Layer:", "Content:", "Basis:", "Source:"]:
                        if field not in doc_text:
                            violations.append(Violation(
                                filename, decl_doc_start, "A2", "warning",
                                f"Axiom Card missing field '{field}'"
                            ))
                    if "Refutation condition:" not in doc_text:
                        violations.append(Violation(
                            filename, decl_doc_start, "A2", "warning",
                            "Axiom Card missing 'Refutation condition:'"
                        ))

                # DC1/DC2: Derivation Card checks
                if "[Derivation Card]" in doc_text:
                    for field in ["Derives from:", "Proposition:", "Content:", "Proof strategy:"]:
                        if field not in doc_text:
                            violations.append(Violation(
                                filename, decl_doc_start, "DC2", "warning",
                                f"Derivation Card missing field '{field}'"
                            ))

                # A1: Check if next line is axiom but no [Axiom Card]
                # Only for manifesto-derived axioms (T1-T8, E1-E2),
                # not for formalization-internal axioms
                if i < len(lines):
                    next_stripped = lines[i].strip()
                    if re.match(r'axiom\s', next_stripped) and "[Axiom Card]" not in doc_text:
                        # Check if doc mentions manifesto source (T/E axioms)
                        if "manifesto" in doc_text.lower() or "ソース:" in doc_text:
                            violations.append(Violation(
                                filename, decl_doc_start, "A1", "warning",
                                "manifesto 由来の axiom に [Axiom Card] がない"
                            ))

                decl_doc_lines = []
            continue

    return violations


def lint_verso_output(filepath):
    """C1: Verify generated Verso source has no backtick-wrapped identifiers inside code blocks.
    Verso's fenced code blocks render content as raw text — backticks appear literally in <pre>."""
    violations = []
    filename = os.path.basename(filepath)
    lines = read_file(filepath)
    in_code_block = False

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            # Check for backtick-wrapped identifiers: `word_word` or `_word`
            if re.search(r'`\w+`', stripped):
                violations.append(Violation(
                    filename, i, "C1", "error",
                    f"コードブロック内にバッククォート付き識別子: {stripped[:60]}"
                ))
    return violations


VERSO_DOCS_DIR = Path(__file__).parent.parent / "lean-formalization" / "docgen-verso" / "Docs"


def main():
    files = sys.argv[1:] if len(sys.argv) > 1 else [
        str(MANIFEST_DIR / f) for f in CORE_FILES
    ]

    all_violations = []
    for filepath in files:
        if not os.path.exists(filepath):
            print(f"WARNING: {filepath} not found, skipping", file=sys.stderr)
            continue
        violations = lint_file(filepath)
        all_violations.extend(violations)

    # C1: Check generated Verso output if it exists
    if VERSO_DOCS_DIR.exists():
        for verso_file in sorted(VERSO_DOCS_DIR.glob("*.lean")):
            violations = lint_verso_output(str(verso_file))
            all_violations.extend(violations)

    # Print results grouped by severity
    if all_violations:
        errors = [v for v in all_violations if v.severity == "error"]
        warnings = [v for v in all_violations if v.severity == "warning"]
        infos = [v for v in all_violations if v.severity == "info"]

        print(f"## Doc Comment Lint: {len(all_violations)} violations "
              f"({len(errors)} errors, {len(warnings)} warnings, {len(infos)} info)\n")

        if errors:
            print("### Errors (must fix)\n")
            for v in errors:
                print(f"  {v}")
            print()
        if warnings:
            print("### Warnings (should fix)\n")
            for v in warnings:
                print(f"  {v}")
            print()
        if infos:
            print("### Info\n")
            for v in infos:
                print(f"  {v}")
            print()

        return 1 if errors else 0
    else:
        print("Doc Comment Lint: all checks passed")
        return 0


if __name__ == "__main__":
    sys.exit(main())
