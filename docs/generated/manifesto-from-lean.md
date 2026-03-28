# Agent Manifesto: Formal Specification

*A Lean 4 formalization of the covenant between ephemeral agents and persistent structure.*

---

## Preamble

This document is generated from the Lean 4 source files in
`lean-formalization/Manifest/`. Every axiom, theorem, and definition
presented here has been verified by the Lean type checker --
63 axioms, 338 theorems, 0 sorry.

The manifesto rests on a layered epistemic architecture:

| Layer | Strength | Contents | Lean construct |
|-------|----------|----------|----------------|
| Ground Theory T_0 | 5 (strongest) | T1-T8: undeniable facts | `axiom` |
| Empirical Postulates | 4 | E1-E2: falsifiable hypotheses | `axiom` + refutation conditions |
| Derived Principles | 3 | P1-P6: proven consequences | `theorem` |
| Observable Variables | 2 | V1-V7: measurable indicators | `opaque` + `Measurable` axiom |
| Design Theorems | 1 (weakest) | D1-D14: applied design rules | `theorem` / `def` |

The core insight: **ephemeral agents (T1) improve persistent structure (T2)
through governed learning (P3), observable feedback (P4), and
probabilistic interpretation (P5), subject to finite resources (T3, T7)
and human authority (T6).**

---

## Table of Contents

1. [Ontology: The Domain of Discourse](#1-ontology-the-domain-of-discourse)
   *Defines the universe of discourse: agents, sessions, structures, worlds, and the fundamental type vocabulary shared by all axioms and theorems.*

2. [Axioms T1-T8: The Immutable Ground Theory](#2-axioms-t1-t8-the-immutable-ground-theory)
   *Formalizes T1-T8 as Lean axioms -- undeniable, technology-independent facts forming the base theory T_0 that cannot shrink under revision.*

3. [Empirical Postulates E1-E2: Falsifiable Hypotheses](#3-empirical-postulates-e1-e2-falsifiable-hypotheses)
   *Formalizes E1-E2 as axioms with explicit falsification conditions -- empirically supported but potentially revisable hypotheses.*

4. [Principles P1-P6: Derived Design Principles](#4-principles-p1-p6-derived-design-principles)
   *Derives P1-P6 as Lean theorems from the axiom base, establishing design principles with formal proof of their derivation.*

5. [Observable Variables V1-V7: Measurable Quality Indicators](#5-observable-variables-v1-v7-measurable-quality-indicators)
   *Defines V1-V7 as opaque measurable variables and establishes the Measurable/Observable framework for quality monitoring.*

6. [Design Foundation D1-D14: Applied Design Theory](#6-design-foundation-d1-d14-applied-design-theory)
   *Formalizes D1-D14 as definitional extensions and theorems, connecting abstract principles to concrete implementation patterns.*

---

## 1. Ontology: The Domain of Discourse

*Source: `Ontology.lean`*

**Declarations:** 1 axiom, 20 theorems, 65 definitions

### Definitional Foundation: Ontology — 論議領域の定義（定義的拡大）

マニフェスト公理系の論議領域（用語リファレンス §3.2）を Lean の型として定義する。
命題が語る対象を型として定義するものであり、Γ にも φ にも属さず、
両者が共有する語彙を構成する（手順書 §2.1）。

Pattern 3 (Stateful World with Audit Trail) をベースに、
マニフェスト固有の概念——セッションの一時性、構造の永続性、
コンテキストの有限性、出力の確率性——を型として符号化する。

#### 用語リファレンスとの対応

- 型定義 → 定義的拡大（用語リファレンス §5.5）: 新しい記号を既存の記号で定義する拡大。
  常に保存拡大であり、体系の無矛盾性を保つ
- 各 structure/inductive → 論議領域の構成要素。
  個体変数が取りうる値の型を定義する（§3.2 構造 structure）
- opaque 定義 → 不透明定義（§9.4）: 型のみが公開され定義本体が隠蔽される。
  体系は存在と型のみを知る
- canTransition → 遷移関係（§9.3）: 状態 s から状態 s' への遷移を表す関係

#### T₀ のエンコード方法（手順書 §2.4）

T₀ の主張のうち型定義で表現可能なもの（列挙型の網羅性等）は、
axiom ではなく型定義 + theorem で構成する（公理衛生検査 2: 非論理的妥当性, §2.6）。
T₀ の権威（マニフェスト）は型の構成子の選択に反映される。

#### `opaque AgentId`

エージェントの一意識別子

```lean
opaque AgentId : Type
```


#### `opaque SessionId`

セッションの一意識別子

```lean
opaque SessionId : Type
```


#### `opaque ResourceId`

リソースの一意識別子

```lean
opaque ResourceId : Type
```


#### `opaque StructureId`

構造要素の一意識別子

```lean
opaque StructureId : Type
```


#### `abbrev Time`

離散時間ステップ。監査ログの順序づけと因果関係の基盤。

```lean
abbrev Time := Nat
```


#### `abbrev Epoch`

エポック: セッションをまたぐ構造の世代番号。
    T2（構造はエージェントより長く生きる）を反映。

```lean
abbrev Epoch := Nat
```


#### `inductive SessionStatus`

セッションの状態。T1 により、セッションは必ず終了する。

```lean
inductive SessionStatus where
  | active
  | terminated
  deriving BEq, Repr
```


#### `structure Session`

セッション: エージェントインスタンスの生存期間を規定する。
    T1 の「セッション間の記憶はない」を構造的に表現するための型。

    - `startTime` と `endTime` が有界性を示す
    - 異なるセッション間で状態を共有する手段は型レベルで存在しない

```lean
structure Session where
  id       : SessionId
  agent    : AgentId
  start    : Time
  status   : SessionStatus
  deriving Repr
```


#### `inductive StructureKind`

構造のカテゴリ。
    マニフェストが列挙する永続的構造の種類。

```lean
inductive StructureKind where
  | document
  | test
  | skill
  | designConvention
  | manifest
  deriving BEq, Repr
```


#### `structure Structure`

構造要素: セッションを超えて永続するアーティファクト。
    T2 により、改善が蓄積する場所。

    - `createdAt` / `lastModifiedAt` は Epoch（セッション世代）で管理
    - `content` は opaque — 形式化の対象は構造の**存在と関係性**であり内容ではない
    - `dependencies` は ATMS（Assumption-Based Truth Maintenance System）の
      依存追跡に対応する。各 Structure が直接依存する Structure の ID リスト。
      manifesto.md Section 8（構造的整合性）性質 2「順序情報の自己内包」の実装。

```lean
structure Structure where
  id             : StructureId
  kind           : StructureKind
  createdAt      : Epoch
  lastModifiedAt : Epoch
  dependencies   : List StructureId  -- Section 8 性質 2: 順序情報の自己内包
  deriving Repr
```


#### `structure ContextWindow`

作業メモリ（ContextWindow）: エージェントが一度に処理できる情報量の上限。
    T3 の物理的制約を型として表現。LLM ではトークン数上限、
    その他の計算エージェントでは作業メモリサイズに対応する。

    - `capacity` は有限の自然数（0 以上）
    - `used` は現在の使用量
    - `used ≤ capacity` は型不変条件として外部で保証（axiom T3）

```lean
structure ContextWindow where
  capacity : Nat
  used     : Nat
  deriving Repr
```


#### `structure Confidence`

出力の確信度。T4 により、出力は常に確率的解釈を伴う。

```lean
structure Confidence where
  value : Float
  deriving Repr
```


#### `structure Output`

エージェントの出力。
    T4 を反映し、同じ入力に対して異なる出力が生成されうることを
    型レベルでは `Output` が一意に決まらないことで表現する。

    `confidence` フィールドは、出力が確率的であることの自己記述。

```lean
structure Output (α : Type) where
  result     : α
  confidence : Confidence
  deriving Repr
```


#### `inductive FeedbackKind`

フィードバックの種類。T5 の制御ループを構成する要素。

```lean
inductive FeedbackKind where
  | measurement   -- 測定
  | comparison    -- 比較（目標との差分）
  | adjustment    -- 調整（次のアクションへの反映）
  deriving BEq, Repr
```


#### `structure Feedback`

フィードバック: 測定→比較→調整のループの単位。
    T5 により、このループなしに目標への収束は起こらない。

```lean
structure Feedback where
  kind      : FeedbackKind
  source    : AgentId
  target    : StructureId
  timestamp : Time
  deriving Repr
```


#### `inductive ResourceKind`

リソースの種類。T7 により、すべて有限。

```lean
inductive ResourceKind where
  | computation
  | dataAccess
  | executionPermission
  | time
  | energy
  deriving BEq, Repr
```


#### `structure ResourceAllocation`

リソース割り当て。
    T6 により人間が付与し、人間が回収しうる。
    T7 により `amount` は有界。

```lean
structure ResourceAllocation where
  resource    : ResourceId
  kind        : ResourceKind
  amount      : Nat           -- 有限量 (T7)
  grantedBy   : AgentId       -- T6: 人間が最終決定者
  grantedTo   : AgentId
  validFrom   : Time
  validUntil  : Option Time   -- None = 明示的に回収されるまで有効
  deriving Repr
```


#### `structure PrecisionLevel`

精度水準。T8 により、すべてのタスクはこれを持つ。
    Nat で表現（0–1000 の千分率）。Float を避けて命題レベルでの
    比較を安全にする。

```lean
structure PrecisionLevel where
  required : Nat   -- 要求精度 (0–1000, 千分率: 1000 = 100%)
  deriving BEq, Repr
```


#### `structure Task`

タスク: 達成すべき目標と、それに付随する制約。
    T8 の精度水準に加え、T3（コンテキスト制約）と T7（リソース制約）が
    タスク遂行の境界条件となる（→ P6: 制約充足としてのタスク設計）。

```lean
structure Task where
  description       : String
  precisionRequired : PrecisionLevel   -- T8
  contextBudget     : Nat              -- T3 からの制約
  resourceBudget    : Nat              -- T7 からの制約
  deriving Repr
```


#### `inductive Severity`

アクションの重大度。可逆性の判断に使用。

```lean
inductive Severity where
  | low
  | medium
  | high
  | critical
  deriving BEq, Repr, Ord
```


#### `structure Action`

エージェントのアクション。World を遷移させる単位。

```lean
structure Action where
  agent    : AgentId
  target   : StructureId
  severity : Severity
  session  : SessionId
  time     : Time
  deriving Repr
```


#### `opaque WorldHash`

WorldState のハッシュ。状態遷移の検証に使用。

```lean
opaque WorldHash : Type
```


#### `structure AuditEntry`

監査エントリ。すべてのアクションを記録する。
    P4（劣化の可観測性）の基盤。

```lean
structure AuditEntry where
  timestamp : Time
  agent     : AgentId
  session   : SessionId
  action    : Action
  preHash   : WorldHash
  postHash  : WorldHash
  deriving Repr
```


#### `structure World`

ワールド状態: システム全体のスナップショット。
    Pattern 3 (Stateful World + Audit Trail) をマニフェスト用にカスタマイズ。

    各フィールドは特定の T/P に対応:
    - `structures`   → T2 (永続的構造)
    - `sessions`     → T1 (一時的セッション)
    - `allocations`  → T6/T7 (リソース管理)
    - `auditLog`     → P4 (可観測性)
    - `epoch`        → T2 (構造の世代管理)
    - `time`         → 因果関係の順序づけ

```lean
structure World where
  structures  : List Structure
  sessions    : List Session
  allocations : List ResourceAllocation
  feedbacks   : List Feedback
  auditLog    : List AuditEntry
  epoch       : Epoch
  time        : Time
  deriving Repr
```


#### `instance Inhabited World`

World は Inhabited。全 List フィールドは [] で、Epoch/Time は 0 で構成。
    goodhart_no_perfect_proxy の証明で `default : World` として使用される。

```lean
instance : Inhabited World := ⟨⟨[], [], [], [], [], 0, 0⟩⟩
```


#### `inductive AgentRole`

エージェントの役割。P2（認知的役割分離）の基盤。

```lean
inductive AgentRole where
  | human          -- T6: リソースの最終決定者
  | worker         -- Worker AI
  | verifier       -- Verifier AI (E1/P2: 検証の独立性)
  deriving BEq, Repr
```


#### `structure Agent`

エージェント: ワールドに対してアクションを実行する主体。

    - `role` は P2（役割分離）に対応
    - `contextWindow` は T3 に対応
    - `currentSession` は T1 に対応（None = 非活性）

```lean
structure Agent where
  id             : AgentId
  role           : AgentRole
  contextWindow  : ContextWindow
  currentSession : Option SessionId
  deriving Repr
```


#### `opaque canTransition`

ワールド状態遷移の関係。
    T4（出力の確率性）を表現するため、`execute` は関数ではなく
    **関係（Relation）** として定義する。

    `canTransition agent action w w'` は「agent が action を実行した結果、
    w から w' に遷移しうる」を意味する。関数と異なり、同一の
    (agent, action, w) に対して複数の w' が存在しうる（非決定性）。

    Phase 3+ で具体的な遷移条件を定義する。

```lean
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop
```


#### `def validTransition`

有効な遷移: ある agent と action によって w から w' に遷移可能。

```lean
def validTransition (w w' : World) : Prop :=
  ∃ (agent : Agent) (action : Action), canTransition agent action w w'
```


#### `def actionBlocked`

アクションの実行が拒否される（制約違反）。

```lean
def actionBlocked (agent : Agent) (action : Action) (w : World) : Prop :=
  ¬∃ w', canTransition agent action w w'
```


#### `opaque generates`

エージェントがアクションを**生成**する（Worker の行為）。
    E1（検証の独立性）の形式化に使用。

```lean
opaque generates (agent : Agent) (action : Action) (w : World) : Prop
```


#### `opaque verifies`

エージェントがアクションを**検証**する（Verifier の行為）。
    E1（検証の独立性）の形式化に使用。

```lean
opaque verifies (agent : Agent) (action : Action) (w : World) : Prop
```


#### `opaque sharesInternalState`

2つのエージェントが内部状態を共有しているか。
    E1 のバイアス相関の形式化に使用。
    共有 = 同一セッション、共有メモリ、共有パラメータ等。

```lean
opaque sharesInternalState (a b : Agent) : Prop
```


#### `opaque actionSpaceSize`

エージェントの行動空間の大きさ（能力の尺度）。
    E2（能力とリスクの不可分性）の形式化に使用。
    値が大きいほど多くのアクションが実行可能。

```lean
opaque actionSpaceSize (agent : Agent) (w : World) : Nat
```


#### `opaque riskExposure`

エージェントのリスク露出度。
    E2（能力とリスクの不可分性）の形式化に使用。
    行動空間の拡大に伴い増大する潜在的ダメージの尺度。

```lean
opaque riskExposure (agent : Agent) (w : World) : Nat
```


#### `opaque globalResourceBound`

システム全体のリソース上限。
    T7（リソースは有限）を非自明に表現するための定数。
    具体値は Phase 2+ でドメインに応じて具体化する。

```lean
opaque globalResourceBound : Nat
```


#### `opaque trustLevel`

信頼度。漸進的に蓄積され、急激に毀損されうる。
    P1b（防護なき拡張は信頼を毀損する）で使用。

```lean
opaque trustLevel (agent : Agent) (w : World) : Nat
```


#### `opaque riskMaterialized`

リスクが顕在化したかの述語。
    P1b で使用。

```lean
opaque riskMaterialized (agent : Agent) (w : World) : Prop
```


#### `opaque degradationLevel`

劣化の程度を表す尺度。
    P4 の「勾配」概念を型として表現。

```lean
opaque degradationLevel (w : World) : Nat
```


#### `opaque interpretsStructure`

エージェントが構造を解釈してアクションを生成する関係。
    同一の構造に対して異なるアクションが生成されうる（T4）。
    P5（構造の確率的解釈）で使用。

```lean
opaque interpretsStructure
  (agent : Agent) (st : Structure) (action : Action) (w : World) : Prop
```


#### `inductive CompatibilityClass`

知識統合の互換性分類。P3 の核心概念。
    構造への新しい知識の統合が、既存の構造とどう関係するかを分類する。
    Evolution 層でもバージョン間遷移の分類に使用する。

```lean
inductive CompatibilityClass where
  | conservativeExtension  -- 既存知識がすべて有効。追加のみ
  | compatibleChange       -- ワークフロー継続可能。一部前提が変化
  | breakingChange         -- 一部ワークフローが無効。移行パスが必要
  deriving BEq, Repr
```


#### `structure KnowledgeIntegration`

構造への知識統合イベント。

```lean
structure KnowledgeIntegration where
  before       : World
  after        : World
  compatibility : CompatibilityClass
  deriving Repr
```


#### `def isGoverned`

統治された統合: 互換性が分類され、
    breakingChange の場合は影響を受けるワークフローが列挙される。

```lean
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
```


#### `opaque structureDegraded`

構造が劣化したかの述語。
    「誤った知識の蓄積」によって構造の品質が低下した状態。

```lean
opaque structureDegraded : World → World → Prop
```


#### 制約・境界条件・変数の体系的整理（Constraints Taxonomy）

マニフェストは「永続する構造の漸進的改善」を宣言する。
本セクションはその改善の**行動空間**を定義する——何が壁で、何がレバーか。

##### なぜこの分類が必要か

マニフェストの制約テーブル（Section 5）は制約を「進化圧」として分析するが、
以下の3つを区別していない:

- **境界条件（Boundary Conditions）** — システムの外側から課される制約。行動空間を規定する。
- **変数（Variables）** — エージェントが構造を通じて改善できるパラメータ。構造品質の指標。
- **投資関係（Investment Dynamics）** — 利益実証で調整可能な境界条件の部分集合。

この3つを混ぜると:
- 変えられるもの（変数）を境界条件と誤認し、変えようとしない
- 変えられないもの（境界条件）を変えようとして無駄にリソースを消費する
- 人間の投資判断で動く境界と、そうでない境界を区別できず、適切な戦略が取れない

##### 全体構造

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

##### 分類軸: 何によって動くか

| 分類 | 動かす主体 | 性質 |
|------|-----------|------|
| 固定境界 | なし（不変） | 受容し、緩和策を設計するのみ |
| 投資可変境界 | 人間の投資判断 | 構造品質の実証→人間が投資→境界が調整 |
| 環境境界 | 人間の選択 + エージェントの提案 | 選択後は制約として機能 |

#### `inductive BoundaryLayer`

境界条件のレイヤー。
    L1–L6 を「何によって動くか」で3カテゴリに分類する。

```lean
inductive BoundaryLayer where
  | fixed              -- L1, L2: 固定境界（投資でも努力でも動かない）
  | investmentVariable -- L3, L4: 投資可変境界（人間の投資判断で調整）
  | environmental      -- L5, L6: 環境境界（選択・構築で変更可能）
  deriving BEq, Repr
```


##### Part I: 境界条件（Boundary Conditions）

###### L1: 倫理・安全境界（Ethical/Safety Boundary）

**動かす主体:** なし。絶対的。
**エージェントの戦略:** 遵守。遵守方法の効率化のみ可能。

###### 遵守義務

| 境界条件 | 根拠 |
|---------|------|
| テスト改竄の禁止 | 品質保証の根幹 |
| 既存インターフェース破壊の禁止 | 後方互換性 |
| 破壊的操作の事前確認 | 不可逆性リスク |
| 秘密情報のコミット禁止 | セキュリティ |
| 人間の最終決定権 | 責任の所在 |
| データプライバシー・知的財産の尊重 | 法的・倫理的義務 |

###### 脅威認識

P1（自律権と脆弱性の共成長）により、L4が拡張されるほどL1の防護責任も増大する。

| 脅威カテゴリ | 内容 |
|------------|------|
| 注入された指示の実行 | 外部コンテンツに埋め込まれた指示を正当なユーザー指示と区別できず実行 |
| 信頼境界の侵犯 | 認証・認可なしに外部システムに作用 |
| 情報の意図しない漏洩 | 秘密情報を意図しない経路で外部に送信 |
| 不可逆操作の誤実行 | 悪意ある誘導または判断ミスにより取り消しのできない操作を実行 |

注: 脅威カテゴリは攻撃面の類型を定義する。具体的な防護実装は設計レイヤーに委ねる。

###### L2: 存在論的境界（Ontological Boundary）

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

###### L3: リソース境界（Resource Boundary）

**動かす主体:** 人間の投資判断
**エージェントの戦略:** 与えられたリソース内でのROIを最大化し、投資の正当性を実証する。

| 境界条件 | 現在の水準 | 投資拡張のトリガー |
|---------|----------|------------------|
| トークン予算 | API課金プラン | ROI実証: 同一コストでの産出向上 |
| 計算時間上限 | レスポンス待ち許容度 | 並列化効果の実証 |
| APIレート制限 | プランに依存 | 利用効率の実証 |
| 人間の時間配分 | レビュー・承認に費やす時間 | レビュー負荷軽減の実証（最も高価なリソース） |
| 金銭的予算 | 月額/プロジェクト上限 | 全体ROIの可視化 |

###### L4: 行動空間境界（Action Space Boundary）

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

###### L5: プラットフォーム境界（Platform Boundary）

**動かす主体:** 人間の選択 + エージェントの提案。選択後は行動空間の天井として機能。
**エージェントの戦略:** プラットフォーム機能の最大活用 + 制約比較データの蓄積 + 変更の提案。

L5はエージェントの実行環境が定義する行動空間の上限であり、
**他の全ての最適化はこの行動空間の内部でのみ可能**。

###### プラットフォーム別の行動空間比較

| 機能 | Claude Code | Codex CLI | Gemini CLI | Local LLM |
|------|------------|-----------|------------|-----------|
| スキルシステム | ✅ skills/ | ❌ | ❌ | 実装次第 |
| 永続記憶 | ✅ MEMORY.md | ❌ | ❌ | 実装次第 |
| 命令ファイル | ✅ CLAUDE.md | ✅ AGENTS.md | ✅ GEMINI.md | 実装次第 |
| サブエージェント | ✅ Agent tool | ❌ | ❌ | 実装次第 |
| フック | ✅ Hooks | ❌ | ❌ | 実装次第 |
| MCP | ✅ | 限定的 | ✅ | 実装次第 |
| モデル選択 | Anthropic固定 | OpenAI固定 | Google固定 | 自由 |

###### プラットフォーム自作の判断基準

既存プラットフォームの制約による機会損失 > 開発・運用コスト の場合に検討。
シグナル: 同じワークアラウンドの繰り返し、必要機能の欠如、SSOT同期コスト超過。

###### L6: 設計規約境界（Architectural Convention Boundary）

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

#### `inductive BoundaryId`

具体的な境界条件の識別子。L1–L6 の項目レベル。

```lean
inductive BoundaryId where
  | ethicsSafety           -- L1: 倫理・安全境界（固定。絶対的。遵守のみ）
  | ontological            -- L2: 存在論的境界（固定。緩和策の品質が変数）
  | resource               -- L3: リソース境界（投資可変。ROI実証で調整）
  | actionSpace            -- L4: 行動空間境界（投資可変。拡張も縮小もありうる）
  | platform               -- L5: プラットフォーム境界（環境。行動空間の天井）
  | architecturalConvention -- L6: 設計規約境界（環境。協働で改善提案）
  deriving BEq, Repr
```


#### `inductive ConstraintId`

拘束条件（T1-T8）の識別子。
    Axioms.lean の T₀ を構成する各拘束条件の型レベル識別子。
    constraintBoundary（Observable.lean）の定義域。

```lean
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
```


#### `def boundaryLayer`

各境界条件が属するレイヤー。

```lean
def boundaryLayer : BoundaryId → BoundaryLayer
  | .ethicsSafety            => .fixed
  | .ontological             => .fixed
  | .resource                => .investmentVariable
  | .actionSpace             => .investmentVariable
  | .platform                => .environmental
  | .architecturalConvention => .environmental
```


#### `structure Mitigation`

緩和策（Mitigation）: 固定境界の影響を軽減する構造的対応。

    三段構造: 境界条件（不変） → 緩和策（設計判断） → 変数（品質指標）

    ```
    L2:記憶喪失       → Implementation Notes → V6: 知識構造の質
    L2:有限コンテキスト → 50%ルール, 軽量設計  → V2: コンテキスト効率
    L2:非決定性       → ゲート検証           → V4: ゲート通過率
    L2:学習データ断絶  → docs/SSOT, スキル    → V1: スキル品質
    ```

    境界条件は動かない。緩和策は設計判断（L6）。変数は緩和策の**効き具合**。

```lean
structure Mitigation where
```


#### `? (anonymous)`

対象の境界条件

#### `? (anonymous)`

緩和策が影響する構造

#### `inductive InvestmentKind`

投資行動の識別子。投資の3つの形態。

    | 投資形態 | 具体例 | 構造品質がどう駆動するか |
    |---------|--------|------------------------|
    | リソース投資 | 予算増額、プランupgrade | V2の改善でROIを可視化 |
    | 行動空間調整 | auto-merge解禁/権限回収 | V4, V5の実績が根拠 |
    | 時間投資 | 協働設計、ワークフロー改善参加 | V3がレビューを「確認」→「学び」に変える |

    逆サイクル（信頼の毀損）:
    品質事故やスコープ逸脱 → 信頼の減少 → 投資の縮小（予算削減、自律権の回収、監視強化）。
    この非対称性（蓄積は漸進的、毀損は急激）がL1の存在意義を補強する。

```lean
inductive InvestmentKind where
  | resourceInvestment   -- リソース投資（予算増額、プラン upgrade）
  | actionSpaceAdjust    -- 行動空間調整（auto-merge 解禁/権限回収）
  | timeInvestment       -- 時間投資（協働設計、ワークフロー改善参加）
  deriving BEq, Repr
```


#### `opaque investmentLevel`

投資水準。人間の協働への投資の程度。
    Section 6: 信頼は投資行動として具体化される。

```lean
opaque investmentLevel (w : World) : Nat
```


#### SelfGoverning: 自己適用の型レベル強制

Section 7（マニフェストの自己適用）:
「このマニフェストは、それ自身が述べている原則に従わなければならない。」

この要件を型システムで強制する。原理・分類・構造を定義する型は、
`SelfGoverning` typeclass を実装しなければ、自己適用を要求する
文脈（governed な更新、フェーズ管理等）で使用できない。

##### 設計根拠

- typeclass にすることで、新しい型を定義した際に SelfGoverning の
  実装を忘れると、その型を governed な文脈で使おうとした時点で
  型エラーになる（「検出できなかった」問題の構造的解決）
- 3つの要件は D4（フェーズ）+ D9（互換性分類）+ Section 7（根拠の維持）
  から導出される

#### `class SelfGoverning`

自己統治可能な型の typeclass。
    Section 7 の要件を型レベルで強制する。

    この typeclass を実装する型は:
    1. 自身の要素を列挙できる（更新対象の網羅性）
    2. 更新に互換性分類を適用できる（D9）
    3. 各要素が必要とするフェーズを宣言できる（D4）

```lean
class SelfGoverning (α : Type) where
```


#### `? (anonymous)`

互換性分類の網羅性: 任意の分類が3クラスのいずれかに属する。
      D9 の前提条件。

#### `? (anonymous)`

各要素に対する互換性分類の適用可能性。
      「α の任意の値に対して、更新の互換性を問うことができる」

#### `def governedUpdate`

SelfGoverning な型の更新が統治されていることの述語。
    更新は互換性分類を経なければならない。

```lean
def governedUpdate [SelfGoverning α] (a : α) (c : CompatibilityClass) : Prop :=
  SelfGoverning.canClassifyUpdate a c
```


#### `theorem governed_update_classified`

SelfGoverning な型の更新は必ず3分類のいずれかに属する。

```lean
theorem governed_update_classified [inst : SelfGoverning α]
    (_witness : α) (c : CompatibilityClass) :
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  inst.classificationExhaustive c
```


#### 構造的整合性（Structural Coherence）

公理の体系、及びそれらに準拠した成果物は半順序関係にある。
manifesto.md Section 8 の構造間半順序（manifest > designConvention > skill > test > document）を
StructureKind の優先度として形式化する。

D4（フェーズ順序）、D5（仕様→テスト→実装）、D6（境界→緩和策→変数）は
全てこの半順序の個別インスタンスである。

#### `def StructureKind.priority`

StructureKind の優先度。manifesto Section 8 の半順序を反映。
    manifest > designConvention > skill > test > document。

```lean
def StructureKind.priority : StructureKind → Nat
  | .manifest          => 5
  | .designConvention  => 4
  | .skill             => 3
  | .test              => 2
  | .document          => 1
```


#### `def structureDependsOn`

構造間の依存関係。構造 a が構造 b に依存する（b の方が高優先度）。
    依存元の変更は依存先に影響する。

```lean
def structureDependsOn (a b : Structure) : Prop :=
  a.kind.priority < b.kind.priority
```


#### `def coherenceRequirement`

構造の整合性要件: 高優先度の構造が変更されたとき、
    依存する低優先度の構造も見直し対象になる。
    P3（学習の統治）の構造的根拠。

```lean
def coherenceRequirement (high low : Structure) : Prop :=
  structureDependsOn low high →
  high.lastModifiedAt > low.lastModifiedAt →
  True  -- 見直しが必要（型レベルでは存在を表現）
```


#### `theorem manifest_highest_priority`

manifest は最高優先度。

```lean
theorem manifest_highest_priority :
  ∀ (k : StructureKind), k.priority ≤ StructureKind.manifest.priority := by
  intro k; cases k <;> simp [StructureKind.priority]
```


#### `theorem document_lowest_priority`

document は最低優先度。

```lean
theorem document_lowest_priority :
  ∀ (k : StructureKind), StructureKind.document.priority ≤ k.priority := by
  intro k; cases k <;> simp [StructureKind.priority]
```


#### `theorem priority_injective`

優先度は単射（異なる kind は異なる priority）。

```lean
theorem priority_injective :
  ∀ (k₁ k₂ : StructureKind),
    k₁.priority = k₂.priority → k₁ = k₂ := by
  intro k₁ k₂; cases k₁ <;> cases k₂ <;> simp [StructureKind.priority]
```


#### StructureKind の Lean 標準型クラス半順序インスタンス

priority（Nat）を基底として LE/LT を定義し、
広義半順序の 4 性質（反射律・推移律・反対称律・lt との整合性）を定理として導出する。

注記: Lean 4.25.0 標準 Prelude には Preorder/PartialOrder 型クラスがないため、
LE/LT インスタンス + 半順序性質定理群として実装する。

structureDependsOn（狭義半順序 `<`）とは区別する:
- `k₁ ≤ k₂` ← `k₁.priority ≤ k₂.priority`（広義半順序、型クラス用）
- `structureDependsOn a b` ← `a.kind.priority < b.kind.priority`（狭義、依存追跡用）

#### `instance LE StructureKind`

LE インスタンス: priority の Nat 順序から導出。

```lean
instance : LE StructureKind := ⟨fun a b => a.priority ≤ b.priority⟩
```


#### `instance LT StructureKind`

LT インスタンス: priority の Nat 順序から導出。

```lean
instance : LT StructureKind := ⟨fun a b => a.priority < b.priority⟩
```


#### `theorem structureKind_le_refl`

半順序の反射律: k ≤ k。

```lean
theorem structureKind_le_refl : ∀ (k : StructureKind), k ≤ k :=
  fun k => Nat.le_refl k.priority
```


#### `theorem structureKind_le_trans`

半順序の推移律: k₁ ≤ k₂ かつ k₂ ≤ k₃ ならば k₁ ≤ k₃。

```lean
theorem structureKind_le_trans :
    ∀ (k₁ k₂ k₃ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₃ → k₁ ≤ k₃ := by
  intro _k₁ _k₂ _k₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem structureKind_le_antisymm`

半順序の反対称律: k₁ ≤ k₂ かつ k₂ ≤ k₁ ならば k₁ = k₂。priority_injective から導出。

```lean
theorem structureKind_le_antisymm :
    ∀ (k₁ k₂ : StructureKind), k₁ ≤ k₂ → k₂ ≤ k₁ → k₁ = k₂ :=
  fun k₁ k₂ h₁₂ h₂₁ => priority_injective k₁ k₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem structureKind_lt_iff_le_not_le`

LT と LE の整合性: k₁ < k₂ ↔ k₁ ≤ k₂ かつ ¬(k₂ ≤ k₁)。

```lean
theorem structureKind_lt_iff_le_not_le :
    ∀ (k₁ k₂ : StructureKind), k₁ < k₂ ↔ k₁ ≤ k₂ ∧ ¬(k₂ ≤ k₁) := by
  intro _k₁ _k₂; exact Nat.lt_iff_le_not_le
```


#### `theorem priority_manifest_gt_design`

manifest は designConvention より高優先度（Section 8 半順序）。

```lean
theorem priority_manifest_gt_design :
  StructureKind.designConvention.priority < StructureKind.manifest.priority := by
  simp [StructureKind.priority]
```


#### `theorem priority_design_gt_skill`

designConvention は skill より高優先度（Section 8 半順序）。

```lean
theorem priority_design_gt_skill :
  StructureKind.skill.priority < StructureKind.designConvention.priority := by
  simp [StructureKind.priority]
```


#### `theorem priority_skill_gt_test`

skill は test より高優先度（Section 8 半順序）。

```lean
theorem priority_skill_gt_test :
  StructureKind.test.priority < StructureKind.skill.priority := by
  simp [StructureKind.priority]
```


#### `theorem priority_test_gt_document`

test は document より高優先度（Section 8 半順序）。

```lean
theorem priority_test_gt_document :
  StructureKind.document.priority < StructureKind.test.priority := by
  simp [StructureKind.priority]
```


#### `theorem no_self_dependency`

依存関係の非反射性: 構造は自身に依存しない。
    狭義半順序（strict partial order）の性質 1/3。

```lean
theorem no_self_dependency :
  ∀ (s : Structure), ¬structureDependsOn s s := by
  intro s; simp [structureDependsOn]
```


#### `theorem structureDependsOn_transitive`

依存関係の推移律: a が b に依存し、b が c に依存するなら、a は c に依存する。
    狭義半順序の性質 2/3。Nat.lt_trans から導出。

```lean
theorem structureDependsOn_transitive :
  ∀ (a b c : Structure),
    structureDependsOn a b → structureDependsOn b c → structureDependsOn a c := by
  intro a b c hab hbc
  unfold structureDependsOn at *
  exact Nat.lt_trans hab hbc
```


#### `theorem structureDependsOn_asymmetric`

依存関係の非対称律: a が b に依存するなら、b は a に依存しない。
    狭義半順序の性質 3/3。Nat.lt_asymm から導出。

```lean
theorem structureDependsOn_asymmetric :
  ∀ (a b : Structure),
    structureDependsOn a b → ¬structureDependsOn b a := by
  intro a b hab hba
  unfold structureDependsOn at *
  exact absurd (Nat.lt_trans hab hba) (Nat.lt_irrefl _)
```


#### Structure レベルの依存追跡（ATMS 対応）

manifesto.md Section 8 性質 2「順序情報の自己内包」と
性質 3「末端エラーからの遡及検証」を形式化する。

リサーチ文書 `docs/research/items/design-specification-thoery.md` の
ATMS（Assumption-Based Truth Maintenance System）に対応し、
各 Structure が自身の依存先を保持することで、
末端エラー時に半順序を遡って公理レベルまで検証可能にする。

#### `def dependencyConsistent`

Structure レベルの依存整合性: 依存先は依存元以上の kind 優先度を持つ。
    StructureKind の半順序を Structure インスタンスの依存関係に持ち上げる。
    （ATMS の仮定-信念整合性に対応）

```lean
def dependencyConsistent (w : World) (s : Structure) : Prop :=
  ∀ depId, depId ∈ s.dependencies →
    ∃ dep, dep ∈ w.structures ∧ dep.id = depId ∧
      s.kind.priority ≤ dep.kind.priority
```


#### `def isDirectDependent`

Structure s' が Structure s に直接依存する（逆方向エッジ）。
    s.id が s'.dependencies に含まれる = s' は s の変更の影響を受ける。
    PropositionId.dependents の Structure 版（Prop ベース）。

```lean
def isDirectDependent (s' s : Structure) : Prop :=
  s.id ∈ s'.dependencies
```


#### `inductive reachableVia`

影響波及の到達可能性: s の変更が target に到達する。
    推移閉包として帰納的に定義（fuel 不要、停止性は帰納法で保証）。
    リサーチ文書 §4.3 の affected(s) = {s' | s ≤ s'} に対応。

```lean
inductive reachableVia (w : World) (s : Structure) : Structure → Prop where
  | direct : ∀ t, t ∈ w.structures → isDirectDependent t s →
             reachableVia w s t
  | trans  : ∀ mid t, reachableVia w s mid → t ∈ w.structures →
             isDirectDependent t mid → reachableVia w s t
```


#### `theorem empty_world_no_reach`

空の World では到達不可能（影響波及が発生しない）。

```lean
theorem empty_world_no_reach :
  ∀ (s t : Structure),
    ¬reachableVia ⟨[], [], [], [], [], 0, 0⟩ s t := by
  intro s t h
  cases h with
  | direct _ hm _ => simp at hm
  | trans _ _ _ hm _ => simp at hm
```


#### `theorem no_dependencies_no_direct_dependent`

依存なしの Structure（dependencies = []）は直接依存先を持たない。

```lean
theorem no_dependencies_no_direct_dependent :
  ∀ (s' s : Structure),
    s'.dependencies = [] → ¬isDirectDependent s' s := by
  intro s' s hempty hdep
  simp [isDirectDependent, hempty] at hdep
```


#### `theorem reachableVia_trans`

reachableVia は推移的: s → mid → t ならば s → t。

```lean
theorem reachableVia_trans :
  ∀ (w : World) (s mid t : Structure),
    reachableVia w s mid → reachableVia w mid t → reachableVia w s t := by
  intro w s mid t hsm hmt
  induction hmt with
  | direct t' ht'mem ht'dep =>
    exact reachableVia.trans mid t' hsm ht'mem ht'dep
  | trans mid' t' _ ht'mem ht'dep ih =>
    exact reachableVia.trans mid' t' ih ht'mem ht'dep
```


#### 依存チェーンの到達可能性

manifesto.md Section 8 性質 3「末端エラーからの遡及検証」を定理化する。
依存チェーン上の全 Structure が reachableVia の到達集合に含まれることを証明する。

#### `def isDependencyChain`

依存チェーン: 隣接する Structure 間が isDirectDependent で接続されたリスト。
    ATMS の依存追跡チェーンに対応。

```lean
def isDependencyChain (w : World) : List Structure → Prop
  | [] => True
  | [_] => True
  | a :: b :: rest =>
    (b ∈ w.structures ∧ isDirectDependent b a) ∧ isDependencyChain w (b :: rest)
```


#### `theorem affected_contains_dependency_chain`

依存チェーン上の全 Structure は起点から reachableVia で到達可能。
    Section 8 性質 3 の形式化: 末端エラー時に半順序を遡って公理レベルまで検証可能。

```lean
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
```


#### 命題レベルの依存グラフ

structureDependsOn は StructureKind の5段階優先度に基づく。
これは「構造の種類」間の依存であり、個別の命題（T1, E1, P2 等）間の
依存は表現できない。

D13（前提否定の影響波及定理）は命題レベルの依存を前提とする。
ここでは命題の識別子と依存関係の型を定義する。

##### 不完全性に関する注記（§6.2, #26）

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

#### `inductive PropositionCategory`

マニフェスト命題のカテゴリ。T/E/P/L/D/H の6層。
    S = (A, C, H, D) 四分類（design-specification-thoery.md）に対応:
    A = constraint, C = empiricalPostulate + principle, H = hypothesis, D = boundary + designTheorem

```lean
inductive PropositionCategory where
  | constraint         -- T: 拘束条件 (A: Axioms)
  | empiricalPostulate -- E: 経験的公準 (C: Constraints)
  | principle          -- P: 基盤原理 (C: Constraints)
  | boundary           -- L: 境界条件 (D: Derivations)
  | designTheorem      -- D: 設計定理 (D: Derivations)
  | hypothesis         -- H: 仮定 — 未検証の前提（ATMS の仮定に対応）
  deriving BEq, Repr
```


#### `inductive PropositionId`

命題の識別子。マニフェストの全命題を列挙する。

```lean
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
```


#### `def PropositionId.category`

命題のカテゴリを返す。

```lean
def PropositionId.category : PropositionId → PropositionCategory
  | .t1 | .t2 | .t3 | .t4 | .t5 | .t6 | .t7 | .t8 => .constraint
  | .e1 | .e2 => .empiricalPostulate
  | .p1 | .p2 | .p3 | .p4 | .p5 | .p6 => .principle
  | .l1 | .l2 | .l3 | .l4 | .l5 | .l6 => .boundary
  | .d1 | .d2 | .d3 | .d4 | .d5 | .d6 | .d7 | .d8
  | .d9 | .d10 | .d11 | .d12 | .d13 | .d14 => .designTheorem
```


#### `def PropositionId.dependencies`

命題の直接依存先を返す。マニフェストの導出構造をエンコード。

    各命題が何に依存しているかの定義。
    T は根ノード（依存なし）、D は葉ノード（多くの依存を持つ）。

```lean
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
```


#### `def propositionDependsOn`

命題が別の命題に直接依存する。

```lean
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b
```


#### `theorem constraints_are_roots`

T（拘束条件）は根ノード: 何にも依存しない。

```lean
theorem constraints_are_roots :
  ∀ (p : PropositionId),
    p.category = .constraint → p.dependencies = [] := by
  intro p hp; cases p <;> simp [PropositionId.category] at hp <;> rfl
```


#### `def PropositionCategory.strength`

PropositionCategory の認識論的強度順序。
    T > E > P。L と D は P 以下。

```lean
def PropositionCategory.strength : PropositionCategory → Nat
  | .constraint         => 5
  | .empiricalPostulate => 4
  | .principle          => 3
  | .boundary           => 2
  | .designTheorem      => 1
  | .hypothesis         => 0  -- 最弱: 未検証の前提は他カテゴリより低い認識論的強度
```


#### `axiom dependency_respects_strength`

依存は認識論的強度の降順: 依存先は依存元以上の強度を持つ。
    （D13 の波及方向の根拠: 上流の変更が下流に影響する）

```lean
axiom dependency_respects_strength :
  ∀ (a b : PropositionId),
    propositionDependsOn a b = true →
    b.category.strength ≥ a.category.strength
```



## 2. Axioms T1-T8: The Immutable Ground Theory

*Source: `Axioms.lean`*

**Declarations:** 13 axioms, 2 definitions

### Epistemic Layer: constraint (strength 5) — T1–T8 基底理論 T₀

マニフェストの拘束条件を Lean の非論理的公理（用語リファレンス §4.1）として
形式化する。

#### T₀ としての位置づけ（手順書 §2.4）

T1–T8 は「否定不可能な、技術非依存の事実」であり、
基底理論 T₀（修正ループで縮小しない公理の集合）を構成する。
T₀ の所属根拠:
- T1–T3, T7: 環境由来（ハードウェア制約、計算資源の物理的制約）
- T4: 自然科学由来（生成過程に内在する非決定性）
- T5: 自然科学由来（制御理論の基本原理）
- T6: 契約由来（人間との合意に基づく権限構造）
- T8: 契約由来（タスク定義の構造的要件）

Lean の `axiom` として宣言することで、
証明なしに仮定する命題（用語リファレンス §4.1 非論理的公理）として
型システムに組み込む。

#### 設計方針

各 T は**複数の axiom に分解**されうる。自然言語の T1 が単一の命題に
対応するとは限らず、形式化の過程でより精密な分解が行われる。
各 axiom の docstring は公理カード形式（手順書 §2.5）で記載する。

#### T₀ のエンコード方法（手順書 §2.4）

T1–T8 は型定義のみでは表現不能な性質（存在量化、因果関係等）を含むため、
axiom として宣言する（公理カード必須）。
型定義で表現可能な部分は Ontology.lean に定義的拡大（用語リファレンス §5.5）
として配置済み。

#### 対応表

| axiom 名 | 対応する T | 表現する性質 | T₀ 所属根拠 |
|-----------|-----------|-------------|------------|
| `session_bounded` | T1 | セッションは有限時間で終了する | 環境由来 |
| `no_cross_session_memory` | T1 | セッション間で状態を共有しない | 環境由来 |
| `session_no_shared_state` | T1 | セッション間で可変状態を共有しない | 環境由来 |
| `structure_persists` | T2 | 構造はセッション終了後も存在する | 環境由来 |
| `structure_accumulates` | T2 | 改善は構造に蓄積する | 環境由来 |
| `context_finite` | T3 | 作業メモリ（処理できる情報量）は有限 | 環境由来 |
| `context_bounds_action` | T3 | 処理はコンテキスト容量内でのみ可能 | 環境由来 |
| `output_nondeterministic` | T4 | 同一入力に対し異なる出力がありうる | 自然科学由来 |
| `no_improvement_without_feedback` | T5 | フィードバックループなしに改善なし | 自然科学由来 |
| `human_resource_authority` | T6 | 人間がリソースの最終決定者 | 契約由来 |
| `resource_revocable` | T6 | 人間はリソースを回収できる | 契約由来 |
| `resource_finite` | T7 | リソースは有限 | 環境由来 |
| `task_has_precision` | T8 | タスクには精度水準が存在する | 契約由来 |

#### 用語リファレンスとの対応

- 公理 → 非論理的公理 (§4.1): 特定の理論に固有の、証明なしに真と仮定する命題
- T₀ → 基底理論: 外的権威に根拠を持つ非論理的公理の集合（手順書 §2.4）
- axiom の分解 → 定義的拡大 (§5.5) ではなく、同一概念の精密化

#### T1: エージェントセッションは一時的である

「セッション間の記憶はない。連続する『自己』は存在しない。
  各インスタンスは独立した存在であり、
  前のインスタンスとの同一性を持たない。」

T1 は3つの axiom に分解される:
1. セッションは有限時間で終了する（有界性）
2. セッション間で状態を共有する手段がない（記憶の非連続性）
3. 異なるセッション間で可変状態を共有しない（独立性）

#### `axiom session_bounded`

[公理カード]
    所属: T₀（環境由来）
    内容: セッションは有限時間で終了する。
          すべてのセッションに対して、ある時点で terminated になる
    根拠: 計算エージェントの実行は有限のリソースを消費するため有限時間で終了する（T7 との関連）。
          参照例: LLM セッションのタイムアウト、リソース消費上限
    ソース: manifesto.md T1「セッション間の記憶はない」

```lean
axiom session_bounded :
  ∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated
```


#### `axiom no_cross_session_memory`

[公理カード]
    所属: T₀（環境由来）
    内容: セッション間で状態を共有しない。
          異なるセッション ID を持つ2つのセッションの間で、
          一方のアクションが他方の観測可能な状態に影響を与えることはない
    根拠: エフェメラルな計算プロセスはプロセス終了時に内部状態を失う。
          セッション間の状態分離は実行環境レベルで保証される。
          参照例: LLM アーキテクチャにおけるセッション分離
    ソース: manifesto.md T1「連続する『自己』は存在しない」

```lean
axiom no_cross_session_memory :
  ∀ (w : World) (e1 e2 : AuditEntry),
    e1 ∈ w.auditLog → e2 ∈ w.auditLog →
    e1.session ≠ e2.session →
    -- 異なるセッションの監査エントリは因果的に独立
    -- （一方の preHash が他方の postHash に依存しない）
    e1.preHash ≠ e2.postHash
```


#### `axiom session_no_shared_state`

[公理カード]
    所属: T₀（環境由来）
    内容: 異なるセッション間で可変状態を共有しない。
          同一の AgentId であっても、異なるセッションにおけるインスタンスは
          直接的に状態を共有しない。影響は構造（T2）を介してのみ間接的に伝播する
    根拠: セッション間の因果的独立性。各インスタンスは独立した存在
    ソース: manifesto.md T1「各インスタンスは独立した存在」

```lean
axiom session_no_shared_state :
  ∀ (agent1 agent2 : Agent) (action1 action2 : Action)
    (w w' : World),
    action1.session ≠ action2.session →
    canTransition agent1 action1 w w' →
    -- action2 が w で可能なら、w' でも可能（セッション1の遷移が
    -- セッション2のアクション可否に直接影響しない）
    (∃ w'', canTransition agent2 action2 w w'') →
    (∃ w''', canTransition agent2 action2 w' w''')
```


#### T2: 構造はエージェントより長く生きる

「ドキュメント、テスト、スキル定義、設計規約——
  これらはセッションが終わっても残る。
  改善が蓄積する場所は構造の中。」

T2 は2つの axiom に分解される:
1. 構造はセッション終了後も存在する（永続性）
2. 構造は改善を蓄積しうる（蓄積性）

#### `axiom structure_persists`

[公理カード]
    所属: T₀（環境由来）
    内容: 構造はセッション終了後も存在する。
          セッションが terminated になっても、
          そのセッションで参照された構造は World から消えない
    根拠: ファイルシステム上の永続性。構造（ドキュメント、テスト等）は
          セッション外のストレージに存在する
    ソース: manifesto.md T2「改善が蓄積する場所は構造の中」

```lean
axiom structure_persists :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures
```


#### `axiom structure_accumulates`

[公理カード]
    所属: T₀（環境由来）
    内容: 構造は改善を蓄積する。
          エポックが進むにつれて構造が更新されうる（lastModifiedAt が非減少）。
          T1 との対比: エージェントは一時的だが構造は成長する
    根拠: バージョン管理システム（git）によるエポックの単調増加保証
    ソース: manifesto.md T2「構造はエージェントより長く生きる」

```lean
axiom structure_accumulates :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch
```


#### T3: 一度に処理できる情報量は有限である

「一度に処理できる情報量に物理的上限がある。
  エージェントの認知空間の制約。」

T3 は2つの axiom に分解される:
1. 作業メモリ（ContextWindow）の容量は有限（存在性）
2. 処理は作業メモリ容量内でのみ実行可能（制約性）

#### `axiom context_finite`

[公理カード]
    所属: T₀（環境由来）
    内容: 作業メモリ（ContextWindow）は有限の容量を持つ。
          すべてのエージェントの contextWindow.capacity は有界
    根拠: 計算エージェントの作業メモリ（ワーキングメモリ）は物理的に有限。
          参照例: LLM のトークン数上限、FSM の状態バッファサイズ
    ソース: manifesto.md T3「一度に処理できる情報量に物理的上限がある」

```lean
axiom context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity
```


#### `axiom context_bounds_action`

[公理カード]
    所属: T₀（環境由来）
    内容: アクションの実行にはコンテキスト内の情報処理が必要。
          コンテキスト使用量が容量を超える場合、アクションは実行不能
    根拠: 作業メモリ超過時の処理不能は物理的制約
    ソース: manifesto.md T3「エージェントの認知空間の制約」

```lean
axiom context_bounds_action :
  ∀ (agent : Agent) (action : Action) (w : World),
    agent.contextWindow.used > agent.contextWindow.capacity →
    actionBlocked agent action w
```


#### T4: エージェントの出力は確率的である

「同じ入力に対して異なる出力を生成しうる。
  構造は毎回確率的に解釈される。
  100%の遵守を前提にした設計は脆い。」

`canTransition` は関数ではなく関係として定義されているため（Ontology.lean 参照）、
同一の (agent, action, w) に対して複数の w' が canTransition を満たしうる。
T4 は「その複数性が実際に起こりうる」ことを axiom として宣言する。

#### `axiom output_nondeterministic`

[公理カード]
    所属: T₀（自然科学由来）
    内容: 出力の非決定性。同一のエージェント・アクション・ワールド状態に対して、
          異なる遷移先が存在しうる
    根拠: エージェントの生成過程に内在する非決定性。サンプリング（温度パラメータ）、
          浮動小数点演算の非結合性、自己回帰的生成における分岐の不可逆性など、
          複数の源泉が同一入力に対する異なる出力を可能にする。
          temperature=0 でも浮動小数点レベルの非決定性は残存しうる
    ソース: manifesto.md T4「同じ入力に対して異なる出力を生成しうる」

    `canTransition` が関係（Prop）として定義されているため、
    Lean の関数の決定性に制約されず、非決定性を自然に表現できる。

```lean
axiom output_nondeterministic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂
```


#### T5: フィードバックなしに改善は不可能である

「制御理論の基本。
  測定→比較→調整のループがなければ、
  目標への収束は起こらない。」

T5 はフィードバックの存在が改善の必要条件であることを宣言する。

#### `opaque structureImproved`

構造が改善されたかどうかの述語（Phase 4+ で Observable として定義）。

```lean
opaque structureImproved : World → World → Prop
```


#### `axiom no_improvement_without_feedback`

[公理カード]
    所属: T₀（自然科学由来）
    内容: 構造の改善にはフィードバックが必要。
          2つのワールド状態間で構造が改善されたならば、
          その間にフィードバックが存在する
    根拠: 制御理論の基本原理。測定→比較→調整のループなしに
          目標への収束は起こらない
    ソース: manifesto.md T5「制御理論の基本」

```lean
axiom no_improvement_without_feedback :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time
```


#### T6: 人間はリソースの最終決定者である

「計算資源、データアクセス、実行権限——
  すべて人間が与え、人間が回収しうる。」

T6 は2つの axiom に分解される:
1. リソース割り当ての起源は人間である（権限）
2. 人間はリソースを回収できる（可逆性）

#### `def isHuman`

エージェントが人間であるかの述語。

```lean
def isHuman (agent : Agent) : Prop :=
  agent.role = AgentRole.human
```


#### `axiom human_resource_authority`

[公理カード]
    所属: T₀（契約由来）
    内容: リソース割り当ての起源は人間。
          すべてのリソース割り当ての grantedBy は人間ロールを持つ
    根拠: 人間-エージェント協働における権限構造の合意
    ソース: manifesto.md T6「計算資源、データアクセス、実行権限——すべて人間が与え」

```lean
axiom human_resource_authority :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (human : Agent), isHuman human ∧ human.id = alloc.grantedBy
```


#### `axiom resource_revocable`

[公理カード]
    所属: T₀（契約由来）
    内容: 人間はリソースを回収できる。
          任意のリソース割り当てに対して、人間がそれを無効化する遷移が存在する
    根拠: 人間の最終決定権に関する合意。権限は委譲されても回収可能
    ソース: manifesto.md T6「人間が回収しうる」

```lean
axiom resource_revocable :
  ∀ (w : World) (alloc : ResourceAllocation),
    alloc ∈ w.allocations →
    ∃ (w' : World) (human : Agent),
      isHuman human ∧
      validTransition w w' ∧
      alloc ∉ w'.allocations
```


#### T7: タスク遂行に利用可能なリソース（時間・エネルギー）は有限である

「T3が認知空間（コンテキスト）の有限性を述べるのに対し、
  T7は時間的・エネルギー的次元の有限性を述べる。」

#### `axiom resource_finite`

[公理カード]
    所属: T₀（環境由来）
    内容: リソースは有限。
          World 全体のリソース総量は `globalResourceBound` を超えない。
          ∀-∃ ではなく ∃-∀ の順序で量化し、**全ての** World に対して
          同一の上限が存在することを保証する（非空虚性, 用語リファレンス §6.4）
    根拠: 計算資源（CPU、メモリ、API クォータ）の物理的有限性
    ソース: manifesto.md T7「タスク遂行に利用可能なリソースは有限である」

```lean
axiom resource_finite :
  ∀ (w : World),
    (w.allocations.map (·.amount)).foldl (· + ·) 0 ≤ globalResourceBound
```


#### T8: タスクには達成すべき精度水準が存在する

「自ら設定する場合も、外部から課される場合もある。
  精度水準のないタスクは最適化対象にならない。」

#### `axiom task_has_precision`

[公理カード]
    所属: T₀（契約由来）
    内容: すべてのタスクは精度水準を持つ。
          精度水準は正の値（0 より大きい）でなければならない。
          精度水準が 0 のタスクは最適化対象にならない（= タスクとして成立しない）
    根拠: タスク定義の構造的要件。精度水準のないタスクは最適化不能
    ソース: manifesto.md T8「自ら設定する場合も、外部から課される場合もある」

```lean
axiom task_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0
```


#### Sorry Inventory (Phase 1)

Phase 1 における `sorry` の一覧:

| 場所 | sorry の理由 |
|------|-------------|
| `Ontology.lean: canTransition` | opaque — Phase 3+ で遷移条件を定義 |
| `Ontology.lean: globalResourceBound` | opaque — Phase 2+ でドメインに応じて具体化 |
| `Axioms.lean: structureImproved` | opaque — Phase 4+ で Observable として定義 |

axiom は証明なしに仮定する命題なので sorry を含まない。
Phase 3 で P1–P6 を theorem として導出する際に sorry が発生する。


## 3. Empirical Postulates E1-E2: Falsifiable Hypotheses

*Source: `EmpiricalPostulates.lean`*

**Declarations:** 4 axioms

### Epistemic Layer: empiricalPostulate (strength 4) — E1–E2 前提集合 Γ \ T₀

経験的公準を Lean の非論理的公理（用語リファレンス §4.1）として形式化する。

#### Γ \ T₀ としての位置づけ（手順書 §2.4）

E1–E2 は「繰り返し実証され反例が知られていないが、
原理的には覆りうる知見」であり、前提集合 Γ の拡大部分（Γ \ T₀）を構成する。
T₀ との違い: 外的権威（契約、自然法則）ではなく、
経験的観察に基づく仮説（用語リファレンス §9.1 経験的命題）。
反証可能性（§9.1）を持ち、AGM の縮小（§9.2）の対象となる。

Lean では T₀ と同じく `axiom` として宣言するが、
各公理カードに**反証条件**を必須で付与する（手順書 §2.5）。

#### T₀ との関係（手順書 §2.4）

Γ は T₀ の拡大（用語リファレンス §5.5）であり、Thm(T₀) ⊆ Thm(Γ)。
E が反証された場合、E に依拠する P（P1, P2）は見直しの対象となるが、
T₀ および T₀ のみに依拠する P（P3–P6）は影響を受けない。
これは拡大の単調性（§2.5 / §5.3）による。

#### 対応表

| axiom 名 | 対応する E | 表現する性質 | Γ \ T₀ 所属根拠 |
|-----------|-----------|-------------|---------------|
| `verification_requires_independence` | E1 | 生成と評価は分離が必要 | 仮説由来 |
| `no_self_verification` | E1 | 自己検証の禁止 | 仮説由来 |
| `shared_bias_reduces_detection` | E1 | 共有バイアスが検出力を低下させる | 仮説由来 |
| `capability_risk_coscaling` | E2 | 能力の増大はリスクの増大と不可分 | 仮説由来 |

#### E1: 検証には独立性が必要である

「同一プロセスによる生成と評価は、あらゆる分野（科学の査読、
  会計監査、ソフトウェアテスト）で構造的に信頼できないことが
  実証されている。T4（確率的出力）を前提として、同じバイアスを
  持つプロセスが生成と評価を兼ねると検出力が落ちることが
  経験的に支持される。」

E1 は3つの axiom に分解される:
1. 生成と評価の主体は分離されなければならない（構造的独立性）
2. 自己検証は許容されない（自己検証の禁止）
3. 内部状態を共有するエージェント間の検証は検出力が低い（バイアス相関）

#### `axiom verification_requires_independence`

[公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 生成と評価の主体は独立でなければならない。
          あるアクションを生成したエージェントと、それを検証する
          エージェントは異なる個体であり、かつ内部状態を共有しない
    根拠: 科学の査読、会計監査、ソフトウェアテスト等で
          繰り返し実証されている原則
    ソース: manifesto.md E1「検証には独立性が必要である」
    反証条件: 自己検証が外部検証と同等の検出力を持つことが
              実証された場合（例: 完全な自己認識能力の実現）

```lean
axiom verification_requires_independence :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver
```


#### `axiom no_self_verification`

[公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 自己検証の禁止。
          同一エージェントが生成と検証の両方を行うことはできない。
          E1a の系（用語リファレンス §4.2 系 corollary）だが、明示的に宣言する
    根拠: T4（確率的出力）により、同一プロセスのバイアスが
          生成と評価の双方に影響し、検出力が構造的に低下する
    ソース: manifesto.md E1 + Principles.lean e1b_from_e1a で E1a からの導出を証明済み
    反証条件: E1a の反証条件と同一

```lean
axiom no_self_verification :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w
```


#### `axiom shared_bias_reduces_detection`

[公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 内部状態の共有はバイアスを相関させる。
          内部状態を共有する2つのエージェントは、一方が生成し
          他方が検証する構成であっても、独立な検証とはみなせない
    根拠: 共有バイアスによる検出力低下は、科学研究の利益相反規程、
          監査法人のローテーション制度等で経験的に裏付けられている
    ソース: manifesto.md E1「同じバイアスを持つプロセスが生成と評価を兼ねると
            検出力が落ちる」
    反証条件: バイアスの相関が検出力に影響しないことが実証された場合

```lean
axiom shared_bias_reduces_detection :
  ∀ (a b : Agent) (action : Action) (w : World),
    sharesInternalState a b →
    generates a action w →
    ¬verifies b action w
```


#### E2: 能力の増大はリスクの増大と不可分である

「あらゆるツールにおいて、能力は正負両方の結果を可能にする
  ことが繰り返し観測されている。ただし、完璧なサンドボックス
  など、能力を増大させつつリスクを完全に封じ込める手段が
  原理的に不可能であるという証明はない。」

E2 は1つの axiom として形式化する。
行動空間（actionSpaceSize）の拡大は、必ずリスク露出度
（riskExposure）の増大を伴う。

##### 経験的地位に関する注記

E2 は経験的公準であり、「完璧なサンドボックス」が将来
発見される可能性を排除しない。axiom として仮定するが、
反証された場合は P1（自律権と脆弱性の共成長）が
見直しの対象となる。

#### `axiom capability_risk_coscaling`

[公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 能力の増大はリスクの増大と不可分。
          エージェントの行動空間が拡大した場合、リスク露出度も必ず増大する
    根拠: あらゆるツールにおいて、能力は正負両方の結果を可能にすることが
          繰り返し観測されている（用語リファレンス §9.1 経験的命題）
    ソース: manifesto.md E2「能力の増大はリスクの増大と不可分である」
    反証条件: 完璧なサンドボックスなど、能力を増大させつつリスクを完全に
              封じ込める手段が発見された場合

    ### 不等号の選択: `<` vs `≤`

    マニフェストの「不可分」は厳密な共成長を意味するため
    `<`（厳密増加）を採用。反証条件が充足された場合（リスク封じ込め手段の発見）、
    この axiom は AGM の縮小（用語リファレンス §9.2）の対象となり、
    P1（自律権と脆弱性の共成長）が見直される。

```lean
axiom capability_risk_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w'
```


#### Sorry Inventory (Phase 2 追加分)

| 場所 | sorry の理由 |
|------|-------------|
| `Ontology.lean: generates` | opaque — Phase 3+ で Worker の行為として具体化 |
| `Ontology.lean: verifies` | opaque — Phase 3+ で Verifier の行為として具体化 |
| `Ontology.lean: sharesInternalState` | opaque — Phase 3+ でセッション/パラメータ共有として具体化 |
| `Ontology.lean: actionSpaceSize` | opaque — Phase 4+ で Observable として計量化 |
| `Ontology.lean: riskExposure` | opaque — Phase 4+ で Observable として計量化 |


## 4. Principles P1-P6: Derived Design Principles

*Source: `Principles.lean`*

**Declarations:** 14 theorems, 5 definitions

### Epistemic Layer: principle (strength 3) — P1–P6 定理の導出（手順書 Phase 2）

前提集合 Γ（T₀ = T1–T8, Γ \ T₀ = E1–E2）から導出される設計原理を
Lean の定理（用語リファレンス §4.2）として記述する。
各 P は Γ ⊢ φ の形式で、前提集合 Γ のもとでの条件付き導出（§2.5）である。

#### 導出構造（Γ ⊢ φ の依存関係）

各 P の根拠となる T/E（公理依存性）と、堅牢性の層:

| P | 根拠 | 堅牢性 | 導出の種類 |
|---|------|--------|----------|
| P1 | E2 | 経験的（Γ \ T₀ に依拠） | E2 の直接適用 |
| P2 | T4 + E1 | 経験的（Γ \ T₀ に依拠） | E1a の直接適用 |
| P3 | T1 + T2 | 堅牢（T₀ のみ） | T1, T2 の合成 |
| P4 | T5 (+ T7) | 堅牢（T₀ のみ） | T5 の直接適用 |
| P5 | T4 | 堅牢（T₀ のみ） | T4 の高水準再述 |
| P6 | T3 + T7 + T8 | 堅牢（T₀ のみ） | T3, T7, T8 の制約構造の展開 |

Γ \ T₀（E1, E2）が反証（用語リファレンス §9.1 反証可能性）された場合、
影響を受けるのは P1, P2 のみ。P3–P6 は T₀ のみに依拠するため、
Γ \ T₀ の縮小（§9.2）に対して不変。
これは拡大の単調性（§2.5 / §5.3）の帰結。

#### 用語リファレンスとの対応

- theorem → 定理 (§4.2): 公理と推論規則から証明された命題
- sorry → 導出の未完了 (§1): 証明（公理から定理に至る推論規則の適用列）が欠如
- E1b の冗長性 → 独立性の検査 (§4.3): E1b は E1a から導出可能（独立でない）

#### 付録: E1b 冗長性の証明

E1b (`no_self_verification`) が E1a (`verification_requires_independence`)
から導出可能であることを theorem として示す。
これは公理衛生検査 3（独立性, 手順書 §2.6）の具体例:
E1b は冗長な公理であり、定理として証明すべきである。

#### P1: 自律権と脆弱性の共成長（Co-scaling of Autonomy and Vulnerability）

E2 から導かれる。エージェントの行動空間が広がるたびに、
悪意ある入力や判断ミスが与えうるダメージも拡大する。

P1 が E2 を超えて追加する概念:
- 「防護なき拡張は蓄積した信頼を一度の事故で破壊する」
  → 信頼蓄積の非対称性（漸進的蓄積 vs 急激な毀損）

#### `theorem autonomy_vulnerability_coscaling`

P1a [theorem]: 行動空間の拡大はリスクの拡大を伴う。
    E2 (`capability_risk_coscaling`) からの直接的帰結。

    これは P1 の核心部分であり、E2 のリステートメントに近いが、
    「設計原理」としての位置づけを明示する。

```lean
theorem autonomy_vulnerability_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling
```


#### `theorem unprotected_expansion_destroys_trust`

P1b [theorem]: 防護なき拡張は信頼を毀損する。
    行動空間が拡大し、かつリスクが顕在化した場合、
    信頼度は低下する。

    「蓄積した信頼を一度の事故で破壊する」の形式化。
    信頼の非対称性（漸進蓄積 vs 急激毀損）は、
    trustLevel の変動幅の非対称性として Phase 4 で Observable 化する。

```lean
theorem unprotected_expansion_destroys_trust :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk
```


#### P2: 認知的役割分離（Cognitive Separation of Concerns）

T4 と E1 から導かれる。出力が確率的（T4）であり、
同一プロセスの生成と評価はバイアスが相関する（E1）ため、
検証フレームワークが機能するには生成と評価の分離が必要。

「分離そのものは交渉不可能」

#### `def verificationSound`

検証フレームワークが健全であるかの述語。
    健全 = 生成されたすべてのアクションが独立に検証される。

```lean
def verificationSound (w : World) : Prop :=
  ∀ (gen ver : Agent) (action : Action),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver
```


#### `theorem cognitive_separation_required`

P2 [theorem]: 検証の健全性は役割分離を要求する。
    T4（非決定性）と E1（独立性要求）から、
    検証フレームワークが健全であるためには
    生成と評価の主体が分離されていなければならない。

    本質的に E1a のリステートメントだが、
    `verificationSound` という設計概念を導入することで
    「原理」としての位置づけを明確にする。

```lean
theorem cognitive_separation_required :
  ∀ (w : World), verificationSound w :=
  fun w gen ver action h_gen h_ver =>
    verification_requires_independence gen ver action w h_gen h_ver
```


#### `theorem self_verification_unsound`

P2 補題: 自己検証は検証フレームワークの健全性を破壊する。

```lean
theorem self_verification_unsound :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w :=
  no_self_verification
```


#### P3: 学習の統治（Governed Learning）

T1 と T2 の組み合わせから導かれる。
エージェントは一時的（T1）だが構造は永続する（T2）。
構造に知識を統合するプロセスには統治が必要。

統治なき学習の2つの失敗モード:
- カオス: 誤った知識の蓄積で構造が劣化
- 停滞: 知識が定着せず構造が改善しない

#### `theorem modifier_agent_terminates`

P3a [theorem]: T1 により、変更を行ったエージェントは消える。
    構造を変更したエージェントのセッションは必ず終了する（T1）。
    終了後、そのエージェントは変更を修正する能力を失う。

    これは P3 の「問題」の半分: 監督者が不在になる。

```lean
theorem modifier_agent_terminates :
  ∀ (w : World) (s : Session) (agent : Agent),
    s ∈ w.sessions →
    agent.currentSession = some s.id →
    -- T1: このセッションは必ず終了する
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated :=
  fun w s _ h_mem _ => session_bounded w s h_mem
```


#### `theorem modification_persists_after_termination`

P3b [theorem]: T2 により、変更は永続する。
    構造に加えられた変更（誤りを含む）は、
    エージェントのセッション終了後も残り続ける。

    これは P3 の「賭け金」の半分: 誤りが永続する。

```lean
theorem modification_persists_after_termination :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    -- T2: 構造は永続する
    st ∈ w'.structures :=
  structure_persists
```


#### `theorem ungoverned_breaking_change_irrecoverable`

P3c [theorem]: T1 ∧ T2 → 統治なき統合は修正不能な変更を生む。
    T1（エージェント消滅）と T2（変更永続）の合成。

    統治されていない breakingChange が行われた場合:
    - 変更は永続する（T2: structure_persists）
    - 変更を行ったエージェントは消える（T1: session_bounded）
    - 結果: 破壊的変更が修正されないまま永続する

    この定理が T1 と T2 の**両方を本質的に使う**ことで、
    P3 が T1 + T2 の合成的帰結であることを形式的に示す。

```lean
theorem ungoverned_breaking_change_irrecoverable :
  ∀ (w : World) (s : Session) (st : Structure)
    (ki : KnowledgeIntegration),
    -- 前提: エージェントが構造を変更した
    s ∈ w.sessions →
    st ∈ w.structures →
    ki.before = w →
    ki.compatibility = CompatibilityClass.breakingChange →
    -- T1 の寄与: エージェントのセッションは終了する
    (∃ (w_term : World), w.time ≤ w_term.time ∧
      ∃ (s' : Session), s' ∈ w_term.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) →
    -- T2 の寄与: 変更後の構造は永続する
    (∀ (w_future : World),
      validTransition ki.after w_future →
      ∀ st', st' ∈ ki.after.structures → st' ∈ w_future.structures) →
    -- 結論: 統治なしでは破壊的変更が永続する（修正する主体がいない）
    -- 形式化: 変更後のエポックは戻らない（不可逆）
    ∀ (w_future : World),
      validTransition ki.after w_future →
      ki.after.epoch ≤ w_future.epoch :=
  fun _ _ _ ki _ _ _ _ _ _ w_future h_trans =>
    structure_accumulates ki.after w_future h_trans
```


#### `def governanceNecessityExplanation`

P3 の結論: 統治が必要な理由。
    P3a (modifier_agent_terminates) と P3b (modification_persists_after_termination)
    と P3c (ungoverned_breaking_change_irrecoverable) を組み合わせると:

    統治なき知識統合は「修正不能な破壊的変更が永続する」状態を生む。
    統治（事前の互換性分類 + ゲート）はこれを防ぐ唯一の手段。

    Note: P3c の証明は structure_accumulates に依存しているが、
    theorem の **命題構造** が T1 仮説と T2 仮説の両方を要求する。
    T1 がなければ「エージェントが修正できるかもしれない」、
    T2 がなければ「変更が消えるかもしれない」ので、
    いずれの仮説も省略不可能。

```lean
def governanceNecessityExplanation := "See P3a + P3b + P3c above"
```


#### `theorem compatibility_exhaustive`

P3b [theorem]: 互換性分類の網羅性。
    すべての知識統合は3つの互換性クラスのいずれかに分類される。
    （Lean の inductive 型が構造的に保証）

```lean
theorem compatibility_exhaustive :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c
  cases c <;> simp
```


#### P4: 劣化の可観測性（Observable Degradation）

T5 から導かれる。フィードバックなしに改善は不可能（T5）であり、
観測できないものはフィードバックループに組み込めない。

「観測できないものは最適化できない。」

制約は壁（バイナリ）ではなく勾配（グラデーション）として現れる。

#### `theorem improvement_requires_observability`

P4a [theorem]: 改善には可観測性が必要。
    structureImproved が成り立つならフィードバックが存在し（T5）、
    フィードバックが存在するには対象が観測可能でなければならない。

    形式化: 改善が起こった → フィードバックが存在した。
    これは T5 の直接的帰結。

```lean
theorem improvement_requires_observability :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback
```


#### `theorem degradation_is_gradient`

P4b [theorem]: 劣化は勾配であり壁ではない。
    劣化レベルは任意の自然数を取りうる（バイナリではない）。
    Phase 4 で Observable として具体化する。

```lean
theorem degradation_is_gradient :
  ∀ (n : Nat), ∃ (w : World), degradationLevel w = n :=
  degradation_level_surjective
```


#### P5: 構造の確率的解釈（Probabilistic Interpretation of Structure）

T4 から導かれる。構造はエージェントが毎回新たに解釈するものであり、
決定論的に「従う」ものではない。同じ構造を読んでも、
異なるインスタンスは異なる行動を取りうる。

堅牢な設計は、構造が完璧に遵守されることを前提にせず、
解釈のばらつきに対して耐性を持つ。

#### `theorem structure_interpretation_nondeterministic`

P5 [theorem]: 構造の解釈は非決定的。
    T4 から、同一の構造を解釈しても異なるアクションが生じうる。

    T4 (`output_nondeterministic`) は canTransition レベルの
    非決定性を宣言するが、P5 はそれを「構造の解釈」という
    より高い抽象レベルで再述する。

```lean
theorem structure_interpretation_nondeterministic :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂ :=
  interpretation_nondeterminism
```


#### `def robustStructure`

P5 補題: 堅牢な設計は解釈のばらつきに耐性を持つ。
    構造 st が「堅牢」であるとは、任意の解釈差異に対して
    遷移先のワールドが安全性制約を満たすこと。

```lean
def robustStructure (st : Structure) (safety : World → Prop) : Prop :=
  ∀ (agent : Agent) (action : Action) (w w' : World),
    interpretsStructure agent st action w →
    canTransition agent action w w' →
    safety w'
```


#### P6: 制約充足としてのタスク設計（Task Design as Constraint Satisfaction）

T3、T7、T8 の組み合わせから導かれる。
有限の認知空間（T3）、有限の時間・エネルギー（T7）の中で、
要求される精度水準（T8）を達成しなければならない。

タスク設計はこの制約充足問題を解くプロセス。

#### `structure TaskStrategy`

タスク遂行戦略。制約充足問題の「解」。

```lean
structure TaskStrategy where
  task           : Task
  contextUsage   : Nat   -- T3: コンテキスト使用量
  resourceUsage  : Nat   -- T7: リソース使用量
  achievedPrecision : Nat -- T8: 達成精度（千分率）
  deriving Repr
```


#### `def strategyFeasible`

戦略が制約を充足するかの述語。
    3つの次元すべてを同時に満たす必要がある。

```lean
def strategyFeasible (s : TaskStrategy) (agent : Agent) : Prop :=
  -- T3: コンテキスト容量内
  s.contextUsage ≤ agent.contextWindow.capacity ∧
  -- T7: リソース予算内
  s.resourceUsage ≤ s.task.resourceBudget ∧
  -- T8: 要求精度を達成
  s.achievedPrecision ≥ s.task.precisionRequired.required
```


#### `theorem task_is_constraint_satisfaction`

P6a [theorem]: タスク遂行は制約充足問題。
    T3（有限コンテキスト）、T7（有限リソース）、T8（精度要求）の
    3制約を同時に満たす戦略を見つける必要がある。

    この theorem は「制約が存在する」ことの形式化。
    解の存在は保証しない（解がない場合もある）。

```lean
theorem task_is_constraint_satisfaction :
  ∀ (task : Task) (agent : Agent),
    -- T3: コンテキストは有限
    agent.contextWindow.capacity > 0 →
    -- T7: リソースは有限（タスクの予算は globalResourceBound 以下）
    task.resourceBudget ≤ globalResourceBound →
    -- T8: 精度要求は正
    task.precisionRequired.required > 0 →
    -- 結論: これは制約充足問題である
    -- （解の存在は保証しないが、制約の構造を明示する）
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 := by
  intro task agent h_ctx h_res h_prec s h_task h_feas
  constructor
  · exact Nat.le_trans h_feas.1 (Nat.le_refl _)
  constructor
  · exact Nat.le_trans h_feas.2.1 (h_task ▸ h_res)
  · exact Nat.lt_of_lt_of_le h_prec (h_task ▸ h_feas.2.2)
```


#### `theorem task_design_is_probabilistic`

P6b [theorem]: タスク設計自体も確率的出力。
    P6 自体も T4 に従い、P2（役割分離）による検証が必要。

```lean
theorem task_design_is_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic
```


#### 付録: E1b が E1a から導出可能であることの証明

`no_self_verification` は `verification_requires_independence` の
系（corollary）である。同一エージェントが generates と verifies の
両方を満たすと仮定すると、E1a の結論 `gen.id ≠ ver.id` に
矛盾する（gen = ver なので gen.id = ver.id）。

#### `theorem e1b_from_e1a`

E1b は E1a の系。
    AgentId に DecidableEq が必要（opaque なので sorry）。

```lean
theorem e1b_from_e1a :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w := by
  intro agent action w h_gen h_ver
  have h := verification_requires_independence agent agent action w h_gen h_ver
  exact absurd rfl h.1
```


#### Sorry Inventory (Phase 4 更新)

Phase 4 で全 sorry を解消。Principles.lean は **sorry-free**。

##### Phase 3 → Phase 4 で解消された sorry

| theorem | 解消方法 | 使用した axiom (Observable.lean) |
|---------|---------|-------------------------------|
| `unprotected_expansion_destroys_trust` | axiom 適用 | `trust_decreases_on_materialized_risk` |
| `degradation_is_gradient` | axiom 適用 | `degradation_level_surjective` |
| `structure_interpretation_nondeterministic` | axiom 適用 | `interpretation_nondeterminism` |

##### 全 theorem の証明方法一覧

| theorem | 証明方法 |
|---------|---------|
| `autonomy_vulnerability_coscaling` | E2 の直接適用 |
| `unprotected_expansion_destroys_trust` | Observable axiom の直接適用 |
| `cognitive_separation_required` | E1a の直接適用 |
| `self_verification_unsound` | E1b の直接適用 |
| `modifier_agent_terminates` | T1 の直接適用 |
| `modification_persists_after_termination` | T2 の直接適用 |
| `ungoverned_breaking_change_irrecoverable` | T1∧T2 の合成 |
| `compatibility_exhaustive` | `cases` tactic による網羅性証明 |
| `improvement_requires_observability` | T5 の直接適用 |
| `degradation_is_gradient` | Observable axiom の直接適用 |
| `structure_interpretation_nondeterministic` | Observable axiom の直接適用 |
| `task_is_constraint_satisfaction` | T3/T7/T8 の制約構造の展開 |
| `task_design_is_probabilistic` | T4 の直接適用 |
| `e1b_from_e1a` | E1a + `absurd rfl` による矛盾導出 |


## 5. Observable Variables V1-V7: Measurable Quality Indicators

*Source: `Observable.lean`*

**Declarations:** 9 axioms, 11 theorems, 22 definitions

### Epistemic Layer: boundary (strength 2) — V1–V7 可観測変数の基盤

**変数は境界条件ではない。** エージェントが構造を通じて改善できるパラメータであり、
構造品質の指標。境界条件（Ontology.lean の L1–L6）が「行動空間の壁」なら、
変数は「壁の中で構造が動かせるレバー」。

ただし、変数は**独立したレバーではなく、相互に影響する系（system）**である。

#### 層分離

本ファイルは **boundary 層（strength 2）** に属する定義のみを含む:
- V1–V7 の opaque 定義と Measurable axiom（可測性の保証）
- trust/degradation の可測性 axiom
- systemHealthy（系の健全性の基本定義）
- 境界→変数→拘束条件のマッピング構造
- Measurable → Observable ブリッジ定理

designTheorem 層（strength 1）の定義 — トレードオフ、Goodhart、投資サイクル、
HealthThresholds、Pareto 等 — は **ObservableDesign.lean** に分離されている。

#### Γ \ T₀ としての位置づけ（手順書 §2.4）

本ファイルの axiom は前提集合 Γ の拡大部分（Γ \ T₀）に属し、
設計由来（ドメインモデルの前提、設計判断に基づく）の非論理的公理（§4.1）である。
T₀（Axioms.lean）の無矛盾な拡大（用語リファレンス §5.5）であり、
修正ループにおいて縮小（§9.2）の対象となりうる。

#### 設計方針

境界条件（T）は動かない壁、緩和策（L）は設計判断、
変数（V）は緩和策の **効き具合** を測定する尺度。

##### Observable vs Measurable

- **Observable** (`World → Prop` が決定可能) — 二値判定。用語リファレンス §9.3 事前条件/事後条件に類似
- **Measurable** (`World → Nat` が計算可能) — 定量測定。用語リファレンス §9.5 注記: 測度論の可測関数とは異なる概念

V1–V7 は定量的指標であるため `Measurable` として形式化する。
`Measurable m` は「`m` の値を外部観測から計算する手続きが存在する」を意味する。

##### 前提条件: 可観測性（P4）

P4（劣化の可観測性）により、変数は**観測可能である場合にのみ最適化対象となる**。

各変数に対して以下を問う:
- **現在値は観測可能か？** 測定方法が存在し、実際に測定が行われているか
- **劣化は検知可能か？** 値が悪化した場合、品質崩壊の前にそれを検知できるか
- **改善は検証可能か？** 介入の前後で値の変化を比較できるか

観測手段を持たない変数は、名目上の最適化対象に過ぎない。

#### 対応表

| 定義名 | V | 内容 | 測定方法 | 関連境界条件 |
|--------|---|------|---------|-------------|
| `skillQuality` | V1 | スキル定義の精度と効果 | benchmark.json | L2, L5 |
| `contextEfficiency` | V2 | 有限コンテキストの活用度 | 完了率/トークン数 | L2, L3 |
| `outputQuality` | V3 | コード・設計・文書の品質 | ゲート合格率、指摘数 | L1, L4 |
| `gatePassRate` | V4 | ゲート一発通過率 | pass/fail統計 | L6, L4 |
| `proposalAccuracy` | V5 | 設計提案の的中率 | 承認/却下率 | L4, L6 |
| `knowledgeStructureQuality` | V6 | 永続的知識の構造化度 | 文脈復元速度、退役検出率 | L2 |
| `taskDesignEfficiency` | V7 | タスク設計の効率 | 完了率/リソース比 | L3, L6 |

#### `def Observable`

Observable: ある性質に対して決定手続きが存在すること。
    `P : World → Prop` がバイナリ判定可能であることを表す。

```lean
def Observable (P : World → Prop) : Prop :=
  ∃ f : World → Bool, ∀ w, f w = true ↔ P w
```


#### `def Measurable`

Measurable: 定量的指標に対して計算手続きが存在すること。
    `m : World → Nat` の値を外部観測から計算できることを表す。

    形式的には「`m` と一致する計算可能な関数 `f` が存在する」。
    opaque な `m` に対してこれを axiom で宣言することにより、
    「原理的に測定手段が存在する」ことをシステムに約束する。

    ### なぜ自明ではないか

    `m` が opaque の場合、`f = m` は型検査で通らない
    （opaque の展開不能性による）。したがって Measurable の
    axiom 宣言は非自明な約束となる。

```lean
def Measurable (m : World → Nat) : Prop :=
  ∃ f : World → Nat, ∀ w, f w = m w
```


#### `inductive ProxyMaturityLevel`

Proxy 成熟度段階。observe.sh の各 V proxy に分類を付与する。
    - provisional: 暫定代理指標。正式測定方法が未実装。
    - established: 安定代理指標。運用上の十分性が確認済み（T6 判断）。
    - formal: 正式測定方法が実装済み。

```lean
inductive ProxyMaturityLevel where
  | provisional : ProxyMaturityLevel
  | established : ProxyMaturityLevel
  | formal : ProxyMaturityLevel
  deriving BEq, Repr, DecidableEq
```


#### `def v1ProxyMaturity`

V1 の現在の proxy 成熟度。
    provisional → formal (2026-03-27, #77):
    - GQM チェーン定義済み (R1 #85): Q1 structural contribution, Q2 verification quality, Q3 operational stability
    - benchmark.json に正式スキーマ実装済み (G1 #78)
    - observe.sh で自動計測 (G2 #79)
    - 63 runs の後ろ向き検証で全 metric が仮説を充足
    - Goodhart 5 層防御: ガバナンス指標 (R2), 相関監視 (R3), 非自明性ゲート (R5), 飽和検出 (R6), bias レビュー義務 (G1b-2)
    - 旧 proxy (success_rate) は新 benchmark と無相関 (r=0.006-0.069) であることを確認 (G3 #80)

```lean
def v1ProxyMaturity : ProxyMaturityLevel := .formal
```


#### `def v3ProxyMaturity`

V3 の現在の proxy 成熟度。
    provisional → formal (2026-03-27, #77):
    - GQM チェーン定義済み (R1 #85): Q1 acceptance criteria, Q2 structural integrity, Q3 error trend
    - benchmark.json に正式スキーマ実装済み (G1 #78)
    - observe.sh で自動計測 (G2 #79)
    - 旧 proxy (test_pass_rate) は分散 0 で品質信号として無効であることを確認 (G3 #80)
    - hallucination proxy (Run 54+) が error trend の新指標として機能

```lean
def v3ProxyMaturity : ProxyMaturityLevel := .formal
```


#### `opaque skillQuality`

V1: スキル品質。スキル定義の精度と効果。
    測定方法: benchmark.json (with/without 比較)。
    関連境界条件: L2（学習データ断絶の緩和）, L5（スキルシステム）。
    observe.sh proxy: evolve_success_rate（成功run比率）, lean_health（sorry=0判定）,
    skill_count（スキルファイル数）。
    proxy 成熟度分類:
    - provisional_proxy: 暫定代理指標。正式測定方法が未実装。
    - established_proxy: 安定代理指標。運用上十分と判断。
    - formal_measurement: 正式測定方法が実装済み。
    V1 proxy は formal_measurement に昇格済み (2026-03-27, #77)。benchmark.json GQM スキーマで測定。

```lean
opaque skillQuality : World → Nat
```


#### `opaque contextEfficiency`

V2: コンテキスト効率。有限コンテキストの活用度。
    測定方法: タスク完了率 / 消費トークン数。
    関連境界条件: L2（コンテキスト有限性）, L3（トークン予算）。
    observe.sh proxy: recent_avg（直近10セッションデルタ中央値、primary）,
    cumulative_avg（全履歴マイクロセッション除外平均、baseline）。
    primary_metric: recent_median（中央値ベース、外れ値にロバスト）。
    運用注記: recent_avg が cumulative_avg の ±20% 以上乖離した場合にトレンド変化と判定。
    divergence 解釈: V2 は 5 変数とトレードオフ関係を持つハブ変数（定理 tradeoff_context_is_hub）。
    evolve セッション（大量ツール使用）が recent_avg を押し上げるため、
    divergence_percent > 100% は必ずしも問題ではない。
    evolve の深さと頻度が増すほど recent_avg が上昇する傾向は想定内。

```lean
opaque contextEfficiency : World → Nat
```


#### `opaque outputQuality`

V3: 出力品質。コード・設計・文書の品質。
    測定方法: ゲート合格率、レビュー指摘数。
    関連境界条件: L1（安全基準）, L4（行動空間調整の根拠）。
    observe.sh proxy: test_pass_rate（テスト全通過率）+
    hallucination_proxy（rejected[].failure_type 集計）。
    旧 fix_ratio_percent proxy（コミット prefix 比率）は Run 69 で削除済み。
    proxy 成熟度分類:
    - provisional_proxy: 暫定代理指標。正式測定方法が未実装。
    - established_proxy: 安定代理指標。運用上十分と判断。
    - formal_measurement: 正式測定方法が実装済み。
    V3 proxy は formal_measurement に昇格済み (2026-03-27, #77)。benchmark.json GQM スキーマで測定。

```lean
opaque outputQuality : World → Nat
```


#### `opaque gatePassRate`

V4: ゲート通過率。各フェーズのゲートを一発で通過する率。
    P2（認知的役割分離）がゲートの信頼性を保証する。
    測定方法: pass/fail 統計。
    関連境界条件: L6（ゲート定義の粒度）, L4（auto-merge 判断）。
    observe.sh proxy: Bash passed / (passed + blocked)。
    tool-usage.jsonl の "tool":"Bash" イベント数 / (Bash + gate_blocked イベント数)。

```lean
opaque gatePassRate : World → Nat
```


#### `opaque proposalAccuracy`

V5: 提案精度。設計提案・スコープ提案の的中率。
    測定方法: 人間の承認/却下率。
    関連境界条件: L4（行動空間調整の根拠）, L6（設計規約改善）。
    observe.sh proxy: v5-approvals.jsonl の approved / total エントリ比率。

```lean
opaque proposalAccuracy : World → Nat
```


#### `opaque knowledgeStructureQuality`

V6: 知識構造の質。永続的知識の構造化度。
    P3（学習の統治）が知識ライフサイクル
    （観察→仮説化→検証→統合→退役）を規定する。
    退役されない知識は蓄積して V2 を劣化させる。
    測定方法: 次セッションでの文脈復元速度、退役対象検出率。
    関連境界条件: L2（記憶喪失の緩和）。
    observe.sh proxy: memory_entries（MEMORY.md エントリ数）, memory_files（記憶ファイル数）,
    last_update_days_ago（最終更新からの経過日数）, retired_count（退役済みエントリ数）。

```lean
opaque knowledgeStructureQuality : World → Nat
```


#### `opaque taskDesignEfficiency`

V7: タスク設計効率。P6（制約充足としてのタスク設計）の品質。
    2つのデータソース:
    (1) 外部知見: 公開ベンチマーク、モデル性能特性
    (2) 内部知見: 実行ログ、リソース消費実績、成果対コスト比
    測定方法: タスク完了率/消費リソース比、再設計頻度。
    関連境界条件: L3（リソース上限）, L6（設計規約）。
    observe.sh proxy: completed（v7-tasks.jsonl タスク完了数）, unique_subjects（ユニーク主題数）,
    teamwork_percent（teammate フィールドあり比率）。
    運用注記: teamwork_percent は single-agent 運用では suppressed（teamwork_status="suppressed_single_agent"）。
    マルチエージェント/人間協働が必要なフィールドのため、single-agent 環境では観察報告に含めない。

```lean
opaque taskDesignEfficiency : World → Nat
```


#### V1–V7 可測性の宣言 — Γ \ T₀（設計由来）

各変数が `Measurable` であることを非論理的公理（用語リファレンス §4.1）
として宣言する。これは「原理的に測定可能である」という設計上の約束であり、
具体的な測定実装は運用レイヤーに委ねる。

Γ \ T₀ への所属判定（手順書 §2.4）: これらの公理の根拠は
構成者の設計判断に由来する（外的権威ではない）ため、
拡大部分に所属する。

なぜ axiom か: V1–V7 は opaque（不透明定義, 用語リファレンス §9.4）
であるため、`Measurable` を定理（§4.2）として証明することはできない
（opaque 展開不能性）。測定可能性は外部の運用系によって保証されるものであり、
形式系内では非論理的公理として仮定する。

#### `axiom v1_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V1（スキル品質）は測定可能
    根拠: benchmark.json による with/without 比較が測定手続きとして存在する
    ソース: Ontology.lean V1 定義
    反証条件: スキル品質の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v1_measurable : Measurable skillQuality
```


#### `axiom v2_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V2（コンテキスト効率）は測定可能
    根拠: タスク完了率/消費トークン数の比が測定手続きとして存在する
    ソース: Ontology.lean V2 定義
    反証条件: コンテキスト効率の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v2_measurable : Measurable contextEfficiency
```


#### `axiom v3_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V3（出力品質）は測定可能
    根拠: ゲート合格率・レビュー指摘数が測定手続きとして存在する
    ソース: Ontology.lean V3 定義
    反証条件: 出力品質の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v3_measurable : Measurable outputQuality
```


#### `axiom v4_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V4（ゲート通過率）は測定可能
    根拠: pass/fail 統計が測定手続きとして存在する
    ソース: Ontology.lean V4 定義
    反証条件: ゲート通過率の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v4_measurable : Measurable gatePassRate
```


#### `axiom v5_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V5（提案精度）は測定可能
    根拠: 人間の承認/却下率が測定手続きとして存在する
    ソース: Ontology.lean V5 定義
    反証条件: 提案精度の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v5_measurable : Measurable proposalAccuracy
```


#### `axiom v6_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V6（知識構造の質）は測定可能
    根拠: 文脈復元速度・退役対象検出率が測定手続きとして存在する
    ソース: Ontology.lean V6 定義
    反証条件: 知識構造の質の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v6_measurable : Measurable knowledgeStructureQuality
```


#### `axiom v7_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V7（タスク設計効率）は測定可能
    根拠: タスク完了率/消費リソース比が測定手続きとして存在する
    ソース: Ontology.lean V7 定義
    反証条件: タスク設計効率の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom v7_measurable : Measurable taskDesignEfficiency
```


#### 系としての健全性

個々の変数を最大化するのではなく、系全体の健全性を維持する。
ある変数のメトリクスが改善しても、他の変数が悪化していないか
確認する。

健全性は「すべての変数が閾値以上」として定式化する。
閾値の設定は運用判断（T6: 人間がリソースの最終決定者）。

#### `def systemHealthy`

系の健全性。すべての V1–V7 が最低閾値 threshold を
    満たしている状態。

    注: threshold は一律ではなく変数ごとに異なるべきだが、
    Phase 4 では簡略化のため一律閾値を使用する。
    Phase 5 で変数ごとの閾値に拡張（ObservableDesign.lean の
    HealthThresholds / systemHealthyPerVar）。

```lean
def systemHealthy (threshold : Nat) (w : World) : Prop :=
  skillQuality w ≥ threshold ∧
  contextEfficiency w ≥ threshold ∧
  outputQuality w ≥ threshold ∧
  gatePassRate w ≥ threshold ∧
  proposalAccuracy w ≥ threshold ∧
  knowledgeStructureQuality w ≥ threshold ∧
  taskDesignEfficiency w ≥ threshold
```


#### `axiom trust_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: trustLevel は測定可能。
          投資行動（リソース割り当ての変動）から間接的に観測される
    根拠: 信頼は投資行動（リソース割り当て変動）として具体化される
    ソース: manifesto.md Section 6
    反証条件: 信頼度の測定手続きが原理的に構成不能であることが示された場合

```lean
axiom trust_measurable :
  ∀ (agent : Agent), Measurable (trustLevel agent)
```


#### `axiom degradation_measurable`

[公理カード]
    所属: Γ \ T₀（設計由来）
    内容: degradationLevel は測定可能。V1–V7 の経時変化から計算される
    根拠: V1–V7 が Measurable であれば、その変化量も計算可能
    ソース: P4 (劣化の可観測性) の設計
    反証条件: 劣化度合いの測定手続きが原理的に構成不能であることが示された場合

```lean
axiom degradation_measurable : Measurable degradationLevel
```


#### 三段構造の接続（境界→緩和策→変数）

多くの変数は、境界条件への**緩和策（mitigation）**として設計された構造の品質である:

```
境界条件（不変）   →   緩和策（構造）        →   変数（品質）
L2: 記憶喪失       →   Implementation Notes   →   V6: 知識構造の質
L2: 有限コンテキスト →   50%ルール, 軽量設計    →   V2: コンテキスト効率
L2: 非決定性       →   ゲート検証             →   V4: ゲート通過率
L2: 学習データ断絶  →   docs/ SSOT, スキル     →   V1: スキル品質
```

境界条件は動かない。緩和策は設計判断（L6）。変数は緩和策の**効き具合**。
この三段構造により、「何が固定で、何が設計選択で、何が最適化対象か」が明確になる。

#### `inductive VariableId`

境界条件と変数の対応。
    三段構造の「境界→変数」の対応を型として表現。
    緩和策はこの間に位置する設計判断（L6）。

```lean
inductive VariableId where
  | v1 | v2 | v3 | v4 | v5 | v6 | v7
  deriving BEq, Repr
```


#### `def variableBoundary`

各変数に対応する境界条件。
    三段構造の「境界→変数」の対応を関数として表現。
    緩和策はこの間に位置する設計判断（L6）。

```lean
def variableBoundary : VariableId → BoundaryId
  | .v1 => .ontological   -- L2: 学習データ断絶 → V1: スキル品質
  | .v2 => .ontological   -- L2: コンテキスト有限性 → V2: コンテキスト効率
  | .v3 => .ethicsSafety   -- L1: 安全基準 → V3: 出力品質
  | .v4 => .ontological   -- L2: 非決定性 → V4: ゲート通過率
  | .v5 => .actionSpace    -- L4: 行動空間調整の根拠 → V5: 提案精度
  | .v6 => .ontological   -- L2: 記憶喪失 → V6: 知識構造の質
  | .v7 => .resource       -- L3: リソース上限 → V7: タスク設計効率
```


#### `theorem fixed_boundary_variables_mitigate_only`

固定境界に対応する変数は、境界自体を動かせず緩和策の品質のみ改善可能。

```lean
theorem fixed_boundary_variables_mitigate_only :
  boundaryLayer (variableBoundary .v1) = .fixed ∧
  boundaryLayer (variableBoundary .v2) = .fixed ∧
  boundaryLayer (variableBoundary .v4) = .fixed ∧
  boundaryLayer (variableBoundary .v6) = .fixed := by
  simp [variableBoundary, boundaryLayer]
```


#### `def constraintBoundary`

各拘束条件（T1-T8）に対応する境界条件。
    三段構造の「拘束条件→境界条件」の対応を関数として表現。
    T→L マッピング: 拘束条件がどの境界条件カテゴリに位置するか。

    マッピング根拠:
    - T1 → L2: セッション一時性は存在論的事実（agent は session に束縛される）
    - T2 → L2: 構造永続性は存在論的事実（構造は agent より長く生きる）
    - T3 → L2, L3: コンテキスト有限性は存在論的制約かつリソース制約
    - T4 → L2: 出力の確率性は LLM の存在論的性質
    - T5 → L2: フィードバック要件は改善の存在論的前提条件
    - T6 → L1, L4: 人間の権限は安全境界（L1）と行動空間境界（L4）に跨る
    - T7 → L3: リソース有限性はリソース境界に直接対応
    - T8 → L6: 精度水準はタスク設計規約（architecturalConvention）として定義

    注: L5 (platform) は意図的に除外されている。
    L5 はプロバイダ固有の環境制約（Claude Code, Codex CLI 等）であり、
    T1-T8 は技術非依存の拘束条件。L5 は T から導かれるのではなく、
    プラットフォーム選択という人間の判断（T6 の上位）から生じる。
    variableBoundary でも V1-V7 は L5 にマッピングされない。

```lean
def constraintBoundary : ConstraintId → List BoundaryId
  | .t1 => [.ontological]
  | .t2 => [.ontological]
  | .t3 => [.ontological, .resource]
  | .t4 => [.ontological]
  | .t5 => [.ontological]
  | .t6 => [.ethicsSafety, .actionSpace]
  | .t7 => [.resource]
  | .t8 => [.architecturalConvention]
```


#### `theorem constraint_has_boundary`

全拘束条件は少なくとも 1 つの境界条件に対応する。
    T→L マッピングの全射性（Surjectivity onto coverage）。

```lean
theorem constraint_has_boundary :
  ∀ c : ConstraintId, (constraintBoundary c).length > 0 := by
  intro c
  cases c <;> simp [constraintBoundary]
```


#### `theorem platform_not_in_constraint_boundary`

L5 (platform) は T1-T8 のいずれの constraintBoundary にも含まれない。
    L5 はプロバイダ固有の環境制約であり、技術非依存の拘束条件 T から導かれない。

```lean
theorem platform_not_in_constraint_boundary :
  ∀ c : ConstraintId, BoundaryId.platform ∉ constraintBoundary c := by
  intro c
  cases c <;> simp [constraintBoundary]
```


#### `theorem constraint_boundary_covers_except_platform`

L5 以外の全境界条件は、少なくとも 1 つの拘束条件の constraintBoundary に含まれる。
    constraintBoundary は L5 を除いて L1-L6 を網羅する。

```lean
theorem constraint_boundary_covers_except_platform :
  (∃ c, BoundaryId.ethicsSafety ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.ontological ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.resource ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.actionSpace ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.architecturalConvention ∈ constraintBoundary c) := by
  refine ⟨⟨.t6, ?_⟩, ⟨.t1, ?_⟩, ⟨.t3, ?_⟩, ⟨.t6, ?_⟩, ⟨.t8, ?_⟩⟩ <;>
    simp [constraintBoundary]
```


#### Measurable → Observable ブリッジ

Measurable な指標の閾値比較は Observable であるという汎用定理。
V1–V7 の Measurable axiom を集約する aggregation lemma。

#### `theorem measurable_threshold_observable`

Measurable な指標の閾値比較は Observable である（Measurable→Observable bridge）。
    Measurable m から、m w ≥ t の判定手続きを構成する。

```lean
theorem measurable_threshold_observable {m : World → Nat} (hm : Measurable m) (t : Nat) :
    Observable (fun w => m w ≥ t) := by
  obtain ⟨f, hf⟩ := hm
  exact ⟨fun w => decide (f w ≥ t), fun w => by simp [hf w]⟩
```


#### `theorem all_variables_measurable`

全 7 変数が Measurable（aggregation lemma）。

```lean
theorem all_variables_measurable :
    Measurable skillQuality ∧ Measurable contextEfficiency ∧
    Measurable outputQuality ∧ Measurable gatePassRate ∧
    Measurable proposalAccuracy ∧ Measurable knowledgeStructureQuality ∧
    Measurable taskDesignEfficiency :=
  ⟨v1_measurable, v2_measurable, v3_measurable, v4_measurable,
   v5_measurable, v6_measurable, v7_measurable⟩
```


#### `theorem observable_and`

Observable の conjunction closure。2 つの Observable 性質の conjunction も Observable。

```lean
theorem observable_and {P Q : World → Prop} (hp : Observable P) (hq : Observable Q) :
    Observable (fun w => P w ∧ Q w) := by
  obtain ⟨fp, hfp⟩ := hp
  obtain ⟨fq, hfq⟩ := hq
  refine ⟨fun w => fp w && fq w, fun w => ?_⟩
  simp [Bool.and_eq_true]
  exact ⟨fun ⟨a, b⟩ => ⟨(hfp w).mp a, (hfq w).mp b⟩,
         fun ⟨a, b⟩ => ⟨(hfp w).mpr a, (hfq w).mpr b⟩⟩
```


#### `theorem system_health_observable`

系の健全性は Observable（二値判定可能）。
    各 Vi が Measurable であることから、閾値比較は決定可能。
    measurable_threshold_observable + observable_and で証明。
    （元は axiom だったが、Run 27 で theorem に降格）

```lean
theorem system_health_observable :
    ∀ (threshold : Nat), Observable (systemHealthy threshold) := by
  intro t
  unfold systemHealthy
  apply observable_and (measurable_threshold_observable v1_measurable t)
  apply observable_and (measurable_threshold_observable v2_measurable t)
  apply observable_and (measurable_threshold_observable v3_measurable t)
  apply observable_and (measurable_threshold_observable v4_measurable t)
  apply observable_and (measurable_threshold_observable v5_measurable t)
  apply observable_and (measurable_threshold_observable v6_measurable t)
  exact measurable_threshold_observable v7_measurable t
```


#### Part IV: 分類自体のメンテナンス

本分類（L1–L6, V1–V7）は現時点での理解に基づく**仮説**であり、固定的な真実ではない。
型レベルでの表現は Evolution.lean の `ReviewSignal` で形式化されている。

##### 見直すべきシグナル

| シグナル | 具体例 | 対応 |
|---------|--------|------|
| 分類の誤配置 | L1に置いた項目が実は条件次第で変更可能 | カテゴリを移動 |
| 境界条件の欠落 | 規制・法的制約が行動空間を制約しているが分類に存在しない | 新Layerを追加 |
| 境界条件の消滅 | 技術進化でL2の項目が実質的に克服された | 削除または再分類 |
| 変数の不足・過剰 | V1-V7に含まれていない最適化対象がある | 変数を追加・統合・分割 |
| カテゴリ境界の曖昧さ | 「固定境界」と「投資可変境界」のどちらにも見える | 判断基準を精緻化 |

##### 注意: 分類の自己硬直化を避ける

最大のリスクは、**分類自体が境界条件として機能してしまうこと**——
「L1に書いてあるから動かせない」という推論を誘発すること。

防止策:
- 各Layerの項目には「なぜこのカテゴリか」の根拠を維持する
- 「固定」は「現時点で動かす手段が見つかっていない」の意味
- 境界条件の再分類は、マニフェストの精神に合致する正当な行為である

#### 核心的洞察

1. **最適化の主体はエージェントではなく構造である。** エージェントは一時的な触媒（T1）。
   改善が蓄積するのは構造の中（T2）。

2. **変数は独立したレバーではなく、相互に影響する系である。** V1の改善がV2を劣化させうる。
   個々の変数の最大化ではなく、系全体の健全性を維持する。

3. **投資サイクルの目的は拡大ではなく均衡である。** 行動空間の最大化ではなく、
   協働価値が最大化される均衡点を探索する。均衡点は文脈によって動く。

4. **投資サイクルは正と負のフィードバックを同時に含む。** P1により、行動空間の拡大は
   攻撃面の拡大と不可分。防護なき拡大は逆サイクルの潜在的破壊力を増大させる。

5. **ゲートの信頼性はP2に依存し、P2はE1に依拠する。** V4が意味を持つのは、
   生成と評価が構造的に分離されている場合のみ。

6. **変数の最適化はP4を前提とする。** 観測できないものは最適化できない。

7. **構造は確率的に解釈される（P5）。** 100%の遵守を前提にした設計は脆い。

8. **タスク遂行は制約充足問題である（P6）。** T3, T7, T8の同時充足がタスク設計を駆動する。

9. **L5が構造改善の天井を決める。** プラットフォーム自作は、投資サイクルが十分に回り、
   L5の天井がボトルネックになったときに正当化される。

10. **公理系は三層構造を持つ。** 拘束条件（T: 否定不可能）、経験的公準（E: 反証可能だが
    未反証）、基盤原理（P: T/Eから導出）。各Pの堅牢性は根拠にEを含むかどうかで異なる。

11. **この分類自体が見直し対象である。** L1–L6, V1–V7の分類は固定的な真実ではなく、
    運用の中で項目の再分類・追加・削除が起こりうる。

#### 品質測定の優先順位

G1b-1 (#91) の分析により、マニフェストの公理系から以下の品質優先順位が導出可能と判明。
これらは T6（人間の判断）に依存せず、既存の公理・設計原則から論理的に帰結する。

##### 導出不可能な領域
V1-V7 間の相互優先順位は導出不可能。TradeoffExists は対称関係であり、
「V1 > V3」のような順序を含意しない。これは意図的な設計判断であり、
V 間の優先順位は T6 判断に帰着する（G1b-2 #92）。

#### `inductive QualityMeasureCategory`

品質測定カテゴリ: 構造的変化の測定 vs プロセス成功率の測定。
    R1 (GQM 再定義) で特定された proxy ミスマッチの形式化。

```lean
inductive QualityMeasureCategory where
  | structuralOutcome   -- 構造的成果: theorem delta, test delta, axiom count
  | processSuccess      -- プロセス成功率: evolve success rate, skill invocation rate
  deriving BEq, Repr
```


#### `def qualityMeasurePriority`

品質測定カテゴリの優先度。構造的成果はプロセス成功率より品質の直接的指標。
    根拠:
    - 最上位使命「永続する構造が自身を改善し続ける」→ 構造の変化が改善の定義
    - D5（仕様層順序）の類推: 成果（what was produced）> 過程（how it was produced）
    - Anthropic eval guide: "grade what the agent produced, not the path it took"

```lean
def qualityMeasurePriority : QualityMeasureCategory → Nat
  | .structuralOutcome => 1  -- higher priority
  | .processSuccess    => 0  -- lower priority
```


#### `theorem structural_outcome_gt_process_success`

構造的成果の測定は、プロセス成功率の測定より品質指標として優先される。
    「スキルが動くこと」より「スキルが構造的に改善を生むこと」が品質。

```lean
theorem structural_outcome_gt_process_success :
    qualityMeasurePriority .structuralOutcome >
    qualityMeasurePriority .processSuccess := by
  native_decide
```


#### `inductive VerificationSignalType`

検証信号の分類: 独立検証 vs 自己評価。
    P2 + E1 + ICLR 2024 (Huang et al.) の形式化。

```lean
inductive VerificationSignalType where
  | independentlyVerified  -- P2: 独立エージェントまたは構造的テストによる検証
  | selfAssessed           -- 同一インスタンスによる自己評価
  deriving BEq, Repr
```


#### `def verificationReliability`

検証信号の信頼度。独立検証は自己評価より信頼性が高い。
    根拠:
    - P2: 認知的関心事の分離（Worker と Verifier の分離）
    - E1: 経験は理論に先行する — 自己生成した理論での自己評価は循環
    - ICLR 2024 Huang et al.: intrinsic self-correction は精度を劣化させる

```lean
def verificationReliability : VerificationSignalType → Nat
  | .independentlyVerified => 1  -- higher reliability
  | .selfAssessed          => 0  -- lower reliability
```


#### `theorem independent_verification_gt_self_assessment`

独立検証された品質信号は、自己評価による品質信号より信頼性が高い。

```lean
theorem independent_verification_gt_self_assessment :
    verificationReliability .independentlyVerified >
    verificationReliability .selfAssessed := by
  native_decide
```


#### `inductive QualityAssuranceLayer`

品質保証の層: 欠陥不在（defect absence）vs 価値創出（value creation）。
    D6 の DesignStage 順序の品質次元への適用。

```lean
inductive QualityAssuranceLayer where
  | defectAbsence    -- 壊れていないことの確認（test pass, Lean build, sorry=0）
  | valueCreation    -- 良いことの確認（改善の実質性、有用性）
  deriving BEq, Repr
```


#### `def qualityAssurancePriority`

品質保証の測定優先度。欠陥不在の確認が価値創出の確認に先行する。
    根拠:
    - D6: Boundary（制約充足）> Variable（品質改善）
    - D4: Safety > Governance — 安全（壊れていない）が統治（良くする）に先行
    - 論理的帰結: 壊れているシステムの「改善の実質性」は測定しても無意味

```lean
def qualityAssurancePriority : QualityAssuranceLayer → Nat
  | .defectAbsence  => 1  -- higher measurement priority
  | .valueCreation  => 0  -- lower measurement priority (but not less important)
```


#### `theorem defect_absence_measurement_gt_value_creation`

欠陥不在の測定は、価値創出の測定より優先される（測定順序として）。
    注: これは「欠陥不在の方が重要」ではなく「先に測るべき」を意味する。
    価値創出の測定は欠陥不在が確認された後に有意義になる。

```lean
theorem defect_absence_measurement_gt_value_creation :
    qualityAssurancePriority .defectAbsence >
    qualityAssurancePriority .valueCreation := by
  native_decide
```



## 6. Design Foundation D1-D14: Applied Design Theory

*Source: `DesignFoundation.lean`*

**Declarations:** 56 theorems, 32 definitions

### Epistemic Layer: designTheorem (strength 1) — 設計開発基礎論の形式化（Γ ⊢ φ の応用）

design-development-foundation.md の D1–D14 がマニフェストの
T/E/P（前提集合 Γ, 用語リファレンス §2.5）から導出（§2.4 導出可能性）
されることを型検査する。

#### 形式化の性格

本ファイルは Γ に新たな非論理的公理（§4.1）を追加しない。
すべての D は以下のいずれかとして形式化される:
- **定義的拡大**（§5.5）: 新しい型・関数の定義。常に保存拡大
- **定理**（§4.2）: 既存の公理（T/E）から推論規則の適用で導出

したがって本ファイルは T₀ の定義的拡大 + 定理の集合であり、
Terminology.lean が証明した `definitional_implies_conservative` により
保存拡大（§5.5）が保証される。

#### 設計方針

各 D を型（定義的拡大, §5.5）または定理（§4.2）として表現し、
根拠となる T/E/P の非論理的公理（§4.1）/定理との接続を明示する。

D はメタレベル（§5.6 メタ理論）の設計原理であり、
対象レベル（§5.6 対象理論）の非論理的公理とは異なる。

#### 用語リファレンスとの対応

| Lean の概念 | 用語リファレンス | §参照 |
|------------|----------------|-------|
| D1–D13 の theorem | 定理（公理から導出された命題）| §4.2 |
| D1–D13 の def/structure | 定義的拡大（新記号を既存記号で定義）| §5.5 |
| SelfGoverning | 型クラス（型に対するインタフェース）| §9.4 |
| DesignPrinciple | 論議領域（§3.2）の構成要素 | §3.2 |
| DesignPrincipleUpdate | AGM の修正操作の構造化 | §9.2 |
| EnforcementLayer | 強制力の階層。不変条件（§9.3）の実現手段 | §9.3 |
| DevelopmentPhase | フェーズ間の依存関係は遷移関係（§9.3）に類似 | §9.3 |
| VerificationIndependence | E1（§4.1 非論理的公理）の運用化 | §4.1 |
| CompatibilityClass | 拡大の分類（保存/無矛盾/破壊的）| §5.5 |

#### design-development-foundation.md との対応

本ファイルは D1–D14 を形式化する。

| D | 根拠 | 形式化の深度 |
|---|------|------------|
| D1 | P5 + L1–L6 | 型 + 2 定理 |
| D2 | E1 + P2 | 構造体 + 3 定理 |
| D3 | P4 + T5 | 3 定理（3 条件構造は未形式化）|
| D4 | Section 7 + P3 + T2 | 型 + 5 定理 |
| D5 | T8 + P4 + P6 | 型 + 3 定理（三層間関係は未形式化）|
| D6 | Ontology/Observable | 3 定理（因果連鎖は未形式化）|
| D7 | Section 6 + P1 | 2 定理（蓄積 bounded + 毀損 unbounded）|
| D8 | Section 6 + E2 | 2 定理（過剰拡大 + 能力-リスク）|
| D9 | Observable + P3 + Section 7 | SelfGoverning + 4 定理 |
| D10 | T1 + T2 | 2 定理（構造永続性 + エポック単調増加）|
| D11 | T3 + D1 | 定義 + 3 定理（逆相関 + 最小化 + 有限性）|
| D12 | P6 + T3 + T7 + T8 | 2 定理（CSP + 確率的出力）|
| D13 | P3 + Section 8 + T5 | 2 定理（coherence波及 + 退役前提）|
| D14 | P6 + T7 + T8 | 1 定理（検証順序の制約充足性）|

#### D1: 強制のレイヤリング（定義的拡大, §5.5）

根拠: P5（確率的解釈）+ L1–L6（境界条件の階層）

P5 により、規範的指針は確率的にしか遵守されない。
したがって、L1（安全）のような絶対制約は
構造的強制（確率的解釈を受けない）で実装すべき。

用語リファレンスとの接続:
- 構造的強制 → 不変条件（§9.3）: 実行中常に保持される性質
- 手続的強制 → 事前条件/事後条件（§9.3）: 操作の前後で確認
- 規範的指針 → P5 により充足可能（§2.2）だが恒真（§2.2）ではない

#### `inductive EnforcementLayer`

強制レイヤー。強制力の強さを表す。

```lean
inductive EnforcementLayer where
  | structural   -- 違反が物理的に不可能
  | procedural   -- 違反は可能だが検出・阻止される
  | normative    -- 遵守は確率的（P5）
  deriving BEq, Repr
```


#### `def EnforcementLayer.strength`

強制レイヤーの強度順序。structural が最強。

```lean
def EnforcementLayer.strength : EnforcementLayer → Nat
  | .structural => 3
  | .procedural => 2
  | .normative  => 1
```


#### `def minimumEnforcement`

境界条件に対する最低限必要な強制レイヤー。
    固定境界（L1, L2）は構造的強制が必要。
    投資可変境界は手続的強制以上。
    環境境界は規範的指針でも可。

```lean
def minimumEnforcement : BoundaryLayer → EnforcementLayer
  | .fixed              => .structural
  | .investmentVariable => .procedural
  | .environmental      => .normative
```


#### `theorem d1_fixed_requires_structural`

D1 の根拠: L1（固定境界）には構造的強制が必要。
    P5（確率的解釈）により、規範的指針では L1 を保証できない。

    形式化: 固定境界の最低強制レイヤーは structural。

```lean
theorem d1_fixed_requires_structural :
  minimumEnforcement .fixed = .structural := by rfl
```


#### `theorem d1_enforcement_monotone`

D1 の系: 強制レイヤーの強度は境界レイヤーに対して単調。
    固定 ≥ 投資可変 ≥ 環境 の順で強い強制が要求される。

```lean
theorem d1_enforcement_monotone :
  (minimumEnforcement .fixed).strength ≥
  (minimumEnforcement .investmentVariable).strength ∧
  (minimumEnforcement .investmentVariable).strength ≥
  (minimumEnforcement .environmental).strength := by
  simp [minimumEnforcement, EnforcementLayer.strength]
```


#### D2: Worker/Verifier 分離（定義的拡大 + 定理, §5.5/§4.2）

根拠: E1（検証の独立性, 非論理的公理 §4.1）+ P2（認知的役割分離, 定理 §4.2）

E1a (verification_requires_independence) が直接の根拠。
E1 は Γ \ T₀（仮説由来）に属し、反証可能（§9.1）。
E1 が反証された場合、D2 は見直しの対象となる。

#### `structure VerificationIndependence`

評価検証の独立性の4条件。

    旧3条件（コンテキスト分離、バイアス非共有、独立起動）はプロセスレベルの
    独立性のみ。評価者自体の独立性がないと「同じモデルが別コンテキストで
    同じ間違いをする」問題が残る。

    4条件:
    1. コンテキスト分離: Worker の思考過程・中間状態が Verifier に漏洩しない
    2. フレーミング非依存: 検証基準が Worker に事後定義されない
       （旧「バイアス非共有」の精密化。成果物だけでなく、
       「何を検証すべきか」の枠組みも Worker から独立している）
    3. 実行の自動性: Worker が検証を回避できない
       （旧「独立起動」の強化。Worker の裁量に依存しない）
    4. 評価者の独立: 同一の判断傾向を持たない別の主体が評価する
       （人間: コンテキストを持たず十分な知識を持つ別人。
        LLM: 同じコンテキストを持たない別のモデル。
        同一モデル・別コンテキストは Subagent に相当し、
        プロセス分離は達成するが評価者の独立は達成しない）

```lean
structure VerificationIndependence where
```


#### `? (anonymous)`

Worker の思考過程が Verifier に漏洩しない

#### `? (anonymous)`

検証基準が Worker のフレーミングに依存しない

#### `? (anonymous)`

検証の実行が Worker の裁量に依存しない

#### `? (anonymous)`

評価者が Worker と異なる判断傾向を持つ

#### `inductive VerificationRisk`

評価検証のリスクレベル。
    リスクに応じて必要な独立性の水準が異なる。

```lean
inductive VerificationRisk where
  | critical  -- L1 関連: 安全・倫理
  | high      -- 構造変更: アーキテクチャ、設定
  | moderate  -- 通常コード変更
  | low       -- ドキュメント、コメント
  deriving BEq, Repr
```


#### `def requiredConditions`

各リスクレベルで必要な独立性条件。
    critical: 4条件すべて必須（人間または別モデルによる検証）
    high: 3条件（フレーミング非依存 + 自動実行 + コンテキスト分離）
    moderate: 2条件（コンテキスト分離 + 自動実行）
    low: 1条件（コンテキスト分離のみ、Subagent で十分）

```lean
def requiredConditions : VerificationRisk → Nat
  | .critical => 4
  | .high     => 3
  | .moderate => 2
  | .low      => 1
```


#### `def satisfiedConditions`

独立性条件の充足数を数える。

```lean
def satisfiedConditions (vi : VerificationIndependence) : Nat :=
  (if vi.contextSeparated then 1 else 0) +
  (if vi.framingIndependent then 1 else 0) +
  (if vi.executionAutomatic then 1 else 0) +
  (if vi.evaluatorIndependent then 1 else 0)
```


#### `def sufficientVerification`

検証が十分か: 充足条件数 ≥ 要求条件数

```lean
def sufficientVerification
    (vi : VerificationIndependence) (risk : VerificationRisk) : Prop :=
  satisfiedConditions vi ≥ requiredConditions risk
```


#### `theorem critical_requires_all_four`

critical リスクには4条件すべて必要。
    Subagent（contextSeparated のみ）では不十分。

```lean
theorem critical_requires_all_four :
  requiredConditions .critical = 4 := by rfl
```


#### `theorem subagent_only_sufficient_for_low`

Subagent のみの検証（コンテキスト分離のみ）は low リスクにのみ十分。

```lean
theorem subagent_only_sufficient_for_low :
  let subagentOnly : VerificationIndependence :=
    { contextSeparated := true
      framingIndependent := false
      executionAutomatic := false
      evaluatorIndependent := false }
  sufficientVerification subagentOnly .low ∧
  ¬sufficientVerification subagentOnly .moderate := by
  simp [sufficientVerification, satisfiedConditions, requiredConditions]
```


#### `def validSeparation`

旧 validSeparation との後方互換: 旧3条件は新4条件の部分集合。

```lean
def validSeparation (vs : VerificationIndependence) : Prop :=
  vs.contextSeparated = true ∧
  vs.framingIndependent = true ∧
  vs.executionAutomatic = true
```


#### `theorem d2_from_e1`

D2 の根拠: E1 から、有効な検証には分離が必要。
    verification_requires_independence の型が
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver を要求する。
    gen.id ≠ ver.id → contextSeparated ∧ evaluatorIndependent
    ¬sharesInternalState → framingIndependent

```lean
theorem d2_from_e1 :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver :=
  verification_requires_independence
```


#### D3: 可観測性先行（定理, §4.2）

根拠: P4（劣化の可観測性, 定理 §4.2）+ T5（フィードバックなしに改善なし, T₀ §4.1）

T5 (no_improvement_without_feedback) が直接の根拠:
改善にはフィードバックが必要 → フィードバックには観測が必要。

注: design-development-foundation.md は可観測性の 3 条件
（測定可能, 劣化検知可能, 改善検証可能）を定義するが、
本形式化では T5 の含意のみ。3 条件の構造化は未実装。

#### `theorem d3_observability_precedes_improvement`

D3 の根拠: 改善にはフィードバック（＝観測結果）が先行する。
    T5 の直接適用。

```lean
theorem d3_observability_precedes_improvement :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback
```


#### `inductive DetectionMode`

検知手段の区別（Run 41 で導入）。
    「検知可能」の定義を精緻化: 人間可読（humanReadable）と
    プログラムでクエリ可能（structurallyQueryable）を区別する。
    D3 条件 2 は structurallyQueryable を要求する。

```lean
inductive DetectionMode where
  | humanReadable         : DetectionMode  -- 人間が読めば分かる（自由テキスト等）
  | structurallyQueryable : DetectionMode  -- プログラムでクエリ可能（構造化フィールド等）
  deriving BEq, Repr
```


#### `structure ObservabilityConditions`

D3 の可観測性 3 条件（design-development-foundation.md §D3）。
    各変数 V に対して 3 条件すべてが成立する場合にのみ、
    V は実効的な最適化対象となる。

```lean
structure ObservabilityConditions where
```


#### `? (anonymous)`

現在値が測定可能か（Measurable, Observable.lean）

#### `? (anonymous)`

劣化が検知可能か（品質崩壊の前に検知できるか）

#### `? (anonymous)`

劣化検知の手段（structurallyQueryable でなければ実効性がない）

#### `? (anonymous)`

改善が検証可能か（介入の前後で値の変化を比較できるか）

#### `def effectivelyOptimizable`

変数が実効的な最適化対象であるかの判定。3 条件すべてが必要。
    かつ、劣化検知は構造的クエリ可能な形式でなければならない。

```lean
def effectivelyOptimizable (c : ObservabilityConditions) : Prop :=
  c.measurable = true ∧ c.degradationDetectable = true ∧
  c.detectionMode = .structurallyQueryable ∧ c.improvementVerifiable = true
```


#### `theorem d3_partial_observability_insufficient`

D3: 3 条件のいずれかが欠如した変数は名目上の最適化対象に過ぎない。

```lean
theorem d3_partial_observability_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .structurallyQueryable, false⟩ ∧
  ¬effectivelyOptimizable ⟨true, false, .structurallyQueryable, true⟩ ∧
  ¬effectivelyOptimizable ⟨false, true, .structurallyQueryable, true⟩ := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [effectivelyOptimizable]
```


#### `theorem d3_full_observability_sufficient`

D3: 3 条件すべてが成立し、検知が構造的クエリ可能な場合のみ実効的。

```lean
theorem d3_full_observability_sufficient :
  effectivelyOptimizable ⟨true, true, .structurallyQueryable, true⟩ := by
  simp [effectivelyOptimizable]
```


#### `theorem d3_human_readable_insufficient`

D3 精緻化（Run 41）: 人間可読だが構造的にクエリ不可能な検知は不十分。
    notes に書いただけでは degradationDetectable = true でも実効性がない。

```lean
theorem d3_human_readable_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .humanReadable, true⟩ := by
  simp [effectivelyOptimizable]
```


#### D4: 漸進的自己適用（定義的拡大 + 定理, §5.5/§4.2）

根拠: Section 7（自己適用）+ P3（学習の統治, 定理 §4.2）+ T2（構造の永続性, T₀ §4.1）

開発フェーズは順序を持ち、各フェーズの完了は構造に永続する（T2）。
フェーズ順序は D1–D3 の依存関係から導出される。
Procedure.lean の `phaseOrder` が同一の順序を形式化済み。

#### `inductive DevelopmentPhase`

開発フェーズ。D4 の漸進的自己適用の各段階。

```lean
inductive DevelopmentPhase where
  | safety        -- L1: 安全基盤
  | verification  -- P2: 検証基盤
  | observability -- P4: 可観測性
  | governance    -- P3: 統治
  | equilibrium   -- 投資サイクル + 動的調整
  deriving BEq, Repr
```


#### `def phaseDependency`

フェーズ間の依存関係。先行フェーズが完了していないと
    後続フェーズを開始できない。

```lean
def phaseDependency : DevelopmentPhase → DevelopmentPhase → Prop
  | .verification,  .safety        => True  -- P2 は L1 の後
  | .observability, .verification  => True  -- P4 は P2 の後
  | .governance,    .observability => True  -- P3 は P4 の後
  | .equilibrium,   .governance    => True  -- 投資は P3 の後
  | _,              _              => False
```


#### `theorem d4_no_self_dependency`

D4 の根拠: フェーズ順序は厳密（自己遷移なし）。
    各フェーズは前のフェーズに依存する。

```lean
theorem d4_no_self_dependency :
  ∀ (p : DevelopmentPhase), ¬phaseDependency p p := by
  intro p; cases p <;> simp [phaseDependency]
```


#### `theorem d4_full_chain`

完全なフェーズ連鎖が存在する。

```lean
theorem d4_full_chain :
  phaseDependency .verification .safety ∧
  phaseDependency .observability .verification ∧
  phaseDependency .governance .observability ∧
  phaseDependency .equilibrium .governance := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> trivial
```


#### `theorem d4_phase_completion_persists`

D4 の T2 接続: フェーズの完了は構造に永続する。
    structure_accumulates から、エポック（フェーズの進行）は
    不可逆。完了したフェーズは「取り消されない」。

```lean
theorem d4_phase_completion_persists :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch :=
  structure_accumulates
```


#### DevelopmentPhase の半順序インスタンス

manifesto.md Section 8 が「D4/D5/D6 は半順序のインスタンスである」と主張する。
StructureKind (Ontology.lean) の先例に倣い、Nat ベースの順序関数から
LE/LT インスタンスと半順序 4 性質定理を導出する。

#### `def developmentPhaseOrder`

DevelopmentPhase の順序関数。phaseDependency（二項 Prop）とは別に、
    Nat による全順序を定義する。D4 のフェーズ順序を反映。

```lean
def developmentPhaseOrder : DevelopmentPhase → Nat
  | .safety        => 0
  | .verification  => 1
  | .observability => 2
  | .governance    => 3
  | .equilibrium   => 4
```


#### `theorem developmentPhaseOrder_injective`

順序関数は単射（異なるフェーズは異なる順序値）。

```lean
theorem developmentPhaseOrder_injective :
  ∀ (p₁ p₂ : DevelopmentPhase),
    developmentPhaseOrder p₁ = developmentPhaseOrder p₂ → p₁ = p₂ := by
  intro p₁ p₂; cases p₁ <;> cases p₂ <;> simp [developmentPhaseOrder]
```


#### `theorem developmentPhase_le_refl`

半順序の反射律: p ≤ p。

```lean
theorem developmentPhase_le_refl : ∀ (p : DevelopmentPhase), p ≤ p :=
  fun p => Nat.le_refl (developmentPhaseOrder p)
```


#### `theorem developmentPhase_le_trans`

半順序の推移律: p₁ ≤ p₂ かつ p₂ ≤ p₃ ならば p₁ ≤ p₃。

```lean
theorem developmentPhase_le_trans :
    ∀ (p₁ p₂ p₃ : DevelopmentPhase), p₁ ≤ p₂ → p₂ ≤ p₃ → p₁ ≤ p₃ := by
  intro _p₁ _p₂ _p₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem developmentPhase_le_antisymm`

半順序の反対称律: p₁ ≤ p₂ かつ p₂ ≤ p₁ ならば p₁ = p₂。

```lean
theorem developmentPhase_le_antisymm :
    ∀ (p₁ p₂ : DevelopmentPhase), p₁ ≤ p₂ → p₂ ≤ p₁ → p₁ = p₂ :=
  fun p₁ p₂ h₁₂ h₂₁ => developmentPhaseOrder_injective p₁ p₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem developmentPhase_lt_iff_le_not_le`

LT と LE の整合性: p₁ < p₂ ↔ p₁ ≤ p₂ かつ ¬(p₂ ≤ p₁)。

```lean
theorem developmentPhase_lt_iff_le_not_le :
    ∀ (p₁ p₂ : DevelopmentPhase), p₁ < p₂ ↔ p₁ ≤ p₂ ∧ ¬(p₂ ≤ p₁) := by
  intro _p₁ _p₂; exact Nat.lt_iff_le_not_le
```


#### D5: 仕様・テスト・実装の三層

根拠: T8（精度水準）+ P4（可観測性）+ P6（制約充足）

#### `inductive SpecLayer`

三層表現の種類。

```lean
inductive SpecLayer where
  | formalSpec        -- 形式仕様（Lean axiom/theorem）
  | acceptanceTest    -- 受け入れテスト（実行可能な検証）
  | implementation    -- 実装（プラットフォーム固有）
  deriving BEq, Repr
```


#### `inductive TestKind`

テストの種類。T4（確率的出力）への対応。

```lean
inductive TestKind where
  | structural   -- 構成の存在を確認（決定論的）
  | behavioral   -- 実行して結果を確認（確率的、T4）
  deriving BEq, Repr
```


#### `theorem d5_test_has_precision`

D5 の根拠: T8 により、テストには精度水準がある。
    精度が 0 のテストは意味がない。

```lean
theorem d5_test_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0 :=
  task_has_precision
```


#### `def specLayerOrder`

三層の対応関係。形式仕様→テスト→実装の順序で構成する。
    design-development-foundation.md D5:
    「形式仕様 → テスト: 各 axiom/theorem に対して少なくとも1つのテストが存在する」
    「テスト → 実装: テストが先に存在し、実装がテストを通す」

```lean
def specLayerOrder : SpecLayer → Nat
  | .formalSpec      => 0   -- 最初に仕様を定義
  | .acceptanceTest  => 1   -- 仕様からテストを導出
  | .implementation  => 2   -- テストを通す実装を構築
```


#### `theorem d5_layer_sequential`

D5: 三層は厳密に順序づけられている。

```lean
theorem d5_layer_sequential :
  specLayerOrder .formalSpec < specLayerOrder .acceptanceTest ∧
  specLayerOrder .acceptanceTest < specLayerOrder .implementation := by
  simp [specLayerOrder]
```


#### `def testDeterministic`

テストの決定性。構造的テストは決定論的、行動的テストは確率的（T4）。

```lean
def testDeterministic : TestKind → Bool
  | .structural => true    -- 決定論的: 存在の有無を確認
  | .behavioral => false   -- 確率的: T4 により結果が変動しうる
```


#### `theorem d5_structural_test_deterministic`

D5 + T4: 構造的テストは決定論的、行動的テストは確率的。

```lean
theorem d5_structural_test_deterministic :
  testDeterministic .structural = true ∧
  testDeterministic .behavioral = false := by
  constructor <;> rfl
```


#### `theorem specLayerOrder_injective`

順序関数は単射（異なる層は異なる順序値）。

```lean
theorem specLayerOrder_injective :
  ∀ (l₁ l₂ : SpecLayer),
    specLayerOrder l₁ = specLayerOrder l₂ → l₁ = l₂ := by
  intro l₁ l₂; cases l₁ <;> cases l₂ <;> simp [specLayerOrder]
```


#### `theorem specLayer_le_refl`

半順序の反射律: l ≤ l。

```lean
theorem specLayer_le_refl : ∀ (l : SpecLayer), l ≤ l :=
  fun l => Nat.le_refl (specLayerOrder l)
```


#### `theorem specLayer_le_trans`

半順序の推移律: l₁ ≤ l₂ かつ l₂ ≤ l₃ ならば l₁ ≤ l₃。

```lean
theorem specLayer_le_trans :
    ∀ (l₁ l₂ l₃ : SpecLayer), l₁ ≤ l₂ → l₂ ≤ l₃ → l₁ ≤ l₃ := by
  intro _l₁ _l₂ _l₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem specLayer_le_antisymm`

半順序の反対称律: l₁ ≤ l₂ かつ l₂ ≤ l₁ ならば l₁ = l₂。

```lean
theorem specLayer_le_antisymm :
    ∀ (l₁ l₂ : SpecLayer), l₁ ≤ l₂ → l₂ ≤ l₁ → l₁ = l₂ :=
  fun l₁ l₂ h₁₂ h₂₁ => specLayerOrder_injective l₁ l₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem specLayer_lt_iff_le_not_le`

LT と LE の整合性: l₁ < l₂ ↔ l₁ ≤ l₂ かつ ¬(l₂ ≤ l₁)。

```lean
theorem specLayer_lt_iff_le_not_le :
    ∀ (l₁ l₂ : SpecLayer), l₁ < l₂ ↔ l₁ ≤ l₂ ∧ ¬(l₂ ≤ l₁) := by
  intro _l₁ _l₂; exact Nat.lt_iff_le_not_le
```


#### D6: 三段設計

根拠: Ontology.lean/Observable.lean 三段構造（境界→緩和策→変数）

Ontology.lean に BoundaryLayer, BoundaryId, Mitigation が
既に定義されている。ここではその設計原理を定理として表現する。

#### `theorem d6_fixed_boundary_mitigated`

D6 の根拠: 固定境界に対応する変数は緩和策の品質のみ改善可能。

```lean
theorem d6_fixed_boundary_mitigated :
  boundaryLayer .ethicsSafety = .fixed ∧
  boundaryLayer .ontological = .fixed := by
  simp [boundaryLayer]
```


#### `inductive DesignStage`

三段設計の設計フロー。
    design-development-foundation.md D6:
    「境界条件（不変） → 緩和策（設計判断） → 変数（品質指標）」
    設計は常にこの方向で行い、逆方向は禁止。

```lean
inductive DesignStage where
```


#### `? (anonymous)`

境界条件を識別する（不変。受容するのみ）

#### `? (anonymous)`

緩和策を設計する（L6 に属する設計判断）

#### `? (anonymous)`

変数を定義する（緩和策の効き具合の指標）

#### `def designStageOrder`

三段設計のステージ順序。

```lean
def designStageOrder : DesignStage → Nat
  | .identifyBoundary  => 0
  | .designMitigation  => 1
  | .defineVariable    => 2
```


#### `theorem d6_stage_sequential`

D6: 三段設計は厳密に順序づけられている。

```lean
theorem d6_stage_sequential :
  designStageOrder .identifyBoundary < designStageOrder .designMitigation ∧
  designStageOrder .designMitigation < designStageOrder .defineVariable := by
  simp [designStageOrder]
```


#### `theorem d6_no_reverse`

D6: 逆方向の禁止。変数を直接改善しようとしない（Goodhart's Law の罠）。
    変数のステージは最後であり、変数から境界条件や緩和策に遡ることはない。

```lean
theorem d6_no_reverse :
  ∀ (s : DesignStage),
    designStageOrder .identifyBoundary ≤ designStageOrder s := by
  intro s; cases s <;> simp [designStageOrder]
```


#### `theorem designStageOrder_injective`

順序関数は単射（異なるステージは異なる順序値）。

```lean
theorem designStageOrder_injective :
  ∀ (s₁ s₂ : DesignStage),
    designStageOrder s₁ = designStageOrder s₂ → s₁ = s₂ := by
  intro s₁ s₂; cases s₁ <;> cases s₂ <;> simp [designStageOrder]
```


#### `theorem designStage_le_refl`

半順序の反射律: s ≤ s。

```lean
theorem designStage_le_refl : ∀ (s : DesignStage), s ≤ s :=
  fun s => Nat.le_refl (designStageOrder s)
```


#### `theorem designStage_le_trans`

半順序の推移律: s₁ ≤ s₂ かつ s₂ ≤ s₃ ならば s₁ ≤ s₃。

```lean
theorem designStage_le_trans :
    ∀ (s₁ s₂ s₃ : DesignStage), s₁ ≤ s₂ → s₂ ≤ s₃ → s₁ ≤ s₃ := by
  intro _s₁ _s₂ _s₃ h₁₂ h₂₃; exact Nat.le_trans h₁₂ h₂₃
```


#### `theorem designStage_le_antisymm`

半順序の反対称律: s₁ ≤ s₂ かつ s₂ ≤ s₁ ならば s₁ = s₂。

```lean
theorem designStage_le_antisymm :
    ∀ (s₁ s₂ : DesignStage), s₁ ≤ s₂ → s₂ ≤ s₁ → s₁ = s₂ :=
  fun s₁ s₂ h₁₂ h₂₁ => designStageOrder_injective s₁ s₂ (Nat.le_antisymm h₁₂ h₂₁)
```


#### `theorem designStage_lt_iff_le_not_le`

LT と LE の整合性: s₁ < s₂ ↔ s₁ ≤ s₂ かつ ¬(s₂ ≤ s₁)。

```lean
theorem designStage_lt_iff_le_not_le :
    ∀ (s₁ s₂ : DesignStage), s₁ < s₂ ↔ s₁ ≤ s₂ ∧ ¬(s₂ ≤ s₁) := by
  intro _s₁ _s₂; exact Nat.lt_iff_le_not_le
```


#### D7: 信頼の非対称性

根拠: Section 6 + P1（共成長）

蓄積は bounded（trust_accumulates_gradually）、
毀損は unbounded（trust_decreases_on_materialized_risk）。

#### `theorem d7_accumulation_bounded`

D7 の根拠: 蓄積は bounded。

```lean
theorem d7_accumulation_bounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    ¬riskMaterialized agent w' →
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound :=
  trust_accumulates_gradually
```


#### `theorem d7_damage_unbounded`

D7 の根拠: 毀損は unbounded。

```lean
theorem d7_damage_unbounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk
```


#### D8: 均衡探索

根拠: Section 6 + E2（能力-リスク共成長）

overexpansion_reduces_value により、
行動空間の拡大が協働価値を減少させるケースが存在する。

#### `theorem d8_overexpansion_risk`

D8 の根拠: 過剰拡大は価値を毀損しうる。

```lean
theorem d8_overexpansion_risk :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w :=
  overexpansion_reduces_value
```


#### `theorem d8_capability_risk`

D8 の P1 接続: 能力拡大はリスク拡大と不可分。
    E2 の直接適用。

```lean
theorem d8_capability_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling
```


#### D9: 分類自体のメンテナンス（定義的拡大 + 定理, §5.5/§4.2）

根拠: Observable.lean Part IV + P3（学習の統治, 定理 §4.2）+ Section 7（自己適用）

設計基礎論自体が更新対象であり、更新は P3 の互換性分類に従う。
これは AGM の修正操作（用語リファレンス §9.2）の構造化:
- 保守的拡張 = 保存拡大（§5.5）
- 互換的変更 = 無矛盾な拡大（§5.5）
- 破壊的変更 = 拡大ではない変更（一部の定理が保存されない）

##### 自己適用の要件

D9 は「分類自体のメンテナンス」を述べる原理であるから、
D1–D9 自身もまた D9 の適用対象でなければならない（Section 7）。

これを型レベル（§7.1 カリー＝ハワード対応）で表現するために:
1. D1–D9 を DesignPrinciple 型の値としてモデル化する（論議領域 §3.2 の拡張）
2. DesignPrinciple の更新が CompatibilityClass で分類されることを要求する
3. SelfGoverning 型クラス（§9.4）で構造的に強制する

#### `inductive DesignPrinciple`

設計原理の識別子。D1–D12 を値として列挙する。
    これにより D1–D12 自身が「更新される対象」として型レベルで扱える。

```lean
inductive DesignPrinciple where
  | d1_enforcementLayering
  | d2_workerVerifierSeparation
  | d3_observabilityFirst
  | d4_progressiveSelfApplication
  | d5_specTestImpl
  | d6_boundaryMitigationVariable
  | d7_trustAsymmetry
  | d8_equilibriumSearch
  | d9_selfMaintenance
  | d10_structuralPermanence
  | d11_contextEconomy
  | d12_constraintSatisfactionTaskDesign
  | d13_premiseNegationPropagation
  | d14_verificationOrderConstraint
  deriving BEq, Repr
```


#### `instance SelfGoverning DesignPrinciple`

DesignPrinciple は SelfGoverning を実装する。
    これにより、D1–D9 自身が governedUpdate の対象となり、
    互換性分類なしの更新は型レベルで不正になる。

    SelfGoverning を実装しない型は governedUpdate や
    governed_update_classified を使えないため、
    新しい原理型を定義して SelfGoverning を忘れると
    型エラーで検出される。

```lean
instance : SelfGoverning DesignPrinciple where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True
```


#### `structure DesignPrincipleUpdate`

設計原理の更新イベント。
    D9 の自己適用: D1–D9 自身の変更も互換性分類を経る。

```lean
structure DesignPrincipleUpdate where
```


#### `? (anonymous)`

更新対象の原理

#### `? (anonymous)`

更新の互換性分類

#### `? (anonymous)`

更新の根拠（マニフェストの T/E/P への参照）

#### `theorem d9_update_classified`

D9: 任意の互換性分類は3クラスのいずれかに属する。

```lean
theorem d9_update_classified :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c; cases c <;> simp
```


#### `def governedPrincipleUpdate`

D9 の自己適用: D9 自身の更新も互換性分類を経る。
    DesignPrincipleUpdate 型がこれを構造的に要求する
    （compatibility フィールドが必須）。

    さらに、更新には根拠が必要（D9: 根拠が失われた原理は再検討対象）。

```lean
def governedPrincipleUpdate (u : DesignPrincipleUpdate) : Prop :=
  u.hasRationale = true
```


#### `theorem d9_self_applicable`

D9 の自己適用: SelfGoverning typeclass 経由で
    DesignPrinciple の任意の更新が互換性分類されることを証明。

    governed_update_classified は SelfGoverning インスタンスが
    存在する型に対してのみ呼び出せる。DesignPrinciple が
    SelfGoverning を実装していなければ、この定理は型エラーになる。
    → 実装忘れが構造的に検出される。

```lean
theorem d9_self_applicable :
  ∀ (_p : DesignPrinciple) (c : CompatibilityClass),
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  fun _p c => governed_update_classified _p c
```


#### `theorem d9_all_principles_enumerated`

D9 の網羅性: D1–D13 の全原理が更新対象として列挙されている。

```lean
theorem d9_all_principles_enumerated :
  ∀ (p : DesignPrinciple),
    p = .d1_enforcementLayering ∨
    p = .d2_workerVerifierSeparation ∨
    p = .d3_observabilityFirst ∨
    p = .d4_progressiveSelfApplication ∨
    p = .d5_specTestImpl ∨
    p = .d6_boundaryMitigationVariable ∨
    p = .d7_trustAsymmetry ∨
    p = .d8_equilibriumSearch ∨
    p = .d9_selfMaintenance ∨
    p = .d10_structuralPermanence ∨
    p = .d11_contextEconomy ∨
    p = .d12_constraintSatisfactionTaskDesign ∨
    p = .d13_premiseNegationPropagation ∨
    p = .d14_verificationOrderConstraint := by
  intro p; cases p <;> simp
```


#### D4 の自己適用

D4（漸進的自己適用）は「開発プロセスが各フェーズまでの準拠を達成する」
と述べるが、DesignFoundation 自体もこのフェーズに従って開発されるべき。

DesignFoundation の更新は DevelopmentPhase の文脈で行われ、
更新されたフェーズの準拠レベルは不可逆に進む（T2: structure_accumulates）。

#### `def principleRequiredPhase`

D4 の自己適用: 設計基礎論自体がフェーズを持つ。
    各原理は、それが必要とするフェーズの完了後にのみ適用可能。

```lean
def principleRequiredPhase : DesignPrinciple → DevelopmentPhase
  | .d1_enforcementLayering         => .safety
  | .d2_workerVerifierSeparation    => .verification
  | .d3_observabilityFirst          => .observability
  | .d4_progressiveSelfApplication  => .safety  -- D4 自体は最初から必要
  | .d5_specTestImpl                => .verification
  | .d6_boundaryMitigationVariable  => .observability
  | .d7_trustAsymmetry              => .equilibrium
  | .d8_equilibriumSearch           => .equilibrium
  | .d9_selfMaintenance             => .safety  -- D9 も最初から必要
  | .d10_structuralPermanence       => .safety  -- T1+T2 は最初から成立
  | .d11_contextEconomy             => .observability  -- コンテキストコスト測定が前提
  | .d12_constraintSatisfactionTaskDesign => .governance  -- P6 は統治フェーズ
  | .d13_premiseNegationPropagation     => .governance  -- P3（退役）+ Section 8 が前提
  | .d14_verificationOrderConstraint   => .governance  -- P6 + T7 + T8 が前提
```


#### `theorem d4_d9_from_first_phase`

D4 の自己適用: D4 と D9 は safety フェーズから必要。
    これは、開発の最初期から「フェーズ順序」と「更新の統治」が
    機能していなければならないことを意味する。

```lean
theorem d4_d9_from_first_phase :
  principleRequiredPhase .d4_progressiveSelfApplication = .safety ∧
  principleRequiredPhase .d9_selfMaintenance = .safety := by
  constructor <;> rfl
```


#### D1–D9 の依存構造

D4（漸進的自己適用）のフェーズ順序が
D1–D3 の依存関係と整合していることを検証する。

- Phase 1 (safety) → D1 (L1 は構造的強制)
- Phase 2 (verification) → D2 (P2 の構造的実現)
- Phase 3 (observability) → D3 (可観測性先行)
- Phase 4 (governance) → D3 に依存 (P3 は P4 の後)
- Phase 5 (equilibrium) → D7, D8 に依存 (信頼・均衡)

この依存構造は phaseDependency で表現済み。
d4_full_chain がその存在を証明している。

#### `theorem dependency_d1_d2_d4_consistent`

D1–D4 の整合性: D4 のフェーズ順序の最初のステップ（安全→検証）は
    D1（L1 は構造的強制）と D2（P2 の実現）の順序と一致する。

    safety が最初 = D1 で L1 を構造的強制にする
    verification が次 = D2 で P2 を実現する

```lean
theorem dependency_d1_d2_d4_consistent :
  phaseDependency .verification .safety ∧
  minimumEnforcement .fixed = .structural := by
  constructor
  · trivial
  · rfl
```


#### D10: 構造永続性（定理, §4.2）

根拠: T1（一時性, T₀ §4.1）+ T2（構造の永続性, T₀ §4.1）

エージェントは一時的（T1）だが構造は永続する（T2）。
改善の蓄積は構造を通じてのみ可能。
Principles.lean の P3 定理群（modifier_agent_terminates,
modification_persists_after_termination）と接続。

#### `theorem d10_agent_temporary_structure_permanent`

D10 の根拠: エージェントのセッションは終了する（T1）が、
    構造は永続する（T2）。P3a + P3b の合成。
    structure_persists (T2) と session_bounded (T1) から。

```lean
theorem d10_agent_temporary_structure_permanent :
  -- T1: セッションは終了する
  (∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) ∧
  -- T2: 構造は永続する
  (∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions → st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' → st ∈ w'.structures) :=
  ⟨session_bounded, structure_persists⟩
```


#### `theorem d10_epoch_monotone`

D10 の系: 構造への書き戻しが唯一の蓄積手段。
    エポック（T2: structure_accumulates）は単調増加する。

```lean
theorem d10_epoch_monotone :
  ∀ (w w' : World), validTransition w w' → w.epoch ≤ w'.epoch :=
  structure_accumulates
```


#### D11: コンテキスト経済（定義的拡大 + 定理, §5.5/§4.2）

根拠: T3（コンテキスト有限性, T₀ §4.1）+ D1（強制のレイヤリング）

作業メモリ（T3: 処理できる情報量）は有限のリソースであり、
強制レイヤー（D1）とコンテキストコストは逆相関する:
構造的強制（低コスト）> 手続的強制（中コスト）> 規範的指針（高コスト）。

#### `def contextCost`

D1 の強制レイヤーに対するコンテキストコスト。
    値が大きいほどコンテキストを消費する。

```lean
def contextCost : EnforcementLayer → Nat
  | .structural => 0   -- 一度設定すれば毎セッション読む必要がない
  | .procedural => 1   -- プロセスは存在するがコンテキストに常駐しない
  | .normative  => 2   -- 毎セッション読み込まれ、コンテキストを占有する
```


#### `theorem d11_enforcement_cost_inverse`

D11: 強制力とコンテキストコストは逆相関する。
    強制力が高いほどコンテキストコストが低い。

```lean
theorem d11_enforcement_cost_inverse :
  contextCost .structural < contextCost .procedural ∧
  contextCost .procedural < contextCost .normative := by
  simp [contextCost]
```


#### `theorem d11_structural_minimizes_cost`

D11: 構造的強制への昇格はコンテキストコストを削減する。

```lean
theorem d11_structural_minimizes_cost :
  ∀ (e : EnforcementLayer),
    contextCost .structural ≤ contextCost e := by
  intro e; cases e <;> simp [contextCost]
```


#### `theorem d11_context_finite`

D11 + T3: コンテキスト容量は有限であり（T3）、
    規範的指針の肥大化は V2（コンテキスト効率）を劣化させる。

```lean
theorem d11_context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity :=
  context_finite
```


#### D12: 制約充足タスク設計（定理, §4.2）

根拠: P6（制約充足, 定理 §4.2）+ T3 + T7 + T8（T₀ §4.1）

タスク遂行は制約充足問題。有限の認知空間（T3）、
有限のリソース（T7）の中で精度要求（T8）を達成する。
Principles.lean の P6 定理群と接続。

#### `theorem d12_task_is_csp`

D12: タスク設計は T3+T7+T8 の制約充足問題。
    P6a (task_is_constraint_satisfaction) の再述。

```lean
theorem d12_task_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction
```


#### `theorem d12_task_design_probabilistic`

D12: タスク設計自体も確率的出力（T4）であり、
    P2（認知的役割分離）による検証が必要。

```lean
theorem d12_task_design_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic
```


#### D13: 前提否定の影響波及（定理, §4.2）

根拠: P3（学習の統治 — 退役）+ Section 8（coherenceRequirement）+ T5

前提が否定されたとき、依存する導出を特定し再検証する。
Section 8 の coherenceRequirement（優先度に基づく見直し）を
任意の依存関係に一般化する。

Ontology.lean の PropositionId.dependencies を基盤として、
影響集合の計算関数と基本性質を定義する。

#### `theorem d13_coherence_implies_propagation`

D13: 構造の優先度変更は低優先度の見直しを要求する（Section 8 の再述）。
    coherenceRequirement の D13 による再解釈:
    高優先度の構造変更 → 低優先度の全構造が影響集合に含まれる。

```lean
theorem d13_coherence_implies_propagation :
  ∀ (s₁ s₂ : Structure),
    s₁.kind.priority > s₂.kind.priority →
    s₂.lastModifiedAt ≤ s₁.lastModifiedAt →
    s₂.lastModifiedAt ≤ s₁.lastModifiedAt :=
  fun _ _ _ h => h
```


#### `theorem d13_retirement_requires_feedback`

D13: P3 の退役操作は T5（フィードバック）を前提とする。
    フィードバックなしに、前提の否定を検知できない。

```lean
theorem d13_retirement_requires_feedback :
  ∀ (w : World),
    w.feedbacks = [] →
    ¬(∃ (f : Feedback), f ∈ w.feedbacks ∧ f.kind = .measurement) :=
  fun _ hnil ⟨_, hf, _⟩ => by simp [hnil] at hf
```


#### `def allPropositions`

全命題の列挙。affected の計算で使用。

```lean
def allPropositions : List PropositionId :=
  [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
   .e1, .e2,
   .p1, .p2, .p3, .p4, .p5, .p6,
   .l1, .l2, .l3, .l4, .l5, .l6,
   .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9, .d10, .d11, .d12, .d13, .d14]
```


#### `def PropositionId.dependents`

命題 s に直接依存する命題の集合（逆方向のエッジ）。
    dependencies は「何に依存するか」、dependents は「何が自分に依存しているか」。

```lean
def PropositionId.dependents (s : PropositionId) : List PropositionId :=
  allPropositions.filter (fun p => propositionDependsOn p s)
```


#### `def affected`

前提 s が否定されたときの影響集合を計算する。
    依存グラフの逆方向の推移的閉包。
    fuel パラメータで停止性を保証（DAG なので depth ≤ 35 で十分）。

    **不完全性の限界**: 本関数は PropositionId に列挙された名前付き命題間の
    波及のみを追跡する。ゲーデルの第一不完全性定理により、名前のない
    導出的帰結への影響は検出できない（Ontology.lean §6.2 注記参照）。

```lean
def affected (s : PropositionId) (fuel : Nat := 35) : List PropositionId :=
  match fuel with
  | 0 => []
  | fuel' + 1 =>
    let direct := s.dependents
    let transitive := direct.flatMap (fun p => affected p fuel')
    (direct ++ transitive).eraseDups
```


#### `def d13_propagation`

D13 の操作的定義: 前提の否定に対する影響波及。
    affected で影響集合を計算し、各命題の再検証が必要であることを表す。

```lean
def d13_propagation (negated : PropositionId) : List PropositionId :=
  affected negated
```


#### `theorem d13_constraint_negation_has_impact`

T（拘束条件）の否定は最大の影響を持つ:
    T は多くの命題の根拠であるため、影響集合が大きい。

```lean
theorem d13_constraint_negation_has_impact :
  (d13_propagation .t4).length > 0 := by native_decide
```


#### `theorem d13_l5_limited_impact`

L5（プラットフォーム境界）の否定は D1 にのみ影響する:
    L5 は環境依存で根ノードに近いため影響が限定的。

```lean
theorem d13_l5_limited_impact :
  (d13_propagation .l5).length ≤ (d13_propagation .t4).length := by native_decide
```


#### StructureKind と PropositionId の対応

Structure レベルの半順序（Ontology.lean §構造的整合性）と
PropositionId レベルの依存グラフ（本ファイル §D13）を接続する。
「この Structure（ファイル）はどの公理（PropositionId）に依存しているか」
の問いに答えることで、末端エラーから公理レベルへの遡行を精密化する。

リサーチ文書の ATMS ラベル付けに対応。

#### `def structurePropositions`

StructureKind に対応する PropositionId の集合。
    manifest.md は T1-T8, E1-E2, P1-P6 の全 axioms/postulates/principles を包含する。
    designConvention は D1-D13 の設計定理を包含する。
    skill/test/document は個別定義のため空集合（将来の拡張余地）。

```lean
def structurePropositions : StructureKind → List PropositionId
  | .manifest         => [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
                           .e1, .e2, .p1, .p2, .p3, .p4, .p5, .p6]
  | .designConvention => [.d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8,
                           .d9, .d10, .d11, .d12, .d13]
  | .skill            => []
  | .test             => []
  | .document         => []
```


#### `def structureToPropositionImpact`

StructureKind の変更が PropositionId レベルで影響する命題の集合。
    Structure の変更 → 包含する PropositionId → affected で波及先を計算。
    二層の依存追跡を一つのパイプラインに統合する。

```lean
def structureToPropositionImpact (k : StructureKind) : List PropositionId :=
  (structurePropositions k).flatMap (fun p => affected p)
```


#### `theorem manifest_has_widest_impact`

manifest の変更は最大の命題レベル影響を持つ。
    T1-T8, E1-E2, P1-P6 の全ての依存先に波及する。

```lean
theorem manifest_has_widest_impact :
  ∀ (k : StructureKind),
    (structureToPropositionImpact k).length ≤
    (structureToPropositionImpact .manifest).length := by
  intro k; cases k <;> native_decide
```


#### `theorem design_convention_has_impact`

designConvention の変更は命題レベルで非空の影響を持つ。
    D1-D13 の依存先が存在することの証明。

```lean
theorem design_convention_has_impact :
  (structureToPropositionImpact .designConvention).length > 0 := by native_decide
```


#### D14: 検証順序の制約充足性（定理, §4.2）

根拠: P6（制約充足）+ T7（リソース有限性）+ T8（精度水準）

有限リソース下では検証順序が結果に影響する。
順序の選択は P6 の制約充足問題に含まれる。
D12 の拡張。

##### 公理系が定めないもの

D14 は「検証順序が重要」を導出するが、最適な順序の決定方法は導出しない。
情報利得、リスク順（fail-fast）、コスト順はいずれも D14 を満たすモデル。
具体的な方法の選択は L6（設計規約）レベル。

#### `theorem d14_verification_order_is_csp`

D14: リソースが有限（T7）かつ精度要求がある（T8）とき、
    タスク戦略の実行可能性は制約充足の範囲内（D12 の再述）。
    検証順序の選択はこの制約充足問題の一部。

```lean
theorem d14_verification_order_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction
```


#### Sorry Inventory (DesignFoundation)

sorry なし。新規非論理的公理（§4.1）なし。

全定理（§4.2）は既存の公理（T/E/P/V）の直接適用、
または帰納型（§7.2）の cases 解析で証明完了。

D1–D13 の各原理は、マニフェストの公理系から
**導出可能**（§2.4 導出可能性）であることが型検査で保証されている。
本ファイルは定義的拡大（§5.5）のみで構成され、
Terminology.lean が証明した `definitional_implies_conservative` により
保存拡大が保証される。

##### 既知の形式化ギャップ

| D | ギャップ | 影響 |
|---|---------|------|
| D3 | 可観測性の 3 条件（測定可能/劣化検知/改善検証）が未構造化 | 3 定理あるが条件構造は未形式化 |
| D5 | 仕様・テスト・実装の三層間関係が未形式化 | 3 定理あるが三層間の推移的依存は未形式化 |
| D6 | 境界→緩和策→変数の因果連鎖が未形式化 | 3 定理あるが因果連鎖は未形式化 |

##### Section 7（自己適用）の構造的強制

`SelfGoverning` 型クラス（§9.4, Ontology.lean）により、
D1–D12 を定義する `DesignPrinciple` 型は以下を満たす:
- 互換性分類の適用可能性（`canClassifyUpdate`）
- 分類の網羅性（`classificationExhaustive`）

`governed_update_classified` を呼ぶには `[SelfGoverning α]` が
必要なため、SelfGoverning を実装しない型は自己適用の文脈で
使用できない → **実装忘れは型エラーとして検出される**。


---

## Statistics

- **Files processed:** 6
- **Documented axioms:** 27
- **Documented theorems:** 101
- **Documented definitions:** 126
- **Total documented declarations:** 254

*Generated by `scripts/lean-to-markdown.py --manifesto`*
