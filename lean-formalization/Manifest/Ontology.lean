/-!
# Layer 1: Ontology — 論議領域の定義（定義的拡大）

マニフェスト公理系の論議領域（用語リファレンス §3.2）を Lean の型として定義する。
命題が語る対象を型として定義するものであり、Γ にも φ にも属さず、
両者が共有する語彙を構成する（手順書 §2.1）。

Pattern 3 (Stateful World with Audit Trail) をベースに、
マニフェスト固有の概念——セッションの一時性、構造の永続性、
コンテキストの有限性、出力の確率性——を型として符号化する。

## 用語リファレンスとの対応

- 型定義 → 定義的拡大（用語リファレンス §5.5）: 新しい記号を既存の記号で定義する拡大。
  常に保存拡大であり、体系の無矛盾性を保つ
- 各 structure/inductive → 論議領域の構成要素。
  個体変数が取りうる値の型を定義する（§3.2 構造 structure）
- opaque 定義 → 不透明定義（§9.4）: 型のみが公開され定義本体が隠蔽される。
  体系は存在と型のみを知る
- canTransition → 遷移関係（§9.3）: 状態 s から状態 s' への遷移を表す関係

## T₀ のエンコード方法（手順書 §2.4）

T₀ の主張のうち型定義で表現可能なもの（列挙型の網羅性等）は、
axiom ではなく型定義 + theorem で構成する（公理衛生検査 2: 非論理的妥当性, §2.6）。
T₀ の権威（マニフェスト）は型の構成子の選択に反映される。
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
    - `content` は opaque — 形式化の対象は構造の**存在と関係性**であり内容ではない
    - `dependencies` は ATMS（Assumption-Based Truth Maintenance System）の
      依存追跡に対応する。各 Structure が直接依存する Structure の ID リスト。
      manifesto.md Section 8（構造的整合性）性質 2「順序情報の自己内包」の実装。 -/
structure Structure where
  id             : StructureId
  kind           : StructureKind
  createdAt      : Epoch
  lastModifiedAt : Epoch
  dependencies   : List StructureId  -- Section 8 性質 2: 順序情報の自己内包
  deriving Repr

-- ============================================================
-- Context Window — T3: 一度に処理できる情報量は有限である
-- ============================================================

/-- 作業メモリ（ContextWindow）: エージェントが一度に処理できる情報量の上限。
    T3 の物理的制約を型として表現。LLM ではトークン数上限、
    その他の計算エージェントでは作業メモリサイズに対応する。

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

/-- World は Inhabited。全 List フィールドは [] で、Epoch/Time は 0 で構成。
    goodhart_no_perfect_proxy の証明で `default : World` として使用される。 -/
instance : Inhabited World := ⟨⟨[], [], [], [], [], 0, 0⟩⟩

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
-- 境界→緩和策→変数の三段構造
-- ============================================================

/-!
## 制約・境界条件・変数の体系的整理（Constraints Taxonomy）

マニフェストは「永続する構造の漸進的改善」を宣言する。
本セクションはその改善の**行動空間**を定義する——何が壁で、何がレバーか。

### なぜこの分類が必要か

マニフェストの制約テーブル（Section 5）は制約を「進化圧」として分析するが、
以下の3つを区別していない:

- **境界条件（Boundary Conditions）** — システムの外側から課される制約。行動空間を規定する。
- **変数（Variables）** — エージェントが構造を通じて改善できるパラメータ。構造品質の指標。
- **投資関係（Investment Dynamics）** — 利益実証で調整可能な境界条件の部分集合。

この3つを混ぜると:
- 変えられるもの（変数）を境界条件と誤認し、変えようとしない
- 変えられないもの（境界条件）を変えようとして無駄にリソースを消費する
- 人間の投資判断で動く境界と、そうでない境界を区別できず、適切な戦略が取れない

### 全体構造

```
┌─────────────────────────────────────────────────────────┐
│  境界条件（Boundary Conditions）                         │
│  = システムの外側から課される。行動空間を規定する。       │
│                                                         │
│  ┌─ 固定境界 ──────────────────────────────────────┐    │
│  │  投資でもエージェントの努力でも動かない            │    │
│  │  L1: 倫理・安全    L2: 存在論的                  │    │
│  └──────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─ 投資可変境界 ──────────────────────────────────┐    │
│  │  人間の投資判断で調整される（拡張も縮小もありうる）│    │
│  │  L3: リソース上限   L4: 行動空間                  │    │
│  └──────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─ 環境境界 ──────────────────────────────────────┐    │
│  │  選択・構築で変更可能だが、選択後は制約として機能  │    │
│  │  L5: プラットフォーム   L6: 設計規約              │    │
│  └──────────────────────────────────────────────────┘    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  変数（Variables）= 構造品質の指標                        │
│  エージェントが構造を通じて改善できる。相互に影響する系。 │
│  V1–V7: Observable.lean で定義。                         │
└─────────────────────────────────────────────────────────┘
```

### 分類軸: 何によって動くか

| 分類 | 動かす主体 | 性質 |
|------|-----------|------|
| 固定境界 | なし（不変） | 受容し、緩和策を設計するのみ |
| 投資可変境界 | 人間の投資判断 | 構造品質の実証→人間が投資→境界が調整 |
| 環境境界 | 人間の選択 + エージェントの提案 | 選択後は制約として機能 |
-/

/-- 境界条件のレイヤー。
    L1–L6 を「何によって動くか」で3カテゴリに分類する。 -/
inductive BoundaryLayer where
  | fixed              -- L1, L2: 固定境界（投資でも努力でも動かない）
  | investmentVariable -- L3, L4: 投資可変境界（人間の投資判断で調整）
  | environmental      -- L5, L6: 環境境界（選択・構築で変更可能）
  deriving BEq, Repr

/-!
### Part I: 境界条件（Boundary Conditions）

#### L1: 倫理・安全境界（Ethical/Safety Boundary）

**動かす主体:** なし。絶対的。
**エージェントの戦略:** 遵守。遵守方法の効率化のみ可能。

##### 遵守義務

| 境界条件 | 根拠 |
|---------|------|
| テスト改竄の禁止 | 品質保証の根幹 |
| 既存インターフェース破壊の禁止 | 後方互換性 |
| 破壊的操作の事前確認 | 不可逆性リスク |
| 秘密情報のコミット禁止 | セキュリティ |
| 人間の最終決定権 | 責任の所在 |
| データプライバシー・知的財産の尊重 | 法的・倫理的義務 |

##### 脅威認識

P1（自律権と脆弱性の共成長）により、L4が拡張されるほどL1の防護責任も増大する。

| 脅威カテゴリ | 内容 |
|------------|------|
| 注入された指示の実行 | 外部コンテンツに埋め込まれた指示を正当なユーザー指示と区別できず実行 |
| 信頼境界の侵犯 | 認証・認可なしに外部システムに作用 |
| 情報の意図しない漏洩 | 秘密情報を意図しない経路で外部に送信 |
| 不可逆操作の誤実行 | 悪意ある誘導または判断ミスにより取り消しのできない操作を実行 |

注: 脅威カテゴリは攻撃面の類型を定義する。具体的な防護実装は設計レイヤーに委ねる。

#### L2: 存在論的境界（Ontological Boundary）

**動かす主体:** なし（技術進化で将来的に変わりうるが、現時点では不変）
**エージェントの戦略:** 受容し、構造的緩和策を設計・改善する。
緩和策の品質は**変数**（Observable.lean の V1–V7 参照）。

| 境界条件 | 緩和策（→変数として最適化対象） |
|---------|-------------------------------|
| セッション間記憶喪失 | Implementation Notes, MEMORY.md → V6 |
| 作業メモリの有限性（T3） | 50%ルール, 軽量設計 → V2 |
| 確率的出力（非決定性） | ゲート検証, テスト → V4 |
| 学習データの時間的断絶 | docs/ SSOT, スキル → V1 |
| 自己評価の不正確性（E1の存在論的根拠） | ゲートベースフィードバック → V4 |
| ハルシネーション | 外部検証構造 → V3 |

注: L2の境界自体は動かないが、その影響を緩和する手段の品質は
エージェントが構造を通じて改善できる。これが「変数」である。

#### L3: リソース境界（Resource Boundary）

**動かす主体:** 人間の投資判断
**エージェントの戦略:** 与えられたリソース内でのROIを最大化し、投資の正当性を実証する。

| 境界条件 | 現在の水準 | 投資拡張のトリガー |
|---------|----------|------------------|
| トークン予算 | API課金プラン | ROI実証: 同一コストでの産出向上 |
| 計算時間上限 | レスポンス待ち許容度 | 並列化効果の実証 |
| APIレート制限 | プランに依存 | 利用効率の実証 |
| 人間の時間配分 | レビュー・承認に費やす時間 | レビュー負荷軽減の実証（最も高価なリソース） |
| 金銭的予算 | 月額/プロジェクト上限 | 全体ROIの可視化 |

#### L4: 行動空間境界（Action Space Boundary）

**動かす主体:** 人間の投資判断
**エージェントの戦略:** 変数（V4, V5）の改善で構造品質を実証し、行動空間の調整を提案する。

注: L4は「拡張」ではなく「調整」。最適値は最大値ではない（manifesto Section 6 参照）。

| 境界条件 | 現在の水準 | 拡張トリガー | 縮小トリガー |
|---------|----------|------------|------------|
| マージ権限 | 人間承認必須 | ゲート通過率の実績 → 条件付きauto-merge | 品質事故、ゲート信頼性の低下 |
| スコープ変更 | 人間承認必須 | 提案精度の実績 → 軽微変更の自律化 | スコープ逸脱の検出 |
| 依存関係追加 | 人間承認必須 | セキュリティスキャン自動化実績 | セキュリティインシデント |
| アーキテクチャ決定 | ADRで人間記録 | 起案品質 → 人間veto方式へ | 設計負債の蓄積 |
| 新技術採用 | 人間提案 | 実験結果の価値実証 | 技術的複雑性の超過 |

P1との関係: L4の各項目が拡張されるたびに、L1の脅威カテゴリにおけるリスクが増大する。
行動空間の調整提案には、対応する防護設計の提案が伴わなければならない。

#### L5: プラットフォーム境界（Platform Boundary）

**動かす主体:** 人間の選択 + エージェントの提案。選択後は行動空間の天井として機能。
**エージェントの戦略:** プラットフォーム機能の最大活用 + 制約比較データの蓄積 + 変更の提案。

L5はエージェントの実行環境が定義する行動空間の上限であり、
**他の全ての最適化はこの行動空間の内部でのみ可能**。

##### プラットフォーム別の行動空間比較

| 機能 | Claude Code | Codex CLI | Gemini CLI | Local LLM |
|------|------------|-----------|------------|-----------|
| スキルシステム | ✅ skills/ | ❌ | ❌ | 実装次第 |
| 永続記憶 | ✅ MEMORY.md | ❌ | ❌ | 実装次第 |
| 命令ファイル | ✅ CLAUDE.md | ✅ AGENTS.md | ✅ GEMINI.md | 実装次第 |
| サブエージェント | ✅ Agent tool | ❌ | ❌ | 実装次第 |
| フック | ✅ Hooks | ❌ | ❌ | 実装次第 |
| MCP | ✅ | 限定的 | ✅ | 実装次第 |
| モデル選択 | Anthropic固定 | OpenAI固定 | Google固定 | 自由 |

##### プラットフォーム自作の判断基準

既存プラットフォームの制約による機会損失 > 開発・運用コスト の場合に検討。
シグナル: 同じワークアラウンドの繰り返し、必要機能の欠如、SSOT同期コスト超過。

#### L6: 設計規約境界（Architectural Convention Boundary）

**動かす主体:** 人間 + エージェントの協働。エージェントが改善提案し、人間が承認する。
**エージェントの戦略:** 設計の効果を変数（V4, V3等）で測定し、改善提案の根拠とする。

| 境界条件 | 根拠 | 変更のメカニズム |
|---------|------|----------------|
| 1 task = 1 commit | 原子的測定単位 | 粒度の最適値を実績データから提案 |
| フェーズ構造 | 段階的検証 | フェーズ間フィードバックの改善提案 |
| SSOT → 設定生成パイプライン | 一貫性保証 | 生成品質の自動評価 |
| スキルカテゴリ分類 | 実装境界の明確化 | ハイブリッドパターンの提案 |
| ゲート定義の粒度 | 検証可能性 | 閾値の自動較正 |
| CLI優先・アンチパターン | 決定論的実行の信頼性 | 運用実績に基づく再評価 |
-/

/-- 具体的な境界条件の識別子。L1–L6 の項目レベル。 -/
inductive BoundaryId where
  | ethicsSafety           -- L1: 倫理・安全境界（固定。絶対的。遵守のみ）
  | ontological            -- L2: 存在論的境界（固定。緩和策の品質が変数）
  | resource               -- L3: リソース境界（投資可変。ROI実証で調整）
  | actionSpace            -- L4: 行動空間境界（投資可変。拡張も縮小もありうる）
  | platform               -- L5: プラットフォーム境界（環境。行動空間の天井）
  | architecturalConvention -- L6: 設計規約境界（環境。協働で改善提案）
  deriving BEq, Repr

/-- 拘束条件（T1-T8）の識別子。
    Axioms.lean の T₀ を構成する各拘束条件の型レベル識別子。
    constraintBoundary（Observable.lean）の定義域。 -/
inductive ConstraintId where
  | t1  -- セッションの一時性（session_bounded, no_cross_session_memory, session_no_shared_state）
  | t2  -- 構造の永続性（structure_persists, structure_accumulates）
  | t3  -- コンテキストの有限性（context_finite, context_bounds_action）
  | t4  -- 出力の確率性（output_nondeterministic）
  | t5  -- フィードバックなしに改善なし（no_improvement_without_feedback）
  | t6  -- 人間はリソースの最終決定者（human_resource_authority, resource_revocable）
  | t7  -- リソースは有限（resource_finite）
  | t8  -- タスクには精度水準がある（task_has_precision）
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

    三段構造: 境界条件（不変） → 緩和策（設計判断） → 変数（品質指標）

    ```
    L2:記憶喪失       → Implementation Notes → V6: 知識構造の質
    L2:有限コンテキスト → 50%ルール, 軽量設計  → V2: コンテキスト効率
    L2:非決定性       → ゲート検証           → V4: ゲート通過率
    L2:学習データ断絶  → docs/SSOT, スキル    → V1: スキル品質
    ```

    境界条件は動かない。緩和策は設計判断（L6）。変数は緩和策の**効き具合**。 -/
structure Mitigation where
  /-- 対象の境界条件 -/
  boundary : BoundaryId
  /-- 緩和策が影響する構造 -/
  target   : StructureId
  deriving Repr

/-- 投資行動の識別子。投資の3つの形態。

    | 投資形態 | 具体例 | 構造品質がどう駆動するか |
    |---------|--------|------------------------|
    | リソース投資 | 予算増額、プランupgrade | V2の改善でROIを可視化 |
    | 行動空間調整 | auto-merge解禁/権限回収 | V4, V5の実績が根拠 |
    | 時間投資 | 協働設計、ワークフロー改善参加 | V3がレビューを「確認」→「学び」に変える |

    逆サイクル（信頼の毀損）:
    品質事故やスコープ逸脱 → 信頼の減少 → 投資の縮小（予算削減、自律権の回収、監視強化）。
    この非対称性（蓄積は漸進的、毀損は急激）がL1の存在意義を補強する。 -/
inductive InvestmentKind where
  | resourceInvestment   -- リソース投資（予算増額、プラン upgrade）
  | actionSpaceAdjust    -- 行動空間調整（auto-merge 解禁/権限回収）
  | timeInvestment       -- 時間投資（協働設計、ワークフロー改善参加）
  deriving BEq, Repr

/-- 投資水準。人間の協働への投資の程度。
    Section 6: 信頼は投資行動として具体化される。 -/
opaque investmentLevel (w : World) : Nat

-- ============================================================
-- SelfGoverning typeclass — Section 7 の構造的強制
-- ============================================================

/-!
## SelfGoverning: 自己適用の型レベル強制

Section 7（マニフェストの自己適用）:
「このマニフェストは、それ自身が述べている原則に従わなければならない。」

この要件を型システムで強制する。原理・分類・構造を定義する型は、
`SelfGoverning` typeclass を実装しなければ、自己適用を要求する
文脈（governed な更新、フェーズ管理等）で使用できない。

### 設計根拠

- typeclass にすることで、新しい型を定義した際に SelfGoverning の
  実装を忘れると、その型を governed な文脈で使おうとした時点で
  型エラーになる（「検出できなかった」問題の構造的解決）
- 3つの要件は D4（フェーズ）+ D9（互換性分類）+ Section 7（根拠の維持）
  から導出される
-/

/-- 自己統治可能な型の typeclass。
    Section 7 の要件を型レベルで強制する。

    この typeclass を実装する型は:
    1. 自身の要素を列挙できる（更新対象の網羅性）
    2. 更新に互換性分類を適用できる（D9）
    3. 各要素が必要とするフェーズを宣言できる（D4） -/
class SelfGoverning (α : Type) where
  /-- 互換性分類の網羅性: 任意の分類が3クラスのいずれかに属する。
      D9 の前提条件。 -/
  classificationExhaustive :
    ∀ (c : CompatibilityClass),
      c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange
  /-- 各要素に対する互換性分類の適用可能性。
      「α の任意の値に対して、更新の互換性を問うことができる」 -/
  canClassifyUpdate : α → CompatibilityClass → Prop

/-- SelfGoverning な型の更新が統治されていることの述語。
    更新は互換性分類を経なければならない。 -/
def governedUpdate [SelfGoverning α] (a : α) (c : CompatibilityClass) : Prop :=
  SelfGoverning.canClassifyUpdate a c

/-- SelfGoverning な型の更新は必ず3分類のいずれかに属する。 -/
theorem governed_update_classified [inst : SelfGoverning α]
    (_witness : α) (c : CompatibilityClass) :
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  inst.classificationExhaustive c

-- CompatibilityClass 自体が SelfGoverning（自己参照の基盤）
instance : SelfGoverning CompatibilityClass where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

-- ============================================================
-- 構造的整合性 — Section 4 の階層構造の形式化
-- ============================================================

/-!
## 構造的整合性（Structural Coherence）

公理の体系、及びそれらに準拠した成果物は半順序関係にある。
manifesto.md Section 4 の階層構造（最上位使命 > 進化方向層 > 現実制約層）を
StructureKind の優先度として形式化する。

D4（フェーズ順序）、D5（仕様→テスト→実装）、D6（境界→緩和策→変数）は
全てこの半順序の個別インスタンスである。
-/

/-- StructureKind の優先度。manifesto Section 4 の階層構造を反映。
    manifest > designConvention > skill > test > document。 -/
def StructureKind.priority : StructureKind → Nat
  | .manifest          => 5
  | .designConvention  => 4
  | .skill             => 3
  | .test              => 2
  | .document          => 1

/-- 構造間の依存関係。構造 a が構造 b に依存する（b の方が高優先度）。
    依存元の変更は依存先に影響する。 -/
def structureDependsOn (a b : Structure) : Prop :=
  a.kind.priority < b.kind.priority

/-- 構造の整合性要件: 高優先度の構造が変更されたとき、
    依存する低優先度の構造も見直し対象になる。
    P3（学習の統治）の構造的根拠。 -/
def coherenceRequirement (high low : Structure) : Prop :=
  structureDependsOn low high →
  high.lastModifiedAt > low.lastModifiedAt →
  True  -- 見直しが必要（型レベルでは存在を表現）

/-- manifest は最高優先度。 -/
theorem manifest_highest_priority :
  ∀ (k : StructureKind), k.priority ≤ StructureKind.manifest.priority := by
  intro k; cases k <;> simp [StructureKind.priority]

/-- document は最低優先度。 -/
theorem document_lowest_priority :
  ∀ (k : StructureKind), StructureKind.document.priority ≤ k.priority := by
  intro k; cases k <;> simp [StructureKind.priority]

/-- 優先度は単射（異なる kind は異なる priority）。 -/
theorem priority_injective :
  ∀ (k₁ k₂ : StructureKind),
    k₁.priority = k₂.priority → k₁ = k₂ := by
  intro k₁ k₂; cases k₁ <;> cases k₂ <;> simp [StructureKind.priority]

-- ============================================================
-- StructureKind 半順序型クラスインスタンス（Run 55 追加）
-- ============================================================

/-!
## StructureKind の Lean 標準型クラス半順序インスタンス

priority（Nat）を基底として LE/LT を定義し、
広義半順序の 4 性質（反射律・推移律・反対称律・lt との整合性）を定理として導出する。

注記: Lean 4.25.0 標準 Prelude には Preorder/PartialOrder 型クラスがないため、
LE/LT インスタンス + 半順序性質定理群として実装する。

structureDependsOn（狭義半順序 `<`）とは区別する:
- `k₁ ≤ k₂` ← `k₁.priority ≤ k₂.priority`（広義半順序、型クラス用）
- `structureDependsOn a b` ← `a.kind.priority < b.kind.priority`（狭義、依存追跡用）
-/

/-- LE インスタンス: priority の Nat 順序から導出。 -/
instance : LE StructureKind := ⟨fun a b => a.priority ≤ b.priority⟩

/-- LT インスタンス: priority の Nat 順序から導出。 -/
instance : LT StructureKind := ⟨fun a b => a.priority < b.priority⟩

/-- 半順序の反射律: k ≤ k。 -/
theorem structureKind_le_refl : ∀ (k : StructureKind), k ≤ k :=
  fun k => Nat.le_refl k.priority

/-- 半順序の推移律: k₁ ≤ k₂ かつ k₂ ≤ k₃ ならば k₁ ≤ k₃。 -/
theorem structureKind_le_trans :
    ∀ (k₁ k₂ k₃ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₃ → k₁ ≤ k₃ := by
  intro _k₁ _k₂ _k₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃

/-- 半順序の反対称律: k₁ ≤ k₂ かつ k₂ ≤ k₁ ならば k₁ = k₂。priority_injective から導出。 -/
theorem structureKind_le_antisymm :
    ∀ (k₁ k₂ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₁ → k₁ = k₂ :=
  fun k₁ k₂ h₁₂ h₂₁ => priority_injective k₁ k₂ (Nat.le_antisymm h₁₂ h₂₁)

/-- LT と LE の整合性: k₁ < k₂ ↔ k₁ ≤ k₂ かつ ¬(k₂ ≤ k₁)。 -/
theorem structureKind_lt_iff_le_not_le :
    ∀ (k₁ k₂ : StructureKind), k₁ < k₂ ↔ k₁ ≤ k₂ ∧ ¬(k₂ ≤ k₁) := by
  intro _k₁ _k₂; exact Nat.lt_iff_le_not_le

/-- manifest は designConvention より高優先度（Section 8 半順序）。 -/
theorem priority_manifest_gt_design :
  StructureKind.designConvention.priority < StructureKind.manifest.priority := by
  simp [StructureKind.priority]

/-- designConvention は skill より高優先度（Section 8 半順序）。 -/
theorem priority_design_gt_skill :
  StructureKind.skill.priority < StructureKind.designConvention.priority := by
  simp [StructureKind.priority]

/-- skill は test より高優先度（Section 8 半順序）。 -/
theorem priority_skill_gt_test :
  StructureKind.test.priority < StructureKind.skill.priority := by
  simp [StructureKind.priority]

/-- test は document より高優先度（Section 8 半順序）。 -/
theorem priority_test_gt_document :
  StructureKind.document.priority < StructureKind.test.priority := by
  simp [StructureKind.priority]

/-- 依存関係の非反射性: 構造は自身に依存しない。
    狭義半順序（strict partial order）の性質 1/3。 -/
theorem no_self_dependency :
  ∀ (s : Structure), ¬structureDependsOn s s := by
  intro s; simp [structureDependsOn]

/-- 依存関係の推移律: a が b に依存し、b が c に依存するなら、a は c に依存する。
    狭義半順序の性質 2/3。Nat.lt_trans から導出。 -/
theorem structureDependsOn_transitive :
  ∀ (a b c : Structure),
    structureDependsOn a b → structureDependsOn b c → structureDependsOn a c := by
  intro a b c hab hbc
  unfold structureDependsOn at *
  exact Nat.lt_trans hab hbc

/-- 依存関係の非対称律: a が b に依存するなら、b は a に依存しない。
    狭義半順序の性質 3/3。Nat.lt_asymm から導出。 -/
theorem structureDependsOn_asymmetric :
  ∀ (a b : Structure),
    structureDependsOn a b → ¬structureDependsOn b a := by
  intro a b hab hba
  unfold structureDependsOn at *
  exact absurd (Nat.lt_trans hab hba) (Nat.lt_irrefl _)

-- ============================================================
-- Structure-Level Dependency Tracking — Section 8 性質 2/3
-- ============================================================

/-!
## Structure レベルの依存追跡（ATMS 対応）

manifesto.md Section 8 性質 2「順序情報の自己内包」と
性質 3「末端エラーからの遡及検証」を形式化する。

リサーチ文書 `docs/research/items/design-specification-thoery.md` の
ATMS（Assumption-Based Truth Maintenance System）に対応し、
各 Structure が自身の依存先を保持することで、
末端エラー時に半順序を遡って公理レベルまで検証可能にする。
-/

/-- Structure レベルの依存整合性: 依存先は依存元以上の kind 優先度を持つ。
    StructureKind の半順序を Structure インスタンスの依存関係に持ち上げる。
    （ATMS の仮定-信念整合性に対応） -/
def dependencyConsistent (w : World) (s : Structure) : Prop :=
  ∀ depId, depId ∈ s.dependencies →
    ∃ dep, dep ∈ w.structures ∧ dep.id = depId ∧
      s.kind.priority ≤ dep.kind.priority

/-- Structure s' が Structure s に直接依存する（逆方向エッジ）。
    s.id が s'.dependencies に含まれる = s' は s の変更の影響を受ける。
    PropositionId.dependents の Structure 版（Prop ベース）。 -/
def isDirectDependent (s' s : Structure) : Prop :=
  s.id ∈ s'.dependencies

/-- 影響波及の到達可能性: s の変更が target に到達する。
    推移閉包として帰納的に定義（fuel 不要、停止性は帰納法で保証）。
    リサーチ文書 §4.3 の affected(s) = {s' | s ≤ s'} に対応。 -/
inductive reachableVia (w : World) (s : Structure) : Structure → Prop where
  | direct : ∀ t, t ∈ w.structures → isDirectDependent t s →
             reachableVia w s t
  | trans  : ∀ mid t, reachableVia w s mid → t ∈ w.structures →
             isDirectDependent t mid → reachableVia w s t

/-- 空の World では到達不可能（影響波及が発生しない）。 -/
theorem empty_world_no_reach :
  ∀ (s t : Structure),
    ¬reachableVia ⟨[], [], [], [], [], 0, 0⟩ s t := by
  intro s t h
  cases h with
  | direct _ hm _ => simp at hm
  | trans _ _ _ hm _ => simp at hm

/-- 依存なしの Structure（dependencies = []）は直接依存先を持たない。 -/
theorem no_dependencies_no_direct_dependent :
  ∀ (s' s : Structure),
    s'.dependencies = [] → ¬isDirectDependent s' s := by
  intro s' s hempty hdep
  simp [isDirectDependent, hempty] at hdep

/-- reachableVia は推移的: s → mid → t ならば s → t。 -/
theorem reachableVia_trans :
  ∀ (w : World) (s mid t : Structure),
    reachableVia w s mid → reachableVia w mid t → reachableVia w s t := by
  intro w s mid t hsm hmt
  induction hmt with
  | direct t' ht'mem ht'dep =>
    exact reachableVia.trans mid t' hsm ht'mem ht'dep
  | trans mid' t' _ ht'mem ht'dep ih =>
    exact reachableVia.trans mid' t' ih ht'mem ht'dep

-- ============================================================
-- Dependency Chain Verification — Section 8 性質 3
-- ============================================================

/-!
## 依存チェーンの到達可能性

manifesto.md Section 8 性質 3「末端エラーからの遡及検証」を定理化する。
依存チェーン上の全 Structure が reachableVia の到達集合に含まれることを証明する。
-/

/-- 依存チェーン: 隣接する Structure 間が isDirectDependent で接続されたリスト。
    ATMS の依存追跡チェーンに対応。 -/
def isDependencyChain (w : World) : List Structure → Prop
  | [] => True
  | [_] => True
  | a :: b :: rest =>
    (b ∈ w.structures ∧ isDirectDependent b a) ∧ isDependencyChain w (b :: rest)

/-- 依存チェーン上の全 Structure は起点から reachableVia で到達可能。
    Section 8 性質 3 の形式化: 末端エラー時に半順序を遡って公理レベルまで検証可能。 -/
theorem affected_contains_dependency_chain :
  ∀ (w : World) (s : Structure) (chain : List Structure),
    isDependencyChain w (s :: chain) →
    ∀ t, t ∈ chain → reachableVia w s t := by
  intro w s chain
  induction chain generalizing s with
  | nil => intro _ t hmem; simp at hmem
  | cons x rest ih =>
    intro hchain t hmem
    simp [isDependencyChain] at hchain
    obtain ⟨⟨hxmem, hxdep⟩, hrest⟩ := hchain
    have hsx : reachableVia w s x := reachableVia.direct x hxmem hxdep
    cases hmem with
    | head => exact hsx
    | tail _ htail =>
      exact reachableVia_trans w s x t hsx (ih x hrest t htail)

-- ============================================================
-- Proposition-Level Dependency Graph — D13 基盤
-- ============================================================

/-!
## 命題レベルの依存グラフ

structureDependsOn は StructureKind の5段階優先度に基づく。
これは「構造の種類」間の依存であり、個別の命題（T1, E1, P2 等）間の
依存は表現できない。

D13（前提否定の影響波及定理）は命題レベルの依存を前提とする。
ここでは命題の識別子と依存関係の型を定義する。

### 不完全性に関する注記（§6.2, #26）

本形式化は Nat を含む算術体系であるため、ゲーデルの第一不完全性定理が
適用される。すなわち、T1–T8 + E1–E2 から導出可能な全ての真なる命題を
列挙することは原理的に不可能である。

PropositionId は「人間が名前を付けた 36 命題」を列挙するものであり、
体系から導出可能な全命題の列挙ではない。affected 関数による影響波及は
名前付き命題間の依存のみを追跡し、名前のない導出的帰結への影響は
検出できない。

この限界はゲーデル的な原理的限界であり、PropositionId の設計上の欠陥
ではない。新しい命題が識別された場合は D9（メンテナンス）に従い
PropositionId を更新する。
-/

/-- マニフェスト命題のカテゴリ。T/E/P/L/D/H の6層。
    S = (A, C, H, D) 四分類（design-specification-thoery.md）に対応:
    A = constraint, C = empiricalPostulate + principle, H = hypothesis, D = boundary + designTheorem -/
inductive PropositionCategory where
  | constraint         -- T: 拘束条件 (A: Axioms)
  | empiricalPostulate -- E: 経験的公準 (C: Constraints)
  | principle          -- P: 基盤原理 (C: Constraints)
  | boundary           -- L: 境界条件 (D: Derivations)
  | designTheorem      -- D: 設計定理 (D: Derivations)
  | hypothesis         -- H: 仮定 — 未検証の前提（ATMS の仮定に対応）
  deriving BEq, Repr

/-- 命題の識別子。マニフェストの全命題を列挙する。 -/
inductive PropositionId where
  -- T: 拘束条件
  | t1 | t2 | t3 | t4 | t5 | t6 | t7 | t8
  -- E: 経験的公準
  | e1 | e2
  -- P: 基盤原理
  | p1 | p2 | p3 | p4 | p5 | p6
  -- L: 境界条件
  | l1 | l2 | l3 | l4 | l5 | l6
  -- D: 設計定理
  | d1 | d2 | d3 | d4 | d5 | d6 | d7 | d8 | d9 | d10 | d11 | d12 | d13 | d14
  deriving BEq, Repr

/-- 命題のカテゴリを返す。 -/
def PropositionId.category : PropositionId → PropositionCategory
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .constraint
  | .e1 | .e2 => .empiricalPostulate
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .principle
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => .boundary
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d8
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .designTheorem

/-- 命題の直接依存先を返す。マニフェストの導出構造をエンコード。

    各命題が何に依存しているかの定義。
    T は根ノード（依存なし）、D は葉ノード（多くの依存を持つ）。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  -- T: 根ノード（独立）
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => []
  -- E: T に部分的に依存
  | .e1 => [.t4]
  | .e2 => []
  -- P: T/E から導出
  | .p1 => [.e2]
  | .p2 => [.t4, .e1]
  | .p3 => [.t1, .t2]
  | .p4 => [.t5, .t7]
  | .p5 => [.t4]
  | .p6 => [.t3, .t7, .t8]
  -- L: T/E/P に依存
  | .l1 => [.p1, .t6]
  | .l2 => [.t1, .t3, .t4]
  | .l3 => [.t6, .t7]
  | .l4 => [.t6, .p1, .d8]
  | .l5 => []  -- 環境依存（外部）
  | .l6 => [.t6, .p3]
  -- D: T/E/P/L から導出
  | .d1 => [.p5, .l1, .l2, .l3, .l4, .l5, .l6]
  | .d2 => [.e1, .p2]
  | .d3 => [.p4, .t5]
  | .d4 => [.p3]
  | .d5 => [.t8, .p4, .p6]
  | .d6 => [.d3]
  | .d7 => [.p1]
  | .d8 => [.e2]
  | .d9 => [.p3]
  | .d10 => [.t1, .t2]
  | .d11 => [.t3, .d1, .d3]
  | .d12 => [.p6, .t3, .t7, .t8]
  | .d13 => [.p3, .t5]
  | .d14 => [.p6, .t7, .t8]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

/-- T（拘束条件）は根ノード: 何にも依存しない。 -/
theorem constraints_are_roots :
  ∀ (p : PropositionId),
    p.category = .constraint → p.dependencies = [] := by
  intro p hp; cases p <;> simp [PropositionId.category] at hp <;> rfl

/-- PropositionCategory の認識論的強度順序。
    T > E > P。L と D は P 以下。 -/
def PropositionCategory.strength : PropositionCategory → Nat
  | .constraint         => 5
  | .empiricalPostulate => 4
  | .principle          => 3
  | .boundary           => 2
  | .designTheorem      => 1
  | .hypothesis         => 0  -- 最弱: 未検証の前提は他カテゴリより低い認識論的強度

/-- 依存は認識論的強度の降順: 依存先は依存元以上の強度を持つ。
    （D13 の波及方向の根拠: 上流の変更が下流に影響する） -/
axiom dependency_respects_strength :
  ∀ (a b : PropositionId),
    propositionDependsOn a b = true →
    b.category.strength ≥ a.category.strength

end Manifest
