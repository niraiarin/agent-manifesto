#!/usr/bin/env python3
"""Generate a Claude Code plugin from export-manifest.json.

Reads export-manifest.json and assembles a plugin directory with:
- hooks/hooks.json + hooks/scripts/ (base hooks)
- agents/ (base agents)
- rules/ (base rules, injected via SessionStart hook)
- .claude-plugin/plugin.json

Usage:
    python3 scripts/generate-plugin.py [output-dir]
    Default output: dist/agent-manifesto-base/
"""

import json
import os
import shutil
import sys

MANIFEST = "export-manifest.json"
DEFAULT_OUTPUT = "dist/agent-manifesto-base"


def main():
    output_dir = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUTPUT

    if not os.path.exists(MANIFEST):
        print(f"ERROR: {MANIFEST} not found. Run from project root.")
        sys.exit(1)

    with open(MANIFEST) as f:
        manifest = json.load(f)

    # Clean output
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)

    os.makedirs(f"{output_dir}/.claude-plugin", exist_ok=True)
    os.makedirs(f"{output_dir}/hooks/scripts", exist_ok=True)
    os.makedirs(f"{output_dir}/agents", exist_ok=True)
    os.makedirs(f"{output_dir}/rules", exist_ok=True)

    # plugin.json
    plugin_json = {
        "name": "agent-manifesto-base",
        "description": "Structural enforcement infrastructure: L1 safety, P2 verification, P3 governance, P4 observability",
        "version": "0.1.0",
        "author": {"name": "nirarin"},
    }
    with open(f"{output_dir}/.claude-plugin/plugin.json", "w") as f:
        json.dump(plugin_json, f, indent=2)
        f.write("\n")

    # Hooks
    hooks_json = {"hooks": {}}
    hook_count = 0
    for name, hook in manifest["hooks"].items():
        if hook["target"] not in ("base", "base-configurable"):
            continue
        src = hook["path"]
        if not os.path.exists(src):
            print(f"  WARN: {src} not found, skipping")
            continue
        shutil.copy2(src, f"{output_dir}/hooks/scripts/{name}")
        os.chmod(f"{output_dir}/hooks/scripts/{name}", 0o755)

        event = hook["event"]
        entry = {
            "hooks": [
                {
                    "type": "command",
                    "command": f"${{CLAUDE_PLUGIN_ROOT}}/hooks/scripts/{name}",
                }
            ]
        }
        if hook.get("matcher"):
            entry["matcher"] = hook["matcher"]
        hooks_json["hooks"].setdefault(event, []).append(entry)
        hook_count += 1

    with open(f"{output_dir}/hooks/hooks.json", "w") as f:
        json.dump(hooks_json, f, indent=2)
        f.write("\n")

    # Agents
    agent_count = 0
    for name, agent in manifest["agents"].items():
        if agent["target"] not in ("base", "base-configurable"):
            continue
        src = agent["path"]
        if os.path.isfile(src):
            shutil.copy2(src, f"{output_dir}/agents/{name}")
        elif os.path.isdir(os.path.dirname(src)):
            # agents/<name>/AGENT.md → agents/<name>.md (flatten)
            if os.path.exists(src):
                dest_name = name if name.endswith(".md") else f"{name}.md"
                shutil.copy2(src, f"{output_dir}/agents/{dest_name}")
        else:
            print(f"  WARN: {src} not found, skipping")
            continue
        agent_count += 1

    # Rules
    rule_count = 0
    for name, rule in manifest["rules"].items():
        if rule["target"] not in ("base", "base-configurable"):
            continue
        src = rule["path"]
        if not os.path.exists(src):
            print(f"  WARN: {src} not found, skipping")
            continue
        shutil.copy2(src, f"{output_dir}/rules/{name}")
        rule_count += 1

    print(f"Plugin generated at {output_dir}/")
    print(f"  Hooks:  {hook_count}")
    print(f"  Agents: {agent_count}")
    print(f"  Rules:  {rule_count}")


if __name__ == "__main__":
    main()
