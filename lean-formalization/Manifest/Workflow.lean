import Manifest.Ontology
import Manifest.Axioms

/-!
# Meta-theoretic: Workflow — 学習ライフサイクルとゲート（定義的拡大）

P3（学習の統治）の統治ライフサイクルを型として表現する。
本ファイルは論議領域（用語リファレンス §3.2）の定義的拡大（§5.5）であり、
新たな非論理的公理（§4.1）を追加しない。

## 学習ライフサイクル（manifesto.md Section 3, P3）

```
観察 → 仮説化 → 検証 → [判定] → 統合 → 退役
```

判定（judging）フェーズは検証と統合の間に位置し、
検証 PASS した改善案の非自明性・品質を評価する。
Judge FAIL 時は仮説化に戻る。省略時は検証→統合の直接遷移も有効。

各段階にゲートがある。観察がすべて仮説になるわけではなく、
仮説がすべて統合されるわけではない。
統合された知識も文脈の変化により退役する（AGM の縮小, §9.2）。

## ゲートと検証（manifesto.md Section 5, Ontology.lean L6）

ゲートは T4（確率的出力）に対する防御機構。
P2（認知的役割分離）がゲートの信頼性を保証する。

検証タイミングは3種:
- 静的検証（設計時）: 構造の内部整合性。不変条件（§9.3）の確認
- 動的検証（実行時）: エージェント出力のリアルタイム検証。事後条件（§9.3）の確認
- 複合検証: 存在性は静的に、正確性は動的に

## 用語リファレンスとの対応

- LearningPhase → 形式体系の構成（§1）における証明の段階に類似
- KnowledgeStatus → 仮定（§6.2）の放出（discharge）プロセスに対応
- validKnowledgeTransition → 推論規則（§1）: 前提から結論を導く変換規則
- retirementCandidate → 縮小（§9.2）: 信念集合から信念を除去
-/

namespace Manifest

-- ============================================================
-- 学習ライフサイクルのフェーズ
-- ============================================================

/-- 学習ライフサイクルのフェーズ。
    P3 の統治ライフサイクル:
    観察 → 仮説化 → 検証 → 判定 → 統合 → 退役。
    judging フェーズは検証と統合の間で非自明性判定を行う。 -/
inductive LearningPhase where
  | observation    -- 観察: 現象の記録
  | hypothesizing  -- 仮説化: 観察からの知識候補の生成
  | verification   -- 検証: 仮説の独立的評価（P2）
  | judging        -- 判定: 検証済み改善案の非自明性・品質評価
  | integration    -- 統合: 検証済み知識の構造への組み込み
  | retirement     -- 退役: 文脈の変化により無効化された知識の除去
  deriving BEq, Repr

/-- フェーズ間の有効な遷移。
    学習ライフサイクルは順序を持つ（逆行は退役を除き不可）。
    judging は verification と integration の間に位置し、
    FAIL 時は hypothesizing にループバックする。 -/
def validPhaseTransition : LearningPhase → LearningPhase → Prop
  | .observation,   .hypothesizing => True
  | .hypothesizing, .verification  => True
  | .verification,  .judging       => True   -- 検証 PASS → Judge 評価
  | .judging,       .integration   => True   -- Judge PASS → 統合
  | .judging,       .hypothesizing => True   -- Judge FAIL → 仮説に戻る（再設計）
  | .verification,  .integration   => True   -- Judge 省略時のフォールバック
  | .integration,   .retirement    => True
  -- 検証の失敗 → 仮説に戻る（再検討）
  | .verification,  .hypothesizing => True
  -- 検証の失敗 → 観察に戻る（observation_error ループバック）
  | .verification,  .observation   => True
  -- 退役 → 新たな観察を誘発しうる
  | .retirement,    .observation   => True
  | _,              _              => False

/-- フェーズ遷移の反射性はない（同一フェーズへの遷移は無効）。 -/
theorem no_self_phase_transition :
  ∀ (p : LearningPhase), ¬validPhaseTransition p p := by
  intro p
  cases p <;> simp [validPhaseTransition]

/-- ライフサイクルの完全な1周は observation から retirement まで（Judge 省略時）。 -/
theorem full_cycle_exists :
  validPhaseTransition .observation .hypothesizing ∧
  validPhaseTransition .hypothesizing .verification ∧
  validPhaseTransition .verification .integration ∧
  validPhaseTransition .integration .retirement := by
  constructor <;> trivial

/-- judging フェーズを含む完全な1周。
    observation → hypothesizing → verification → judging → integration → retirement。 -/
theorem full_cycle_with_judging :
  validPhaseTransition .observation .hypothesizing ∧
  validPhaseTransition .hypothesizing .verification ∧
  validPhaseTransition .verification .judging ∧
  validPhaseTransition .judging .integration ∧
  validPhaseTransition .integration .retirement := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> trivial

-- ============================================================
-- ゲート
-- ============================================================

/-- 検証のタイミング。
    implementation-boundaries.md の分類。 -/
inductive VerificationTiming where
  | static   -- 静的検証（設計時）: 決定論的
  | dynamic  -- 動的検証（実行時）: リアルタイム
  | compound -- 複合: 存在性は静的、正確性は動的
  deriving BEq, Repr

/-- ゲート: フェーズ間の品質関門。
    T4（確率的出力）に対する防御機構であり、
    P2（認知的役割分離）が信頼性を保証する。 -/
structure Gate where
  /-- ゲートが位置するフェーズ遷移の出口 -/
  fromPhase : LearningPhase
  /-- ゲートが位置するフェーズ遷移の入口 -/
  toPhase   : LearningPhase
  /-- 検証のタイミング -/
  timing    : VerificationTiming
  deriving Repr

/-- ゲートの配置が有効であること（有効なフェーズ遷移上にあること）。 -/
def validGatePlacement (g : Gate) : Prop :=
  validPhaseTransition g.fromPhase g.toPhase

-- ============================================================
-- 知識要素（Knowledge Item）
-- ============================================================

/-- 知識要素の状態。ライフサイクルの各フェーズに対応。 -/
inductive KnowledgeStatus where
  | observed     -- 観察済み
  | hypothesized -- 仮説化済み
  | verified     -- 検証済み
  | integrated   -- 統合済み（構造に組み込み済み）
  | retired      -- 退役済み
  deriving BEq, Repr

/-- 知識要素。学習ライフサイクルを通過する情報の単位。 -/
structure KnowledgeItem where
  status        : KnowledgeStatus
  /-- 知識の対象となる構造 -/
  targetStructure : StructureId
  /-- 統合時の互換性分類（統合済みの場合のみ有意） -/
  compatibility : CompatibilityClass
  /-- 検証は独立的に行われたか（P2） -/
  independentlyVerified : Bool
  deriving Repr

/-- 知識要素の状態遷移が有効であること。 -/
def validKnowledgeTransition (from_ to : KnowledgeStatus) : Prop :=
  match from_, to with
  | .observed,     .hypothesized => True
  | .hypothesized, .verified     => True
  | .verified,     .integrated   => True
  | .integrated,   .retired      => True
  -- 検証失敗 → 再仮説化
  | .verified,     .hypothesized => True
  -- 検証失敗 → 再観察（observation_error ループバック）
  | .verified,     .observed     => True
  | _,             _             => False

-- ============================================================
-- ゲート通過条件
-- ============================================================

/-- 統合ゲートの前提条件:
    知識は独立に検証されていなければならない（P2 の運用化）。
    breakingChange の場合はエポック増加も要求する。 -/
def integrationGateCondition
    (ki : KnowledgeItem) (w_before w_after : World) : Prop :=
  -- P2: 独立検証済み
  ki.independentlyVerified = true ∧
  -- 検証済みステータス
  ki.status = .verified ∧
  -- breakingChange → エポック増加
  (ki.compatibility = .breakingChange → w_before.epoch < w_after.epoch)

/-- 退役ゲートの前提条件:
    breakingChange により無効化された知識は退役候補。
    「破壊的変更により無効化された知識は退役の候補となる」 -/
def retirementCandidate (ki : KnowledgeItem) : Prop :=
  ki.status = .integrated ∧
  ki.compatibility = .breakingChange

-- ============================================================
-- ワークフローの健全性
-- ============================================================

/-- 統合前に検証が行われていることの保証。
    P2（認知的役割分離）+ P3（学習の統治）の合成。

    検証なしの統合は禁止される。 -/
theorem integration_requires_verification :
  ¬validKnowledgeTransition .observed .integrated ∧
  ¬validKnowledgeTransition .hypothesized .integrated := by
  constructor <;> simp [validKnowledgeTransition]

/-- 退役は統合後にのみ発生する。
    観察・仮説・検証中の知識は退役できない。 -/
theorem retirement_only_after_integration :
  ¬validKnowledgeTransition .observed .retired ∧
  ¬validKnowledgeTransition .hypothesized .retired ∧
  ¬validKnowledgeTransition .verified .retired := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [validKnowledgeTransition]

/-- T5 との接続: 改善（統合）にはフィードバック（検証）が先行する。
    validKnowledgeTransition は .verified → .integrated のみを許可し、
    .observed/.hypothesized → .integrated を禁止する。
    これは T5（フィードバックなしに改善なし）のワークフロー層での表現。 -/
theorem feedback_precedes_improvement :
  validKnowledgeTransition .verified .integrated = True := by
  rfl

-- ============================================================
-- V6 退役接続 (Observable.lean V6)
-- ============================================================

/-!
## V6 と退役の接続

Observable.lean V6:
「退役されない知識は蓄積してコンテキスト効率（V2）を劣化させる」

V6（知識構造の質）は退役の測定を含む:
- 陳腐化した知識の検出率
- 退役プロセスの実行頻度

退役は LearningPhase.retirement として形式化済み。
ここでは退役と V6/V2 の関係を型レベルで表現する。
-/

/-- 退役未実施の知識による V2 劣化リスク。
    統合済みだが breakingChange により無効化された知識が
    退役されずに残ると、コンテキストを圧迫する。 -/
def unretiredKnowledgePressure (ki : KnowledgeItem) : Prop :=
  retirementCandidate ki ∧ ki.status ≠ .retired

/-- 退役が V6 の構成要素であることの型レベル表現。
    知識の状態管理（統合→退役）が適切に行われていることが
    V6 の品質を構成する。 -/
def retirementContributesToV6 (ki : KnowledgeItem) : Prop :=
  -- 退役候補が適切に退役されている
  retirementCandidate ki → ki.status = .retired

-- ============================================================
-- KnowledgeStatus 遷移の構造的性質
-- ============================================================

/-- KnowledgeStatus の遷移に反射性はない（同一状態への遷移は無効）。
    no_self_phase_transition の KnowledgeStatus 版。 -/
theorem no_self_knowledge_transition :
  ∀ (s : KnowledgeStatus), ¬validKnowledgeTransition s s := by
  intro s
  cases s <;> simp [validKnowledgeTransition]

/-- KnowledgeStatus の完全な前進サイクルが存在する:
    observed → hypothesized → verified → integrated → retired。
    full_cycle_exists の KnowledgeStatus 版。 -/
theorem knowledge_full_cycle_exists :
  validKnowledgeTransition .observed .hypothesized ∧
  validKnowledgeTransition .hypothesized .verified ∧
  validKnowledgeTransition .verified .integrated ∧
  validKnowledgeTransition .integrated .retired := by
  constructor <;> trivial

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory (Workflow)

sorry なし。新規 axiom なし。
全 theorem は validPhaseTransition / validKnowledgeTransition の
構造的な cases 解析で証明完了。
-/

end Manifest
