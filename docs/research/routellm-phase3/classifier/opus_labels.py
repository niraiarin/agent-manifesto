#!/usr/bin/env python3
"""
opus_labels.py — #653 Item 1: Opus 4.7 GT labeling for 100 candidates.

各 gt-XXX に対する私 (Claude Opus 4.7) の routing 判定。
taxonomy §4 A1-A6 軸と real prompt の用途を総合して label 付与。

注意: これは LLM-labeler であり、完全な「human GT」ではない。
classifier (e5-small + LR) とは別 model family の判定なので
closed-loop accuracy よりは独立性が高い (BELLA の critic model パターン)。
"""

# (id, label, rationale_short)
OPUS_LABELS = [
    ("gt-000", "cloud_required", "doc revision task, multi-step file modification"),
    ("gt-001", "cloud_required", "/research skill invocation"),
    ("gt-002", "cloud_required", "merge + worktree creation + research, orchestration"),
    ("gt-003", "cloud_required", "multi-step issue creation task"),
    ("gt-004", "cloud_required", "direction for multi-issue follow-up"),
    ("gt-005", "cloud_required", "/evolve skill invocation + T6 orchestration"),
    ("gt-006", "cloud_required", "plugin export tooling task"),
    ("gt-007", "cloud_required", "complex research task with structured data"),
    ("gt-008", "cloud_required", "deep design discussion of ADaPT / Gate/Judge simplification"),
    ("gt-009", "hybrid", "short acknowledgement + PR direction"),
    ("gt-010", "cloud_required", "deep analysis of axiom system origin"),
    ("gt-011", "hybrid", "session continuation marker, no specific task"),
    ("gt-012", "cloud_required", "research implementation task with external URL reading"),
    ("gt-013", "hybrid", "decision among ABCD options, discussion"),
    ("gt-014", "cloud_required", "close branches + deep /research on #506"),
    ("gt-015", "hybrid", "short status confirmation"),
    ("gt-016", "cloud_required", "/research issue creation with assumption"),
    ("gt-017", "hybrid", "debugging question for LM Studio"),
    ("gt-018", "cloud_required", "evolve skill metadata dump = orchestration context"),
    ("gt-019", "cloud_required", "complex workflow verification question"),
    ("gt-020", "cloud_required", "README modification task"),
    ("gt-021", "hybrid", "design conversation about research workflow"),
    ("gt-022", "cloud_required", "defer decision + /research pivot"),
    ("gt-023", "hybrid", "short ack + PR review request"),
    ("gt-024", "cloud_required", "bash tool output from hook fix = code modification context"),
    ("gt-025", "hybrid", "status check for test plan"),
    ("gt-026", "cloud_required", "research skill invocation metadata"),
    ("gt-027", "cloud_required", "warning resolution (code fix) task"),
    ("gt-028", "cloud_required", "verification methodology question"),
    ("gt-029", "cloud_required", "export-plugins tool execution"),
    ("gt-030", "cloud_required", "Judge evaluation request for artifacts"),
    ("gt-031", "cloud_required", "/verify skill invocation for brownfield"),
    ("gt-032", "cloud_required", "workflow execution with T6 boundary"),
    ("gt-033", "cloud_required", "deep philosophical question about axiom sufficiency"),
    ("gt-034", "cloud_required", "Gap re-check (research Loop)"),
    ("gt-035", "cloud_required", "/formal-derivation-procedure invocation"),
    ("gt-036", "cloud_required", "PR conflict resolution (git ops + code)"),
    ("gt-037", "cloud_required", "generic infrastructure request"),
    ("gt-038", "cloud_required", "axiom-based redesign + issue creation"),
    ("gt-039", "cloud_required", "same as 38 truncated"),
    ("gt-040", "cloud_required", "verify request + workflow improvement"),
    ("gt-041", "cloud_required", "deep local implementation research"),
    ("gt-042", "cloud_required", "Lean document modification tradeoff question"),
    ("gt-043", "cloud_required", "Lean format/linter design + implementation"),
    ("gt-044", "cloud_required", "hook setup script preparation (code gen)"),
    ("gt-045", "cloud_required", "meta design question on skill-driven axiom derivation"),
    ("gt-046", "hybrid", "discussion about paper significance"),
    ("gt-047", "cloud_required", "batch stop + handoff orchestration"),
    ("gt-048", "hybrid", "questioning/critique of workflow"),
    ("gt-049", "hybrid", "meta discussion about issue scope"),
    ("gt-050", "hybrid", "tool operation complaint + request"),
    ("gt-051", "hybrid", "status question about plugin integration"),
    ("gt-052", "cloud_required", "verify via independent agent contexts"),
    ("gt-053", "cloud_required", "deep design discussion on Gap 6"),
    ("gt-054", "cloud_required", "workflow Round 2 verification"),
    ("gt-055", "cloud_required", "bash tool output from hook update = code context"),
    ("gt-056", "local_confident", "handoff skill invocation"),
    ("gt-057", "cloud_required", "issue creation with context scoping"),
    ("gt-058", "cloud_required", "design question about handoff behavior"),
    ("gt-059", "cloud_required", "Gap Analysis direction with tag index reference"),
    ("gt-060", "cloud_required", "research skill critique + improvement"),
    ("gt-061", "cloud_required", "new feature design: clean room writing"),
    ("gt-062", "hybrid", "test plan pass status check"),
    ("gt-063", "cloud_required", "P2 hook update tool output"),
    ("gt-064", "cloud_required", "trace test request + traceability validation"),
    ("gt-065", "hybrid", "design question on subagent vs agent-teams"),
    ("gt-066", "hybrid", "short question about SKILL configuration"),
    ("gt-067", "local_confident", "simple file read + summarize"),
    ("gt-068", "hybrid", "short continuation prompt"),
    ("gt-069", "cloud_required", "settings.json hook modification tool output"),
    ("gt-070", "cloud_required", "deep research request with T6 delegation setup"),
    ("gt-071", "hybrid", "debugging question about Content block issue"),
    ("gt-072", "cloud_required", "meta script design for AI understanding"),
    ("gt-073", "hybrid", "discussion on ccr tool-use issue"),
    ("gt-074", "hybrid", "ssh tunnel command output"),
    ("gt-075", "hybrid", "correction/discussion about testing approach"),
    ("gt-076", "hybrid", "workflow process question"),
    ("gt-077", "cloud_required", "/research with Gap Loop"),
    ("gt-078", "hybrid", "debugging + suggestion about llama-server"),
    ("gt-079", "cloud_required", "session handoff design + prompt generation"),
    ("gt-080", "cloud_required", "research workflow execution guidance question"),
    ("gt-081", "cloud_required", "websearch + SakanaAI research"),
    ("gt-082", "cloud_required", "MT.6 test structural fix tool output"),
    ("gt-083", "cloud_required", "deep design question on successor issue recursion"),
    ("gt-084", "hybrid", "UI implementation question"),
    ("gt-085", "cloud_required", "skill execution direction"),
    ("gt-086", "cloud_required", "PR #413 verification check"),
    ("gt-087", "local_confident", "CLAUDE.md re-read and continue"),
    ("gt-088", "cloud_required", "/research for paper reproducibility"),
    ("gt-089", "local_confident", "simple summarization of issues in plain language"),
    ("gt-090", "cloud_required", "verify memory content integrity"),
    ("gt-091", "cloud_required", "paper deep-dive for workflow gap"),
    ("gt-092", "hybrid", "short check about merge contents"),
    ("gt-093", "hybrid", "short ack about model name"),
    ("gt-094", "hybrid", "short critique about options independence"),
    ("gt-095", "hybrid", "discussion with no objection"),
    ("gt-096", "hybrid", "short meta question about session handoff"),
    ("gt-097", "hybrid", "short decision AB"),
    ("gt-098", "cloud_required", "deep axiom closure question with Q5/Q6 structure"),
    ("gt-099", "cloud_required", "/research invocation"),
]


def main():
    import argparse
    import json
    from pathlib import Path

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    label_map = {id_: (lbl, rat) for id_, lbl, rat in OPUS_LABELS}
    entries = [json.loads(l) for l in args.input.read_text().splitlines() if l.strip()]

    with open(args.output, "w") as f:
        for e in entries:
            lbl, rat = label_map.get(e["id"], (None, None))
            e["gt_label"] = lbl
            e["annotator"] = "claude-opus-4-7"
            e["annotator_notes"] = rat
            f.write(json.dumps(e, ensure_ascii=False) + "\n")

    from collections import Counter
    dist = Counter(label_map[e["id"]][0] for e in entries if e["id"] in label_map)
    agreement = sum(1 for e in entries if label_map.get(e["id"], (None,))[0] == e["predicted_label"])
    print(f"[opus-labels] wrote {len(entries)} labeled → {args.output}")
    print(f"[opus-labels] GT distribution: {dict(dist)}")
    print(f"[opus-labels] agreement with classifier: {agreement}/{len(entries)} = {agreement/len(entries):.1%}")


if __name__ == "__main__":
    main()
