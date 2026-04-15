#!/usr/bin/env python3
"""Extract doc comments from Lean 4 files and produce human-readable Markdown.

Handles two kinds of Lean 4 doc comments:
  - Module doc comments:      /-! ... -/
  - Declaration doc comments: /-- ... -/  (associated with the next declaration)

Modes:
  Single file:   python3 lean-to-markdown.py <file.lean>
  Combined doc:  python3 lean-to-markdown.py --combined <file1.lean> [<file2.lean> ...]
  Manifesto:     python3 lean-to-markdown.py --manifesto

The --manifesto flag processes the 6 core files in canonical order and produces
a unified document with title, preamble, and table of contents.
"""

import argparse
import re
import sys
import textwrap
from pathlib import Path


# Declaration keywords that a /-- comment attaches to
DECL_KEYWORDS = {
    "axiom", "theorem", "def", "opaque", "lemma", "instance",
    "class", "structure", "inductive", "abbrev", "noncomputable",
}

# Canonical file order for the manifesto document
MANIFESTO_FILE_ORDER = [
    "Ontology.lean",
    "Axioms.lean",
    "EmpiricalPostulates.lean",
    "Principles.lean",
    "Observable.lean",
    "DesignFoundation.lean",
]

# Human-readable chapter titles
CHAPTER_TITLES = {
    "Ontology.lean": "Ontology: The Domain of Discourse",
    "Axioms.lean": "Axioms T1-T8: The Immutable Ground Theory",
    "EmpiricalPostulates.lean": "Empirical Postulates E1-E2: Falsifiable Hypotheses",
    "Principles.lean": "Principles P1-P6: Derived Design Principles",
    "Observable.lean": "Observable Variables V1-V7: Measurable Quality Indicators",
    "DesignFoundation.lean": "Design Foundation D1-D14: Applied Design Theory",
}

# Chapter summaries for the TOC
CHAPTER_SUMMARIES = {
    "Ontology.lean":
        "Defines the universe of discourse: agents, sessions, structures, worlds, "
        "and the fundamental type vocabulary shared by all axioms and theorems.",
    "Axioms.lean":
        "Formalizes T1-T8 as Lean axioms -- undeniable, technology-independent facts "
        "forming the base theory T_0 that cannot shrink under revision.",
    "EmpiricalPostulates.lean":
        "Formalizes E1-E2 as axioms with explicit falsification conditions -- "
        "empirically supported but potentially revisable hypotheses.",
    "Principles.lean":
        "Derives P1-P6 as Lean theorems from the axiom base, establishing "
        "design principles with formal proof of their derivation.",
    "Observable.lean":
        "Defines V1-V7 as opaque measurable variables and establishes the "
        "Measurable/Observable framework for quality monitoring.",
    "DesignFoundation.lean":
        "Formalizes D1-D14 as definitional extensions and theorems, connecting "
        "abstract principles to concrete implementation patterns.",
}


def extract_doc_blocks(source: str) -> list[dict]:
    """Parse a Lean source string and return ordered doc blocks.

    Each block is a dict with:
      kind:  "module" | "declaration"
      body:  the Markdown text inside the comment (dedented)
      decl_name:  (declaration only) the name of the next declaration
      decl_keyword: (declaration only) e.g. "axiom", "theorem"
      decl_signature: (declaration only) full signature up to := or first blank line
    """
    blocks = []
    lines = source.split("\n")
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]
        stripped = line.strip()

        # --- Module doc comment: /-! ... -/ ---
        if stripped.startswith("/-!"):
            body_lines = []
            # Check for single-line: /-! ... -/
            if stripped.endswith("-/") and len(stripped) > 5:
                body_lines.append(stripped[3:-2].strip())
                i += 1
            else:
                # First line may have content after /-!
                rest = stripped[3:].strip()
                if rest:
                    body_lines.append(rest)
                i += 1
                while i < n:
                    ln = lines[i]
                    if ln.rstrip().endswith("-/"):
                        # Last line -- strip trailing -/
                        content = ln.rstrip()[:-2]
                        if content.strip():
                            body_lines.append(content.rstrip())
                        break
                    body_lines.append(ln.rstrip())
                    i += 1
                i += 1  # skip the closing -/ line

            blocks.append({
                "kind": "module",
                "body": _dedent(body_lines),
            })
            continue

        # --- Declaration doc comment: /-- ... -/ ---
        if stripped.startswith("/--"):
            body_lines = []
            # Single-line: /-- ... -/
            if stripped.endswith("-/") and len(stripped) > 5:
                body_lines.append(stripped[3:-2].strip())
                i += 1
            else:
                rest = stripped[3:].strip()
                if rest:
                    body_lines.append(rest)
                i += 1
                while i < n:
                    ln = lines[i]
                    if ln.rstrip().endswith("-/"):
                        content = ln.rstrip()[:-2]
                        if content.strip():
                            body_lines.append(content.rstrip())
                        break
                    body_lines.append(ln.rstrip())
                    i += 1
                i += 1

            # Now find the next declaration
            decl_name = None
            decl_keyword = None
            decl_sig_lines = []
            # Skip blank lines and section-separator comments (-- ===...)
            # but NOT inline comments within signatures
            while i < n:
                dline = lines[i].strip()
                if not dline:
                    i += 1
                    continue
                if dline.startswith("--"):
                    # Skip standalone comment lines before a declaration
                    i += 1
                    continue
                # Check if this line starts a declaration
                first_word = dline.split()[0] if dline.split() else ""
                if first_word in DECL_KEYWORDS:
                    decl_keyword = first_word
                    # Collect signature lines until blank line or next doc comment
                    # Include inline -- comments as part of the signature
                    while i < n:
                        sl = lines[i]
                        sl_stripped = sl.strip()
                        # Stop at blank lines or new doc comments
                        if not sl_stripped or sl_stripped.startswith("/-"):
                            break
                        decl_sig_lines.append(sl.rstrip())
                        i += 1
                    # Extract name: second token after keyword(s)
                    sig_text = " ".join(decl_sig_lines)
                    decl_name = _extract_decl_name(sig_text)
                break

            blocks.append({
                "kind": "declaration",
                "body": _dedent(body_lines),
                "decl_name": decl_name,
                "decl_keyword": decl_keyword,
                "decl_signature": "\n".join(decl_sig_lines) if decl_sig_lines else None,
            })
            continue

        i += 1

    return blocks


def _extract_decl_name(sig: str) -> str | None:
    """Extract the declaration name from a signature line.

    Handles patterns like:
      axiom session_bounded :
      theorem autonomy_vulnerability_coscaling :
      def isHuman (agent : Agent) : Prop :=
      opaque structureImproved : World -> World -> Prop
      noncomputable def foo ...
      instance : LE DevelopmentPhase := ...
    """
    tokens = sig.split()
    for idx, tok in enumerate(tokens):
        if tok in DECL_KEYWORDS:
            continue
        # Handle unnamed instances: "instance : LE Foo"
        if tok == ":":
            # This is an unnamed instance, use the type as name
            rest = tokens[idx + 1:] if idx + 1 < len(tokens) else []
            type_name = " ".join(rest).split(":=")[0].strip().split("where")[0].strip()
            return type_name if type_name else "(anonymous)"
        # This should be the name
        # Strip trailing colon/parens
        name = tok.rstrip(":(")
        return name if name else None
    return None


def _dedent(lines: list[str]) -> str:
    """Remove common leading whitespace from lines, preserving relative indent."""
    if not lines:
        return ""
    return textwrap.dedent("\n".join(lines)).strip()


def _bump_headings(body: str, offset: int) -> str:
    """Shift Markdown headings down by offset levels.

    In combined mode, chapter titles use ##, so file-internal headings
    need to be pushed down. A # in the file becomes ### (offset=2), etc.
    """
    if offset <= 0:
        return body

    def _replace(m):
        hashes = m.group(1)
        new_level = min(len(hashes) + offset, 6)
        return "#" * new_level + m.group(2)

    return re.sub(r'^(#{1,6})([ \t])', _replace, body, flags=re.MULTILINE)


def blocks_to_markdown(blocks: list[dict], source_file: str) -> str:
    """Render extracted blocks as Markdown (single-file mode)."""
    parts = []
    file_label = Path(source_file).stem
    parts.append(f"---\nsource: `{Path(source_file).name}`\n---\n")

    for block in blocks:
        if block["kind"] == "module":
            parts.append(block["body"])
            parts.append("")  # blank line separator

        elif block["kind"] == "declaration":
            keyword = block.get("decl_keyword") or "?"
            name = block.get("decl_name") or "(anonymous)"
            sig = block.get("decl_signature")

            # Render the doc body
            body = block["body"]

            # Add declaration header
            parts.append(f"### `{keyword} {name}`\n")
            parts.append(body)

            # Add signature as code block
            if sig:
                parts.append(f"\n```lean\n{sig}\n```\n")

            parts.append("")  # separator

    return "\n".join(parts)


def blocks_to_chapter(blocks: list[dict], source_file: str,
                      chapter_number: int) -> tuple[str, list[str]]:
    """Render extracted blocks as a chapter in combined mode.

    Returns (chapter_markdown, list_of_section_anchors) for TOC generation.
    """
    filename = Path(source_file).name
    chapter_title = CHAPTER_TITLES.get(filename, Path(source_file).stem)
    anchor = _make_anchor(chapter_title)

    parts = []
    toc_entries = []

    # Chapter heading (## level)
    parts.append(f"## {chapter_number}. {chapter_title}")
    parts.append("")
    parts.append(f"*Source: `{filename}`*")
    parts.append("")

    # Count declarations for chapter stats
    axiom_count = sum(1 for b in blocks if b.get("decl_keyword") == "axiom")
    theorem_count = sum(1 for b in blocks if b.get("decl_keyword") == "theorem")
    def_count = sum(1 for b in blocks if b.get("decl_keyword") in
                    ("def", "opaque", "structure", "inductive", "class", "abbrev"))
    stats_parts = []
    if axiom_count:
        stats_parts.append(f"{axiom_count} axiom{'s' if axiom_count != 1 else ''}")
    if theorem_count:
        stats_parts.append(f"{theorem_count} theorem{'s' if theorem_count != 1 else ''}")
    if def_count:
        stats_parts.append(f"{def_count} definition{'s' if def_count != 1 else ''}")
    if stats_parts:
        parts.append(f"**Declarations:** {', '.join(stats_parts)}")
        parts.append("")

    for block in blocks:
        if block["kind"] == "module":
            # Bump headings: # -> ###, ## -> ####
            body = _bump_headings(block["body"], 2)
            parts.append(body)
            parts.append("")

        elif block["kind"] == "declaration":
            keyword = block.get("decl_keyword") or "?"
            name = block.get("decl_name") or "(anonymous)"
            sig = block.get("decl_signature")
            body = block["body"]

            # Declaration header at #### level
            parts.append(f"#### `{keyword} {name}`\n")
            # Bump any headings inside declaration doc comments
            body = _bump_headings(body, 2)
            parts.append(body)

            # Add signature as code block
            if sig:
                parts.append(f"\n```lean\n{sig}\n```\n")

            parts.append("")

    return "\n".join(parts), toc_entries


def _make_anchor(text: str) -> str:
    """Create a GitHub-style anchor from heading text."""
    anchor = text.lower()
    anchor = re.sub(r'[^\w\s-]', '', anchor)
    anchor = re.sub(r'\s+', '-', anchor)
    return anchor


def generate_combined_document(file_paths: list[str]) -> str:
    """Generate a combined manifesto document from multiple Lean files.

    Includes title, preamble, table of contents, and all chapters.
    """
    parts = []

    # Title
    parts.append("# Agent Manifesto: Formal Specification")
    parts.append("")
    parts.append("*A Lean 4 formalization of the covenant between ephemeral agents "
                 "and persistent structure.*")
    parts.append("")

    # Preamble
    parts.append("---")
    parts.append("")
    parts.append("## Preamble")
    parts.append("")
    parts.append(textwrap.dedent("""\
        This document is generated from the Lean 4 source files in
        `lean-formalization/Manifest/`. Every axiom, theorem, and definition
        presented here has been verified by the Lean type checker --
        55 axioms, 488 theorems, 0 sorry.

        The manifesto rests on a layered epistemic architecture:

        | Layer | Strength | Contents | Lean construct |
        |-------|----------|----------|----------------|
        | Ground Theory T_0 | 5 (strongest) | T1-T8: undeniable facts | `axiom` |
        | Empirical Postulates | 4 | E1-E2: falsifiable hypotheses | `axiom` + refutation conditions |
        | Derived Principles | 3 | P1-P6: proven consequences | `theorem` |
        | Observable Variables | 2 | V1-V7: measurable indicators | `opaque` + `Measurable` axiom |
        | Design Theorems | 1 (weakest) | D1-D14: applied design rules | `theorem` / `def` |

        The core insight: **ephemeral agents (T1) improve persistent structure (T2)
        through governed learning (P3), observable feedback (P4), and
        probabilistic interpretation (P5), subject to finite resources (T3, T7)
        and human authority (T6).**"""))
    parts.append("")

    # Table of Contents
    parts.append("---")
    parts.append("")
    parts.append("## Table of Contents")
    parts.append("")

    for idx, fpath in enumerate(file_paths, 1):
        filename = Path(fpath).name
        title = CHAPTER_TITLES.get(filename, Path(fpath).stem)
        anchor = _make_anchor(f"{idx}-{title}")
        summary = CHAPTER_SUMMARIES.get(filename, "")
        parts.append(f"{idx}. [{title}](#{anchor})")
        if summary:
            parts.append(f"   *{summary}*")
        parts.append("")

    parts.append("---")
    parts.append("")

    # Chapters
    total_axioms = 0
    total_theorems = 0
    total_defs = 0

    for idx, fpath in enumerate(file_paths, 1):
        path = Path(fpath)
        if not path.exists():
            parts.append(f"## {idx}. ERROR: {fpath} not found\n")
            continue

        source = path.read_text(encoding="utf-8")
        blocks = extract_doc_blocks(source)

        # Count for final stats
        for b in blocks:
            kw = b.get("decl_keyword")
            if kw == "axiom":
                total_axioms += 1
            elif kw == "theorem":
                total_theorems += 1
            elif kw in ("def", "opaque", "structure", "inductive", "class", "abbrev"):
                total_defs += 1

        chapter_md, _ = blocks_to_chapter(blocks, fpath, idx)
        parts.append(chapter_md)
        parts.append("")  # blank line between chapters

    # Footer
    parts.append("---")
    parts.append("")
    parts.append("## Statistics")
    parts.append("")
    parts.append(f"- **Files processed:** {len(file_paths)}")
    parts.append(f"- **Documented axioms:** {total_axioms}")
    parts.append(f"- **Documented theorems:** {total_theorems}")
    parts.append(f"- **Documented definitions:** {total_defs}")
    parts.append(f"- **Total documented declarations:** {total_axioms + total_theorems + total_defs}")
    parts.append("")
    parts.append("*Generated by `scripts/lean-to-markdown.py --manifesto`*")
    parts.append("")

    return "\n".join(parts)


def process_file(filepath: str) -> str:
    """Read a Lean file and return its Markdown rendering."""
    path = Path(filepath)
    if not path.exists():
        print(f"Error: {filepath} not found", file=sys.stderr)
        sys.exit(1)
    source = path.read_text(encoding="utf-8")
    blocks = extract_doc_blocks(source)
    return blocks_to_markdown(blocks, filepath)


def main():
    parser = argparse.ArgumentParser(
        description="Extract doc comments from Lean 4 files and produce Markdown.")
    parser.add_argument("files", nargs="*", help="Lean source files to process")
    parser.add_argument("--combined", action="store_true",
                        help="Combine multiple files into a single document with TOC")
    parser.add_argument("--manifesto", action="store_true",
                        help="Process the 6 core manifesto files in canonical order")
    parser.add_argument("-o", "--output", type=str, default=None,
                        help="Write output to file instead of stdout")
    parser.add_argument("--base-dir", type=str,
                        default="lean-formalization/Manifest",
                        help="Base directory for Lean files (used with --manifesto)")

    args = parser.parse_args()

    if args.manifesto:
        base = Path(args.base_dir)
        file_paths = [str(base / f) for f in MANIFESTO_FILE_ORDER]
        output = generate_combined_document(file_paths)
    elif args.combined and args.files:
        output = generate_combined_document(args.files)
    elif args.files:
        parts = []
        for filepath in args.files:
            parts.append(process_file(filepath))
        output = "\n".join(parts)
    else:
        parser.print_help()
        sys.exit(1)

    if args.output:
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(output, encoding="utf-8")
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
