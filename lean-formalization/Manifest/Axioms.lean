import Manifest.Ontology

/-!
# Layer 2: Constraints (T1–T8)

マニフェストの拘束条件を Lean axiom として形式化する。

拘束条件は「否定不可能な、技術非依存の事実」であり、
公理系の核をなす。Lean の `axiom` として宣言することで、
証明なしに仮定する命題として型システムに組み込む。

## 設計方針

各 T は**複数の axiom に分解**されうる。自然言語の T1 が単一の命題に
対応するとは限らず、形式化の過程でより精密な分解が行われる。
各 axiom の docstring に、対応する T の番号と、自然言語との対応を記す。

## 対応表

| axiom 名 | 対応する T | 表現する性質 |
|-----------|-----------|-------------|
| `session_bounded` | T1 | セッションは有限時間で終了する |
| `no_cross_session_memory` | T1 | セッション間で状態を共有しない |
| `session_no_shared_state` | T1 | セッション間で可変状態を共有しない |
| `structure_persists` | T2 | 構造はセッション終了後も存在する |
| `structure_accumulates` | T2 | 改善は構造に蓄積する |
| `context_finite` | T3 | コンテキストウィンドウは有限 |
| `context_bounds_action` | T3 | 処理はコンテキスト容量内でのみ可能 |
| `output_nondeterministic` | T4 | 同一入力に対し異なる出力がありうる |
| `no_improvement_without_feedback` | T5 | フィードバックループなしに改善なし |
| `human_resource_authority` | T6 | 人間がリソースの最終決定者 |
| `resource_revocable` | T6 | 人間はリソースを回収できる |
| `resource_finite` | T7 | リソースは有限 |
| `task_has_precision` | T8 | タスクには精度水準が存在する |
-/

namespace Manifest

-- ============================================================
-- T1: エージェントセッションは一時的である
-- ============================================================

/-!
## T1: エージェントセッションは一時的である

「セッション間の記憶はない。連続する『自己』は存在しない。
  各インスタンスは独立した存在であり、
  前のインスタンスとの同一性を持たない。」

T1 は3つの axiom に分解される:
1. セッションは有限時間で終了する（有界性）
2. セッション間で状態を共有する手段がない（記憶の非連続性）
3. 異なるセッション間で可変状態を共有しない（独立性）
-/

/-- T1a: セッションは有限時間で終了する。
    すべてのセッションに対して、ある時点で terminated になる。 -/
axiom session_bounded :
  ∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated

/-- T1b: セッション間で状態を共有しない。
    異なるセッション ID を持つ2つのセッションの間で、
    一方のアクションが他方の観測可能な状態に影響を与えることはない。

    形式化: 異なるセッションに属するアクションは、
    それぞれの audit entry において独立している。 -/
axiom no_cross_session_memory :
  ∀ (w : World) (e1 e2 : AuditEntry),
    e1 ∈ w.auditLog → e2 ∈ w.auditLog →
    e1.session ≠ e2.session →
    -- 異なるセッションの監査エントリは因果的に独立
    -- （一方の preHash が他方の postHash に依存しない）
    e1.preHash ≠ e2.postHash

/-- T1c: 異なるセッション間で可変状態を共有しない。
    同一の AgentId であっても、異なるセッションにおけるインスタンスは
    直接的に状態を共有しない。影響は構造（T2）を介してのみ間接的に伝播する。

    形式化: あるセッション内のアクションによる遷移は、
    そのセッションに関連しないアクションの成否に影響しない。 -/
axiom session_no_shared_state :
  ∀ (agent1 agent2 : Agent) (action1 action2 : Action)
    (w w' : World),
    action1.session ≠ action2.session →
    canTransition agent1 action1 w w' →
    -- action2 が w で可能なら、w' でも可能（セッション1の遷移が
    -- セッション2のアクション可否に直接影響しない）
    (∃ w'', canTransition agent2 action2 w w'') →
    (∃ w''', canTransition agent2 action2 w' w''')

-- ============================================================
-- T2: 構造はエージェントより長く生きる
-- ============================================================

/-!
## T2: 構造はエージェントより長く生きる

「ドキュメント、テスト、スキル定義、設計規約——
  これらはセッションが終わっても残る。
  改善が蓄積する場所は構造の中。」

T2 は2つの axiom に分解される:
1. 構造はセッション終了後も存在する（永続性）
2. 構造は改善を蓄積しうる（蓄積性）
-/

/-- T2a: 構造はセッション終了後も存在する。
    セッションが terminated になっても、
    そのセッションで参照された構造は World から消えない。 -/
axiom structure_persists :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures

/-- T2b: 構造は改善を蓄積する。
    エポックが進むにつれて構造が更新されうる
    （lastModifiedAt が非減少）。
    これは T1 との対比: エージェントは一時的だが構造は成長する。 -/
axiom structure_accumulates :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch

-- ============================================================
-- T3: コンテキストウィンドウは有限である
-- ============================================================

/-!
## T3: コンテキストウィンドウは有限である

「一度に処理できる情報量に物理的上限がある。
  エージェントの認知空間の制約。」

T3 は2つの axiom に分解される:
1. コンテキストウィンドウの容量は有限（存在性）
2. 処理はコンテキスト容量内でのみ実行可能（制約性）
-/

/-- T3a: コンテキストウィンドウは有限の容量を持つ。
    すべてのエージェントの contextWindow.capacity は有界。 -/
axiom context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity

/-- T3b: アクションの実行にはコンテキスト内の情報処理が必要。
    コンテキスト使用量が容量を超える場合、アクションは実行不能。 -/
axiom context_bounds_action :
  ∀ (agent : Agent) (action : Action) (w : World),
    agent.contextWindow.used > agent.contextWindow.capacity →
    actionBlocked agent action w

-- ============================================================
-- T4: エージェントの出力は確率的である
-- ============================================================

/-!
## T4: エージェントの出力は確率的である

「同じ入力に対して異なる出力を生成しうる。
  構造は毎回確率的に解釈される。
  100%の遵守を前提にした設計は脆い。」

`canTransition` は関数ではなく関係として定義されているため（Ontology.lean 参照）、
同一の (agent, action, w) に対して複数の w' が canTransition を満たしうる。
T4 は「その複数性が実際に起こりうる」ことを axiom として宣言する。
-/

/-- T4: 出力の非決定性。
    同一のエージェント・アクション・ワールド状態に対して、
    異なる遷移先が存在しうる。

    `canTransition` が関係（Prop）として定義されているため、
    Lean の関数の決定性に制約されず、非決定性を自然に表現できる。 -/
axiom output_nondeterministic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂

-- ============================================================
-- T5: フィードバックなしに改善は不可能である
-- ============================================================

/-!
## T5: フィードバックなしに改善は不可能である

「制御理論の基本。
  測定→比較→調整のループがなければ、
  目標への収束は起こらない。」

T5 はフィードバックの存在が改善の必要条件であることを宣言する。
-/

/-- 構造が改善されたかどうかの述語（Phase 4+ で Observable として定義）。 -/
opaque structureImproved : World → World → Prop

/-- T5: 構造の改善にはフィードバックが必要。
    2つのワールド状態間で構造が改善されたならば、
    その間にフィードバックが存在する。 -/
axiom no_improvement_without_feedback :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time

-- ============================================================
-- T6: 人間はリソースの最終決定者である
-- ============================================================

/-!
## T6: 人間はリソースの最終決定者である

「計算資源、データアクセス、実行権限——
  すべて人間が与え、人間が回収しうる。」

T6 は2つの axiom に分解される:
1. リソース割り当ての起源は人間である（権限）
2. 人間はリソースを回収できる（可逆性）
-/

/-- エージェントが人間であるかの述語。 -/
def isHuman (agent : Agent) : Prop :=
  agent.role = AgentRole.human

/-- T6a: リソース割り当ての起源は人間。
    すべてのリソース割り当ての grantedBy は人間ロールを持つ。 -/
axiom human_resource_authority :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (human : Agent), isHuman human ∧ human.id = alloc.grantedBy

/-- T6b: 人間はリソースを回収できる。
    任意のリソース割り当てに対して、人間がそれを無効化する
    遷移が存在する。 -/
axiom resource_revocable :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (w' : World) (human : Agent),
      isHuman human ∧
      validTransition w w' ∧
      alloc ∉ w'.allocations

-- ============================================================
-- T7: タスク遂行に利用可能なリソースは有限である
-- ============================================================

/-!
## T7: タスク遂行に利用可能なリソース（時間・エネルギー）は有限である

「T3が認知空間（コンテキスト）の有限性を述べるのに対し、
  T7は時間的・エネルギー的次元の有限性を述べる。」
-/

/-- T7: リソースは有限。
    World 全体のリソース総量は `globalResourceBound` を超えない。
    ∀-∃ ではなく ∃-∀ の順序で量化し、**全ての** World に対して
    同一の上限が存在することを保証する（自明な充足を防ぐ）。 -/
axiom resource_finite :
  ∀ (w : World),
    (w.allocations.map (·.amount)).foldl (· + ·) 0 ≤ globalResourceBound

-- ============================================================
-- T8: タスクには達成すべき精度水準が存在する
-- ============================================================

/-!
## T8: タスクには達成すべき精度水準が存在する

「自ら設定する場合も、外部から課される場合もある。
  精度水準のないタスクは最適化対象にならない。」
-/

/-- T8: すべてのタスクは精度水準を持つ。
    精度水準は正の値（0 より大きい）でなければならない。
    精度水準が 0 のタスクは最適化対象にならない（= タスクとして成立しない）。
    PrecisionLevel.required は千分率（Nat, 0–1000）。 -/
axiom task_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory (Phase 1)

Phase 1 における `sorry` の一覧:

| 場所 | sorry の理由 |
|------|-------------|
| `Ontology.lean: canTransition` | opaque — Phase 3+ で遷移条件を定義 |
| `Ontology.lean: globalResourceBound` | opaque — Phase 2+ でドメインに応じて具体化 |
| `Axioms.lean: structureImproved` | opaque — Phase 4+ で Observable として定義 |

axiom は証明なしに仮定する命題なので sorry を含まない。
Phase 3 で P1–P6 を theorem として導出する際に sorry が発生する。
-/

end Manifest
