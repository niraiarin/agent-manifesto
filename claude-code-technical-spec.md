Now let me compile and deliver the comprehensive technical specification review based on all the documentation I've fetched:

---

# CLAUDE CODE TECHNICAL SPECIFICATION REVIEW
## Comprehensive Feature Architecture & Implementation Details

**Current Date:** March 22, 2026  
**Documentation Version:** Latest (fetched March 2026)  
**Status:** Complete technical specification covering all documented features

---

## A. HOOKS

### A.1 Exact Configuration Format

**File locations (priority order):**
- Session CLI: `--hooks` flag (JSON)
- Project scope: `.claude/settings.json` → `hooks` object
- User scope: `~/.claude/settings.json` → `hooks` object
- Plugin scope: `hooks/hooks.json` or inline in `plugin.json`

**Complete hook configuration schema:**

```json
{
  "hooks": {
    "[EventType]": [
      {
        "matcher": "regex_pattern_or_literal",
        "hooks": [
          {
            "type": "command|http|prompt|agent",
            "command": "path/to/script.sh",
            "url": "http://localhost:8080/webhook",
            "prompt": "Evaluate: $ARGUMENTS",
            "async": false,
            "timeout": 600,
            "statusMessage": "Custom status...",
            "once": false,
            "headers": { "Authorization": "Bearer $TOKEN" },
            "allowedEnvVars": ["TOKEN"],
            "model": "fast-model"
          }
        ]
      }
    ]
  }
}
```

### A.2 All Hook Event Types & Input/Output Schemas

**21 total events documented.** Complete schema for each:

#### SessionStart
- **Matcher values:** `"startup"`, `"resume"`, `"clear"`, `"compact"`
- **Stdin JSON:**
  ```json
  {
    "session_id": "abc123",
    "source": "startup|resume|clear|compact",
    "model": "claude-sonnet-4-6",
    "transcript_path": "/path/to/transcript.jsonl",
    "cwd": "/current/working/dir",
    "permission_mode": "default",
    "hook_event_name": "SessionStart"
  }
  ```
- **Stdout JSON (exit 0 only):**
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "additionalContext": "Text added to context"
    }
  }
  ```
- **Special:** `CLAUDE_ENV_FILE` environment variable available; stdout added as context
- **Supported handlers:** `command` only

#### InstructionsLoaded
- **Matcher values:** `"session_start"`, `"nested_traversal"`, `"path_glob_match"`, `"include"`, `"compact"`
- **Stdin JSON:**
  ```json
  {
    "file_path": "/path/to/CLAUDE.md",
    "memory_type": "User|Project|Local|Managed",
    "load_reason": "session_start|nested_traversal|path_glob_match|include|compact",
    "globs": ["**/*.ts"],
    "trigger_file_path": "/file/that/triggered/load",
    "parent_file_path": "/parent/instruction/file"
  }
  ```
- **Output:** Observability only (no decision control)
- **Matcher:** Optional (fires on all loads if no matcher)

#### UserPromptSubmit
- **Matcher support:** NONE (always fires)
- **Stdin JSON:**
  ```json
  {
    "prompt": "User's exact prompt text",
    "session_id": "...",
    "transcript_path": "...",
    "cwd": "..."
  }
  ```
- **Stdout JSON:**
  ```json
  {
    "decision": "block|allow",
    "reason": "Why blocked",
    "hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "additionalContext": "Context to add"
    }
  }
  ```
- **Can block:** YES (exit 2 blocks submission)
- **Stdout processing:** Plain text added as context (regardless of exit code)

#### PreToolUse
- **Matcher values:** Tool names: `"Bash"`, `"Edit"`, `"Write"`, `"Read"`, `"Glob"`, `"Grep"`, `"WebFetch"`, `"WebSearch"`, `"Agent"`, `"mcp__server__tool"`
- **Stdin JSON:**
  ```json
  {
    "tool_name": "Bash|Edit|Write|Read|Glob|Grep|WebFetch|WebSearch|Agent",
    "tool_input": { /* tool-specific */ },
    "tool_use_id": "toolu_01ABC123...",
    "session_id": "...",
    "cwd": "..."
  }
  ```
- **Stdout JSON (exit 0 only):**
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow|deny|ask",
      "permissionDecisionReason": "Why allowed/denied",
      "updatedInput": {
        "command": "modified bash command"
      },
      "additionalContext": "Context for Claude"
    }
  }
  ```
- **Can block:** YES (exit 2 blocks tool)
- **Matcher support:** Regex on tool name

#### PermissionRequest
- **Matcher values:** Tool names (same as PreToolUse)
- **Stdin JSON:**
  ```json
  {
    "tool_name": "Bash",
    "tool_input": { /* ... */ },
    "permission_suggestions": [
      {
        "type": "addRules|replaceRules",
        "rules": [{ "toolName": "Bash", "ruleContent": "rm -rf" }],
        "behavior": "allow|deny|ask",
        "destination": "localSettings|projectSettings|userSettings"
      }
    ]
  }
  ```
- **Stdout JSON (exit 0 only):**
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PermissionRequest",
      "decision": {
        "behavior": "allow|deny|ask",
        "updatedInput": { /* modified input */ },
        "updatedPermissions": [
          {
            "type": "addRules|replaceRules|removeRules|setMode|addDirectories|removeDirectories",
            "rules": [{ "toolName": "Bash", "ruleContent": "ls *" }],
            "behavior": "allow|deny|ask",
            "destination": "session|localSettings|projectSettings|userSettings"
          }
        ],
        "message": "Explanation if denied",
        "interrupt": false
      }
    }
  }
  ```
- **Can block:** YES (exit 2 denies)

#### PostToolUse & PostToolUseFailure
- **Input addition:** `tool_response` (success) or `error`, `is_interrupt` (failure)
- **Stdout JSON:**
  ```json
  {
    "decision": "block|allow",
    "reason": "Context or reason",
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse|PostToolUseFailure",
      "additionalContext": "Context for Claude",
      "updatedMCPToolOutput": "Replacement output (MCP tools only)"
    }
  }
  ```
- **Can block:** No (tool already executed)

#### Notification
- **Matcher values:** `"permission_prompt"`, `"idle_prompt"`, `"auth_success"`, `"elicitation_dialog"`
- **Stdin JSON:**
  ```json
  {
    "message": "Notification text",
    "title": "Optional title",
    "notification_type": "permission_prompt|idle_prompt|auth_success|elicitation_dialog"
  }
  ```
- **Output:** Observability only
- **Can block:** No

#### SubagentStart
- **Matcher values:** Agent type: `"Bash"`, `"Explore"`, `"Plan"`, custom names
- **Stdin JSON:**
  ```json
  {
    "agent_id": "agent-abc123",
    "agent_type": "Explore|Plan|Bash|custom"
  }
  ```
- **Stdout JSON:**
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "SubagentStart",
      "additionalContext": "Context to inject"
    }
  }
  ```
- **Can block:** No

#### SubagentStop
- **Matcher values:** Agent type
- **Stdin JSON:**
  ```json
  {
    "agent_id": "agent-abc123",
    "agent_type": "...",
    "agent_transcript_path": "...",
    "last_assistant_message": "Subagent's final response"
  }
  ```
- **Output:** Can block with exit 2 or `{"decision": "block"}`
- **Can block:** YES

#### Stop
- **Matcher support:** NONE (always fires)
- **Stdin JSON:**
  ```json
  {
    "last_assistant_message": "Claude's final response text",
    "stop_hook_active": false
  }
  ```
- **Output:** `{"decision": "block", "reason": "..."}`
- **Can block:** YES (exit 2 prevents Claude from stopping)

#### StopFailure
- **Matcher values:** `"rate_limit"`, `"authentication_failed"`, `"billing_error"`, `"invalid_request"`, `"server_error"`, `"max_output_tokens"`, `"unknown"`
- **Logging/observability only** (cannot block)

#### TeammateIdle
- **Matcher support:** NONE
- **Input:** `"teammate_name"`, `"team_name"`
- **Output:** Exit 2 sends stderr feedback; JSON `{"continue": false}` stops teammate
- **Can block:** YES

#### TaskCompleted
- **Matcher support:** NONE
- **Input:** `"task_id"`, `"task_subject"`, `"task_description"`, `"teammate_name"`, `"team_name"`
- **Output:** Exit 2 prevents completion; JSON controls behavior
- **Can block:** YES

#### ConfigChange
- **Matcher values:** `"user_settings"`, `"project_settings"`, `"local_settings"`, `"policy_settings"`, `"skills"`
- **Input:** `"source"`, `"file_path"`
- **Output:** `{"decision": "block", "reason": "..."}`
- **Note:** Cannot block `policy_settings`; can block others with exit 2

#### WorktreeCreate
- **Matcher support:** NONE
- **Input:** `{"name": "feature-auth"}`
- **Stdout:** Absolute path to created worktree
- **Supported handlers:** `command` only
- **Exit code:** Non-zero fails creation

#### WorktreeRemove
- **Matcher support:** NONE
- **Input:** `{"worktree_path": "/path"}`
- **Observability only**
- **Supported handlers:** `command` only

#### PreCompact & PostCompact
- **Matcher values:** `"manual"`, `"auto"`
- **Input additions:** `"trigger"`, and `"custom_instructions"` or `"compact_summary"`
- **Output:** PostCompact has no decision control

#### SessionEnd
- **Matcher values:** `"clear"`, `"resume"`, `"logout"`, `"prompt_input_exit"`, `"bypass_permissions_disabled"`, `"other"`
- **Observability only**
- **Default timeout:** 1.5 seconds (override: `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`)

#### Elicitation & ElicitationResult
- **Matcher values:** MCP server names
- **Input:** `"mcp_server_name"`, `"message"`, `"mode"`, `"requested_schema"`, `"url"`, `"elicitation_id"`
- **Stdout JSON:**
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "Elicitation|ElicitationResult",
      "action": "accept|decline|cancel",
      "content": {
        "field_name": "field_value"
      }
    }
  }
  ```
- **Can block:** YES

### A.3 Exit Code Semantics

| Exit Code | Behavior | JSON Processing | Effect |
|-----------|----------|-----------------|--------|
| **0** | Success | ✓ Parses stdout | Event proceeds; JSON controls behavior |
| **2** | Blocking error | ✗ Ignores JSON | Blocks event; stderr → Claude/user |
| **Other** | Non-blocking error | ✗ Ignores JSON | Continues; stderr in verbose mode |

**Exit code 2 blocking behavior by event:**

**Can block (21 events):** UserPromptSubmit, PreToolUse, PermissionRequest, SubagentStop, Stop, TeammateIdle, TaskCompleted, ConfigChange (except policy_settings), Elicitation, ElicitationResult, WorktreeCreate

**Cannot block (11 events):** InstructionsLoaded, PostToolUse, PostToolUseFailure, Notification, SubagentStart, StopFailure, SessionStart, SessionEnd, PreCompact, PostCompact, WorktreeRemove

### A.4 Matcher Syntax

**Format:** POSIX extended regex by default; literal strings accepted

**Matcher mapping by event:**

| Events | Matches | Format | Examples |
|--------|---------|--------|----------|
| PreToolUse, PostToolUse, PermissionRequest | Tool name | Regex | `"Bash"`, `"Edit\|Write"`, `"mcp__memory__.*"` |
| SubagentStart, SubagentStop | Agent type | Regex | `"Explore"`, `"Plan"`, `"custom-.*"` |
| SessionStart, SessionEnd | Session state | Literal | `"startup"`, `"resume"`, `"clear"` |
| Notification | Notification type | Literal | `"permission_prompt"`, `"auth_success"` |
| ConfigChange | Config source | Literal | `"user_settings"`, `"policy_settings"` |
| PreCompact, PostCompact | Trigger type | Literal | `"manual"`, `"auto"` |
| InstructionsLoaded | Load reason | Literal | `"session_start"`, `"path_glob_match"` |
| StopFailure | Error type | Literal | `"rate_limit"`, `"invalid_request"` |
| Elicitation, ElicitationResult | MCP server name | Regex | `"memory"`, `"slack.*"` |

**No matcher support (always fires):** UserPromptSubmit, Stop, TeammateIdle, TaskCompleted, WorktreeCreate, WorktreeRemove

**MCP tool matching:**
```
mcp__<server>__<tool>
mcp__memory__create_entities
mcp__filesystem__read_file

# Matcher patterns:
mcp__memory__.*          # all memory tools
mcp__.*__write.*         # write ops from any server
mcp__.*                  # all MCP tools
```

### A.5 Hook Limitations & Edge Cases

1. **No matcher support for:** UserPromptSubmit, Stop, TeammateIdle, TaskCompleted, WorktreeCreate, WorktreeRemove
2. **HTTP hooks are non-blocking:** Connection failures, timeouts, non-2xx responses don't stop execution
3. **Command hook stdout only processed on exit 0:** Exit 2 ignores JSON output
4. **Policy settings cannot be blocked:** Blocking decisions for ConfigChange with policy_settings source are ignored
5. **JSON validation required:** Stdout must be valid JSON only (shell profile output causes failure)
6. **Async hooks:** `type: "command"` with `async: true` runs background without blocking; only `command` type supports async
7. **Prompt/Agent hooks:** Use `$ARGUMENTS` placeholder for input JSON
8. **Environment variables:** Can use `$CLAUDE_PROJECT_DIR`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`
9. **Hook deduplication:** Identical handlers across matchers run once in parallel
10. **Permission cascade:** PreToolUse `"allow"` still respects deny/ask rules in permissions settings

### A.6 Can Hooks Invoke Subagents? Can They Modify Conversation?

**Subagent invocation:** NOT DOCUMENTED. Hooks execute before/after events but cannot directly spawn agents.

**Modify conversation:** 
- Hooks can inject context via `additionalContext` field
- Can modify tool input via `updatedInput` (PreToolUse only)
- Can modify MCP tool output via `updatedMCPToolOutput` (PostToolUse only for MCP)
- Cannot directly modify conversation history or prior messages
- Cannot emit new messages to Claude

### A.7 Async Hooks

**Configuration:**
```json
{
  "type": "command",
  "command": "./script.sh",
  "async": true
}
```

**Behavior:**
- Runs in background without blocking the current event
- Only `command` type supports async
- HTTP, prompt, agent hooks always block
- Fire-and-forget: no result processing, no exit code checking
- Useful for logging, metrics, cleanup operations

---

## B. SETTINGS & PERMISSIONS

### B.1 Exact settings.json Schema & All Valid Fields

**File locations (loaded in order):**
1. Managed scope: OS-specific (plist, registry, or `/etc/claude-code/`)
2. User scope: `~/.claude/settings.json`
3. Project scope: `.claude/settings.json`
4. Local scope: `.claude/settings.local.json` (gitignored)
5. CLI: `--config` flag (JSON inline)

**Complete schema:**

```json
{
  "model": "claude-sonnet-4-6|claude-opus-4-6|claude-haiku-4-5|default|opusplan|fast|inherit",
  "effort": "low|medium|high|max",
  "agent": "subagent-name",
  "enabledPlugins": {
    "plugin-name@marketplace": true,
    "another-plugin": false
  },
  "extraKnownMarketplaces": [
    "https://github.com/user/marketplace/marketplace.json"
  ],
  "strictKnownMarketplaces": false,
  "permissions": {
    "mode": "default|plan|acceptEdits|dontAsk|bypassPermissions",
    "allow": [
      "Bash",
      "Read",
      "Write(/src/**/*.ts)",
      "Bash(npm *)",
      "Agent(researcher)",
      "Skill(deploy)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Edit(.git/**)",
      "Agent(Explore)"
    ]
  },
  "sandbox": {
    "enabled": true,
    "pathPrefixes": [
      "/home/user/safe-dir",
      "/tmp/scratch"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "./format.sh" }
        ]
      }
    ]
  },
  "env": {
    "DEBUG": "1",
    "API_KEY": "$SECRET_API_KEY"
  },
  "autoMemoryEnabled": true,
  "autoMemoryDirectory": "~/.claude/projects/myproject/memory",
  "claudeMdExcludes": [
    "**/monorepo/other-team/.claude/rules/**"
  ],
  "theme": "dark|light|auto",
  "lineBreakMode": "soft|hard|wrap",
  "notificationHooks": [
    { "type": "command", "command": "./notify.sh" }
  ],
  "system-prompt-prefix": "You are...",
  "system-prompt-suffix": "Remember...",
  "models": {
    "allowedModels": ["claude-sonnet-4-6", "claude-haiku-4-5"],
    "defaultModel": "claude-sonnet-4-6",
    "restrictedModel": "claude-haiku-4-5"
  },
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "$GITHUB_TOKEN" }
    },
    "local-db": {
      "command": "/usr/local/bin/my-server",
      "cwd": "/path/to/workdir"
    }
  },
  "channelsEnabled": true,
  "statusLine": {
    "enabled": true,
    "command": "~/.claude/status-line.sh"
  },
  "vimMode": false,
  "attributionSettings": {
    "githubUsername": "myusername",
    "enableContributionMetrics": true
  },
  "fileSuggestion": {
    "excludePatterns": ["**/.git/**", "**/node_modules/**"]
  },
  "summarySettings": {
    "saveTranscripts": true,
    "location": "~/.claude/transcripts"
  },
  "languageDetection": true,
  "cleanupPeriodDays": 30,
  "maxOutputTokens": 4096,
  "maxInputTokens": 100000,
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
  "CLAUDE_CODE_DISABLE_BACKGROUND_TASKS": "0",
  "CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD": "1"
}
```

### B.2 Permission Pattern Syntax

**Format:** `Tool(specifier)` for fine-grained, `Tool` for all uses

**Complete syntax:**

```json
{
  "allow": [
    "Bash",                              // Any bash command
    "Bash(npm *)",                       // Prefix match: npm, npm install, npm test
    "Bash(git commit|git push)",         // Multiple commands (regex alternation)
    "Edit",                              // Any file edit
    "Edit(/src/**/*.ts)",                // Glob pattern: TypeScript in src/
    "Edit(.claude/**)",                  // Deny .claude internal files
    "Write",                             // Any file write
    "Read(/etc/**)",                     // Read-only access to /etc
    "Glob",                              // Any glob search
    "Grep",                              // Any grep search
    "WebFetch",                          // Any HTTP fetch
    "WebSearch",                         // Any web search
    "Agent",                             // Any subagent
    "Agent(Explore)",                    // Specific subagent
    "Agent(Explore|Plan)",               // Multiple subagents
    "Skill(deploy)",                     // Specific skill
    "Skill(deploy *)",                   // Skill prefix (with arguments)
    "MCP(github)",                       // Specific MCP server
    "mcp__github__*",                    // MCP server tools by name
    "mcp__*__search_*"                   // Tool pattern matching
  ]
}
```

**Wildcard patterns:**
- `*`: matches any characters (not `/` for paths)
- `**`: recursive glob (matches `/`)
- `[abc]`: character class
- `{a,b}`: brace expansion not supported in rules
- Regex alternation: `|` (e.g., `npm|yarn`)

### B.3 Scope Hierarchy & Exact Merge Behavior

**Scope priority (highest to lowest):**
1. **Managed** (enforced)
2. **Local** (`.claude/settings.local.json`)
3. **Project** (`.claude/settings.json`)
4. **User** (`~/.claude/settings.json`)

**Merge behavior by field type:**

| Field type | Merge behavior | Example |
|------------|---|----------|
| Scalar (string, number, boolean) | Highest priority wins | If Project has `model: sonnet`, User has `opus`, Project wins |
| Array (permissions, hooks) | **Arrays MERGE** (concat + dedupe) | Deny rules from all scopes combine |
| Object (env, mcpServers) | **Deep merge** | `env` vars from all scopes available; highest scope wins for conflicts |
| Nested object (permissions.allow, permissions.deny) | **Arrays MERGE** | Deny rules from Managed + Project + User all applied |

**Example merge scenario:**
```
User settings.json:
  permissions.deny: ["Bash(rm -rf /)"]
  env: { DEBUG: "0" }

Project settings.json:
  permissions.deny: ["Write(.git)"]
  env: { DEBUG: "1" }

Result:
  permissions.deny: ["Bash(rm -rf /)", "Write(.git)"]
  env: { DEBUG: "1" }  (project wins)
```

### B.4 What Permissions Can & Cannot Control

**CAN control:**
- Direct tool use: Bash, Edit, Write, Read, Glob, Grep
- Web access: WebFetch, WebSearch
- MCP tools: all MCP server capabilities
- Subagents: specific agent types by name
- Skills: specific skills by name
- File paths: glob patterns for read/write scope

**CANNOT control:**
- Model selection (model field is separate from permissions)
- Hooks execution (configured separately)
- MCP server loading (separate .mcp.json config)
- Context window size
- Session timeout
- Output formatting
- Theme/appearance settings

**Enforcement notes:**
- Permissions are "gating" not "hiding": denied tools don't appear in prompts but aren't secret
- Permission prompts can be auto-approved with hooks or permission modes
- Sandboxing is separate from permissions (both enforce isolation)

---

## C. AGENTS (SUBAGENTS)

### C.1 Exact .claude/agents/ File Format

**Location:** `.claude/agents/<name>.md` or `~/.claude/agents/<name>.md` or plugin `agents/`

**Complete frontmatter schema:**

```yaml
---
name: code-reviewer
description: Expert code reviewer. Use proactively after code changes.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet|opus|haiku|inherit|full-model-id
permissionMode: default|acceptEdits|dontAsk|bypassPermissions|plan
maxTurns: 20
skills:
  - api-conventions
  - error-handling-patterns
mcpServers:
  memory:
    type: stdio
    command: npx
    args: ["@modelcontextprotocol/server-memory"]
  github: "github"  # reference by name (reuse parent connection)
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate-command.sh"
memory: user|project|local|none
background: false
effort: low|medium|high|max
isolation: worktree
---

You are a code reviewer...
```

**Frontmatter field details:**

| Field | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `name` | Yes | string | N/A | lowercase, letters, hyphens, max 64 chars; becomes `/name` command |
| `description` | Yes | string | N/A | Used for delegation decisions; include "use proactively" for auto-invocation |
| `tools` | No | comma-separated | inherit all | Allowlist: only these tools available |
| `disallowedTools` | No | comma-separated | none | Denylist: remove from inherited tools |
| `model` | No | alias\|full ID\|"inherit" | inherit | model alias or claude-sonnet-4-6 format |
| `permissionMode` | No | enum | inherit parent | default, acceptEdits, dontAsk, bypassPermissions, plan |
| `maxTurns` | No | integer | unlimited | Max agentic turns before stop |
| `skills` | No | array | none | Full skill content injected at startup |
| `mcpServers` | No | object\|array | inherit parent | Inline definitions scoped to agent |
| `hooks` | No | object | none | Event handlers for agent lifecycle (PreToolUse, PostToolUse, Stop) |
| `memory` | No | user\|project\|local | none | Persistent memory directory for cross-session learning |
| `background` | No | boolean | false | Run in background without blocking conversation |
| `effort` | No | low\|medium\|high\|max | inherit | Claude model effort level |
| `isolation` | No | "worktree" | none | Run in git worktree (auto-cleanup if no changes) |

**Markdown body becomes system prompt:** Everything after closing `---` is the agent's system prompt (not loaded into parent conversation).

**Priority resolution (agents with same name):**
1. CLI `--agents` flag (session only)
2. `.claude/agents/` (project)
3. `~/.claude/agents/` (user)
4. Plugin agents (lowest)

### C.2 Context Isolation: What is Shared, What Isn't

**Shared with parent conversation:**
- Working directory
- File system (read/write access per permissions)
- MCP servers (unless overridden with `mcpServers` field)
- Environment variables
- CLAUDE.md and rules (loaded fresh at agent startup)
- Permissions context (with possible mode override)

**NOT shared:**
- Conversation history (parent messages don't carry over)
- Agent's full conversation history (exists in separate transcript)
- Agent's system prompt (completely different from parent)
- Agent's context window (independent allocation)
- Agent-level skills (only loaded if `skills` field specified)

**Isolation mechanism:**
- Each subagent runs in its own process with separate context
- Transcripts stored separately at `~/.claude/projects/{project}/subagents/agent-{agentId}.jsonl`
- Auto-compaction at ~95% capacity (configurable: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`)

### C.3 Can Hooks Trigger Subagents? Can Subagents Communicate?

**Hooks triggering subagents:** NOT SUPPORTED. Hooks cannot directly spawn agents. However:
- `SubagentStart` and `SubagentStop` hooks can react when agents spawn (observability)
- Agent-level hooks (in frontmatter) can conditionally validate tool use

**Subagent-to-subagent communication:**
- NOT SUPPORTED in single-session mode
- Only parent conversation can mediate between subagents
- Subagent results return to parent; parent decides next agent
- For true inter-agent communication, use [agent teams](#d-agent-teams)

**Agent-to-parent communication:**
- `SendMessage` tool: subagent can message parent with agent ID as recipient
- Parent receives agent ID after subagent completes
- Can resume subagent with `SendMessage` using the agent ID

### C.4 Worktree Isolation for Agents

**Configuration:**
```yaml
isolation: worktree
```

**Behavior:**
- Agent gets its own git worktree (temporary clone of repo)
- Worktree path: `~/.claude/worktrees/{name}/`
- Auto-cleanup: deleted if agent makes no file changes
- Persisted: if agent writes files, worktree survives for inspection
- WorktreeCreate hook: can override creation logic
- WorktreeRemove hook: fires on cleanup

**Use case:** Safe experimentation without affecting main branch

---

## D. AGENT TEAMS

### D.1 Exact Configuration & Launch

**Enable flag (required):**
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Launch (natural language):**
```text
/Create an agent team to refactor the authentication module in parallel.
Spawn 3 teammates: one for frontend, one for backend, one for tests.
```

**Launch (via CLI):**
```bash
claude --teammate-mode in-process|tmux  # Sets display mode
```

**Display modes:**
- `in-process` (default): all teammates in main terminal, Shift+Down cycles
- `tmux`: separate panes (requires tmux or iTerm2)
- `auto`: tmux if available, in-process otherwise

### D.2 Shared Task List Mechanism

**Storage:** `~/.claude/teams/{team-name}/` and `~/.claude/tasks/{team-name}/`

**Task structure:**
```json
{
  "id": "task-001",
  "subject": "Implement authentication",
  "description": "Add login/signup endpoints",
  "status": "pending|in-progress|completed",
  "assignee": "teammate-id",
  "dependencies": ["task-000"],
  "created_at": "2026-03-22T...",
  "completed_at": null
}
```

**Task coordination:**
- Teammates claim unassigned tasks using file locking (prevents race conditions)
- Tasks with unresolved dependencies blocked until dependencies complete
- Lead creates tasks; teammates self-claim or lead assigns
- Task completion auto-unblocks dependent tasks

### D.3 Inter-Agent Messaging Protocol

**Message types:**
1. **Direct message:** `message(teammate_id, text)` - to one teammate
2. **Broadcast:** `broadcast(text)` - to all teammates
3. **Idle notification:** automatic when teammate finishes
4. **Lead notification:** automatic when lead finishes turn

**Delivery:** Messages automatic (pushed to inbox); no polling required

**Message routing:**
- Teammates see messages in their session
- Lead can cycle through teammates to read/respond
- Messages are session-scoped (lost when session ends)

### D.4 Lead vs Teammate Roles: Exact Capabilities

**Lead capabilities:**
- Spawn teammates
- Create/assign tasks
- Message individual teammates or broadcast
- Approve plans (if plan mode enabled)
- Shut down teammates
- Clean up team resources
- Make autonomous decisions about team direction
- Allocate work based on expertise

**Teammate capabilities:**
- Claim unassigned tasks
- Work independently on assigned tasks
- Message other teammates
- Request shutdown
- Send updates to lead
- Cannot spawn other teammates (no nesting)
- Cannot create/manage other teammates
- Cannot clean up team (lead only)

**Permission inheritance:**
- Teammates start with lead's permission mode
- Can override individually after spawn: `change permission mode of researcher to bypassPermissions`
- Cannot set per-teammate permissions at spawn time

### D.5 Experimental Status & Limitations

**Known limitations:**
- No session resumption with in-process teammates (`/resume` doesn't restore them)
- Task status can lag (teammates sometimes fail to mark tasks complete)
- Shutdown can be slow (waits for current request to finish)
- One team per session only
- No nested teams (teammates cannot spawn teams)
- Lead is fixed (cannot transfer leadership)
- Permissions set at spawn (cannot change all teammates at once)
- Split panes require tmux or iTerm2 (not VS Code integrated terminal, Windows Terminal, Ghostty)

**Cost implications:**
- Each teammate has own context window
- Token usage scales linearly with team size
- Recommended: 3-5 teammates for most tasks
- Coordination overhead increases with team size

---

## E. SKILLS

### E.1 Exact .claude/skills/ File Format

**Location:** `.claude/skills/<skill-name>/SKILL.md` or `~/.claude/skills/<skill-name>/SKILL.md` or plugin `skills/`

**Complete frontmatter schema:**

```yaml
---
name: api-conventions
description: API design patterns for this codebase. Use when writing API endpoints.
argument-hint: "[endpoint-name]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Bash, Grep
model: inherit|sonnet|opus|haiku|full-model-id
effort: low|medium|high|max
context: inline|fork
agent: Explore|Plan|general-purpose|custom-name
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate.sh"
---

Your skill instructions...
```

**Frontmatter field details:**

| Field | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `name` | No | string | directory name | `/name` command; lowercase, hyphens only |
| `description` | Recommended | string | first paragraph | When to use; Claude uses for auto-invocation |
| `argument-hint` | No | string | none | Hint for `/skill-name [args]` autocomplete |
| `disable-model-invocation` | No | boolean | false | `true` = only user can invoke (no auto-invoke) |
| `user-invocable` | No | boolean | true | `false` = only Claude can invoke (hidden from `/`) |
| `allowed-tools` | No | comma-separated | inherit parent | Tools available without permission prompts |
| `model` | No | alias\|full ID\|"inherit" | inherit | Model for skill execution |
| `effort` | No | low\|medium\|high\|max | inherit | Effort level override |
| `context` | No | inline\|fork | inline | inline=main conversation, fork=subagent |
| `agent` | No | agent name | general-purpose (if fork) | Which subagent type for `context: fork` |
| `hooks` | No | object | none | Lifecycle hooks (PreToolUse, PostToolUse only) |

**Markdown body:** Instructions or task definition (becomes context or subagent prompt)

**String substitutions in skill content:**

```yaml
name: my-skill
description: Do something with $ARGUMENTS
---

Your task: $0  # first argument
Secondary input: $ARGUMENTS[1]  # second argument
All args: $ARGUMENTS

Session ID: ${CLAUDE_SESSION_ID}
Skill dir: ${CLAUDE_SKILL_DIR}
```

### E.2 How Triggering Works: Description Matching Mechanism

**Discovery:** Skill descriptions loaded into context at session start (not full content)

**Auto-invocation (Claude decides):**
- Claude reads description from context
- Recognizes when task matches description
- Proactively invokes skill if `disable-model-invocation: false`
- Keywords in description critical for matching

**Manual invocation:**
- User types `/skill-name` or `/skill-name args`
- Always available if `user-invocable: true`
- Description doesn't matter for manual invocation

**Matching quality factors:**
- Specific keywords: "deploy", "security review", "generate API docs"
- Include trigger phrase: "use when", "use proactively"
- Avoid vague descriptions: good="Implement database migrations", bad="Do stuff"

**Context loading:**
- Descriptions always loaded (2% of context window budget, min 16KB fallback)
- Full skill content loaded on invocation
- Supporting files (reference.md, examples.md) loaded on demand

### E.3 Context: Fork vs Inline — Exact Behavior Difference

**Inline (default):**
```yaml
context: inline
```
- Skill content injected into main conversation context
- Claude can reference conversation history
- Claude uses parent's tools and permissions
- Results stay in main conversation
- Subagent compaction doesn't affect skill

**Fork:**
```yaml
context: fork
agent: Explore
```
- Skill becomes prompt for isolated subagent
- Subagent type determines tools, model, permissions
- Parent conversation history NOT passed to subagent
- Results summarized and returned to parent
- Subagent transcript stored separately

**Practical difference:**

| Aspect | Inline | Fork |
|--------|--------|------|
| Context | Shares conversation | Isolated |
| Tools | Parent's tools (filtered by allowed-tools) | Agent type's tools |
| Permission prompts | Yes (parent permissions apply) | Pre-approved at spawn |
| Output verbosity | Full response | Summary |
| Use case | Reference docs, conventions | Research, parallel work |

### E.4 Tool Restrictions in Skills

**Configuration:**
```yaml
allowed-tools: Read, Grep, Bash
```

**Behavior:**
- Listed tools available without permission prompts when skill active
- Unlisted tools still require permission (unless auto-approved globally)
- Works for both inline and fork context

**Example restrictive skill:**
```yaml
name: code-reviewer
description: Code review specialist
allowed-tools: Read, Glob, Grep, Bash
# Cannot Edit or Write (not allowed)
```

### E.5 Can Skills Spawn Agents?

**Direct spawning:** NOT SUPPORTED via frontmatter

**Workarounds:**
1. **Fork context:** `context: fork` already runs in subagent context
2. **Skill-in-skill:** Skill can reference another skill (both inline)
3. **Bash invocation:** Skill can invoke `/agent` or `/subagent` via bash command

**Example (implicit agent use):**
```yaml
name: research-async
context: fork
agent: Explore  # implicit: this skill runs in Explore subagent
---

Research the following topic...
```

---

## F. RULES (.claude/rules/)

### F.1 Exact File Format

**Location:** `.claude/rules/<name>.md` (any name, discovered recursively)

**Frontmatter (optional):**
```yaml
---
paths:
  - "src/api/**/*.ts"
  - "lib/**/*.ts"
  - "*.md"
---

# API Development Rules

- All endpoints must validate input
- Use standard error format
- Include OpenAPI comments
```

**Behavior:**
- Rules without `paths` field: loaded unconditionally at session start
- Rules with `paths` field: lazy-loaded when Claude reads matching files
- Can be nested in subdirectories: `.claude/rules/backend/`, `.claude/rules/frontend/`

**Path glob syntax:**

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All TypeScript files anywhere |
| `src/**/*` | All files under src/ |
| `*.md` | Markdown files in root only |
| `src/api/**/*.ts` | TypeScript in src/api/ |
| `src/**/*.{ts,tsx}` | TS and TSX in src/ |

### F.2 Lazy Loading Behavior

**When loaded:**
- **Unconditional rules:** Session start (like CLAUDE.md)
- **Path-specific rules:** When Claude opens matching file
- **Not loaded:** Until trigger condition met

**Unloading:**
- Rules stay in context once loaded
- Not unloaded until session ends

**User-level rules:** `~/.claude/rules/` loaded before project rules (project can override)

### F.3 Interaction with CLAUDE.md

**Loading order:**
1. Managed policy CLAUDE.md (cannot be excluded)
2. Ancestor CLAUDE.md files (walking up tree)
3. Project CLAUDE.md (`./CLAUDE.md` or `./.claude/CLAUDE.md`)
4. User CLAUDE.md (`~/.claude/CLAUDE.md`)
5. Nested CLAUDE.md (discovered in subdirectories, lazy-loaded)
6. Unconditional rules (`.claude/rules/` without `paths`)
7. Path-specific rules (`.claude/rules/` with `paths`, lazy-loaded)

**Precedence:** More specific locations override broader ones

**Exclude mechanism:**
```json
{
  "claudeMdExcludes": [
    "**/monorepo/other-team/.claude/rules/**",
    "/full/path/to/CLAUDE.md"
  ]
}
```

---

## G. SCHEDULED TASKS (/loop)

### G.1 Exact Configuration: Interval Syntax, Cron Support

**User-facing `/loop` syntax:**
```text
/loop 30m check if the deployment finished
/loop check the build every 2 hours
/loop 5m /review-pr 1234
```

**Underlying cron expression (5-field):**
```
minute hour day-of-month month day-of-week

Examples:
*/5 * * * *        every 5 minutes
0 * * * *          every hour on the hour
7 * * * *          every hour at :07
0 9 * * *          every day at 9am
0 9 * * 1-5        weekdays at 9am
30 14 15 3 *       March 15 at 2:30pm
```

**Interval units:**
- `s` for seconds (rounded up to nearest minute)
- `m` for minutes
- `h` for hours
- `d` for days

**Defaults:**
- No interval specified: every 10 minutes
- Seconds rounded up (7s → 1m)
- Non-even intervals rounded (7m → 5m or 10m)

**Tools available:**
- `CronCreate`: Schedule new task
- `CronList`: List all tasks
- `CronDelete`: Cancel task

### G.2 Three-Day Expiry Behavior

**Expiry mechanism:**
- Recurring tasks automatically expire 3 days after creation
- Final execution happens at expiry
- Task automatically deleted after final run
- One-shot tasks deleted after single execution
- No notifications sent before expiry

**Extends expiry:**
- Cancel and recreate task before 3-day mark
- Use Desktop scheduled tasks for durable scheduling
- Use GitHub Actions for unattended automation

### G.3 What Can Be Scheduled

**Allowed:**
- Any prompt/question
- CLI commands (wrapped in `/command` syntax)
- Skill invocations (`/skill-name args`)
- Sub-commands (`/loop 5m /loop 10m /review`)

**Session-scoped limitations:**
- Only fire while Claude Code running
- No catch-up for missed fires
- No persistence across restarts
- Max 50 scheduled tasks per session

### G.4 Limitations

1. **Session-scoped only:** Tasks die when session ends
2. **No catch-up:** Missed fires don't replay
3. **Polling-based:** Check every second for due tasks
4. **Fire timing:** Between turns, not during Claude's response
5. **Jitter:** Up to 10% of period late (capped at 15 min)
6. **3-day expiry:** Recurring tasks auto-delete after 3 days
7. **No guaranteed delivery:** If session crashes, tasks lost

---

## H. CHANNELS

### H.1 How to Receive Push Messages

**Architecture:**
- Channel = MCP server that pushes events into session
- Declared with `capabilities.experimental['claude/channel']`
- Receives webhook data and forwards to Claude

**Setup:**
1. Create MCP server with channel capability
2. Add to `.mcp.json` in project or `~/.claude.json`
3. Emit `notifications/claude/channel` when event occurs
4. Claude receives as `<channel>` tag in context

**Example MCP server setup:**
```json
{
  "mcpServers": {
    "webhook": {
      "command": "bun",
      "args": ["./webhook.ts"]
    }
  }
}
```

### H.2 Configuration Format

**MCP server configuration:**
```ts
const mcp = new Server(
  { name: 'webhook', version: '0.0.1' },
  {
    capabilities: {
      experimental: { 'claude/channel': {} },
      tools: {}  // for two-way replies
    },
    instructions: 'Events from webhook channel arrive as <channel source="webhook" ...>. Reply with the reply tool.'
  }
)
```

**Notification format:**
```ts
await mcp.notification({
  method: 'notifications/claude/channel',
  params: {
    content: 'Event body text',
    meta: {
      source: 'ci',
      severity: 'high',
      run_id: '1234'
    }
  }
})
```

**Arrives in Claude as:**
```xml
<channel source="webhook" severity="high" run_id="1234">
Event body text
</channel>
```

### H.3 Security Model

**Gate inbound messages:**
- Check sender identity before emitting
- Use allowlist of approved senders
- Gate on sender, not room/chat (prevents group chat injection)

**One-way vs two-way:**
- One-way: channel → Claude only
- Two-way: expose reply tool for Claude → channel

**Approval flow:**
- During research preview: custom channels need `--dangerously-load-development-channels`
- Org policy enforced: Team/Enterprise admins must enable channels
- Platform-specific security: Telegram/Discord include pairing flows

### H.4 Integration Patterns

**CI integration:**
```ts
// Webhook receives CI failure
POST /webhook/ci
{ "build": "failed", "url": "https://ci.example.com/run/123" }

// Becomes:
<channel source="ci" build="failed" url="...">Failed</channel>

// Claude automatically investigates logs and fixes
```

**Chat bridge:**
```ts
// DM received on Telegram
// TG bot forwards to channel:
<channel source="telegram" sender_id="12345" chat_id="67890">
Help me deploy to prod
</channel>

// Claude replies:
reply_tool(chat_id="67890", text="Starting deployment...")
```

---

## I. PLUGINS

### I.1 plugin.yaml Schema (Note: It's plugin.json, not YAML)

**Location:** `.claude-plugin/plugin.json`

**Complete schema:**

```json
{
  "name": "deployment-tools",
  "version": "2.1.0",
  "description": "Deployment automation tools",
  "author": {
    "name": "Dev Team",
    "email": "dev@company.com",
    "url": "https://github.com/team"
  },
  "homepage": "https://docs.example.com",
  "repository": "https://github.com/user/plugin",
  "license": "MIT",
  "keywords": ["deployment", "ci-cd"],
  "commands": ["./custom/deploy.md", "./custom/check.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

**Field details:**

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| `name` | Yes | string | kebab-case, used for namespacing |
| `version` | No | semver | Auto-detected from marketplace.json if omitted |
| `description` | No | string | Plugin purpose |
| `author` | No | object | Author metadata |
| `homepage` | No | string | Documentation URL |
| `repository` | No | string | Source code URL |
| `license` | No | string | License identifier (MIT, Apache-2.0) |
| `keywords` | No | array | Discovery tags |
| `commands` | No | string\|array | Additional command files |
| `agents` | No | string\|array | Additional agent definitions |
| `skills` | No | string\|array | Additional skill directories |
| `hooks` | No | string\|array\|object | Hook config files or inline |
| `mcpServers` | No | string\|array\|object | MCP config files or inline |
| `outputStyles` | No | string\|array | Output style definitions |
| `lspServers` | No | string\|array\|object | Language server configs |

### I.2 What Can Be Bundled

**Components:**
- Skills (with supporting files, scripts)
- Agents (subagent definitions)
- Commands (markdown commands, legacy)
- Hooks (event handlers)
- MCP servers (tool integrations)
- LSP servers (code intelligence)
- Output styles (display formatting)
- Settings (default configuration)

**Files/resources:**
- Scripts (shell, python, node)
- Configuration files
- Documentation
- Templates
- Examples

**NOT bundled:**
- Compiled binaries (reference from PATH)
- Node modules (install via hook or separate)
- Large datasets (reference externally)

### I.3 Installation Scopes

**Scopes (priority highest → lowest):**

| Scope | Location | File | Shared | Use case |
|-------|----------|------|--------|----------|
| Managed | OS-specific | managed-settings.json | Organization-wide | Enforced policies |
| Project | `.claude/settings.json` | enabledPlugins | Team (version control) | Project-specific tools |
| Local | `.claude/settings.local.json` | enabledPlugins | You only (gitignored) | Personal workspace setup |
| User | `~/.claude/settings.json` | enabledPlugins | All your projects | Personal tools |

**Plugin installation:**
```bash
claude plugin install plugin-name@marketplace --scope user|project|local
```

### I.4 Version Management

**Versioning scheme:**
- Semantic: `MAJOR.MINOR.PATCH`
- MAJOR: breaking changes
- MINOR: backward-compatible features
- PATCH: bug fixes

**Version location:**
- Primary: `plugin.json` version field
- Secondary: `marketplace.json` version entry
- If both exist: `plugin.json` takes priority

**Update mechanism:**
- Claude Code checks version on load
- If version changed: uses cached plugin update
- If version not changed: uses cached version (caching!)
- Bump version to force user update

**Data persistence:**
- `${CLAUDE_PLUGIN_DATA}`: persistent directory across updates
- `${CLAUDE_PLUGIN_ROOT}`: plugin directory (replaced on update)
- Recommended: store dependencies and state in `${CLAUDE_PLUGIN_DATA}`

---

## J. MCP SERVERS

### J.1 .mcp.json Format

**Locations:**
- User scope: `~/.claude.json` (mcp Servers field, or projectPaths)
- Project scope: `.mcp.json` (checked into version control)
- Plugin: `.mcp.json` in plugin root, or inline in `plugin.json`

**Complete schema:**

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "$GITHUB_TOKEN",
        "GITHUB_API_URL": "https://api.github.com"
      },
      "cwd": "/path/to/workdir"
    },
    "memory": {
      "type": "sse",
      "url": "http://localhost:3000/sse"
    },
    "slack": {
      "type": "http",
      "url": "http://localhost:8765",
      "timeout": 30000
    },
    "database": {
      "type": "stdio",
      "command": "./db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/db.conf"]
    }
  }
}
```

**Server types:**

| Type | Transport | Use case |
|------|-----------|----------|
| `stdio` (or omit) | stdin/stdout | Local processes |
| `http` | HTTP POST | Remote HTTP servers |
| `sse` | Server-sent events | Event streams |
| `ws` | WebSocket | Bidirectional streaming |

**Environment variables:**
- `${CLAUDE_PLUGIN_ROOT}`: plugin installation directory
- `${CLAUDE_PLUGIN_DATA}`: persistent data directory
- Shell vars: `$GITHUB_TOKEN`, `$API_KEY` (from system env)

### J.2 Local vs Remote Server Configuration

**Local (stdio):**
```json
{
  "command": "./path/to/binary",
  "args": ["--arg1", "value1"],
  "env": { "VAR": "value" },
  "cwd": "/workdir"
}
```
- Spawned as subprocess
- Communicates over stdin/stdout
- Can use relative paths (resolved relative to `.mcp.json` location)

**Remote (http/sse/ws):**
```json
{
  "type": "http",
  "url": "https://mcp-server.example.com",
  "timeout": 30000
}
```
- Long-lived connection to remote server
- No local subprocess spawned
- Must be running before session starts
- No env vars (already baked into remote)

### J.3 Scope Hierarchy & Precedence

**Scope loading order (highest → lowest):**
1. Managed policy: `/etc/claude-code/.mcp.json` (cannot be excluded)
2. Project: `.mcp.json` (checked into version control)
3. User: `~/.claude.json` under `mcpServers` field
4. Plugin: `.mcp.json` in plugin directory
5. CLI: `--mcp-servers` flag (JSON)

**Merge behavior:**
- Server names are deduplicated (higher scope wins)
- `mcpServers` object is deep-merged
- CLI `--mcp-servers` can override project/user scopes

**Example merge:**
```
User ~/.claude.json:
  mcpServers: { github: {...}, memory: {...} }

Project .mcp.json:
  mcpServers: { github: {...}, slack: {...} }

Result:
  github: from Project (higher priority)
  memory: from User
  slack: from Project
```

### J.4 Tool Search & Discovery

**MCP Tool Search feature:**
- Discovers tools from all connected MCP servers
- Searches by name, description, or capability
- Reduces context consumed by tool descriptions
- Lazy-loads tool details on demand

**Configuration:**
```json
{
  "mcpServers": {
    "github": {
      "toolSearch": {
        "enabled": true,
        "maxResults": 10
      }
    }
  }
}
```

**How it works:**
1. Claude asks tool search for matching tools
2. Tool search returns minimal info (name, summary)
3. Claude selects tool to use
4. Full schema loaded on demand before calling

**Limits:**
- Output limit: warnings if tool descriptions exceed threshold
- Server must implement standard tool list operation
- Not all MCP servers support tool search

---

## K. PLAN MODE

### K.1 How It Works Exactly

**Entry:**
- User explicitly requests: "Use plan mode" or `/plan`
- Claude proposes plan for complex task
- Or `claude --model opusplan` (automatic)

**Behavior:**
- Claude enters read-only exploration mode
- Tools available: Read, Glob, Grep only (no Write, Edit, Bash)
- Can gather context but cannot modify files
- Produces detailed plan with code examples
- User reviews and approves before implementation

**Exit:**
- User says "go ahead" or approves plan
- Claude transitions to implementation mode
- Can now use full tool set
- Executes plan or refined version

**Subagent delegation:**
- Plan subagent uses Plan agent type (read-only)
- Researches context thoroughly
- Returns plan to parent for approval

### K.2 What Tools Are Available in Plan Mode

**Allowed:**
- Read (any file)
- Glob (directory search)
- Grep (text search)
- Agent (can spawn Plan subagent for detailed research)

**Blocked:**
- Write, Edit (file modifications)
- Bash (command execution)
- WebFetch (restricted)
- WebSearch (restricted)

**Permission mode:** `plan` automatically set

---

## L. CHECKPOINTS

### L.1 What Is Captured vs Not Captured

**Captured:**
- Every user prompt (creates checkpoint)
- File edits made via Write and Edit tools
- Code state before each edit
- Conversation history and messages
- Persists across session resume

**NOT captured:**
- Bash command side effects (files modified by bash)
- External changes (manual edits outside Claude Code)
- Changes from concurrent sessions
- Environment variable changes
- Working directory changes

**Access:**
- `Esc` + `Esc` or `/rewind` to open rewind menu
- Scrollable list of prompts with timestamps
- Can restore code, conversation, or both
- Can summarize from checkpoint forward

### L.2 How to Revert Programmatically

**Built-in:**
- No programmatic API for checkpoints
- `/rewind` command is interactive only
- Checkpoints stored in session transcript (JSONL format)

**Workaround (git-based):**
- Use `git stash`, `git reset`, `git revert` in bash
- Checkpoints complement but don't replace version control

**Files location:**
- Session transcripts: `~/.claude/projects/{project}/{sessionId}/`
- Checkpoint data: embedded in main transcript
- Format: JSONL with `type: "checkpoint"` entries

---

## M. HEADLESS MODE

### M.1 CLI Flags for Headless Execution

**Primary flag:**
```bash
claude -p "Your prompt here"   # or --print
```

**All compatible flags:**

```bash
# Input/output
-p, --print                 Run non-interactively, print response
--output-format json|text|stream-json
--json-schema '{...}'       Structured output schema
--append-system-prompt "..."
--system-prompt "..."
--include-partial-messages  Stream partial results

# Context
--continue                  Continue most recent conversation
--resume SESSION_ID         Continue specific session
--add-dir /path            Add directory to context
--cwd /path                Set working directory

# Tools & permissions
--allowedTools "Bash,Read,Edit"
--disallowedTools "WebFetch"
--dangerously-skip-permissions

# Configuration
--model claude-sonnet-4-6
--config /path/to/settings.json
--agents '{...}'           Inline agent definitions
--mcp-servers '{...}'      Inline MCP config

# Behavior
--effort low|medium|high|max
--verbose                  Show debug info
--session-name "my-task"   Name the session
```

### M.2 What's Different from Interactive Mode

**Interactive (`claude` alone):**
- Full TUI with multi-line input
- Can use `/` commands (`/memory`, `/rewind`, `/loop`, etc.)
- Skills available via `/` invocation
- Can approve tools with prompts
- Streaming response with real-time display

**Headless (`claude -p`):**
- Single-line prompt only
- No `/` commands (describe task instead)
- Skills available but not via `/` syntax
- Tools must be pre-approved with `--allowedTools`
- Full response returned after completion
- Can stream with `--output-format stream-json`

**Capabilities not available in headless:**
- `/memory`, `/rewind`, `/loop` (use separate `claude` calls)
- `/agents`, `/plugin` (configure ahead of time)
- `/config`, `/debug` (use CLI flags)
- Interactive `/` commands generally

### M.3 Scripting Patterns

**Single request:**
```bash
claude -p "Summarize this codebase" --output-format json | jq '.result'
```

**Structured output:**
```bash
claude -p "Extract function names from auth.py" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"functions":{"type":"array","items":{"type":"string"}}},"required":["functions"]}' \
  | jq '.structured_output.functions'
```

**Streaming:**
```bash
claude -p "Write a poem" \
  --output-format stream-json \
  --verbose \
  --include-partial-messages \
  | jq -rj 'select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'
```

**Multi-turn conversation:**
```bash
session=$(claude -p "Start a review" --output-format json | jq -r '.session_id')
claude -p "Focus on performance" --resume "$session" --output-format json
claude -p "Summarize findings" --resume "$session" --output-format json
```

**Auto-approve tools:**
```bash
claude -p "Run tests and fix failures" \
  --allowedTools "Bash,Read,Edit" \
  --output-format json
```

---

## N. CLAUDE.MD

### N.1 Loading Hierarchy

**Resolution order (entire tree is loaded, then merged):**

1. **Managed policy** (OS-specific path, cannot be excluded)
2. **Ancestor CLAUDE.md** (walking up directory tree from cwd)
   - `/project/CLAUDE.md`
   - `/project/subdir/CLAUDE.md` (lazy-loaded when entering subdir)
   - `/CLAUDE.md` (if at root)
3. **Project CLAUDE.md** (`.claude/CLAUDE.md` or `./CLAUDE.md`)
4. **User CLAUDE.md** (`~/.claude/CLAUDE.md`)
5. **User rules** (`~/.claude/rules/*.md`)
6. **Project rules** (`.claude/rules/*.md`, lazy-loaded by path match)
7. **Additional directories** (via `--add-dir`, if `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`)

**Merge behavior:**
- All applicable CLAUDE.md files concatenated in order above
- More specific (project) overrides broader (user)
- Later rules override earlier ones

**Lazy loading:**
- Parent CLAUDE.md: loaded at session start
- Subdirectory CLAUDE.md: loaded when Claude reads files in that directory
- Path-specific rules: loaded when file matches `paths` glob

### N.2 @imports Syntax

**Format:**
```markdown
See @README for overview
Conventions: @docs/api-conventions.md
Personal: @~/.claude/my-preferences.md
```

**Behavior:**
- `@path/to/file` expands to file content
- Relative paths: resolved relative to file containing import
- Absolute paths: `/path/to/file` or `~/home/file`
- Max depth: 5 hops (prevents cycles)
- First use requires approval dialog

**Example:**
```markdown
# Project Setup

## Build
@package.json

## Conventions
- @docs/git-workflow.md
- @docs/code-style.md

## Personal Preferences
- @~/.claude/my-project-preferences.md
```

### N.3 Compact Instructions Section Behavior

**Compact command:**
- `/compact` compresses conversation from current turn forward
- Generates AI summary of messages
- Original messages preserved in transcript
- Frees context space

**Behavior of CLAUDE.md in compaction:**
- CLAUDE.md fully preserved (re-injected fresh)
- Not included in summary
- Can be re-injected if needed via hook

**Size recommendation:**
- Target under 200 lines per CLAUDE.md
- Longer files consumed more context, less adherence
- Split via `@imports` or `.claude/rules/` if needed

### N.4 Size Recommendations & Limits

**Practical limits:**

| Metric | Recommendation | Limit | Notes |
|--------|---|---|---|
| Single CLAUDE.md | <200 lines | None (enforced) | Quality degrades significantly over 200 lines |
| Total loaded CLAUDE.md | <4000 lines | None | Consumed as context; impacts adherence |
| Rules in memory | <50 files | None | Each rule loaded per-session |
| Import depth | 1-2 hops | 5 max | Deeper imports slow loading |
| Import file size | <5000 lines | None | Very large imports consume context |

**Context impact:**
- CLAUDE.md loaded into every session (consumes tokens)
- Skill descriptions: 2% of context window (fallback 16KB)
- Rules: Full content at session start or when loaded

**Optimization:**
- Move detailed content to separate files (reference with `@`)
- Use `.claude/rules/` for path-specific instructions
- Keep main CLAUDE.md focused on essentials
- Use skills for task-specific workflows (load on demand)

---

## UNDOCUMENTED OR UNCLEAR FEATURES

**Items mentioned in docs but NOT fully specified:**

1. **Prompt-based hooks:** How `$ARGUMENTS` placeholder works in prompt hook evaluation (example shows usage but not exact mechanism)
2. **Agent-based hooks:** Complete example for how to structure agent hook prompts (only high-level description)
3. **Plan Mode subagent delegation:** Exact mechanism for how approval flows from Plan agent back to parent
4. **Context fork behavior in skills:** How much of CLAUDE.md is reloaded in forked skill subagent (documented as "loaded fresh" but not detailed)
5. **Tool search scalability:** Limits on number of MCP tools before tool search becomes necessary (not quantified)
6. **Checkpoint restore atomicity:** Whether checkpoint restore is atomic or incremental (not specified)
7. **Session ID generation:** Algorithm/format for session IDs (not documented)
8. **MCP oauth refresh:** When/how OAuth tokens are refreshed for long-running sessions
9. **Subagent inheritance of MCP servers:** Exact precedence when subagent's mcpServers field has name conflicts with parent's `.mcp.json`
10. **Hook deduplication algorithm:** Exact logic for determining "identical" hooks (by command string? by full config?)

---

## SPECIFIC RECOMMENDATIONS FOR DESIGN IMPLEMENTATION

**For system design considerations:**

1. **Hooks are NOT blocking by default:** Design assumes all hooks are non-blocking unless explicitly configured with exit code 2. This is critical for preventing performance bottlenecks.

2. **Scope precedence is strict:** The hierarchy (Managed > Local > Project > User) is enforced; no way to alias or remap scopes. Design systems expecting this order.

3. **Checkpoints are session-local:** No distributed checkpoint mechanism. Each session gets its own checkpoint history. Design accordingly for multi-session systems.

4. **Agent teams are experimental:** Do not build critical system dependencies on them. Document limitations around resumption and task coordination.

5. **Skills descriptions consume fixed context budget:** 2% of context window with 16KB fallback. Design skill discovery systems expecting this constraint.

6. **MCP tool search is optional:** Not all MCP servers implement tool search. Have fallback behavior for servers that don't.

7. **Rule lazy-loading is by exact path match:** Not by semantic rules or inheritance. Path matching must be exact glob patterns.

8. **CLAUDE.md merges rather than replaces:** Multiple CLAUDE.md files in tree are concatenated, not overridden. Design for accumulation not replacement.

---

## SOURCES

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks.md)
- [Claude Code Settings](https://code.claude.com/docs/en/settings.md)
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents.md)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams.md)
- [Claude Code Skills](https://code.claude.com/docs/en/skills.md)
- [Claude Code Memory & CLAUDE.md](https://code.claude.com/docs/en/memory.md)
- [Claude Code Scheduled Tasks](https://code.claude.com/docs/en/scheduled-tasks.md)
- [Claude Code Channels Reference](https://code.claude.com/docs/en/channels-reference.md)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference.md)
- [Claude Code MCP Integration](https://code.claude.com/docs/en/mcp.md)
- [Claude Code Checkpointing](https://code.claude.com/docs/en/checkpointing.md)
- [Claude Code Headless Mode](https://code.claude.com/docs/en/headless.md)
