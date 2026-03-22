/-!
# Layer 1: Ontology — World Model

マニフェスト公理系 (T1–T8) を自然に表現するための基本型定義。

Pattern 3 (Stateful World with Audit Trail) をベースに、
マニフェスト固有の概念——セッションの一時性、構造の永続性、
コンテキストの有限性、出力の確率性——を型として符号化する。
-/

namespace Manifest

-- ============================================================
-- Identifiers
-- ============================================================

/-- エージェントの一意識別子 -/
opaque AgentId : Type

/-- セッションの一意識別子 -/
opaque SessionId : Type

/-- リソースの一意識別子 -/
opaque ResourceId : Type

/-- 構造要素の一意識別子 -/
opaque StructureId : Type

-- opaque 型に対する Repr インスタンス（deriving Repr の前提）
instance : Repr AgentId := ⟨fun _ _ => "«AgentId»"⟩
instance : Repr SessionId := ⟨fun _ _ => "«SessionId»"⟩
instance : Repr ResourceId := ⟨fun _ _ => "«ResourceId»"⟩
instance : Repr StructureId := ⟨fun _ _ => "«StructureId»"⟩

-- ============================================================
-- Time and Epoch
-- ============================================================

/-- 離散時間ステップ。監査ログの順序づけと因果関係の基盤。 -/
abbrev Time := Nat

/-- エポック: セッションをまたぐ構造の世代番号。
    T2（構造はエージェントより長く生きる）を反映。 -/
abbrev Epoch := Nat

-- ============================================================
-- Session — T1: エージェントセッションは一時的である
-- ============================================================

/-- セッションの状態。T1 により、セッションは必ず終了する。 -/
inductive SessionStatus where
  | active
  | terminated
  deriving BEq, Repr

/-- セッション: エージェントインスタンスの生存期間を規定する。
    T1 の「セッション間の記憶はない」を構造的に表現するための型。

    - `startTime` と `endTime` が有界性を示す
    - 異なるセッション間で状態を共有する手段は型レベルで存在しない -/
structure Session where
  id       : SessionId
  agent    : AgentId
  start    : Time
  status   : SessionStatus
  deriving Repr

-- ============================================================
-- Structure — T2: 構造はエージェントより長く生きる
-- ============================================================

/-- 構造のカテゴリ。
    マニフェストが列挙する永続的構造の種類。 -/
inductive StructureKind where
  | document
  | test
  | skill
  | designConvention
  | manifest
  deriving BEq, Repr

/-- 構造要素: セッションを超えて永続するアーティファクト。
    T2 により、改善が蓄積する場所。

    - `createdAt` / `lastModifiedAt` は Epoch（セッション世代）で管理
    - `content` は opaque — 形式化の対象は構造の**存在と関係性**であり内容ではない -/
structure Structure where
  id             : StructureId
  kind           : StructureKind
  createdAt      : Epoch
  lastModifiedAt : Epoch
  deriving Repr

-- ============================================================
-- Context Window — T3: コンテキストウィンドウは有限である
-- ============================================================

/-- コンテキストウィンドウ: エージェントが一度に処理できる情報量の上限。
    T3 の物理的制約を型として表現。

    - `capacity` は有限の自然数（0 以上）
    - `used` は現在の使用量
    - `used ≤ capacity` は型不変条件として外部で保証（axiom T3） -/
structure ContextWindow where
  capacity : Nat
  used     : Nat
  deriving Repr

-- ============================================================
-- Output — T4: エージェントの出力は確率的である
-- ============================================================

/-- 出力の確信度。T4 により、出力は常に確率的解釈を伴う。 -/
structure Confidence where
  value : Float
  deriving Repr

/-- エージェントの出力。
    T4 を反映し、同じ入力に対して異なる出力が生成されうることを
    型レベルでは `Output` が一意に決まらないことで表現する。

    `confidence` フィールドは、出力が確率的であることの自己記述。 -/
structure Output (α : Type) where
  result     : α
  confidence : Confidence
  deriving Repr

-- ============================================================
-- Feedback — T5: フィードバックなしに改善は不可能である
-- ============================================================

/-- フィードバックの種類。T5 の制御ループを構成する要素。 -/
inductive FeedbackKind where
  | measurement   -- 測定
  | comparison    -- 比較（目標との差分）
  | adjustment    -- 調整（次のアクションへの反映）
  deriving BEq, Repr

/-- フィードバック: 測定→比較→調整のループの単位。
    T5 により、このループなしに目標への収束は起こらない。 -/
structure Feedback where
  kind      : FeedbackKind
  source    : AgentId
  target    : StructureId
  timestamp : Time
  deriving Repr

-- ============================================================
-- Human & Resource — T6/T7: 人間はリソースの最終決定者 / リソースは有限
-- ============================================================

/-- リソースの種類。T7 により、すべて有限。 -/
inductive ResourceKind where
  | computation
  | dataAccess
  | executionPermission
  | time
  | energy
  deriving BEq, Repr

/-- リソース割り当て。
    T6 により人間が付与し、人間が回収しうる。
    T7 により `amount` は有界。 -/
structure ResourceAllocation where
  resource    : ResourceId
  kind        : ResourceKind
  amount      : Nat           -- 有限量 (T7)
  grantedBy   : AgentId       -- T6: 人間が最終決定者
  grantedTo   : AgentId
  validFrom   : Time
  validUntil  : Option Time   -- None = 明示的に回収されるまで有効
  deriving Repr

-- ============================================================
-- Task — T8: タスクには達成すべき精度水準が存在する
-- ============================================================

/-- 精度水準。T8 により、すべてのタスクはこれを持つ。
    Nat で表現（0–1000 の千分率）。Float を避けて命題レベルでの
    比較を安全にする。 -/
structure PrecisionLevel where
  required : Nat   -- 要求精度 (0–1000, 千分率: 1000 = 100%)
  deriving BEq, Repr

/-- タスク: 達成すべき目標と、それに付随する制約。
    T8 の精度水準に加え、T3（コンテキスト制約）と T7（リソース制約）が
    タスク遂行の境界条件となる（→ P6: 制約充足としてのタスク設計）。 -/
structure Task where
  description       : String
  precisionRequired : PrecisionLevel   -- T8
  contextBudget     : Nat              -- T3 からの制約
  resourceBudget    : Nat              -- T7 からの制約
  deriving Repr

-- ============================================================
-- Action & Severity
-- ============================================================

/-- アクションの重大度。可逆性の判断に使用。 -/
inductive Severity where
  | low
  | medium
  | high
  | critical
  deriving BEq, Repr, Ord

/-- エージェントのアクション。World を遷移させる単位。 -/
structure Action where
  agent    : AgentId
  target   : StructureId
  severity : Severity
  session  : SessionId
  time     : Time
  deriving Repr

-- ============================================================
-- Audit Trail — Pattern 3 ベース
-- ============================================================

/-- WorldState のハッシュ。状態遷移の検証に使用。 -/
opaque WorldHash : Type

instance : Repr WorldHash := ⟨fun _ _ => "«WorldHash»"⟩

/-- 監査エントリ。すべてのアクションを記録する。
    P4（劣化の可観測性）の基盤。 -/
structure AuditEntry where
  timestamp : Time
  agent     : AgentId
  session   : SessionId
  action    : Action
  preHash   : WorldHash
  postHash  : WorldHash
  deriving Repr

-- ============================================================
-- World — 状態の統合
-- ============================================================

/-- ワールド状態: システム全体のスナップショット。
    Pattern 3 (Stateful World + Audit Trail) をマニフェスト用にカスタマイズ。

    各フィールドは特定の T/P に対応:
    - `structures`   → T2 (永続的構造)
    - `sessions`     → T1 (一時的セッション)
    - `allocations`  → T6/T7 (リソース管理)
    - `auditLog`     → P4 (可観測性)
    - `epoch`        → T2 (構造の世代管理)
    - `time`         → 因果関係の順序づけ -/
structure World where
  structures  : List Structure
  sessions    : List Session
  allocations : List ResourceAllocation
  feedbacks   : List Feedback
  auditLog    : List AuditEntry
  epoch       : Epoch
  time        : Time
  deriving Repr

-- ============================================================
-- Agent — エージェントの統合定義
-- ============================================================

/-- エージェントの役割。P2（認知的役割分離）の基盤。 -/
inductive AgentRole where
  | human          -- T6: リソースの最終決定者
  | worker         -- Worker AI
  | verifier       -- Verifier AI (E1/P2: 検証の独立性)
  deriving BEq, Repr

/-- エージェント: ワールドに対してアクションを実行する主体。

    - `role` は P2（役割分離）に対応
    - `contextWindow` は T3 に対応
    - `currentSession` は T1 に対応（None = 非活性） -/
structure Agent where
  id             : AgentId
  role           : AgentRole
  contextWindow  : ContextWindow
  currentSession : Option SessionId
  deriving Repr

-- ============================================================
-- State Transition — 関係ベース（T4 対応）
-- ============================================================

/-- ワールド状態遷移の関係。
    T4（出力の確率性）を表現するため、`execute` は関数ではなく
    **関係（Relation）** として定義する。

    `canTransition agent action w w'` は「agent が action を実行した結果、
    w から w' に遷移しうる」を意味する。関数と異なり、同一の
    (agent, action, w) に対して複数の w' が存在しうる（非決定性）。

    Phase 3+ で具体的な遷移条件を定義する。 -/
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop

/-- 有効な遷移: ある agent と action によって w から w' に遷移可能。 -/
def validTransition (w w' : World) : Prop :=
  ∃ (agent : Agent) (action : Action), canTransition agent action w w'

/-- アクションの実行が拒否される（制約違反）。 -/
def actionBlocked (agent : Agent) (action : Action) (w : World) : Prop :=
  ¬∃ w', canTransition agent action w w'

-- ============================================================
-- E1/E2 Support — 生成・検証・行動空間・リスク
-- ============================================================

/-- エージェントがアクションを**生成**する（Worker の行為）。
    E1（検証の独立性）の形式化に使用。 -/
opaque generates (agent : Agent) (action : Action) (w : World) : Prop

/-- エージェントがアクションを**検証**する（Verifier の行為）。
    E1（検証の独立性）の形式化に使用。 -/
opaque verifies (agent : Agent) (action : Action) (w : World) : Prop

/-- 2つのエージェントが内部状態を共有しているか。
    E1 のバイアス相関の形式化に使用。
    共有 = 同一セッション、共有メモリ、共有パラメータ等。 -/
opaque sharesInternalState (a b : Agent) : Prop

/-- エージェントの行動空間の大きさ（能力の尺度）。
    E2（能力とリスクの不可分性）の形式化に使用。
    値が大きいほど多くのアクションが実行可能。 -/
opaque actionSpaceSize (agent : Agent) (w : World) : Nat

/-- エージェントのリスク露出度。
    E2（能力とリスクの不可分性）の形式化に使用。
    行動空間の拡大に伴い増大する潜在的ダメージの尺度。 -/
opaque riskExposure (agent : Agent) (w : World) : Nat

-- ============================================================
-- Global Resource Bound — T7 対応
-- ============================================================

/-- システム全体のリソース上限。
    T7（リソースは有限）を非自明に表現するための定数。
    具体値は Phase 2+ でドメインに応じて具体化する。 -/
opaque globalResourceBound : Nat

-- ============================================================
-- P1/P4/P5 Support — 信頼・劣化・解釈（Phase 3+ で使用）
-- ============================================================

/-- 信頼度。漸進的に蓄積され、急激に毀損されうる。
    P1b（防護なき拡張は信頼を毀損する）で使用。 -/
opaque trustLevel (agent : Agent) (w : World) : Nat

/-- リスクが顕在化したかの述語。
    P1b で使用。 -/
opaque riskMaterialized (agent : Agent) (w : World) : Prop

/-- 劣化の程度を表す尺度。
    P4 の「勾配」概念を型として表現。 -/
opaque degradationLevel (w : World) : Nat

/-- エージェントが構造を解釈してアクションを生成する関係。
    同一の構造に対して異なるアクションが生成されうる（T4）。
    P5（構造の確率的解釈）で使用。 -/
opaque interpretsStructure
  (agent : Agent) (st : Structure) (action : Action) (w : World) : Prop

-- ============================================================
-- Compatibility / Knowledge Integration — P3/Evolution 共用
-- ============================================================

/-- 知識統合の互換性分類。P3 の核心概念。
    構造への新しい知識の統合が、既存の構造とどう関係するかを分類する。
    Evolution 層でもバージョン間遷移の分類に使用する。 -/
inductive CompatibilityClass where
  | conservativeExtension  -- 既存知識がすべて有効。追加のみ
  | compatibleChange       -- ワークフロー継続可能。一部前提が変化
  | breakingChange         -- 一部ワークフローが無効。移行パスが必要
  deriving BEq, Repr

/-- 構造への知識統合イベント。 -/
structure KnowledgeIntegration where
  before       : World
  after        : World
  compatibility : CompatibilityClass
  deriving Repr

/-- 統治された統合: 互換性が分類され、
    breakingChange の場合は影響を受けるワークフローが列挙される。 -/
def isGoverned (ki : KnowledgeIntegration) : Prop :=
  match ki.compatibility with
  | .conservativeExtension =>
    -- 既存の構造がすべて保持される
    ∀ st, st ∈ ki.before.structures → st ∈ ki.after.structures
  | .compatibleChange =>
    -- 構造は保持されるが、一部が更新されうる
    ∀ st, st ∈ ki.before.structures →
      st ∈ ki.after.structures ∨
      ∃ st', st' ∈ ki.after.structures ∧ st'.id = st.id
  | .breakingChange =>
    -- エポックが進み、影響範囲が追跡可能
    ki.before.epoch < ki.after.epoch

/-- 構造が劣化したかの述語。
    「誤った知識の蓄積」によって構造の品質が低下した状態。 -/
opaque structureDegraded : World → World → Prop

-- ============================================================
-- 境界→緩和策→変数の三段構造 (constraints-taxonomy Part II)
-- ============================================================

/-- 境界条件のレイヤー。
    constraints-taxonomy.md の L1–L6 を3カテゴリに分類。
    「何によって動くか」が分類軸。 -/
inductive BoundaryLayer where
  | fixed              -- L1, L2: 固定境界（投資でも努力でも動かない）
  | investmentVariable -- L3, L4: 投資可変境界（人間の投資判断で調整）
  | environmental      -- L5, L6: 環境境界（選択・構築で変更可能）
  deriving BEq, Repr

/-- 具体的な境界条件の識別子。
    L1–L6 の項目レベル。 -/
inductive BoundaryId where
  | ethicsSafety           -- L1: 倫理・安全境界
  | ontological            -- L2: 存在論的境界
  | resource               -- L3: リソース境界
  | actionSpace            -- L4: 行動空間境界
  | platform               -- L5: プラットフォーム境界
  | architecturalConvention -- L6: 設計規約境界
  deriving BEq, Repr

/-- 各境界条件が属するレイヤー。 -/
def boundaryLayer : BoundaryId → BoundaryLayer
  | .ethicsSafety            => .fixed
  | .ontological             => .fixed
  | .resource                => .investmentVariable
  | .actionSpace             => .investmentVariable
  | .platform                => .environmental
  | .architecturalConvention => .environmental

/-- 緩和策（Mitigation）: 固定境界の影響を軽減する構造的対応。
    constraints-taxonomy.md:
    「境界条件は動かない。緩和策は設計判断。変数は緩和策の効き具合。」 -/
structure Mitigation where
  /-- 対象の境界条件 -/
  boundary : BoundaryId
  /-- 緩和策が影響する構造 -/
  target   : StructureId
  deriving Repr

/-- 投資行動の識別子。
    constraints-taxonomy.md Part III: 投資の3つの形態。 -/
inductive InvestmentKind where
  | resourceInvestment   -- リソース投資（予算増額、プラン upgrade）
  | actionSpaceAdjust    -- 行動空間調整（auto-merge 解禁/権限回収）
  | timeInvestment       -- 時間投資（協働設計、ワークフロー改善参加）
  deriving BEq, Repr

/-- 投資水準。人間の協働への投資の程度。
    Section 6: 信頼は投資行動として具体化される。 -/
opaque investmentLevel (w : World) : Nat

end Manifest
