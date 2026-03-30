#!/usr/bin/env python3
"""
Generate Verso-compatible .lean documentation files from Manifest source files.

Reads the 6 core Lean files, extracts module doc comments (/-! ... -/) and
declaration doc comments (/-- ... -/), and generates Verso markup files
in docgen-verso/Docs/.
"""

import re
import os
import sys

# Paths
MANIFEST_DIR = os.path.join(os.path.dirname(__file__), "..", "lean-formalization", "Manifest")
DOCS_DIR = os.path.join(os.path.dirname(__file__), "..", "lean-formalization", "docgen-verso", "Docs")
DOCS_ROOT = os.path.join(os.path.dirname(__file__), "..", "lean-formalization", "docgen-verso", "Docs.lean")

# Source files to process (order matters for the table of contents)
SOURCE_FILES = [
    ("Ontology.lean", "Ontology", "Ontology: Core Type Definitions"),
    ("Axioms.lean", "Axioms", "Axioms: Base Theory T0"),
    ("EmpiricalPostulates.lean", "EmpiricalPostulates", "Empirical Postulates: E1-E2"),
    ("Principles.lean", "Principles", "Principles: P1-P6"),
    ("Observable.lean", "Observable", "Observable Variables: V1-V7"),
    ("DesignFoundation.lean", "DesignFoundation", "Design Foundation: D1-D14"),
]


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def postprocess_verso(content):
    """Post-process generated Verso file to escape underscores outside code blocks."""
    lines = content.split("\n")
    result = []
    in_code_block = False
    in_lean_preamble = True  # Before #doc directive

    for line in lines:
        stripped = line.strip()

        # Track code blocks
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            result.append(line)
            continue

        if in_code_block:
            result.append(line)
            continue

        # Don't touch preamble (import, open, set_option, etc.)
        if in_lean_preamble:
            if stripped.startswith("#doc"):
                in_lean_preamble = False
            result.append(line)
            continue

        # Headers also need underscore escaping (e.g., T_0 in headings)
        # but don't escape the # prefix itself

        # Escape identifiers with underscores that Verso interprets as emphasis
        # Protect existing backtick spans first
        backtick_spans = []
        def save_bt(m):
            backtick_spans.append(m.group(0))
            return f"\x00BT{len(backtick_spans)-1}\x00"
        escaped = re.sub(r'`[^`]+`', save_bt, line)

        # Wrap bare _word and word_word patterns in backticks
        escaped = re.sub(r'(?<![`\w])(\w+_\w+)(?![`\w])', r'`\1`', escaped)
        escaped = re.sub(r'(?<![`\w])(_\w*)(?![`\w])', r'`\1`', escaped)

        # Restore backtick spans
        for i, span in enumerate(backtick_spans):
            escaped = escaped.replace(f"\x00BT{i}\x00", span)

        result.append(escaped)

    return "\n".join(result)


def escape_code_for_verso(code):
    """Pass-through: Verso's unnamed ``` blocks do NOT interpret _ as emphasis.
    No escaping needed for code inside fenced code blocks.
    (Verified: Verso Parser.lean treats ``` content as raw text.)"""
    return code


def extract_full_declaration(content, after_first_line_pos, first_line):
    """Extract the full multi-line Lean declaration starting from first_line.

    Continues reading lines after first_line until we hit a blank line,
    a new doc comment, a section separator (-- ===), or a new top-level declaration.
    """
    lines = [first_line]
    rest = content[after_first_line_pos:]
    # Skip the leading newline if present
    if rest.startswith("\n"):
        rest = rest[1:]
    for line in rest.split("\n"):
        stripped = line.strip()
        # Stop conditions
        if stripped == "":
            break
        if stripped.startswith("/--") or stripped.startswith("/-!"):
            break
        if stripped.startswith("-- ===="):
            break
        # New top-level (non-indented) declaration
        if not line[0:1].isspace() and re.match(
            r'(?:noncomputable\s+)?(?:axiom|theorem|def|opaque|structure|inductive|abbrev|instance|class|lemma)\s',
            stripped
        ):
            break
        lines.append(line.rstrip())
    return "\n".join(lines)


def extract_doc_comments(content):
    """Extract module doc comments and declaration doc comments with surrounding context."""
    blocks = []

    # Extract module doc comments: /-! ... -/
    for m in re.finditer(r'/\-\!(.*?)\-/', content, re.DOTALL):
        text = m.group(1)
        blocks.append(("module", text, m.start()))

    # Extract declaration doc comments: /-- ... -/
    # followed by their full declaration (multi-line, up to next blank line or next doc comment)
    # Pattern 1: Top-level declarations (axiom, theorem, def, etc.)
    for m in re.finditer(
        r'/\-\-(.*?)\-/\s*\n((?:noncomputable\s+)?(?:axiom|theorem|def|opaque|structure|inductive|abbrev|instance|class|lemma)\s+[^\n]+)',
        content, re.DOTALL
    ):
        doc_text = m.group(1)
        decl_start = m.group(2).strip()
        decl_end_pos = m.end()
        full_decl = extract_full_declaration(content, decl_end_pos, decl_start)
        blocks.append(("decl", doc_text, m.start(), full_decl))

    # Pattern 2: Structure field doc comments (indented /-- ... -/ followed by field : Type)
    for m in re.finditer(
        r'[ \t]+/\-\-(.*?)\-/\s*\n([ \t]+\w+\s*:\s*[^\n]+)',
        content, re.DOTALL
    ):
        doc_text = m.group(1)
        field_line = m.group(2).strip()
        blocks.append(("decl", doc_text, m.start(), field_line))

    # Pattern 3: Inductive constructor doc comments (indented /-- ... -/ followed by | constructorName)
    for m in re.finditer(
        r'[ \t]+/\-\-(.*?)\-/\s*\n([ \t]+\|\s+\w+[^\n]*)',
        content, re.DOTALL
    ):
        doc_text = m.group(1)
        ctor_line = m.group(2).strip()
        blocks.append(("decl", doc_text, m.start(), ctor_line))

    # Remove duplicates: if two blocks start at the same position, keep the one
    # from Pattern 1 (top-level declarations) over Pattern 2/3 (fields/constructors)
    seen_positions = {}
    for b in blocks:
        pos = b[2]
        if pos not in seen_positions:
            seen_positions[pos] = b
        elif b[0] == "decl" and seen_positions[pos][0] == "decl":
            # Prefer the one with a declaration keyword match
            import re as _re
            existing_decl = seen_positions[pos][3] if len(seen_positions[pos]) > 3 else ""
            new_decl = b[3] if len(b) > 3 else ""
            kw_pattern = r'^(?:noncomputable\s+)?(?:axiom|theorem|def|opaque|structure|inductive|abbrev|instance|class|lemma)\s'
            if _re.match(kw_pattern, new_decl) and not _re.match(kw_pattern, existing_decl):
                seen_positions[pos] = b
    blocks = list(seen_positions.values())

    # Sort by position in file
    blocks.sort(key=lambda b: b[2])
    return blocks


def escape_verso_special(line):
    """Escape characters that have special meaning in Verso markup.

    Verso treats:
    - [text] as link syntax
    - _text_ as emphasis (underscores)
    - {text} as directives
    - Single * as emphasis markers
    """
    # Skip lines that are already in backticks or are headers
    if not line.strip():
        return line

    # Protect backtick-wrapped content first
    # Extract all backtick spans, process the rest, then restore
    backtick_spans = []
    def save_backtick(m):
        backtick_spans.append(m.group(0))
        return f"\x00BT{len(backtick_spans)-1}\x00"

    line = re.sub(r'`[^`]+`', save_backtick, line)

    # Escape square brackets for Verso:
    # [] (empty) -> wrap context in backticks if not already
    # [text] -> replace brackets with parens to avoid link parsing
    line = re.sub(r'\[\]', '`[]`', line)
    # [text] that's not a markdown link -> (text)
    line = re.sub(r'\[([^\]]+)\](?!\()', r'(\1)', line)

    # Escape bare underscores in identifiers that aren't inside backticks
    # e.g., session_bounded -> `session_bounded`
    # Match word_word patterns (Lean identifiers with underscores)
    def backtick_identifier(m):
        ident = m.group(0)
        # Don't wrap if it's already a header marker or list item
        return f'`{ident}`'

    line = re.sub(r'(?<![`\w])([a-zA-Z]\w*_\w+)(?![`\w])', backtick_identifier, line)

    # Escape curly braces that aren't Verso directives
    # {include ...} is a Verso directive, but {text} in ASCII art is not
    line = re.sub(r'\{(?!include\s)', r'\\{', line)
    line = re.sub(r'(?<!\\)\}', r'\\}', line)
    # But don't double-escape
    line = line.replace('\\\\{', '\\{').replace('\\\\}', '\\}')

    # Restore backtick spans
    for i, span in enumerate(backtick_spans):
        line = line.replace(f"\x00BT{i}\x00", span)

    return line


def is_ascii_art_line(line):
    """Detect ASCII art lines (box drawing, etc.)."""
    stripped = line.strip()
    # Lines that are primarily box-drawing characters
    if re.match(r'^[┌┐└┘├┤┬┴│─═╔╗╚╝║╠╣╦╩\s\-\+\|]+$', stripped):
        return True
    # Lines with box drawing at start
    if stripped and stripped[0] in '┌┐└┘├┤│║╔╗╚╝╠╣':
        return True
    return False


def markdown_to_verso(text):
    """Convert Markdown-style doc comments to Verso markup.

    Key differences:
    - **bold** -> *bold* (single asterisk in Verso)
    - Tables are not supported; convert to bullet lists
    - Code blocks stay as-is
    - Headers stay as-is (#, ##, etc.)
    - Square brackets, underscores, curly braces need escaping
    - ASCII art diagrams are wrapped in code blocks
    """
    lines = text.split("\n")
    result = []
    in_table = False
    table_headers = []
    table_rows = []
    in_code_block = False
    in_ascii_art = False

    for line in lines:
        stripped = line.strip()

        # Track code blocks (don't transform inside them)
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            result.append(line)
            continue

        if in_code_block:
            result.append(line)
            continue

        # Handle table separator and data lines BEFORE ascii art detection
        # (because |---| matches both ascii art and table separator patterns)
        if re.match(r'\s*\|.*\|', stripped):
            # Close any open ASCII art block first
            if in_ascii_art:
                in_ascii_art = False
                result.append("```")
            # Check separator row FIRST (before header detection)
            if re.match(r'\s*\|[\-\s|:]+\|$', stripped):
                if in_table:
                    # Separator row inside table, skip
                    continue
                else:
                    # Orphan separator, skip entirely
                    continue
            elif not in_table:
                in_table = True
                table_rows = []
                # This is the header row
                cells = [c.strip() for c in stripped.strip('|').split('|')]
                table_headers = cells
                table_rows.append(cells)
                continue
            else:
                # Data row
                cells = [c.strip() for c in stripped.strip('|').split('|')]
                table_rows.append(cells)
                continue
        else:
            if in_table:
                in_table = False
                # Emit :::table directive
                result.append("")
                result.append(":::table +header")
                for row in table_rows:
                    result.append("*")
                    for cell in row:
                        cell_escaped = escape_verso_special(cell) if cell else " "
                        result.append(f"  * {cell_escaped}")
                result.append(":::")
                result.append("")
                table_rows = []

            # Detect and wrap ASCII art blocks
            if is_ascii_art_line(line):
                if not in_ascii_art:
                    in_ascii_art = True
                    result.append("```")
                result.append(line)
                continue
            else:
                if in_ascii_art:
                    in_ascii_art = False
                    result.append("```")

            # Convert **bold** to *bold* (Verso uses single *)
            line = re.sub(r'\*\*([^*]+)\*\*', r'*\1*', line)

            # Escape Verso-special characters in non-header, non-code lines
            if not stripped.startswith("#"):
                line = escape_verso_special(line)

            result.append(line)

    # Close any open ASCII art block
    if in_ascii_art:
        result.append("```")

    # Flush any pending table
    if in_table and table_rows:
        result.append("")
        result.append(":::table +header")
        for row in table_rows:
            result.append("*")
            for cell in row:
                cell_escaped = escape_verso_special(cell) if cell else " "
                result.append(f"  * {cell_escaped}")
        result.append(":::")
        result.append("")

    return "\n".join(result)


def clean_doc_text(text):
    """Clean up doc comment text, removing leading whitespace artifacts."""
    lines = text.split("\n")

    # Find minimum indentation (excluding empty lines)
    min_indent = float('inf')
    for line in lines:
        if line.strip():
            indent = len(line) - len(line.lstrip())
            min_indent = min(min_indent, indent)

    if min_indent == float('inf'):
        min_indent = 0

    # Remove common indentation
    cleaned = []
    for line in lines:
        if line.strip():
            cleaned.append(line[min_indent:])
        else:
            cleaned.append("")

    # Strip leading/trailing blank lines
    while cleaned and not cleaned[0].strip():
        cleaned.pop(0)
    while cleaned and not cleaned[-1].strip():
        cleaned.pop()

    return "\n".join(cleaned)


def heading_to_tag(heading_line):
    """Simulate Verso's tag generation: non-ASCII chars become underscores.

    Verso encodes headings into internal tags where CJK/non-ASCII characters
    are replaced with underscores. This means two Japanese headings of the
    same character count (e.g., '遵守義務' and '脅威認識') produce the
    same tag '____' and collide.
    """
    return re.sub(r'[^\x00-\x7f]', '_', heading_line)


def deduplicate_headings(text):
    """Make headings produce unique Verso tags by appending a counter.

    Verso generates internal tags from heading text where non-ASCII characters
    are replaced with underscores. Two different Japanese headings of the same
    length produce identical tags and cause 'Duplicate tag' build errors.

    This function detects collisions at the tag level (not just text level)
    and appends a disambiguating counter.
    """
    lines = text.split("\n")
    result = []
    seen_tags = {}  # tag string -> count

    for line in lines:
        m = re.match(r'^(#{1,6})\s+(.*)', line)
        if m:
            prefix = m.group(1)
            heading_text = m.group(2)
            tag = heading_to_tag(f"{prefix} {heading_text}")
            seen_tags[tag] = seen_tags.get(tag, 0) + 1
            if seen_tags[tag] > 1:
                # Append ASCII counter to make the tag unique
                # Avoid () [] {} — all are Verso special chars
                line = f"{prefix} {heading_text} Part {seen_tags[tag]}"
        result.append(line)

    return "\n".join(result)


def generate_verso_file(filename, module_name, title, blocks):
    """Generate a Verso .lean file from extracted doc blocks."""
    sections = []

    for block in blocks:
        if block[0] == "module":
            text = clean_doc_text(block[1])
            text = markdown_to_verso(text)
            sections.append(text)
        elif block[0] == "decl":
            text = clean_doc_text(block[1])
            text = markdown_to_verso(text)
            full_decl = block[3]

            # Extract kind and name for the heading
            decl_match = re.match(
                r'(?:noncomputable\s+)?(axiom|theorem|def|opaque|structure|inductive|abbrev|instance|class|lemma)\s+(\S+)',
                full_decl.split("\n")[0]
            )
            if decl_match:
                kind = decl_match.group(1)
                name = decl_match.group(2)
                # Add declaration info with full type signature
                # Escape underscores in code blocks to prevent Verso emphasis parsing
                safe_decl = escape_code_for_verso(full_decl)
                text = text + f"\n\n*Declaration:* `{kind} {name}`\n\n```\n{safe_decl}\n```"
            else:
                safe_decl = escape_code_for_verso(full_decl)
                text = text + f"\n\n```\n{safe_decl}\n```"

            sections.append(text)

    # Build the Verso file content
    content_body = "\n\n".join(sections)

    # Deduplicate headings to avoid Verso "Duplicate tag" build errors
    content_body = deduplicate_headings(content_body)

    verso_content = f"""/-
Agent Manifesto - {title}
Generated by generate-verso-source.py
-/

import VersoManual

open Verso.Genre Manual

set_option linter.verso.markup.emph false

#doc (Manual) "{title}" =>

{content_body}
"""
    # Post-process: escape underscored identifiers outside code blocks
    verso_content = postprocess_verso(verso_content)
    return verso_content


def update_docs_root(module_names):
    """Update Docs.lean to include all generated modules."""
    # Read the existing Docs.lean
    existing = read_file(DOCS_ROOT)

    # Build new imports and includes
    all_imports = ["import Docs.Overview"] + [f"import Docs.{name}" for name in module_names]
    all_includes = ["{include 0 Docs.Overview}"] + [f"{{include 0 Docs.{name}}}" for name in module_names]

    new_content = f"""/-
Agent Manifesto - Formal Documentation
Generated with Verso (leanprover/verso)
-/

import VersoManual

{chr(10).join(all_imports)}

open Verso.Genre Manual

set_option pp.rawOnError true

-- Point to the parent lean-formalization directory as the example project
set_option verso.exampleProject ".."
set_option verso.exampleModule "Manifest.Axioms"

#doc (Manual) "Agent Manifesto: Formal Specification" =>
%%%
authors := ["Agent Manifesto Project"]
shortTitle := "Agent Manifesto"
%%%

This document provides a navigable, hyperlinked view of the Agent Manifesto's
Lean 4 formalization. The project encodes a set of axioms, boundary conditions,
observable variables, and design principles as formal Lean definitions and theorems.

*Project statistics:* 63 axioms, 343 theorems, 0 sorry.

# Structure

The formalization is organized into the following modules:

- *Ontology* (`Manifest.Ontology`) -- Core type definitions: `Session`, `Structure`, `Context`, `Resource`, `Task`, and boundary conditions L1--L6
- *Axioms* (`Manifest.Axioms`) -- Base theory T0: axioms T1--T8 encoding fundamental constraints
- *Empirical Postulates* (`Manifest.EmpiricalPostulates`) -- Empirical postulates E1--E2
- *Observable* (`Manifest.Observable`) -- Observable variables V1--V7 for measurement
- *Principles* (`Manifest.Principles`) -- Derived principles P1--P6
- *DesignFoundation* (`Manifest.DesignFoundation`) -- Design development foundation D1--D14
- *Evolution* (`Manifest.Evolution`) -- Evolution mechanics and improvement tracking

{chr(10).join(all_includes)}
"""
    return new_content


def main():
    os.makedirs(DOCS_DIR, exist_ok=True)

    generated_modules = []

    for filename, module_name, title in SOURCE_FILES:
        filepath = os.path.join(MANIFEST_DIR, filename)
        if not os.path.exists(filepath):
            print(f"WARNING: {filepath} not found, skipping", file=sys.stderr)
            continue

        content = read_file(filepath)
        blocks = extract_doc_comments(content)

        if not blocks:
            print(f"WARNING: No doc comments found in {filename}", file=sys.stderr)
            continue

        verso_content = generate_verso_file(filename, module_name, title, blocks)

        output_path = os.path.join(DOCS_DIR, f"{module_name}.lean")
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(verso_content)

        print(f"Generated: {output_path} ({len(blocks)} doc blocks)")
        generated_modules.append(module_name)

    # Update Docs.lean
    new_docs_root = update_docs_root(generated_modules)
    with open(DOCS_ROOT, "w", encoding="utf-8") as f:
        f.write(new_docs_root)
    print(f"Updated: {DOCS_ROOT}")

    print(f"\nDone. Generated {len(generated_modules)} Verso source files.")


if __name__ == "__main__":
    main()
