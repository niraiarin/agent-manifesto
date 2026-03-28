# Implementation Boundaries: Choosing the Right Approach

> "The best tools are the ones that work for both humans and machines." — Eric Holmes
>
> When you have a hammer, everything looks like a nail. When you have an LLM, everything looks like a prompt. This document defines when **not** to use an LLM — and when each implementation strategy is the right choice.
>
> **位置づけ:** Lean 形式化（`lean-formalization/Manifest/`）が公理系——拘束条件（T1〜T8）、経験的公準（E1〜E2）、基盤原理（P1〜P6）——を定義し、Constraints Taxonomy（`lean-formalization/Manifest/Ontology.lean` の L1–L6 および `Observable.lean` の V1–V7）が行動空間を定義する。本文書はその行動空間の中で**何をどう実装するか**の判断基準を定義する。
>
> **技術非依存性:** 本文書は特定のプラットフォーム（Claude Code, Codex CLI, Gemini CLI等）に依存しない原則を定義する。以下の用語は汎用概念として使用する:
> - **Skill** — エージェントに判断力・ワークフロー知識・ドメイン専門性を提供する、再利用可能な知識モジュール。プラットフォーム固有の実装形態は問わない。
> - **Hook** — 特定のイベント（ファイル保存、コミット等）に対して決定論的に実行される前処理・後処理。Git hooks等の一般概念。
> - **Config file** — エージェントの行動を規定する永続的な設定ファイル。プラットフォーム固有の命名（CLAUDE.md, AGENTS.md等）は問わない。
> - **Protocol-mediated integration** — 永続的な接続を通じて外部サービスと通信する統合方式（MCP等のプロトコル実装を含む）。

## Two Orthogonal Axes, Not a Linear Hierarchy

Implementation choices operate on two independent axes:

```
Knowledge Layer          Execution Layer
(what to do, why)        (how to invoke)

 ┌─ Nothing              ┌─ CLI (direct invocation)
 │  (agent already        │  Shell commands, scripts,
 │   knows enough)        │  existing tools
 │                        │
 ├─ Config file / Prompt  ├─ Protocol-mediated
 │  (lightweight config,  │  Persistent connections,
 │   preferences, rules)  │  service-specific APIs
 │                        │
 ├─ Skill                 └─ None (pure generation)
 │  (domain expertise,        Agent writes output
 │   workflow judgment)        directly
 │
 └─ Agent orchestration
    (complex orchestration,
     multi-agent systems)
```

**These axes are orthogonal.** A Skill may orchestrate CLI tools (Skill + CLI), enhance a protocol-mediated server with workflow knowledge (Skill + Protocol), or generate output using only the agent's built-in capabilities (Skill + no execution layer). The choice on each axis is independent.

---

## The Full Spectrum of Options

Before reaching for a Skill or protocol-mediated integration, consider whether a simpler approach suffices:

| Approach | When to use | Example |
|---|---|---|
| **Do nothing** | Agent already knows how | "Run the tests" — agent knows `pytest` |
| **Prompt engineering** | One-off instructions suffice | "Use our team's commit format: `type(scope): msg`" |
| **Config file** | Persistent preferences/rules | Code style, project conventions, banned patterns |
| **Hooks** | Deterministic pre/post actions | Auto-format on save, lint before commit |
| **CLI tool** | Well-defined, deterministic task | `prettier`, `black`, `gh pr list --json` |
| **Skill** | Judgment, workflow, domain expertise | PR review with team conventions, sprint planning |
| **Protocol-mediated** | External service with no CLI | Service requiring persistent connection, OAuth lifecycle |
| **Agent orchestration** | Multi-agent coordination | Complex pipelines with delegation and parallel execution |

**Default to the simplest approach that works.** Many problems that seem to need a Skill are better solved by a config file entry or a well-structured prompt.

---

## Execution Layer: CLI vs Protocol-Mediated Integration

### When CLI Is Sufficient

Eric Holmes' "[MCP is Dead. Long Live the CLI](https://ejholmes.github.io/2026/02/28/mcp-is-dead-long-live-the-cli.html)" argues that LLMs naturally use CLIs because they're trained on vast amounts of shell documentation and examples. His core points:

1. **LLMs already know CLIs** — trained on man pages, Stack Overflow, GitHub repos
2. **Same debuggability** — run the same command, see the same output
3. **Protocol-mediated integration adds unnecessary abstraction** — when a CLI already exists for the service

These arguments apply directly to the **execution layer**: when choosing *how to invoke* an external service, prefer CLI over protocol-mediated integration if a good CLI exists.

> **Scope of Holmes' argument:** Holmes specifically compares protocol-mediated vs CLI as execution interfaces. He does not address Skills, which operate on the knowledge layer. Extending his argument to conclude "Skills are unnecessary" would be a misreading — Skills provide domain expertise and judgment, not an execution interface.

### When CLI Falls Short

CLIs are designed for human consumption. Machine parsing can be fragile:

- **Unstructured output:** Not all CLIs support `--json`. Column-based output has variable widths and changes across versions.
- **Non-determinism:** Network-dependent CLIs, time-sensitive operations, and environment-specific behavior reduce reproducibility.
- **Development cost:** "Near zero cost per invocation" ignores the cost of writing, testing, and maintaining custom CLI scripts.

### When Protocol-Mediated Integration Is Justified

Protocol-mediated integration's value is in **persistent, authenticated connections** to external services — not in making API calls (`curl` does that):

- **No CLI equivalent exists** for the service (the primary justification)
- Session management or OAuth token lifecycle that no CLI handles
- Real-time bidirectional communication (push updates, event streams)
- Dynamic, service-specific capability surface that must be exposed to the agent

Protocol-mediated integration is **not** justified when:
- A CLI already exists (`gh`, `jira`, `aws`, `kubectl`, etc.)
- The interaction is stateless request/response (`curl` suffices)
- You're wrapping a REST API that doesn't need persistent connections

### Execution Layer Comparison

| Property | CLI | Protocol-mediated |
|---|---|---|
| Determinism | High (but not guaranteed — network, env, time) | Depends on backing service |
| Output structure | Human-readable; `--json` when available | Structured JSON guaranteed |
| Testability | Unit tests, CI/CD | Integration tests + server |
| Debuggability | Same command, same output | Transport logs |
| Composability | Pipes, `jq`, redirects | Protocol-mediated only |
| Auth | Battle-tested (SSO, kubeconfig, etc.) | Protocol-specific schemes |
| Runtime dependency | Shell only | Server process required |
| Initialization | Binary on disk | Child process lifecycle |

**CLI wins on debuggability and composability. Protocol-mediated wins on output structure and service coverage.** Choose based on the specific trade-offs relevant to your use case.

---

## Knowledge Layer: Nothing vs Config vs Skill

### The Knowledge Escalation

Unlike the execution layer (where CLI and protocol-mediated are alternatives), the knowledge layer *does* have a natural escalation:

```
Nothing → Config file → Skill → Agent orchestration
simpler                              more complex
```

**Default to nothing.** Escalate only when the simpler option genuinely can't express the needed knowledge.

### When to Use Each

**Nothing (agent's training data):**
- Standard CLI usage (`gh`, `aws`, `kubectl`, `docker`)
- Common programming patterns and best practices
- Well-known frameworks and libraries

> **Caveat:** Agent training knowledge is probabilistic, not guaranteed (T4). It may be outdated, lack organization-specific context, or miss recent changes. For *standard* CLI usage of *well-known* tools, this is usually sufficient. For organization-specific wrappers, custom flags, or internal tools, a Skill or config entry is warranted.

**Config file / System prompt:**
- Project conventions (naming, formatting, file structure)
- Team preferences ("always use bun instead of npm")
- Simple rules that don't require judgment ("never commit .env files")

**Skill:**
- Domain expertise that requires judgment (PR review with team conventions)
- Multi-step workflows with adaptive decision-making
- Creative output with specific style/quality standards
- Knowledge too complex or context-dependent for a flat config file

**Agent orchestration:**
- Multi-agent coordination with delegation
- Complex pipelines requiring parallel execution
- Systems needing programmatic control over agent behavior

> **P6（制約充足としてのタスク設計）との関係:** Agent orchestration への escalation は、T3（認知空間の有限性）、T7（時間・エネルギーの有限性）、T8（精度水準）の制約充足問題として導出される。単一エージェントの認知容量・時間内では要求精度を達成できないと判断された場合に、タスク分解・分散が必要になる。具体的な分散パターン（木構造的委譲、チーム並行処理等）はこの制約充足の解であり、制約の具体的な値に依存する。

---

## Design Principle: Cognitive Separation (P2)

P2（認知的役割分離、`lean-formalization/Manifest/Principles.lean` で形式化）は実装手段を問わないが、実装設計には直接的な含意がある。P2はT4（確率的出力）とE1（検証の独立性、経験的公準）から導出される。E1に依拠するためP群の中では根拠の強度が異なるが、実装設計においてこの原理は交渉不可能として扱う:

**生成と評価の分離は、品質保証の構造的前提条件である。**

| 分離の実現手段 | 適用場面 |
|-------------|---------|
| 別のエージェントによるレビュー | コード生成後のレビュー、設計提案の検証 |
| 外部ツールによる検証 | テスト実行、リンター、型チェッカー |
| 人間によるレビュー | アーキテクチャ決定、スコープ判断 |
| 時間的分離（別セッション） | 作成セッションとは別のセッションでの評価 |

手段の選択はタスクの性質とL3（リソース）に依存するが、
**生成物を生成者自身のみが評価する構造は、意図的に回避する。**
これは「検証が存在すること」だけでなく「検証が構造的に独立していること」を要求する。

**P5（確率的解釈）との関係:** 構造は毎回確率的に解釈される（T4）。つまりP2を「エージェントが遵守すべきルール」として記述するだけでは不十分。構造自体が、生成と評価が同一プロセスに閉じない設計になっていなければならない（例: テストが存在しないコードはマージできないという構造的制約）。

---

## Design Principle: Verification Timing (P4)

P4（劣化の可観測性）は「いつ観測するか」の時間的区別を含意する。検証は実行タイミングによって異なる性質を持つ:

| 検証タイミング | 性質 | 適用例 |
|-------------|------|-------|
| **静的検証（設計時）** | 構造の内部整合性を実行前に検証。決定論的。 | 型チェック、構造の無矛盾性検証、規約の整合性確認 |
| **動的検証（実行時）** | エージェント出力を実行中にリアルタイムで検証。 | スコープチェック、出力品質ゲート、リソース消費監視 |
| **静的＋動的（複合）** | 存在性は静的に、正確性は動的に検証。 | ロールバック計画の存在（静的）＋ロールバックの正確性（動的） |

**実装判断への含意:** 変数（V1〜V7）の観測手段を設計する際、その変数が静的に検証可能か動的にしか検証できないかを判断する。静的に検証可能な性質は構造に組み込む（P5の耐性設計）。動的にしか検証できない性質にはランタイムの検証メカニズムが必要（L3のリソースコストを伴う）。

---

## Skill Categories and CLI Applicability

Skills fall into three categories, and CLI expectations differ by category:

### Category 1: Document & Asset Creation

These skills use the agent's built-in capabilities to generate output. **No CLI component is expected or needed.** The skill's value is in design knowledge, style guides, and quality standards — pure knowledge-layer concerns.

A Category 1 skill with no CLI component is **normal**, not a yellow flag.

### Category 2: Workflow Automation

These skills orchestrate multi-step processes. **CLI integration is strongly recommended.** Deterministic subtasks within the workflow should be implemented as CLI tools:

- Build scripts in `scripts/` for deterministic subtasks
- Leverage existing CLI tools (`gh`, `jq`, `prettier`, `pandoc`)
- The Skill provides judgment and sequencing; CLI tools provide execution

```
┌─ Skill ──────────────────────────────────────┐
│  Judgment: what to do, in what order, why     │
│                                               │
│  ┌─ CLI layer ─────────────────────────────┐  │
│  │  scripts/validate.py    (self-built)    │  │
│  │  gh pr list             (existing tool) │  │
│  │  jq '.[] | select(..)'  (existing tool) │  │
│  │  scripts/aggregate.py   (self-built)    │  │
│  └─────────────────────────────────────────┘  │
└───────────────────────────────────────────────┘
```

A Category 2 skill with no CLI component **is** a yellow flag — it may mean deterministic work is leaking into the LLM.

### Category 3: Protocol-Mediated Enhancement

These skills add workflow knowledge on top of protocol-mediated server capabilities. **Protocol-mediated integration is expected, not a "last resort."** The skill coordinates API calls with domain expertise.

```
┌─────────────────────────────────────────────────┐
│  Skill (workflow knowledge)                      │
│  "Sprint planning best practices"                │
│       │                                          │
│       ▼                                          │
│  Protocol-mediated server (service connection)   │
│  "Project management API: fetch issues, create   │
│   tasks"                                         │
└─────────────────────────────────────────────────┘
```

A Category 3 skill using protocol-mediated integration is the **intended pattern**, not an anti-pattern.

---

## Environment Applicability

CLI-centric guidance applies differently across environments. The applicability depends on L5（プラットフォーム境界）:

| Guidance | CLI-capable env | API-only env | GUI-only env |
|---|---|---|---|
| CLI-First for Category 2 | **Strongly applies** | **Applies** (with code execution) | **Does not apply** (no CLI) |
| Category 1 Skills | Works | Works | **Primary environment** |
| Category 3 Skills | Works | Works | Works (with protocol config) |
| Config file | Supported | System prompt equivalent | Platform-dependent |
| Hooks | Platform-dependent | Not applicable | Not applicable |

GUI-only environments are a primary environment for Skill usage — especially Category 1 (document/design creation) and Category 3 (protocol-enhanced workflows). CLI-First guidance does not apply there.

---

## Decision Framework

### Step 1: Do You Need to Build Anything?

| Question | If YES |
|---|---|
| Can the agent already do this without any configuration? | **Do nothing.** Stop here. |
| Can a config file entry or system prompt cover this? | **Write a config entry.** Stop here. |
| Is this a deterministic pre/post action? | **Use Hooks.** Stop here. |

### Step 2: What Kind of Knowledge Is Needed?

| Question | If YES |
|---|---|
| Does this require domain expertise, judgment, or adaptive workflow? | → **Build a Skill.** Proceed to Step 3. |
| Is this a deterministic, well-defined operation? | → **Build a CLI tool.** Stop here. |

### Step 3: What Execution Layer Does the Skill Need?

| Question | Answer |
|---|---|
| Does the skill generate output using the agent's built-in capabilities? (Category 1) | **Skill only.** No execution layer needed. |
| Does the skill orchestrate deterministic subtasks? (Category 2) | **Skill + CLI.** Extract deterministic steps to `scripts/` or existing CLIs. |
| Does the skill need to connect to an external service? | **Does a CLI exist for the service?** → Skill + CLI. **No CLI exists?** → Skill + Protocol-mediated. |

### Litmus Tests

Before implementing, ask:

| # | Question | If YES | If NO |
|---|---|---|---|
| 1 | Does a CLI exist **and** does it cover the entire workflow without judgment? | **Use the CLI directly.** | → Q2 |
| 2 | Can I write a complete, deterministic spec for the full task? | **Build a CLI tool.** | → Q3 |
| 3 | Does this require interpreting ambiguous intent or applying judgment? | **Skill.** | → Q4 |
| 4 | Does this require persistent connection to a service with no CLI? | **Protocol-mediated** (possibly with Skill for workflow). | → Q5 |
| 5 | Is this a multi-step workflow mixing judgment and deterministic steps? | **Skill orchestrating CLI tools.** | → Q6 |
| 6 | Am I building this because it's cool, or because it solves a real problem? | Reconsider. | Reconsider harder. |

> **Note on Q1:** A CLI existing for a domain does not mean the workflow is covered. `gh` exists but doesn't know your team's PR review conventions. `terraform` exists but doesn't know your module structure policy. If the workflow requires judgment, a Skill is warranted even when the CLI exists — the Skill orchestrates the CLI with domain knowledge.

---

## Composability: Where CLI Shines

CLIs compose through pipes, `jq`, `grep`, and redirects. This is powerful and often the only practical approach for deterministic pipelines:

```bash
# Analyze a large Terraform plan: count resources with actual changes
terraform show -json plan.out | jq '[.resource_changes[] | select(.change.actions[0] == "no-op" | not)] | length'
```

**When a workflow is a deterministic pipeline, it should be a shell script, not a Skill.** Skills and protocol-mediated integrations compose only through agent-mediated reasoning, which burns tokens and introduces non-determinism.

However, many real workflows are **not** purely deterministic pipelines — they require judgment at decision points. In these cases, a Skill orchestrating CLI tools provides the best of both worlds.

---

## Anti-Patterns

### 1. "Protocol wrapper as HTTP client"

```python
# Anti-pattern: Protocol server that wraps a simple REST API
class WeatherServer:
    def get_weather(self, city):
        return requests.get(f"https://api.weather.com/{city}").json()
```

If `curl` can do the same thing, the protocol layer adds complexity without value.

### 2. "Protocol-mediated when a CLI already exists"

```
# Anti-pattern: Building a protocol server for GitHub
class GitHubServer:
    def list_prs(self, repo): ...
    def create_issue(self, repo, title, body): ...
```

`gh pr list`, `gh issue create` — already works, already debuggable, already composable.

### 3. "Skill as script wrapper"

```markdown
# Anti-pattern: Skill that just runs a script
## Instructions
Run `python scripts/process.py --input {file} --output {result}`
Return the result to the user.
```

If the Skill's only job is running a script and returning output, it should be a CLI tool directly.

### 4. "Restating standard CLI documentation"

```markdown
# Anti-pattern: Skill that teaches the agent what it already knows
## Instructions
To list pull requests, run `gh pr list`.
To view a PR, run `gh pr view {number}`.
```

Agents already know standard CLI usage from training data (T4 caveat applies). **However**, documenting *organization-specific* CLI usage is legitimate: custom flags, internal CLI wrappers, team-specific workflows, version-pinned behavior.

### 5. "Everything in one Skill"

```markdown
# Anti-pattern: Monolithic skill
## Instructions
1. Validate the YAML frontmatter (deterministic — should be CLI)
2. Format the markdown (deterministic — should be CLI)
3. Run the test suite (deterministic — should be CLI)
4. Analyze the results and suggest improvements (judgment — correct for Skill)
```

Steps 1–3 should be CLI tools called by the Skill. Only step 4 — the judgment part — belongs in the Skill itself. **(Applies to Category 2 skills; Category 1 skills may legitimately contain only judgment/creative steps.)**

### 6. "CLI for ambiguous input"

```bash
# Anti-pattern: CLI that tries to handle natural language
$ create-skill "something that helps with project management somehow"
```

If the input requires interpretation, forcing it through a CLI creates a bad UX.

### 7. "Self-review" (P2 violation)

```markdown
# Anti-pattern: Generator evaluates its own output
## Instructions
1. Write the implementation
2. Review your implementation for bugs
3. Fix any issues you find
4. Confirm the implementation is correct
```

P2（認知的役割分離）に反する。生成者による自己レビューは author bias により欠陥を体系的に見落とす。ステップ2-3は、外部ツール（テスト、リンター）、別のエージェント、または人間レビューに委ねるべき。

---

## The Practical Pain of Protocol-Mediated Integration

Beyond design philosophy, protocol-mediated integration has day-to-day friction that CLIs don't:

- **Initialization is flaky.** Servers are child processes that need to start, stay running, and not silently hang.
- **Re-auth never ends.** Multiple integrations mean authenticating each one separately.
- **Permissions are all-or-nothing.** You can allowlist tools by name, but can't scope to read-only operations or restrict parameters.

These are real costs that should be weighed against the benefits (structured output, service coverage, persistent connections).

---

## Implications for Skill Creation

### Phase 0: Triage (before any Skill work begins)

Before writing a skill definition:

1. **Determine the category.** Is this Category 1 (creation), Category 2 (workflow), or Category 3 (protocol enhancement)? This determines CLI expectations.
2. **Search for existing tools.** For Category 2, search for CLI tools covering parts of the workflow. If an existing CLI covers the entire workflow without judgment, the answer is "you don't need a Skill."
3. **Consider simpler alternatives.** Would a config file entry, a Hook, or a system prompt instruction suffice?

### During Skill Creation

| Phase | Gate |
|---|---|
| **Intent capture** | Determine category. For Category 2: "Does a CLI already cover the full workflow without judgment?" |
| **Workflow decomposition** | Category 2: Separate deterministic steps (→ `scripts/` or existing CLI) from judgment steps (→ skill definition). Category 1: Focus on quality standards and creative direction. |
| **Skill drafting** | Category 2: Skill orchestrates CLI tools; never put deterministic logic in instructions. Category 1/3: Skill contains knowledge appropriate to the category. |
| **Testing** | CLI components: unit tests, deterministic assertions. Skill components: eval/iteration loop. |

### The Output Standard

**Category 2 Skills must:**
- `scripts/`: Contain CLI tools for deterministic subtasks
- Skill definition: Reference existing CLI tools; contain only judgment, orchestration, and context
- `compatibility`: List required external CLI tools

**Category 1 Skills must:**
- Skill definition: Contain design knowledge, style guides, quality standards
- `assets/` (optional): Templates, fonts, reference materials
- No CLI component is expected

**Category 3 Skills must:**
- Skill definition: Contain workflow knowledge for protocol-mediated coordination
- Document required servers and their configuration

---

## References

- Eric Holmes, "[MCP is Dead. Long Live the CLI](https://ejholmes.github.io/2026/02/28/mcp-is-dead-long-live-the-cli.html)" (2026-02-28) — argues for CLI over protocol-mediated integration as an execution interface
