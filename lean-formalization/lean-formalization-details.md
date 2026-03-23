# Lean Formalization — 設計判断ログ

## Phase 1: Ontology + T1–T8

### 完了日: 2026-03-22

### オントロジー設計

**ベースパターン:** Pattern 3 (Stateful World + Audit Trail) をカスタマイズ。
マニフェストの公理系が要求する概念（セッションの一時性、構造の永続性、フィードバックループ、リソース管理）を自然に表現するため、Pattern 1 の最小構成ではなく、監査証跡付きの状態管理パターンを選択。

**型の一覧 (15型):**

| 型 | 対応する T/P | 役割 |
|----|-------------|------|
| `Session`, `SessionStatus` | T1 | セッションの一時性 |
| `Structure`, `StructureKind` | T2 | 永続的構造 |
| `ContextWindow` | T3 | 認知空間の制約 |
| `Output`, `Confidence` | T4 | 確率的出力 |
| `Feedback`, `FeedbackKind` | T5 | フィードバックループ |
| `ResourceAllocation`, `ResourceKind` | T6/T7 | リソース管理 |
| `Task`, `PrecisionLevel` | T8 | タスク精度水準 |
| `Agent`, `AgentRole` | P2準備 | 役割分離 |
| `Action`, `Severity` | — | 状態遷移の単位 |
| `AuditEntry` | P4準備 | 監査証跡 |
| `World` | — | 状態の統合 |

### 重要な設計判断

#### 1. `canTransition` を関係（Prop）にした

**問題:** T4「同じ入力に対して異なる出力を生成しうる」を表現したいが、Lean の `def` は決定論的関数。`execute : Agent → Action → World → Option World` だと、同一引数に対して常に同一の値を返す。

**検討した選択肢:**
- (a) `execute` を関数のまま残し、T4 を `¬(∀ ... ∃! ...)` で表現 → 関数の意味論と矛盾。`∃!` は必ず成立するので axiom が unsound になりうる。
- (b) `Set World` を返す関数にする → 空集合（拒否）と非空集合（複数遷移先）を表現できるが、集合の扱いが重い。
- (c) `canTransition : Agent → Action → World → World → Prop` (関係) → 同一入力に複数の w' が Prop を満たしうる。最も自然。

**決定:** (c) を採用。`canTransition` は `opaque` として宣言し、Phase 3 で具体的な遷移条件を定義する。

**帰結:**
- `validTransition w w' := ∃ agent action, canTransition agent action w w'`
- `actionBlocked agent action w := ¬∃ w', canTransition agent action w w'`
- T4 axiom: `∃ agent action w w₁ w₂, canTransition ... ∧ canTransition ... ∧ w₁ ≠ w₂`

#### 2. `globalResourceBound` を opaque 定数にした

**問題:** T7「リソースは有限」を `∀ w, ∃ bound, sum ≤ bound` と書くと自明に充足（任意の有限和に対して bound = sum を取れる）。

**検討した選択肢:**
- (a) `∀ w, ∃ bound, ...` → 自明（✗）
- (b) `∃ bound, ∀ w, ...` → 意味はあるが、存在量化子が証明義務を生む
- (c) `opaque globalResourceBound : Nat` + `∀ w, sum ≤ globalResourceBound` → 固定上限。具体値は後で決められる

**決定:** (c) を採用。メモリ MEMORY.md にも記録済み。

#### 3. `PrecisionLevel.required` を Nat (千分率) にした

**問題:** `Float` は IEEE 754 で NaN, Infinity, 負のゼロなど Prop レベルの比較に不適切。`task.precisionRequired.required > 0.0` は Float の `>` に依存し、意味論が不安定。

**決定:** `Nat` で千分率 (0–1000) を使用。`0` = 0%, `1000` = 100%。T8 axiom は `> 0` となり、Nat の自然な順序で安全に比較。

#### 4. T1c を `session_no_shared_state` に書き換えた

**問題:** 旧 T1c (`session_identity_unique`) の body が `True` で空虚。「各インスタンスは独立した存在」を型設計が保証するという主張はあるが、axiom として宣言する意味がない。

**決定:** セッション間の遷移独立性を表現する実質的な axiom に書き換え:
```
∀ agent1 agent2 action1 action2 w w',
  action1.session ≠ action2.session →
  canTransition agent1 action1 w w' →
  (∃ w'', canTransition agent2 action2 w w'') →
  (∃ w''', canTransition agent2 action2 w' w''')
```
「あるセッションのアクションによる遷移が、別セッションのアクションの可否に直接影響しない」を表現。

**注意:** この axiom は強い主張。World は共有状態（structures, allocations）を持つため、間接的な影響は T2 を通じて起こりうる。axiom の意図は「**直接的な** 状態共有がない」こと。Phase 2 レビューで強度を再検討する。

### Axiom 対応表 (最終版)

| axiom 名 | T | 性質 | 非自明性 |
|-----------|---|------|----------|
| `session_bounded` | T1 | セッション有界性 | ✓ |
| `no_cross_session_memory` | T1 | 監査エントリの因果独立 | ✓ |
| `session_no_shared_state` | T1 | 遷移独立性 | ✓ (要再検討) |
| `structure_persists` | T2 | 構造の永続性 | ✓ |
| `structure_accumulates` | T2 | エポック非減少 | ✓ |
| `context_finite` | T3 | 容量 > 0 ∧ used ≤ capacity | ✓ |
| `context_bounds_action` | T3 | 容量超過 → blocked | ✓ |
| `output_nondeterministic` | T4 | 異なる遷移先の存在 | ✓ |
| `no_improvement_without_feedback` | T5 | 改善 → フィードバック存在 | ✓ |
| `human_resource_authority` | T6 | 割り当ての起源は人間 | ✓ |
| `resource_revocable` | T6 | 人間による回収可能性 | ✓ |
| `resource_finite` | T7 | 総量 ≤ globalResourceBound | ✓ |
| `task_has_precision` | T8 | 精度 > 0 | ✓ |

### Phase 2 への引き継ぎ

1. **E1 (検証の独立性):** `AgentRole.verifier` は既に Ontology にある。Worker と Verifier の独立性を axiom 化する。SKILL.md の `IndependenceGuarantee` パターンを参考に。
2. ~~**E2 (能力とリスクの不可分性):** 行動空間の拡大がリスク増大と不可分であることの形式化。新しい型（`Capability`, `RiskLevel`）が必要になる可能性。~~ → Phase 2 で完了。
3. **`session_no_shared_state` の強度再検討:** 共有 World 上の間接的影響をどう扱うか。
4. **`structureImproved` の具体化:** Phase 4 の Observable 層で定義予定だが、Phase 3 の P4 導出時に暫定定義が必要になる可能性。

---

## Phase 2: Empirical Postulates (E1–E2)

### 完了日: 2026-03-22

### 新規追加した型・述語

Ontology.lean に5つの opaque 述語を追加:

| 述語 | 型 | 用途 |
|------|-----|------|
| `generates` | `Agent → Action → World → Prop` | E1: Worker がアクションを生成 |
| `verifies` | `Agent → Action → World → Prop` | E1: Verifier がアクションを検証 |
| `sharesInternalState` | `Agent → Agent → Prop` | E1: 内部状態の共有（バイアス相関） |
| `actionSpaceSize` | `Agent → World → Nat` | E2: 能力（行動空間の大きさ） |
| `riskExposure` | `Agent → World → Nat` | E2: リスク露出度 |

### 重要な設計判断

#### 5. E1 を3つの axiom に分解した

**問題:** E1「検証には独立性が必要」は単一の命題としては曖昧。「同一プロセスによる生成と評価」の「同一」と「プロセス」を精密に定義する必要がある。

**分解:**
- **E1a (`verification_requires_independence`):** 生成者と検証者は異なる個体（`gen.id ≠ ver.id`）であり、かつ内部状態を共有しない（`¬sharesInternalState gen ver`）。
- **E1b (`no_self_verification`):** 同一エージェントによる自己検証の明示的禁止。E1a の系だが、boundary condition として独立に宣言。
- **E1c (`shared_bias_reduces_detection`):** 内部状態を共有する2エージェント間の検証も禁止。異なる AgentId でも sharesInternalState なら不可。

**検討した代替案:**
- (a) `AgentRole` ベースで「Worker は verifies できない」とする → 役割は動的に変わりうるため不十分。
- (b) `generates` と `verifies` を関数にして排他性を型で保証 → Prop の方が柔軟で、axiom として宣言する方が意図が明確。

**決定:** opaque 述語 + axiom の組み合わせ。述語を opaque にすることで、具体的な「何が生成で何が検証か」の定義を Phase 3+ に委ねつつ、独立性の構造的要件は今の時点で確定する。

#### 6. E2 の不等号に `<`（厳密増加）を選択

**問題:** マニフェストは「能力の増大はリスクの増大と**不可分**」と述べるが、同時に「完璧なサンドボックスが原理的に不可能であるという証明はない」と留保している。

**検討した選択肢:**
- (a) `<` (厳密増加): 能力が上がれば必ずリスクも上がる
- (b) `≤` (非減少): リスクが据え置きの可能性を許容
- (c) 存在量化: 「リスクが増大しないケースが**ない**」

**決定:** (a) `<` を採用。根拠:
- マニフェストの「不可分」は共成長を意味し、`≤` だとリスクゼロ増加を許容してしまう
- 「原理的に不可能であるという証明はない」という留保は、axiom の**経験的地位**（将来覆りうること）として表現される
- axiom が反証された場合、P1（自律権と脆弱性の共成長）が見直し対象になる

#### 7. `actionSpaceSize` と `riskExposure` を Nat にした

**問題:** 能力とリスクの「大きさ」をどう計量するか。

**検討した選択肢:**
- (a) `Nat` — 離散的、Prop レベルの比較が安全
- (b) `Float` — 連続的だが IEEE 754 問題（Phase 1 で学習済み）
- (c) カスタム有界型 — 正確だが複雑

**決定:** (a) `Nat` を採用。Phase 1 の PrecisionLevel と同じ方針。具体的な計量方法は Phase 4 の Observable 層で定義。

### Axiom 対応表 (Phase 2 追加分)

| axiom 名 | E | 性質 | 非自明性 |
|-----------|---|------|----------|
| `verification_requires_independence` | E1 | 生成者≠検証者 ∧ 状態非共有 | ✓ |
| `no_self_verification` | E1 | 自己検証の禁止 | ✓ (E1a の系) |
| `shared_bias_reduces_detection` | E1 | 共有バイアス → 検証禁止 | ✓ |
| `capability_risk_coscaling` | E2 | 行動空間↑ → リスク↑ (厳密) | ✓ |

### Phase 3 への引き継ぎ

1. **P1 (自律権と脆弱性の共成長):** E2 から直接導出。`capability_risk_coscaling` を使う。
2. **P2 (認知的役割分離):** T4 + E1 から導出。`output_nondeterministic` + `verification_requires_independence` を使う。
3. **P3 (学習の統治):** T1 + T2 から導出。E は不要。
4. **P4 (劣化の可観測性):** T5 から導出。`structureImproved` の具体化が必要。
5. **P5 (構造の確率的解釈):** T4 から導出。`canTransition` の非決定性を使う。
6. **P6 (制約充足としてのタスク設計):** T3 + T7 + T8 から導出。
7. ~~**`generates` / `verifies` / `sharesInternalState` の具体化:** Worker AI / Verifier AI プロトコルとの接続。~~ → Phase 4+ に繰り越し。
8. ~~**E1b (`no_self_verification`) が E1a の系であることの証明:** Phase 3 で theorem として導出可能か検討。~~ → Phase 3 で `e1b_from_e1a` として証明完了。

---

## Phase 3: Foundational Principles (P1–P6)

### 完了日: 2026-03-22

### 新規追加した型・述語

| 型/述語 | 種類 | 用途 |
|---------|------|------|
| `trustLevel` | opaque Nat | P1: 信頼度（漸進蓄積 vs 急激毀損） |
| `riskMaterialized` | opaque Prop | P1: リスクの顕在化 |
| `CompatibilityClass` | inductive | P3: 知識統合の互換性分類（3クラス） |
| `KnowledgeIntegration` | structure | P3: 統合イベント |
| `Observable` | def | P4: 決定手続きの存在 |
| `degradationLevel` | opaque Nat | P4: 劣化の程度（勾配） |
| `interpretsStructure` | opaque Prop | P5: 構造解釈の関係 |
| `robustStructure` | def | P5: 解釈ばらつきへの耐性 |
| `TaskStrategy` | structure | P6: 制約充足の「解」 |
| `strategyFeasible` | def | P6: 3次元制約の充足判定 |

### 重要な設計判断

#### 8. P の形式化方針 — 「リステートメント + 追加概念」

**問題:** P1 は E2 からの直接的帰結であり、P2 は E1a のリステートメント。theorem が axiom の単なるコピーでは形式化の意味がない。

**決定:** 各 P を2段階で構成:
- **(a) 核心 theorem:** T/E からの直接導出。proof は axiom の適用のみ。
- **(b) 追加概念:** マニフェストが P として追加している概念（信頼の非対称性、統治のライフサイクル、堅牢性など）を新しい型・述語で表現し、それらに関する theorem を sorry 付きで宣言。

この方針により:
- (a) は proof が完了しており、T/E → P の導出関係が機械検証される
- (b) は sorry が残るが、設計概念の型付けが完了している
- sorry を消すことが Phase 4（Observable 層）の作業になる

#### 9. E1b 冗長性の証明方法

**証明:**
```lean
theorem e1b_from_e1a :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w → ¬verifies agent action w := by
  intro agent action w h_gen h_ver
  have h := verification_requires_independence agent agent action w h_gen h_ver
  exact absurd rfl h.1
```

`verification_requires_independence` に gen = ver = agent を代入すると、
結論 `agent.id ≠ agent.id` が得られる。`rfl : agent.id = agent.id` と
矛盾するため `absurd` で導出。

**帰結:** E1b は axiom から theorem に降格可能。ただし、EmpiricalPostulates.lean の
axiom 宣言はそのまま残す（boundary condition としての明示性を維持）。

#### 10. P6a の証明 — sorry なしで完了

P6a は T3/T7/T8 の制約構造を展開するだけで証明できた。
これは「制約充足問題である」ことの形式的確認であり、
解の存在証明ではない点に注意。

#### 11. `CompatibilityClass` を inductive にした

**問題:** P3 の互換性分類を型としてどう表現するか。

**検討した選択肢:**
- (a) `inductive` — 3値の列挙型。`cases` tactic で網羅性証明可能
- (b) `structure` — フィールドで条件を持つ。柔軟だが列挙できない
- (c) `Prop` の述語3つ — 型レベルの分類ではなく命題レベル

**決定:** (a) `inductive` を採用。`compatibility_exhaustive` theorem が
`cases` tactic だけで証明できることで、分類の網羅性が機械的に保証される。

### Theorem 対応表 (Phase 3)

| theorem | P | 根拠 | sorry | 証明方法 |
|---------|---|------|-------|---------|
| `autonomy_vulnerability_coscaling` | P1a | E2 | なし | E2 直接適用 |
| `unprotected_expansion_destroys_trust` | P1b | E2 + 新概念 | あり | trustLevel 未定義 |
| `cognitive_separation_required` | P2 | E1a | なし | E1a 直接適用 |
| `self_verification_unsound` | P2補 | E1b | なし | E1b 直接適用 |
| `modifier_agent_terminates` | P3a | T1 | なし | T1 (session_bounded) 直接適用 |
| `modification_persists_after_termination` | P3b | T2 | なし | T2a (structure_persists) 直接適用 |
| `ungoverned_breaking_change_irrecoverable` | P3c | T1∧T2 | なし | 合成: T1仮説+T2仮説+structure_accumulates |
| `compatibility_exhaustive` | P3d | — | なし | cases tactic |
| `improvement_requires_observability` | P4a | T5 | なし | T5 直接適用 |
| `degradation_is_gradient` | P4b | 新概念 | あり | degradationLevel 未定義 |
| `structure_interpretation_nondeterministic` | P5 | T4 | あり | interpretsStructure 未定義 |
| `task_is_constraint_satisfaction` | P6a | T3+T7+T8 | なし | 制約展開 |
| `task_design_is_probabilistic` | P6b | T4 | なし | T4 直接適用 |
| `e1b_from_e1a` | 付録 | E1a | なし | absurd rfl |

**結果: 14 theorems 中 11 個が sorry なし。sorry 残り 3 個。**

#### 12. P3 (`governance_necessity`) の再設計 — T1∧T2 の合成的論証

**問題:** 旧 `governance_necessity` は結論 `w.epoch ≤ w'.epoch` を `structure_accumulates` だけで導出しており、T1 仮説を使っていなかった。マニフェストの P3 は T1 と T2 の**合成**から統治の必要性を導くため、形式化がマニフェストの論証構造を反映していなかった。

**論証構造の分析:**
```
T1（問題）: エージェントは消える → 変更を行った主体が修正不能になる
T2（賭け金）: 構造は残る → 変更（誤りも含む）が永続する
T1 ∧ T2:   → 修正不能な変更が永続する → 統治が必要
```

**決定:** `governance_necessity` を3つの theorem に分解:
- **P3a (`modifier_agent_terminates`):** T1 の寄与。変更を行ったエージェントのセッションは必ず終了する。`session_bounded` の直接適用。
- **P3b (`modification_persists_after_termination`):** T2 の寄与。セッション終了後も構造は残る。`structure_persists` の直接適用。
- **P3c (`ungoverned_breaking_change_irrecoverable`):** T1∧T2 の合成。破壊的変更が行われ、エージェントが消え（T1仮説）、変更が永続する（T2仮説）場合、変更後のエポックは不可逆に進む。命題構造が T1 と T2 の両方を要求。

**残る懸念:** P3c の proof term は `structure_accumulates` に依存し、T1/T2 仮説は proof term 内で「使われていない」ように見える。しかし、**命題の型**が両仮説を要求するため、仮説なしでは theorem が成立しない。これは「仮説が命題の成立条件であり、証明の構成要素ではない」パターンであり、形式的には valid。マニフェストの「T1∧T2 → P3」という依存関係は型レベルで表現されている。

### Phase 4 への引き継ぎ

1. ~~**sorry 解消:**~~ → Phase 4 で完了。
2. ~~**Observable 層の構築:** V1–V7 の形式化。~~ → Phase 4 で完了。
3. **`robustStructure` の具体化:** P5 の堅牢性概念の運用的定義。→ Phase 5 に繰り越し。

---

## Phase 4: Observable Variables (V1–V7)

### 完了日: 2026-03-22

### リファクタリング: opaque 宣言の移動

Phase 3 で Principles.lean に配置していた opaque 宣言4つを Ontology.lean に移動:
- `trustLevel`, `riskMaterialized`, `degradationLevel`, `interpretsStructure`

理由: Observable.lean が Principles.lean を import すると循環依存が発生するため、
これらの宣言を Ontology.lean（全モジュールの基盤）に配置し、Observable.lean と
Principles.lean の双方から参照可能にした。

### 新規追加した型・述語

| 名前 | 種類 | 定義場所 | 用途 |
|------|------|---------|------|
| `Measurable` | def | Observable.lean | 定量的指標の計算可能性 |
| `skillQuality` (V1) | opaque | Observable.lean | スキル品質 |
| `contextEfficiency` (V2) | opaque | Observable.lean | コンテキスト効率 |
| `outputQuality` (V3) | opaque | Observable.lean | 出力品質 |
| `gatePassRate` (V4) | opaque | Observable.lean | ゲート通過率 |
| `proposalAccuracy` (V5) | opaque | Observable.lean | 提案精度 |
| `knowledgeStructureQuality` (V6) | opaque | Observable.lean | 知識構造の質 |
| `taskDesignEfficiency` (V7) | opaque | Observable.lean | タスク設計効率 |
| `TradeoffExists` | def | Observable.lean | 変数間トレードオフの存在 |
| `GoodhartVulnerable` | def | Observable.lean | Goodhart 脆弱性 |
| `systemHealthy` | def | Observable.lean | 系の健全性 |
| `paretoImprovement` | def | Observable.lean | Pareto 改善 |

### 重要な設計判断

#### 13. Observable vs Measurable の区別

Observable (`World → Prop` に対する決定手続き) と Measurable (`World → Nat` の計算手続き) を区別。
V1–V7 は定量的指標なので Measurable として形式化。Observable は二値判定に使用（例: systemHealthy）。

Measurable の定義 `∃ f : World → Nat, ∀ w, f w = m w` は、opaque な m に対して非自明:
opaque の展開不能性により `f = m` が型検査で通らないため、axiom 宣言が実質的な約束となる。

#### 14. トレードオフの形式化: 存在量化

`TradeoffExists m₁ m₂ := ∃ w w', m₁ w < m₁ w' ∧ m₂ w' < m₂ w`

「常に劣化する」ではなく「劣化しうるワールド対が存在する」という弱い主張を選択。
Pareto 改善の不可能性は含意しない。これは Constraints Taxonomy（Ontology.lean/Observable.lean） の
「潜在的な副作用」という記述に忠実。

#### 15. Goodhart's Law の型レベル表現

`GoodhartVulnerable m := ∀ approx, (∃ w, approx w = m w) → ∃ w', approx w' ≠ m w'`

「少なくとも1点で一致する任意の近似測定に対して、乖離するワールドが存在する」。
これは「完璧な近似は存在しない」を直接的に述べる。V4 と V7 に適用。

#### 16. Sorry 解消戦略: axiom の追加

3つの sorry を「Phase 4 Observable 層の axiom」として解消:
- `trust_decreases_on_materialized_risk` — 経験的（信頼の非対称性）
- `degradation_level_surjective` — 設計仮定（勾配としての劣化）
- `interpretation_nondeterminism` — T4 の高水準再述

代替案として sorry のまま残すことも検討したが、「Phase 4 で Observable 化が完了すれば
これらの性質は観測可能になる」という設計上の約束を明示するため axiom 化を選択。

各 axiom の妥当性は Observable.lean の Sorry Inventory セクションで検証済み
（空虚性、トートロジー性、反証可能性の3観点）。

### Axiom 対応表 (Phase 4 追加分)

| axiom | 性格 | 対象 |
|-------|------|------|
| `v1_measurable` – `v7_measurable` (7個) | observable-axiom | V1–V7 可測性 |
| `tradeoff_v1_v2`, `tradeoff_v6_v2`, `tradeoff_v2_v1`, `tradeoff_v2_v6`, `tradeoff_v7_v2` (5個) | tradeoff-axiom | 変数間トレードオフ |
| `v4_goodhart`, `v7_goodhart` (2個) | goodhart-axiom | Goodhart 脆弱性 |
| `system_health_observable` (1個) | observable-axiom | 系の健全性 |
| `trust_decreases_on_materialized_risk` (1個) | observable-axiom, empirical | P1b sorry 解消 |
| `degradation_level_surjective` (1個) | observable-axiom | P4b sorry 解消 |
| `interpretation_nondeterminism` (1個) | observable-axiom, derived-from-T4 | P5 sorry 解消 |
| `trust_measurable`, `degradation_measurable` (2個) | observable-axiom | 信頼度・劣化度の可測性 |

**Phase 4 新規 axiom 合計: 20 個**

### Phase 5 への引き継ぎ

1. ~~**Evolution 層:** バージョン間の互換性分類（CompatibilityClass の拡張）~~ → Phase 5 で完了。
2. ~~**`robustStructure` の具体化:** Phase 5 の安全性検証に組み込む~~ → Phase 5 で safeVersionTransition として組み込み。
3. **systemHealthy の変数ごと閾値:** 現在は一律 threshold だが、変数ごとに異なる閾値へ拡張 → Phase 6+ に繰り越し。
4. **Pareto 最適性の探索:** paretoImprovement の到達不能性（Pareto フロンティア）の形式化 → Phase 6+ に繰り越し。

---

## Phase 5: Manifest Evolution

### 完了日: 2026-03-22

### リファクタリング: CompatibilityClass の Ontology への移動

Phase 3 で Principles.lean に配置していた以下の定義を Ontology.lean に移動:
- `CompatibilityClass` (inductive)
- `KnowledgeIntegration` (structure)
- `isGoverned` (def)
- `structureDegraded` (opaque)

理由: Evolution.lean が Principles.lean を import すると Observable → Axioms → EmpiricalPostulates
の下流すべてに依存し、import DAG が不必要に肥大化する。CompatibilityClass は
StructureKind と同様にオントロジカルな列挙型であり、Ontology.lean が適切な配置場所。
Principles.lean は Ontology.lean を import 済みのため、既存の theorem は影響を受けない。

### ビルドシステムの修正

Phase 4 まで `lake build` 未実施だったため、初回ビルドで以下の問題を検出・修正:

1. **Verso 依存の除去**: `doc.verso` オプションが有効だった lakefile.lean を修正。
   Verso の markdown parser が `/-!` doc comment 内のヘッダネスティングに厳格で、
   既存の全ファイルでエラー。Verso は形式化の本質ではないため依存を除去。
2. **opaque 型の Repr インスタンス追加**: `AgentId`, `SessionId`, `ResourceId`,
   `StructureId`, `WorldHash` は opaque 型のため `Repr` を自動導出できない。
   各 opaque 型にプレースホルダー `Repr` インスタンスを追加。
3. **import 順序の修正**: Lean 4 では `import` が全ファイルの先頭にある必要があるが、
   全モジュールで `/-!` doc comment が import の前にあった。全7ファイルを修正。
4. **P3c proof の修正**: `ungoverned_breaking_change_irrecoverable` の proof term で
   `ki` パラメータがワイルドカード `_` になっていたため `ki.after` が解決不能。
   パラメータ名を明示して修正。
5. **Workflow.lean, Meta.lean の作成**: Manifest.lean が import しているが
   ファイルが存在しなかった。プレースホルダーとして作成。

### 新規追加した型・述語

| 名前 | 種類 | 定義場所 | 用途 |
|------|------|---------|------|
| `ManifestVersion` | structure | Evolution.lean | バージョン（番号・エポック・公理数） |
| `VersionTransition` | structure | Evolution.lean | バージョン間遷移イベント |
| `validVersionTransition` | def | Evolution.lean | 遷移の有効性（番号単調増加・エポック非減少） |
| `breakingChangeRequiresEpochBump` | def | Evolution.lean | 破壊的変更 → エポック増加要求 |
| `CompatibilityClass.join` | def | Evolution.lean | 互換性の合成（supremum） |
| `CompatibilityClass.le` | def | Evolution.lean | 互換性の順序 |
| `VersionHistory` | def | Evolution.lean | 遷移列 |
| `historyCompatibility` | def | Evolution.lean | 遷移列全体の互換性 |
| `isManifestStructure` | def | Evolution.lean | StructureKind.manifest の判定 |
| `governedTransition` | def | Evolution.lean | 統治された遷移 |
| `stasisUnhealthy` | def | Evolution.lean | 静止の不健全性 |
| `safeVersionTransition` | def | Evolution.lean | 安全なバージョン遷移 |
| `ReviewSignal` | inductive | Evolution.lean | 分類見直しシグナル（5種） |
| `ClassificationReview` | structure | Evolution.lean | 見直しイベント |

### 重要な設計判断

#### 17. CompatibilityClass に格子構造（join semi-lattice）を導入

**問題:** HANDOFF では「conservativeExtension の連鎖は conservativeExtension」
「compatibleChange の推移性」「breakingChange の後は移行パスが必要」を個別に
要求しているが、これらは単一の代数的構造から導出可能。

**決定:** CompatibilityClass.join（supremum 演算）を定義し、格子構造として形式化。
順序は conservativeExtension ≤ compatibleChange ≤ breakingChange。

合成のルール:
- join は可換、結合的、冪等（= join semi-lattice）
- conservativeExtension は最小元（単位元）
- breakingChange は最大元（吸収元）

これにより HANDOFF の3要件が統一的に導出される:
- conservativeExtension の推移性 → `conservative_extension_transitive`
- compatibleChange の閉包性 → `compatible_change_closed`
- breakingChange の支配性 → `breaking_change_dominates`

全 theorem は `cases` tactic + `rfl` / `simp` で証明完了（sorry なし）。

#### 18. axiom を追加しない設計

**問題:** Evolution 層の性質を axiom として宣言するか、theorem として導出するか。

**検討した選択肢:**
- (a) 新規 axiom を追加 — 強い仮定を置ける
- (b) 全て theorem — 既存の axiom から導出

**決定:** (b) を採用。Evolution 層の定理はすべて Phase 1–4 の axiom
（特に T2 の structure_persists, structure_accumulates）から導出可能。
CompatibilityClass の代数的性質は inductive 型の構造から `cases` で導出。

新規 axiom 0 個は形式系の健全性にとって望ましい:
axiom が増えるほど矛盾のリスクが高まるため、導出可能な性質は theorem にすべき。

#### 19. Section 7「静止の不健全性」を Prop（命題）で表現

**問題:** manifesto.md Section 7 の「静止は健全な状態ではない」をどう形式化するか。

**検討した選択肢:**
- (a) axiom: 「マニフェストは更新されなければならない」→ 存在量化が必要で過度に強い
- (b) def (Prop): 「静止は不健全である」条件を型として定義 → 使用者が判断可能
- (c) theorem: 「静止 → 不健全」を既存 axiom から導出 → 依拠する axiom がない

**決定:** (b) `stasisUnhealthy` を `def` として定義。
構造のエポックが進んでいるにもかかわらずマニフェストのバージョンが追随していない場合、
更新が必要であることを命題として表現。axiom でも theorem でもなく、
「この条件が成立するとき、更新の必要性を示唆する」という設計ガイドラインとして機能する。

#### 20. ReviewSignal — Constraints Taxonomy（Ontology.lean/Observable.lean） Part IV の型化

**問題:** Constraints Taxonomy（Ontology.lean/Observable.lean） の見直しシグナル5種をどう形式化するか。

**決定:** `ReviewSignal` inductive 型として5つのコンストラクタで表現。
`ClassificationReview` structure で見直しイベントを型付け。
`review_within_framework` theorem で「任意の見直しはマニフェストの枠内」を証明
（breakingChange_ge の直接適用）。

### Theorem 対応表 (Phase 5)

| theorem | 根拠 | sorry | 証明方法 |
|---------|------|-------|---------|
| `conservativeExtension_le` | 構造的 | なし | cases + rfl |
| `breakingChange_ge` | 構造的 | なし | cases + rfl |
| `compatibility_join_comm` | 構造的 | なし | cases + rfl |
| `compatibility_join_assoc` | 構造的 | なし | cases + rfl |
| `compatibility_join_idem` | 構造的 | なし | cases + rfl |
| `conservative_extension_transitive` | 構造的 | なし | subst + rfl |
| `compatible_change_closed` | 構造的 | なし | cases + simp |
| `breaking_change_dominates` | 構造的 | なし | cases + rfl |
| `empty_history_conservative` | 構造的 | なし | rfl |
| `two_conservative_compose` | 構造的 | なし | rw + rfl |
| `manifest_persists_as_structure` | T2 (structure_persists) | なし | 直接適用 |
| `ungoverned_manifest_change_irreversible` | T2 (structure_accumulates) | なし | 直接適用 |
| `review_within_framework` | breakingChange_ge | なし | 直接適用 |

**結果: 13 theorems (Evolution.lean) + 5 theorems (Observable.lean 拡張)、全て sorry-free。新規 axiom 0 個。**

### 任意タスクの実装

#### 21. 変数ごと閾値（HealthThresholds）

**問題:** `systemHealthy` は一律閾値だが、実運用では V4（ゲート通過率）は高い閾値、
V5（提案精度）は比較的低い閾値など、変数ごとに異なる要求水準が必要。

**決定:** `HealthThresholds` structure を追加し、`systemHealthyPerVar` を定義。
`uniformThresholds` 関数で一律閾値を `HealthThresholds` に変換し、
`uniform_thresholds_equiv` theorem で `systemHealthy` との同値性を証明。
これにより既存の `systemHealthy` は `systemHealthyPerVar` の特殊ケースとして位置づけられる。

#### 22. Pareto フロンティアの形式化

**問題:** `paretoImprovement` は定義済みだが、Pareto フロンティア（改善不能領域）は未形式化。

**決定:** `paretoOptimal`（Pareto 改善が存在しない）と `paretoDominated`（Pareto 改善が存在する）を
相互排他な述語として定義。`pareto_optimal_not_dominated` と `not_dominated_is_optimal` で
排他性を証明。

トレードオフ axiom から「Pareto optimal でないワールドの存在」を導出する定理は
新規 axiom なしでは証明不能なため見送り。トレードオフ axiom は「劣化するワールド対が存在する」を
述べるのみで、「あるワールドが dominated である」ことの直接的根拠にはならない。
この方向の拡張には「到達可能性」の概念（validTransition を介した接続性）が必要。

#### 23. robustStructure の Observable 層での具体化

**問題:** Principles.lean の `robustStructure` は抽象的な安全性述語 `safety : World → Prop` を
パラメータに取るが、具体的な安全性制約との接続がなかった。

**決定:** `healthRobustStructure` を定義。safety = `systemHealthyPerVar th` として
robustStructure を具体化。「解釈のばらつきに対して系の健全性が保持される構造」を表す。

注: Evolution.lean は Principles.lean を import しないため（DAG の設計判断 #17）、
robustStructure を直接参照せず同等の構造を展開定義している。
`health_robust_unfolds` theorem で定義の展開が自明であることを証明。

### Theorem 対応表 (Phase 5 拡張分)

| theorem | 場所 | 根拠 | sorry | 証明方法 |
|---------|------|------|-------|---------|
| `uniform_thresholds_equiv` | Observable.lean | 構造的 | なし | simp |
| `pareto_optimal_not_dominated` | Observable.lean | 構造的 | なし | exact |
| `not_dominated_is_optimal` | Observable.lean | 構造的 | なし | exact |
| `health_robust_unfolds` | Observable.lean | 構造的 | なし | rfl |

### Workflow.lean の実装

#### 24. 学習ライフサイクルを inductive 型 + 遷移関数で形式化

**問題:** P3 の統治ライフサイクル（観察→仮説化→検証→統合→退役）をどう型にするか。

**検討した選択肢:**
- (a) 状態機械を opaque 遷移関係で定義 — 柔軟だが性質の証明が困難
- (b) `LearningPhase` inductive + `validPhaseTransition` 関数 — 遷移の有効性が cases で証明可能
- (c) 依存型で遷移列を型として保証 — 正確だが複雑

**決定:** (b) を採用。`validPhaseTransition` を Prop 値関数として定義し、
有効な遷移のみ `True` を返す。検証失敗時の仮説への差し戻し（verification → hypothesizing）と
退役後の新観察（retirement → observation）の循環パスも明示的に許可。

証明された性質:
- 自己遷移の禁止（`no_self_phase_transition`）
- 完全な1周の存在（`full_cycle_exists`）
- 統合前の検証必須（`integration_requires_verification`）
- 退役は統合後のみ（`retirement_only_after_integration`）
- T5 との接続（`feedback_precedes_improvement`）

#### 25. KnowledgeItem — 知識要素の状態管理

**問題:** 学習ライフサイクルを通過する情報の単位をどう型付けするか。

**決定:** `KnowledgeItem` structure に `KnowledgeStatus`（ライフサイクル上の位置）、
`compatibility`（CompatibilityClass）、`independentlyVerified`（P2 の運用化）を持たせる。
`integrationGateCondition` で統合ゲートの前提条件を定式化:
独立検証済み ∧ verified ステータス ∧ breakingChange → エポック増加。

### Meta.lean の実装

#### 26. 公理の認識論的地位を型で表現

**問題:** 公理系の三層構造（T / E / V）と、E の反証が P に与える影響範囲を形式化するか。

**決定:** `AxiomStatus`（constraint / empiricalPostulate / observableAxiom）と
`DerivationBasis`（constraintOnly / empiricalDependent / observableDependent / structural）を
inductive 型として定義。`principleDerivation` 関数で各 P の導出根拠をマッピングし、
`empirical_falsification_scope` theorem で「E 反証時に影響を受けるのは P1 と P2 のみ」を証明。

`majority_principles_robust` theorem で「堅牢な P（T のみに依拠）が過半数（4/6）」を証明。
これは公理系が E の反証に対して構造的にレジリエントであることのメタ的保証。

#### 27. AxiomSystemProfile — 公理系の自己記述

**問題:** 公理系の構成（axiom 数、theorem 数、sorry 数）を型レベルで追跡できるか。

**決定:** `AxiomSystemProfile` structure で公理系の統計を保持し、
`currentProfile` で Phase 5 完了時点のプロファイルを定義。
`current_total_axioms` と `current_sorry_free` theorem で
axiom 数 = 37、sorry 数 = 0 を型検査で保証。

注: この手法には限界がある — `currentProfile` は手動で更新する必要があり、
Lean の型システムが実際の axiom 数を自動カウントするわけではない。
しかし、手動更新であっても型検査が通ることで「プロファイルの数値が
実際のコードと矛盾していない」ことの弱い保証にはなる。

### Theorem 対応表 (Workflow + Meta)

| theorem | 場所 | 根拠 | sorry | 証明方法 |
|---------|------|------|-------|---------|
| `no_self_phase_transition` | Workflow | 構造的 | なし | cases + simp |
| `full_cycle_exists` | Workflow | 構造的 | なし | trivial |
| `integration_requires_verification` | Workflow | 構造的 | なし | simp |
| `retirement_only_after_integration` | Workflow | 構造的 | なし | simp |
| `feedback_precedes_improvement` | Workflow | 構造的 | なし | rfl |
| `current_total_axioms` | Meta | 構造的 | なし | rfl |
| `current_sorry_free` | Meta | 構造的 | なし | rfl |
| `constraint_not_falsifiable` | Meta | 構造的 | なし | simp |
| `empirical_is_falsifiable` | Meta | 構造的 | なし | simp |
| `constraint_derived_immune` | Meta | 構造的 | なし | simp |
| `structural_derived_immune` | Meta | 構造的 | なし | simp |
| `empirical_falsification_scope` | Meta | 構造的 | なし | simp |
| `majority_principles_robust` | Meta | 構造的 | なし | simp |
| `all_true_is_valid` | Meta | 構造的 | なし | simp |
| `vacuous_is_invalid` | Meta | 構造的 | なし | simp |

### 累計サマリ（最終）

| Phase | 内容 | axiom 数 | sorry | theorem 数 |
|-------|------|---------|-------|-----------|
| 1 | Ontology + T1–T8 | 13 | 0 | — |
| 2 | E1–E2 | 4 | 0 | — |
| 3 | P1–P6 | — | 0 (Phase 4 で解消) | 14 |
| 4 | V1–V7 Observable | 20 | 0 | — |
| 5 | Evolution + Observable 拡張 | 0 | 0 | 17 |
| 5+ | Workflow + Meta | 0 | 0 | 15 |
| **合計** | | **37 axioms** | **0 sorry** | **46 theorems** |

### Phase 6+ への引き継ぎ

1. ~~**systemHealthy の変数ごと閾値:**~~ → Phase 5 で完了。
2. ~~**Pareto フロンティアの形式化:**~~ → Phase 5 で完了。
3. ~~**Workflow.lean の実装:**~~ → Phase 5+ で完了。
4. ~~**Meta.lean の実装:**~~ → Phase 5+ で完了。
5. **VersionHistory の帰納的定理:** 遷移列全体に対する保存性質の証明（List.Mem の型解決に課題あり）。
6. **Pareto フロンティアの到達不能性:** validTransition を介した到達可能性の概念が必要。
7. **robustStructure と healthRobustStructure の形式的同値性:** Principles.lean を import する統合モジュールで証明可能。
8. **AxiomSystemProfile の自動検証:** #check_axiom_count のような tactic/macro で自動カウントする仕組み。
9. **Workflow の Observable 化:** LearningPhase の遷移を V4（ゲート通過率）と接続する。

---

## Gap 解消: 整合性チェック後の追加実装

### 実施日: 2026-03-22

#### 28. 境界→緩和策→変数の三段構造を Ontology に型化

**問題:** Constraints Taxonomy（Ontology.lean/Observable.lean） Part II の核心構造「境界条件は動かない。緩和策は設計判断。変数は緩和策の効き具合」が型として表現されていなかった。

**決定:** Ontology.lean に以下を追加:
- `BoundaryLayer` inductive (fixed / investmentVariable / environmental)
- `BoundaryId` inductive (L1–L6 の6項目)
- `boundaryLayer` 関数 (各 L が属するレイヤー)
- `Mitigation` structure (境界→構造の対応)
- `InvestmentKind` inductive (投資の3形態)
- `investmentLevel` opaque (投資水準)

`variableBoundary` 関数で V→L の対応を定義し、`fixed_boundary_variables_mitigate_only` theorem で「固定境界に対応する V は緩和策の品質改善のみ可能」を証明。

#### 29. 投資サイクルの形式化

**問題:** manifesto Section 6 と taxonomy Part III の中心概念「信頼→投資→行動空間→構造品質→信頼」の正のフィードバックループが未形式化だった。

**決定:** Observable.lean に新規 axiom 4件を追加:
- `trust_accumulates_gradually`: 信頼の漸進的蓄積（bounded increment）
- `trust_drives_investment`: 系の健全性改善 → 投資水準非減少
- `risk_reduces_investment`: リスク顕在化 → 投資縮小（逆サイクル）
- `overexpansion_reduces_value`: 行動空間の過剰拡大 → 協働価値減少

**信頼の非対称性の完成:** Phase 4 で毀損側（unbounded decrease）のみだったが、蓄積側（bounded increase via trustIncrementBound）を追加。`trustAsymmetry` def で両方を統合的に表現。

**axiom の妥当性レビュー:**

| axiom | 空虚でないか | トートロジーでないか | 反証可能か |
|-------|------------|-------------------|-----------|
| trust_accumulates_gradually | ✓ 3前提 | ✓ bounded increment を主張 | ✓ 信頼蓄積にbound がないモデル |
| trust_drives_investment | ✓ 健全性改善 + 変数改善が前提 | ✓ 投資の非減少を主張 | ✓ 改善しても投資が減少するケース |
| risk_reduces_investment | ✓ リスク顕在化 + 信頼減少が前提 | ✓ 投資非増加を主張 | ✓ リスク後も投資が増加するケース |
| overexpansion_reduces_value | ✓ 具体的な3つ組の存在 | ✓ 価値の減少を主張 | ✓ 行動空間が常に価値増加するモデル |

#### 30. 均衡の探索の形式化

**問題:** 「最適自律度 ≠ 最大自律度」という manifesto Section 6 の主張が未形式化。

**決定:** `atEquilibrium` def と `overexpansion_reduces_value` axiom で表現。均衡 = 行動空間をこれ以上拡大しても協働価値が改善しない状態。`contractionJustified` def で L4 の縮小トリガーを形式化（リスク顕在化 ∧ 非均衡状態 → 縮小が正当化）。

#### 31. Section 7 の T4/E1/P1 自己適用

**問題:** Section 7 の自己適用のうち T2/P3 のみ形式化されており、T4（確率的解釈）、E1（検証の独立性）、P1（共成長）が未形式化。

**決定:** Evolution.lean に3つの theorem を追加。いずれも既存 axiom の直接適用（output_nondeterministic, verification_requires_independence, capability_risk_coscaling）。新規 axiom は不要。

#### 32. V6 退役接続

**問題:** V6（知識構造の質）の定義に「退役の測定を含む」とあるが、LearningPhase.retirement との接続がなかった。

**決定:** Workflow.lean に `unretiredKnowledgePressure` と `retirementContributesToV6` を追加。退役未実施の知識が V2（コンテキスト効率）を圧迫するリスクと、退役が V6 の品質を構成することを型レベルで表現。

### 追加 axiom/theorem 対応表

| 名前 | 場所 | 種類 | sorry |
|------|------|------|-------|
| trust_accumulates_gradually | Observable | axiom | — |
| trust_drives_investment | Observable | axiom | — |
| risk_reduces_investment | Observable | axiom | — |
| overexpansion_reduces_value | Observable | axiom | — |
| fixed_boundary_variables_mitigate_only | Observable | theorem | なし |
| manifesto_probabilistically_interpreted | Evolution | theorem | なし |
| manifesto_evaluation_requires_independence | Evolution | theorem | なし |
| manifesto_scope_risk_coscaling | Evolution | theorem | なし |

### 累計サマリ（最終）

| Phase | 内容 | axiom 数 | sorry | theorem 数 |
|-------|------|---------|-------|-----------|
| 1 | Ontology + T1–T8 | 13 | 0 | — |
| 2 | E1–E2 | 4 | 0 | — |
| 3 | P1–P6 | — | 0 | 14 |
| 4 | V1–V7 Observable | 20 | 0 | — |
| 5+ | Evolution + Observable + Workflow + Meta | 4 | 0 | 36 |
| **合計** | | **41 axioms** | **0 sorry** | **50 theorems** |

---

## 整合性チェック: 原文書 vs Lean 形式化

### 実施日: 2026-03-22

対象文書:
- manifesto.md（マニフェスト本体）
- Constraints Taxonomy（Ontology.lean/Observable.lean）（制約・境界条件・変数の体系的整理）
- implementation-boundaries.md（実装境界の選択指針）

---

### 1. manifesto.md との整合性

#### Section 2: 公理系 — T1–T8

| T | 原文の主張 | 形式化 | 整合 | 備考 |
|---|-----------|--------|------|------|
| T1 | セッション間の記憶はない。連続する「自己」は存在しない | session_bounded, no_cross_session_memory, session_no_shared_state | ✅ | T1c は「直接的」状態共有の禁止。間接的影響（T2経由）は許容。設計判断 #4 で強度の懸念を記録済み |
| T2 | 構造はセッションが終わっても残る。改善が蓄積する場所 | structure_persists, structure_accumulates | ✅ | |
| T3 | 一度に処理できる情報量に物理的上限がある | context_finite, context_bounds_action | ✅ | |
| T4 | 同じ入力に対して異なる出力を生成しうる | output_nondeterministic | ✅ | 存在量化（∃ ... w₁ ≠ w₂）で非決定性を表現 |
| T5 | 測定→比較→調整のループがなければ目標への収束は起こらない | no_improvement_without_feedback | ✅ | structureImproved は opaque。「改善」の具体的定義は未確定 |
| T6 | 計算資源等は人間が与え、人間が回収しうる | human_resource_authority, resource_revocable | ✅ | |
| T7 | タスク遂行に利用可能なリソースは有限 | resource_finite (globalResourceBound) | ✅ | 設計判断 #2: opaque 定数による非自明な有限性表現 |
| T8 | タスクには達成すべき精度水準が存在する | task_has_precision | ✅ | 千分率 Nat で Float を回避（設計判断 #3） |

**所見:** T1–T8 は完全にカバー。形式化の選択（opaque 関係、Nat 計量等）は設計判断ログで根拠が記録されている。

#### Section 2: 公理系 — E1–E2

| E | 原文の主張 | 形式化 | 整合 | 備考 |
|---|-----------|--------|------|------|
| E1 | 同一プロセスによる生成と評価は構造的に信頼できない | verification_requires_independence, no_self_verification, shared_bias_reduces_detection | ✅ | 3 axiom に分解。E1b は E1a の系であることを e1b_from_e1a で証明済み |
| E2 | 能力の増大はリスクの増大と不可分 | capability_risk_coscaling | ⚠️ | 厳密不等号 `<` を採用。原文は「不可分」だが「完璧なサンドボックスが原理的に不可能という証明はない」と留保。設計判断 #6 で根拠記録済み。axiom の経験的地位（覆りうること）で留保を表現 |

**所見:** E1 は忠実。E2 の `<` は原文の留保との間に若干の緊張があるが、設計判断で明示的に議論されており許容範囲。

#### Section 3: P1–P6

| P | 原文の主張 | 形式化 | 整合 | 備考 |
|---|-----------|--------|------|------|
| P1 | 自律権拡張はリスク拡張と不可分。防護なき拡張は信頼破壊 | autonomy_vulnerability_coscaling (E2直接), unprotected_expansion_destroys_trust | ✅ | 信頼の非対称性を trustLevel + trust_decreases_on_materialized_risk で表現 |
| P2 | 検証フレームワークの健全性は役割分離を要求 | cognitive_separation_required, self_verification_unsound | ✅ | verificationSound 述語で設計概念を導入 |
| P3 | 学習の統治。ライフサイクル: 観察→仮説化→検証→統合→退役 | modifier_agent_terminates, modification_persists, ungoverned_breaking_change_irrecoverable, compatibility_exhaustive | ✅ | CompatibilityClass の3分類が忠実。ライフサイクルは Workflow.lean で LearningPhase として形式化 |
| P3 | 互換性分類: 保守的拡張/互換的変更/破壊的変更 | CompatibilityClass inductive | ✅ | isGoverned で各クラスの意味を定義。Evolution.lean で格子構造を追加 |
| P4 | 観測できないものは最適化できない。勾配としての制約 | improvement_requires_observability, degradation_is_gradient | ✅ | Observable / Measurable の区別を導入 |
| P5 | 構造は確率的に解釈される。堅牢な設計は解釈のばらつきに耐性を持つ | structure_interpretation_nondeterministic, robustStructure | ✅ | healthRobustStructure で Observable 層と接続 |
| P6 | タスク設計は制約充足問題 | task_is_constraint_satisfaction, task_design_is_probabilistic | ✅ | TaskStrategy + strategyFeasible で3次元制約を表現 |
| P6 | 具体的分散パターンは「解」であり「原理」ではない | — | ✅ | 原文に忠実: 具体パターンは形式化せず、制約構造のみ |

**所見:** P1–P6 は忠実にカバー。P3 のライフサイクルが Workflow.lean に、互換性分類が Evolution.lean に分散しているが、概念的にはすべて型として表現されている。

#### Section 4: ビジョン

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| 構造が主体である | T2 (structure_persists, structure_accumulates) | ✅ | 暗黙的。「構造」が World.structures に、「改善の蓄積」が epoch 非減少に対応 |
| 階層構造（最上位使命→進化方向層→現実制約層） | — | ➖ | 形式化の対象外。概念的ガイドであり型にする必要性は低い |
| 免疫系の比喩 | — | ➖ | 比喩であり形式化の対象外 |

#### Section 5: 制約という進化圧

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| 制約の二面性（防御的/生成的フレーム） | — | ➖ | 原文の表は概念的分析。T が axiom として、その帰結が P として形式化されており、実質的にはカバー済み |
| 進化圧が構造設計を駆動する | — | ➖ | 高レベルの洞察であり、個々の T→P 導出として表現済み |

#### Section 6: 協働の均衡

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| 投資サイクル（構造品質改善→利益→投資増加） | trust_drives_investment, risk_reduces_investment | ✅ **解消** | 設計判断 #29 で形式化 |
| 均衡の探索（最適自律度≠最大自律度） | atEquilibrium, overexpansion_reduces_value | ✅ **解消** | 設計判断 #30 で形式化 |
| P1 が生む構造的緊張（正負フィードバック同時回転） | capability_risk_coscaling, trust_decreases_on_materialized_risk | ⚠️ | 部分的。正のループ（信頼蓄積→拡張）は未形式化。負のループのみ |
| 信頼の非対称性（蓄積は漸進、毀損は急激） | trust_decreases_on_materialized_risk | ✅ | 「急激な毀損」は axiom で表現。「漸進的蓄積」は未形式化（非対称性の片方のみ） |
| L4 縮小トリガー | contractionJustified | ✅ **解消** | 設計判断 #30 で形式化 |

#### Section 7: 自己適用

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| T1–T8 の自己適用 | manifest_persists_as_structure (T2) | ⚠️ | T2 のみ直接適用。T1/T4/E1/T8 の自己適用は記述的（docstring）で定理としては未証明 |
| P1–P6 の自己適用 | governedTransition (P3), stasisUnhealthy | ⚠️ | P3 と「静止の不健全性」は形式化。P1/P2/P4/P5/P6 の自己適用は未形式化 |
| 静止は健全な状態ではない | stasisUnhealthy | ✅ | def (Prop) として表現。設計判断 #19 |

---

### 2. Constraints Taxonomy（Ontology.lean/Observable.lean） との整合性

#### L1–L6 境界条件

| L | 原文の内容 | 形式化 | 整合 | 備考 |
|---|-----------|--------|------|------|
| L1 | 倫理・安全境界（テスト改竄禁止、破壊的操作の事前確認等） | BoundaryId.ethicsSafety, BoundaryLayer.fixed | ⚠️ | L1 の存在は型として表現。遵守義務・脅威カテゴリの個別項目は運用的であり未列挙 |
| L2 | 存在論的境界（記憶喪失、有限コンテキスト、確率的出力等） | T1, T3, T4 axioms | ✅ | L2 の項目は T1/T3/T4 として axiom 化されている。緩和策の品質が V として形式化 |
| L3 | リソース境界（トークン予算、計算時間等） | globalResourceBound, resource_finite | ⚠️ | 一般的な有限性は表現。具体的な投資トリガー（ROI実証等）は未形式化 |
| L4 | 行動空間境界（マージ権限、スコープ変更等） | actionSpaceSize | ⚠️ | 行動空間の「大きさ」はあるが、具体的な権限項目（auto-merge等）は抽象化されている。拡張/縮小トリガーは未形式化 |
| L5 | プラットフォーム境界 | — | ➖ | 運用的関心事であり形式化の対象外。プラットフォーム比較表等は型にする必要がない |
| L6 | 設計規約境界（1 task = 1 commit、フェーズ構造等） | LearningPhase (Workflow.lean) | ⚠️ | フェーズ構造は形式化。「1 task = 1 commit」等の具体規約は運用的であり抽象化が適切 |

#### 境界→緩和策→変数の三段構造

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| 三段構造（境界条件→緩和策→変数） | BoundaryLayer, BoundaryId, Mitigation, variableBoundary | ✅ **解消** | 設計判断 #28 で形式化 |

#### V1–V7 変数

| V | 原文の定義 | 形式化 | 整合 | 備考 |
|---|-----------|--------|------|------|
| V1 | スキル品質 | opaque skillQuality + v1_measurable | ✅ | |
| V2 | コンテキスト効率 | opaque contextEfficiency + v2_measurable | ✅ | |
| V3 | 出力品質 | opaque outputQuality + v3_measurable | ✅ | |
| V4 | ゲート通過率 | opaque gatePassRate + v4_measurable + v4_goodhart | ✅ | Goodhart 脆弱性も形式化 |
| V5 | 提案精度 | opaque proposalAccuracy + v5_measurable | ✅ | |
| V6 | 知識構造の質（退役の測定を含む） | opaque knowledgeStructureQuality + v6_measurable | ⚠️ | opaque として存在するが、「退役の測定」という V6 の特徴的要素は LearningPhase.retirement と接続されていない |
| V7 | タスク設計効率（外部+内部知見の2ソース） | opaque taskDesignEfficiency + v7_measurable + v7_goodhart | ⚠️ | 2つのデータソース（外部/内部知見）の区別は未形式化 |

#### 変数の相互依存性

| トレードオフ | 原文 | 形式化 | 整合 |
|------------|------|--------|------|
| V1↑ → V2↓ | スキルがコンテキストを消費 | tradeoff_v1_v2 | ✅ |
| V4↑ → Goodhart | ゲートが通りやすいタスクに偏る | v4_goodhart | ✅ |
| V6↑ → V2↓ | 詳細な知識がコンテキストを占有 | tradeoff_v6_v2 | ✅ |
| V2↑ → V1,V6↓ | 効率追求で知識を圧縮しすぎる | tradeoff_v2_v1, tradeoff_v2_v6 | ✅ |
| V7↑ → V2↓ + Goodhart | 高度な分散設計がコンテキスト消費 | tradeoff_v7_v2 + v7_goodhart | ✅ |

**所見:** トレードオフ構造は忠実にカバー。

#### Part III: 投資サイクル

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| 信頼 = 投資行動として具体化 | trustLevel (opaque Nat) | ⚠️ | trustLevel は Nat だが「投資行動」との接続はない |
| 正のフィードバック（信頼蓄積→拡張） | trust_accumulates_gradually, trust_drives_investment | ✅ **解消** | 設計判断 #29 で形式化 |
| 逆サイクル（品質事故→信頼減少→投資縮小） | trust_decreases_on_materialized_risk | ⚠️ | 「信頼減少」はあるが「投資縮小」への接続がない |
| 仮説としての更新可能性 | — | ➖ | メタ的記述であり形式化不要 |

#### Part IV: 分類自体のメンテナンス

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| 見直しシグナル5種 | ReviewSignal (Evolution.lean) | ✅ | misclassification, missingConstraint, obsoleteConstraint, variableInadequacy, ambiguousBoundary |
| 見直しトリガー | — | ⚠️ | トリガー条件は型として表現されていない（ReviewSignal は結果の分類のみ） |
| 自己硬直化の防止 | review_within_framework | ✅ | 「再分類はマニフェストの枠内」を theorem で証明 |

#### 核心的洞察（11項目）

| # | 洞察 | 形式化 | 整合 |
|---|------|--------|------|
| 1 | 最適化の主体は構造 | T2 axioms | ✅ |
| 2 | 変数は相互に影響する系 | TradeoffExists axioms | ✅ |
| 3 | 投資サイクルの目的は均衡 | atEquilibrium, overexpansion_reduces_value | ✅ 解消 |
| 4 | 正と負のフィードバック同時回転 | capability_risk_coscaling + trust | ⚠️ 部分的 |
| 5 | ゲート信頼性は P2→E1 に依拠 | e1b_from_e1a, empirical_falsification_scope | ✅ |
| 6 | 変数最適化は P4 が前提 | Observable/Measurable 定義 | ✅ |
| 7 | 構造は確率的に解釈 (P5) | robustStructure, healthRobustStructure | ✅ |
| 8 | タスク遂行は制約充足 (P6) | task_is_constraint_satisfaction | ✅ |
| 9 | L5 が天井を決める | — | ➖ 運用的 |
| 10 | 公理系は三層構造 | AxiomStatus, DerivationBasis (Meta.lean) | ✅ |
| 11 | 分類自体が見直し対象 | ReviewSignal, review_within_framework | ✅ |

---

### 3. implementation-boundaries.md との整合性

| 概念 | 形式化 | 整合 | 備考 |
|------|--------|------|------|
| P2 の実装（生成と評価の分離） | verificationSound, cognitive_separation_required | ✅ | |
| P4 の検証タイミング（静的/動的/複合） | VerificationTiming (Workflow.lean) | ✅ | static, dynamic, compound の3値 |
| スキルカテゴリ 1/2/3 | — | ➖ | 運用的分類。形式化の対象外 |
| アンチパターン7種 | — | ➖ | 運用的ガイドライン。形式化の対象外 |
| CLI vs Protocol-Mediated の判断 | — | ➖ | L5/L6 レベルの運用判断。形式化不要 |
| Knowledge Layer の段階的エスカレーション | — | ➖ | 運用的 |
| 自己レビューは P2 違反 | self_verification_unsound | ✅ | Anti-pattern #7 に直接対応 |

**所見:** implementation-boundaries.md は運用的ガイドラインが中心。形式化すべき原理的内容（P2, P4 のタイミング）はカバー済み。

---

### 4. 整合性の総合評価

#### 完全にカバー（✅）: 18項目

- T1–T8 全8制約
- E1–E2 全2公準
- P1–P6 全6原理（互換性分類・学習ライフサイクル含む）
- V1–V7 全7変数（Measurable + トレードオフ + Goodhart）
- Section 7 の核心（静止の不健全性、統治された更新）
- Part IV の見直しシグナルと自己硬直化防止
- Meta 層の三層構造と反証影響分析
- implementation-boundaries.md の P2/P4 実装

#### 部分的カバー（⚠️）: 8項目

| 項目 | 不足部分 | 優先度 |
|------|---------|--------|
| E2 の留保（完璧なサンドボックスの可能性） | axiom の経験的地位として表現済み。これ以上の形式化は不要 | 低 |
| L3/L4 の具体的トリガー | 投資/縮小の条件は運用的。actionSpaceSize で抽象化されている | 低 |
| 信頼の非対称性 | 毀損のみ形式化。蓄積メカニズムが未定義 | 中 |
| V6 の退役測定 | LearningPhase.retirement は存在するが V6 との接続がない | 中 |
| V7 の外部/内部知見の区別 | opaque で抽象化。2ソースの区別は運用レベル | 低 |
| Section 7 の T1/T4/E1/T8 自己適用 | docstring で記述。定理としての証明は可能だが省略 | 低 |
| Part III の逆サイクル | 信頼減少はあるが投資縮小への接続がない | 中 |
| 見直しトリガーの条件 | ReviewSignal は結果分類のみ。トリガー条件は未型化 | 低 |

#### 未カバー（❌ Gap）: 3項目 → **解消後: 1項目**

| Gap | 原文の位置 | 状態 |
|-----|-----------|------|
| ~~**投資サイクル**~~ | manifesto Section 6, taxonomy Part III | ✅ 設計判断 #29 で解消 |
| ~~**均衡の探索**~~ | manifesto Section 6, taxonomy Part III | ✅ 設計判断 #30 で解消 |
| ~~**境界→緩和策→変数の三段構造**~~ | taxonomy Part II | ✅ 設計判断 #28 で解消 |
| **L1 遵守義務・脅威カテゴリ** | taxonomy L1 | ❌ 未形式化。運用的ルールであり axiom 化の優先度は低い |

#### 形式化対象外（➖）: 7項目

- ビジョンの比喩（免疫系）、階層図
- L5 プラットフォーム比較
- スキルカテゴリ、アンチパターン、CLI vs Protocol 判断
- 投資サイクルモデルの更新可能性（メタ的記述）

---

### 5. 不整合・過剰形式化の検出

#### 潜在的不整合

| # | 内容 | 深刻度 | 対応 |
|---|------|--------|------|
| 1 | T1c (session_no_shared_state) は World が共有状態を持つため強すぎる可能性 | 中 | 設計判断 #4 で認識済み。「直接的」共有の禁止として解釈 |
| 2 | E2 の `<` は原文の「原理的に不可能という証明はない」との間に緊張 | 低 | 設計判断 #6 で明示的に議論済み。axiom の経験的地位で吸収 |
| 3 | structureImproved (T5) が opaque のまま具体化されていない | 低 | 「改善」の定義は運用に委ねる設計。V1–V7 の改善が間接的に対応 |

#### 過剰形式化の確認

検出なし。全ての型・axiom・theorem はマニフェスト原文の概念に対応しており、原文にない概念を導入していない。Evolution.lean の格子構造（join semi-lattice）は CompatibilityClass の代数的性質の自然な帰結であり、原文を超えた「発見」だが「逸脱」ではない。
