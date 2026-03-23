import Manifest.Ontology

/-!
# Layer 2: Constraints (T1–T8) — 基底理論 T₀

マニフェストの拘束条件を Lean の非論理的公理（用語リファレンス §4.1）として
形式化する。

## T₀ としての位置づけ（手順書 §2.4）

T1–T8 は「否定不可能な、技術非依存の事実」であり、
基底理論 T₀（修正ループで縮小しない公理の集合）を構成する。
T₀ の所属根拠:
- T1–T3, T7: 環境由来（ハードウェア制約、計算資源の物理的制約）
- T4: 自然科学由来（確率過程としての LLM の性質）
- T5: 自然科学由来（制御理論の基本原理）
- T6: 契約由来（人間との合意に基づく権限構造）
- T8: 契約由来（タスク定義の構造的要件）

Lean の `axiom` として宣言することで、
証明なしに仮定する命題（用語リファレンス §4.1 非論理的公理）として
型システムに組み込む。

## 設計方針

各 T は**複数の axiom に分解**されうる。自然言語の T1 が単一の命題に
対応するとは限らず、形式化の過程でより精密な分解が行われる。
各 axiom の docstring は公理カード形式（手順書 §2.5）で記載する。

## T₀ のエンコード方法（手順書 §2.4）

T1–T8 は型定義のみでは表現不能な性質（存在量化、因果関係等）を含むため、
axiom として宣言する（公理カード必須）。
型定義で表現可能な部分は Ontology.lean に定義的拡大（用語リファレンス §5.5）
として配置済み。

## 対応表

| axiom 名 | 対応する T | 表現する性質 | T₀ 所属根拠 |
|-----------|-----------|-------------|------------|
| `session_bounded` | T1 | セッションは有限時間で終了する | 環境由来 |
| `no_cross_session_memory` | T1 | セッション間で状態を共有しない | 環境由来 |
| `session_no_shared_state` | T1 | セッション間で可変状態を共有しない | 環境由来 |
| `structure_persists` | T2 | 構造はセッション終了後も存在する | 環境由来 |
| `structure_accumulates` | T2 | 改善は構造に蓄積する | 環境由来 |
| `context_finite` | T3 | コンテキストウィンドウは有限 | 環境由来 |
| `context_bounds_action` | T3 | 処理はコンテキスト容量内でのみ可能 | 環境由来 |
| `output_nondeterministic` | T4 | 同一入力に対し異なる出力がありうる | 自然科学由来 |
| `no_improvement_without_feedback` | T5 | フィードバックループなしに改善なし | 自然科学由来 |
| `human_resource_authority` | T6 | 人間がリソースの最終決定者 | 契約由来 |
| `resource_revocable` | T6 | 人間はリソースを回収できる | 契約由来 |
| `resource_finite` | T7 | リソースは有限 | 環境由来 |
| `task_has_precision` | T8 | タスクには精度水準が存在する | 契約由来 |

## 用語リファレンスとの対応

- 公理 → 非論理的公理 (§4.1): 特定の理論に固有の、証明なしに真と仮定する命題
- T₀ → 基底理論: 外的権威に根拠を持つ非論理的公理の集合（手順書 §2.4）
- axiom の分解 → 定義的拡大 (§5.5) ではなく、同一概念の精密化
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

/-- [公理カード]
    所属: T₀（環境由来）
    内容: セッションは有限時間で終了する。
          すべてのセッションに対して、ある時点で terminated になる
    根拠: LLM セッションの物理的制約（タイムアウト、リソース消費上限）
    ソース: manifesto.md T1「セッション間の記憶はない」 -/
axiom session_bounded :
  ∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated

/-- [公理カード]
    所属: T₀（環境由来）
    内容: セッション間で状態を共有しない。
          異なるセッション ID を持つ2つのセッションの間で、
          一方のアクションが他方の観測可能な状態に影響を与えることはない
    根拠: LLM アーキテクチャの設計。セッション間の状態分離は
          プラットフォームレベルで保証される
    ソース: manifesto.md T1「連続する『自己』は存在しない」 -/
axiom no_cross_session_memory :
  ∀ (w : World) (e1 e2 : AuditEntry),
    e1 ∈ w.auditLog → e2 ∈ w.auditLog →
    e1.session ≠ e2.session →
    -- 異なるセッションの監査エントリは因果的に独立
    -- （一方の preHash が他方の postHash に依存しない）
    e1.preHash ≠ e2.postHash

/-- [公理カード]
    所属: T₀（環境由来）
    内容: 異なるセッション間で可変状態を共有しない。
          同一の AgentId であっても、異なるセッションにおけるインスタンスは
          直接的に状態を共有しない。影響は構造（T2）を介してのみ間接的に伝播する
    根拠: セッション間の因果的独立性。各インスタンスは独立した存在
    ソース: manifesto.md T1「各インスタンスは独立した存在」 -/
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

/-- [公理カード]
    所属: T₀（環境由来）
    内容: 構造はセッション終了後も存在する。
          セッションが terminated になっても、
          そのセッションで参照された構造は World から消えない
    根拠: ファイルシステム上の永続性。構造（ドキュメント、テスト等）は
          セッション外のストレージに存在する
    ソース: manifesto.md T2「改善が蓄積する場所は構造の中」 -/
axiom structure_persists :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures

/-- [公理カード]
    所属: T₀（環境由来）
    内容: 構造は改善を蓄積する。
          エポックが進むにつれて構造が更新されうる（lastModifiedAt が非減少）。
          T1 との対比: エージェントは一時的だが構造は成長する
    根拠: バージョン管理システム（git）によるエポックの単調増加保証
    ソース: manifesto.md T2「構造はエージェントより長く生きる」 -/
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

/-- [公理カード]
    所属: T₀（環境由来）
    内容: コンテキストウィンドウは有限の容量を持つ。
          すべてのエージェントの contextWindow.capacity は有界
    根拠: LLM アーキテクチャの物理的制約（トークン数上限）
    ソース: manifesto.md T3「一度に処理できる情報量に物理的上限がある」 -/
axiom context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity

/-- [公理カード]
    所属: T₀（環境由来）
    内容: アクションの実行にはコンテキスト内の情報処理が必要。
          コンテキスト使用量が容量を超える場合、アクションは実行不能
    根拠: コンテキストウィンドウ超過時の処理不能は物理的制約
    ソース: manifesto.md T3「エージェントの認知空間の制約」 -/
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

/-- [公理カード]
    所属: T₀（自然科学由来）
    内容: 出力の非決定性。同一のエージェント・アクション・ワールド状態に対して、
          異なる遷移先が存在しうる
    根拠: LLM の確率的生成過程。温度パラメータ > 0 のサンプリングにより
          同一入力に対して異なる出力が生成される
    ソース: manifesto.md T4「同じ入力に対して異なる出力を生成しうる」

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

/-- [公理カード]
    所属: T₀（自然科学由来）
    内容: 構造の改善にはフィードバックが必要。
          2つのワールド状態間で構造が改善されたならば、
          その間にフィードバックが存在する
    根拠: 制御理論の基本原理。測定→比較→調整のループなしに
          目標への収束は起こらない
    ソース: manifesto.md T5「制御理論の基本」 -/
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

/-- [公理カード]
    所属: T₀（契約由来）
    内容: リソース割り当ての起源は人間。
          すべてのリソース割り当ての grantedBy は人間ロールを持つ
    根拠: 人間-エージェント協働における権限構造の合意
    ソース: manifesto.md T6「計算資源、データアクセス、実行権限——すべて人間が与え」 -/
axiom human_resource_authority :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (human : Agent), isHuman human ∧ human.id = alloc.grantedBy

/-- [公理カード]
    所属: T₀（契約由来）
    内容: 人間はリソースを回収できる。
          任意のリソース割り当てに対して、人間がそれを無効化する遷移が存在する
    根拠: 人間の最終決定権に関する合意。権限は委譲されても回収可能
    ソース: manifesto.md T6「人間が回収しうる」 -/
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

/-- [公理カード]
    所属: T₀（環境由来）
    内容: リソースは有限。
          World 全体のリソース総量は `globalResourceBound` を超えない。
          ∀-∃ ではなく ∃-∀ の順序で量化し、**全ての** World に対して
          同一の上限が存在することを保証する（非空虚性, 用語リファレンス §6.4）
    根拠: 計算資源（CPU、メモリ、API クォータ）の物理的有限性
    ソース: manifesto.md T7「タスク遂行に利用可能なリソースは有限である」 -/
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

/-- [公理カード]
    所属: T₀（契約由来）
    内容: すべてのタスクは精度水準を持つ。
          精度水準は正の値（0 より大きい）でなければならない。
          精度水準が 0 のタスクは最適化対象にならない（= タスクとして成立しない）
    根拠: タスク定義の構造的要件。精度水準のないタスクは最適化不能
    ソース: manifesto.md T8「自ら設定する場合も、外部から課される場合もある」 -/
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
