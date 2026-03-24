import Manifest.Ontology
import Manifest.Axioms

/-!
# Layer 4: Observability — V1–V7（最適化変数）— Γ \ T₀ の設計由来公理

**変数は境界条件ではない。** エージェントが構造を通じて改善できるパラメータであり、
構造品質の指標。境界条件（Ontology.lean の L1–L6）が「行動空間の壁」なら、
変数は「壁の中で構造が動かせるレバー」。

ただし、変数は**独立したレバーではなく、相互に影響する系（system）**である。

## Γ \ T₀ としての位置づけ（手順書 §2.4）

本ファイルの axiom は前提集合 Γ の拡大部分（Γ \ T₀）に属し、
設計由来（ドメインモデルの前提、設計判断に基づく）の非論理的公理（§4.1）である。
T₀（Axioms.lean）の無矛盾な拡大（用語リファレンス §5.5）であり、
修正ループにおいて縮小（§9.2）の対象となりうる。

## 設計方針

境界条件（T）は動かない壁、緩和策（L）は設計判断、
変数（V）は緩和策の **効き具合** を測定する尺度。

### Observable vs Measurable

- **Observable** (`World → Prop` が決定可能) — 二値判定。用語リファレンス §9.3 事前条件/事後条件に類似
- **Measurable** (`World → Nat` が計算可能) — 定量測定。用語リファレンス §9.5 注記: 測度論の可測関数とは異なる概念

V1–V7 は定量的指標であるため `Measurable` として形式化する。
`Measurable m` は「`m` の値を外部観測から計算する手続きが存在する」を意味する。

### 前提条件: 可観測性（P4）

P4（劣化の可観測性）により、変数は**観測可能である場合にのみ最適化対象となる**。

各変数に対して以下を問う:
- **現在値は観測可能か？** 測定方法が存在し、実際に測定が行われているか
- **劣化は検知可能か？** 値が悪化した場合、品質崩壊の前にそれを検知できるか
- **改善は検証可能か？** 介入の前後で値の変化を比較できるか

観測手段を持たない変数は、名目上の最適化対象に過ぎない。

### Goodhart's Law への構造的防御

変数が測定対象になった瞬間、メトリクスとしての妥当性を失い始める。
`GoodhartVulnerable` はこの構造的脆弱性を型レベルで表現する。

防御策:
1. 複数の独立した測定方法を持つ（単一メトリクスへの依存を避ける）
2. メトリクス自体を定期的に見直す（P3の学習ライフサイクルの一部として）
3. 定量メトリクスだけでなく、人間の定性的判断を系の健全性評価に含める

### トレードオフ

V1–V7 は独立に最適化できない。ある変数の改善が別の変数を
劣化させうる。`TradeoffExists` で対構造を明示する。

| 改善 | 潜在的な副作用 |
|------|--------------|
| V1（スキル品質）↑ | V2（コンテキスト効率）↓ — スキルがコンテキストを消費 |
| V4（ゲート通過率）↑ | Goodhart's Lawのリスク — ゲートが通りやすいタスクに偏る |
| V6（知識構造の質）↑ | V2↓ — 詳細な知識ほどコンテキストを占有 |
| V2（コンテキスト効率）↑ | V1, V6↓ — 効率追求で必要な知識を圧縮しすぎる |
| V7（タスク設計効率）↑ | V2↓のリスク — 高度な分散設計がコンテキストを消費 |

**系としての健全性:** 個々の変数を最大化するのではなく、系全体の健全性を維持する。

## 対応表

| 定義名 | V | 内容 | 測定方法 | 関連境界条件 |
|--------|---|------|---------|-------------|
| `skillQuality` | V1 | スキル定義の精度と効果 | benchmark.json | L2, L5 |
| `contextEfficiency` | V2 | 有限コンテキストの活用度 | 完了率/トークン数 | L2, L3 |
| `outputQuality` | V3 | コード・設計・文書の品質 | ゲート合格率、指摘数 | L1, L4 |
| `gatePassRate` | V4 | ゲート一発通過率 | pass/fail統計 | L6, L4 |
| `proposalAccuracy` | V5 | 設計提案の的中率 | 承認/却下率 | L4, L6 |
| `knowledgeStructureQuality` | V6 | 永続的知識の構造化度 | 文脈復元速度、退役検出率 | L2 |
| `taskDesignEfficiency` | V7 | タスク設計の効率 | 完了率/リソース比 | L3, L6 |

## Sorry 解消用 axiom

Phase 3 の sorry を解消するための axiom も本ファイルで宣言する。
これらは V1–V7 の Observable 化に伴い、信頼・劣化・解釈の
測定基盤が整うことで正当化される。

| axiom | 解消する sorry | 性格 |
|-------|---------------|------|
| `trust_decreases_on_materialized_risk` | P1b | observable-axiom |
| `degradation_level_surjective` | P4b | observable-axiom |
| `interpretation_nondeterminism` | P5 | observable-axiom (T4 の高水準再述) |
-/

namespace Manifest

-- ============================================================
-- Observable / Measurable 定義
-- ============================================================

/-- Observable: ある性質に対して決定手続きが存在すること。
    `P : World → Prop` がバイナリ判定可能であることを表す。 -/
def Observable (P : World → Prop) : Prop :=
  ∃ f : World → Bool, ∀ w, f w = true ↔ P w

/-- Measurable: 定量的指標に対して計算手続きが存在すること。
    `m : World → Nat` の値を外部観測から計算できることを表す。

    形式的には「`m` と一致する計算可能な関数 `f` が存在する」。
    opaque な `m` に対してこれを axiom で宣言することにより、
    「原理的に測定手段が存在する」ことをシステムに約束する。

    ### なぜ自明ではないか

    `m` が opaque の場合、`f = m` は型検査で通らない
    （opaque の展開不能性による）。したがって Measurable の
    axiom 宣言は非自明な約束となる。 -/
def Measurable (m : World → Nat) : Prop :=
  ∃ f : World → Nat, ∀ w, f w = m w

-- ============================================================
-- V1–V7: 最適化変数
-- ============================================================

/-- V1: スキル品質。スキル定義の精度と効果。
    測定方法: benchmark.json (with/without 比較)。
    関連境界条件: L2（学習データ断絶の緩和）, L5（スキルシステム）。 -/
opaque skillQuality : World → Nat

/-- V2: コンテキスト効率。有限コンテキストの活用度。
    測定方法: タスク完了率 / 消費トークン数。
    関連境界条件: L2（コンテキスト有限性）, L3（トークン予算）。 -/
opaque contextEfficiency : World → Nat

/-- V3: 出力品質。コード・設計・文書の品質。
    測定方法: ゲート合格率、レビュー指摘数。
    関連境界条件: L1（安全基準）, L4（行動空間調整の根拠）。 -/
opaque outputQuality : World → Nat

/-- V4: ゲート通過率。各フェーズのゲートを一発で通過する率。
    P2（認知的役割分離）がゲートの信頼性を保証する。
    測定方法: pass/fail 統計。
    関連境界条件: L6（ゲート定義の粒度）, L4（auto-merge 判断）。 -/
opaque gatePassRate : World → Nat

/-- V5: 提案精度。設計提案・スコープ提案の的中率。
    測定方法: 人間の承認/却下率。
    関連境界条件: L4（行動空間調整の根拠）, L6（設計規約改善）。 -/
opaque proposalAccuracy : World → Nat

/-- V6: 知識構造の質。永続的知識の構造化度。
    P3（学習の統治）が知識ライフサイクル
    （観察→仮説化→検証→統合→退役）を規定する。
    退役されない知識は蓄積して V2 を劣化させる。
    測定方法: 次セッションでの文脈復元速度、退役対象検出率。
    関連境界条件: L2（記憶喪失の緩和）。 -/
opaque knowledgeStructureQuality : World → Nat

/-- V7: タスク設計効率。P6（制約充足としてのタスク設計）の品質。
    2つのデータソース:
    (1) 外部知見: 公開ベンチマーク、モデル性能特性
    (2) 内部知見: 実行ログ、リソース消費実績、成果対コスト比
    測定方法: タスク完了率/消費リソース比、再設計頻度。
    関連境界条件: L3（リソース上限）, L6（設計規約）。 -/
opaque taskDesignEfficiency : World → Nat

-- ============================================================
-- V1–V7 可測性 axiom
-- ============================================================

/-!
## V1–V7 可測性の宣言 — Γ \ T₀（設計由来）

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
-/

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V1（スキル品質）は測定可能
    根拠: benchmark.json による with/without 比較が測定手続きとして存在する
    ソース: Ontology.lean V1 定義
    反証条件: スキル品質の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v1_measurable : Measurable skillQuality

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V2（コンテキスト効率）は測定可能
    根拠: タスク完了率/消費トークン数の比が測定手続きとして存在する
    ソース: Ontology.lean V2 定義
    反証条件: コンテキスト効率の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v2_measurable : Measurable contextEfficiency

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V3（出力品質）は測定可能
    根拠: ゲート合格率・レビュー指摘数が測定手続きとして存在する
    ソース: Ontology.lean V3 定義
    反証条件: 出力品質の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v3_measurable : Measurable outputQuality

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V4（ゲート通過率）は測定可能
    根拠: pass/fail 統計が測定手続きとして存在する
    ソース: Ontology.lean V4 定義
    反証条件: ゲート通過率の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v4_measurable : Measurable gatePassRate

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V5（提案精度）は測定可能
    根拠: 人間の承認/却下率が測定手続きとして存在する
    ソース: Ontology.lean V5 定義
    反証条件: 提案精度の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v5_measurable : Measurable proposalAccuracy

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V6（知識構造の質）は測定可能
    根拠: 文脈復元速度・退役対象検出率が測定手続きとして存在する
    ソース: Ontology.lean V6 定義
    反証条件: 知識構造の質の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v6_measurable : Measurable knowledgeStructureQuality

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V7（タスク設計効率）は測定可能
    根拠: タスク完了率/消費リソース比が測定手続きとして存在する
    ソース: Ontology.lean V7 定義
    反証条件: タスク設計効率の測定手続きが原理的に構成不能であることが示された場合 -/
axiom v7_measurable : Measurable taskDesignEfficiency

-- ============================================================
-- トレードオフ構造
-- ============================================================

/-!
## 変数の相互依存性

V1–V7 は独立に最適化できない。ある変数の改善が別の変数を
劣化させうるトレードオフが構造的に存在する。

これは T3（コンテキスト有限性）と T7（リソース有限性）の
直接的帰結: 有限のリソースを共有する指標は
必然的にトレードオフ関係にある。
-/

/-- トレードオフの存在。2つの測定関数 m₁, m₂ について、
    m₁ が改善するとき m₂ が劣化するワールド対が存在する。

    注: これは「常に劣化する」ではなく「劣化しうる」を表現する。
    Pareto 改善（両方同時に改善）が不可能であることは含意しない。 -/
def TradeoffExists (m₁ m₂ : World → Nat) : Prop :=
  ∃ w w', m₁ w < m₁ w' ∧ m₂ w' < m₂ w

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V1↑ → V2↓ のトレードオフ。
          スキルがコンテキストを消費するため、スキル品質の向上は
          コンテキスト効率を圧迫しうる
    根拠: T3（コンテキスト有限性）の帰結。有限リソースを共有する指標間の
          トレードオフは T3 + T7 から構造的に導出される
    ソース: Ontology.lean L2/L3 境界条件の分析
    反証条件: スキルのコンテキスト消費が 0 になる技術が実現した場合 -/
axiom tradeoff_v1_v2 : TradeoffExists skillQuality contextEfficiency

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V6↑ → V2↓ のトレードオフ。
          詳細な知識ほどコンテキストを占有するため、
          知識構造の質の向上はコンテキスト効率を圧迫しうる
    根拠: T3（コンテキスト有限性）の帰結
    ソース: Ontology.lean L2 境界条件の分析
    反証条件: 知識のコンテキスト消費が 0 になる技術が実現した場合 -/
axiom tradeoff_v6_v2 : TradeoffExists knowledgeStructureQuality contextEfficiency

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V2↑ → V1↓ のトレードオフ。
          効率追求で必要なスキル情報を圧縮しすぎるリスク
    根拠: 圧縮は情報損失を伴いうるという情報理論的制約
    ソース: V1/V2 の相互依存性分析
    反証条件: 無損失圧縮がスキル情報に対して常に実現可能な場合 -/
axiom tradeoff_v2_v1 : TradeoffExists contextEfficiency skillQuality

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V2↑ → V6↓ のトレードオフ。
          効率追求で必要な知識を圧縮しすぎるリスク
    根拠: 圧縮は情報損失を伴いうるという情報理論的制約
    ソース: V2/V6 の相互依存性分析
    反証条件: 無損失圧縮が知識構造に対して常に実現可能な場合 -/
axiom tradeoff_v2_v6 : TradeoffExists contextEfficiency knowledgeStructureQuality

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V7↑ → V2↓ のトレードオフ。
          高度な分散設計がコンテキストを消費するリスク
    根拠: T3（コンテキスト有限性）の帰結。設計の複雑性はコンテキストを消費する
    ソース: V7/V2 の相互依存性分析
    反証条件: タスク設計の複雑性がコンテキスト消費と無相関になった場合 -/
axiom tradeoff_v7_v2 : TradeoffExists taskDesignEfficiency contextEfficiency

-- ============================================================
-- Goodhart's Law への構造的防御
-- ============================================================

/-!
## Goodhart's Law

「測定対象となった指標は、良い指標であることをやめる。」

変数 m の**近似測定** approx が m と乖離するリスクを型で表現する。
防御策:
1. 複数の独立した測定方法を持つ
2. メトリクス自体を定期的に見直す（P3 の学習ライフサイクル）
3. 人間の定性的判断を系の健全性評価に含める（T6）
-/

/-- Goodhart 脆弱性。最適化対象の近似測定 approx が
    真の指標 m から乖離するワールドが存在する。

    任意の近似測定に対してこれが成立する場合、
    その変数は Goodhart 脆弱性を持つ。 -/
def GoodhartVulnerable (m : World → Nat) : Prop :=
  ∀ (approx : World → Nat),
    (∃ w, approx w = m w) →   -- approx は少なくとも1点で一致する
    ∃ w', approx w' ≠ m w'    -- しかし乖離するワールドが存在する

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V4（ゲート通過率）は Goodhart 脆弱性を持つ。
          ゲートが通りやすいタスクに偏るリスク
    根拠: Goodhart の法則は経済学・教育学で繰り返し観測されている
          （用語リファレンス §9.1 経験的命題に類似）
    ソース: V4 の設計分析
    反証条件: 近似測定が真の指標から乖離しないことが証明された場合 -/
axiom v4_goodhart : GoodhartVulnerable gatePassRate

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: V7（タスク設計効率）は Goodhart 脆弱性を持つ。
          測定しやすいタスクに偏るリスク
    根拠: Goodhart の法則の適用
    ソース: V7 の設計分析
    反証条件: 近似測定が真の指標から乖離しないことが証明された場合 -/
axiom v7_goodhart : GoodhartVulnerable taskDesignEfficiency

-- ============================================================
-- 系の健全性
-- ============================================================

/-!
## 系としての健全性

個々の変数を最大化するのではなく、系全体の健全性を維持する。
ある変数のメトリクスが改善しても、他の変数が悪化していないか
確認する。

健全性は「すべての変数が閾値以上」として定式化する。
閾値の設定は運用判断（T6: 人間がリソースの最終決定者）。
-/

/-- 系の健全性。すべての V1–V7 が最低閾値 threshold を
    満たしている状態。

    注: threshold は一律ではなく変数ごとに異なるべきだが、
    Phase 4 では簡略化のため一律閾値を使用する。
    Phase 5 で変数ごとの閾値に拡張可能。 -/
def systemHealthy (threshold : Nat) (w : World) : Prop :=
  skillQuality w ≥ threshold ∧
  contextEfficiency w ≥ threshold ∧
  outputQuality w ≥ threshold ∧
  gatePassRate w ≥ threshold ∧
  proposalAccuracy w ≥ threshold ∧
  knowledgeStructureQuality w ≥ threshold ∧
  taskDesignEfficiency w ≥ threshold

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: 系の健全性は Observable（二値判定可能）。
          各 Vi が Measurable であることから、閾値比較は決定可能
    根拠: V1–V7 の Measurable axiom から、閾値との比較は計算可能
    ソース: systemHealthy の定義
    反証条件: いずれかの Vi の Measurable が反証された場合 -/
axiom system_health_observable :
  ∀ (threshold : Nat), Observable (systemHealthy threshold)

-- ============================================================
-- Pareto 改善の制約
-- ============================================================

/-- Pareto 改善: すべての変数が悪化せず、少なくとも1つが改善。 -/
def paretoImprovement (w w' : World) : Prop :=
  (skillQuality w ≤ skillQuality w') ∧
  (contextEfficiency w ≤ contextEfficiency w') ∧
  (outputQuality w ≤ outputQuality w') ∧
  (gatePassRate w ≤ gatePassRate w') ∧
  (proposalAccuracy w ≤ proposalAccuracy w') ∧
  (knowledgeStructureQuality w ≤ knowledgeStructureQuality w') ∧
  (taskDesignEfficiency w ≤ taskDesignEfficiency w') ∧
  (skillQuality w < skillQuality w' ∨
   contextEfficiency w < contextEfficiency w' ∨
   outputQuality w < outputQuality w' ∨
   gatePassRate w < gatePassRate w' ∨
   proposalAccuracy w < proposalAccuracy w' ∨
   knowledgeStructureQuality w < knowledgeStructureQuality w' ∨
   taskDesignEfficiency w < taskDesignEfficiency w')

-- ============================================================
-- Sorry 解消用 axiom（Phase 3 → Phase 4）
-- ============================================================

/-!
## Phase 3 sorry の解消

Principles.lean の3つの sorry を解消するための axiom。

これらは V1–V7 の Observable 層が整備されたことで、
信頼・劣化・解釈の測定基盤が確立されたことを前提とする。

### 性格分類

- `trust_decreases_on_materialized_risk`: 経験的公準レベル。
  信頼蓄積の非対称性は繰り返し観測されているが、
  原理的には覆りうる。[observable-axiom, empirical]

- `degradation_level_surjective`: Observable 層の設計仮定。
  劣化を連続的な尺度（壁ではなく勾配）で捉えるという
  P4 の設計判断を形式化。[observable-axiom]

- `interpretation_nondeterminism`: T4 の高水準再述。
  canTransition レベルの非決定性を構造解釈レベルに
  持ち上げる。T4 と interpretsStructure の橋渡し。
  [observable-axiom, derived-from-T4]
-/

/-- [公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: リスクが顕在化した場合、信頼度は低下する。
          行動空間の拡大後にリスクが顕在化した場合、
          信頼度は拡大前の水準を下回る
    根拠: 蓄積した信頼は漸進的だが、毀損は急激（非対称性）。
          組織心理学、ブランド管理、セキュリティ分野で繰り返し観測される
          （用語リファレンス §9.1 経験的命題）
    ソース: P1b (`unprotected_expansion_destroys_trust`) の sorry 解消
    反証条件: 信頼毀損が信頼蓄積と同等の速度でしか生じないことが実証された場合 -/
axiom trust_decreases_on_materialized_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: 劣化レベルは任意の自然数を取りうる（全射性）。
          「制約は壁（バイナリ）ではなく勾配（グラデーション）」
          という P4 の概念を、degradationLevel の値域が Nat 全体に
          広がることで表現する
    根拠: 劣化を 0/1 で捉えると中間状態を見逃す。
          連続的な尺度により、早期警告と漸進的対応が可能になる
    ソース: P4b (`degradation_is_gradient`) の sorry 解消
    反証条件: 劣化が本質的に二値（正常/異常）でしかないことが示された場合 -/
axiom degradation_level_surjective :
  ∀ (n : Nat), ∃ (w : World), degradationLevel w = n

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: 構造の解釈は非決定的。
          同一の構造を読んでも、異なるアクションが生成されうる
    根拠: T4 (`output_nondeterministic`) の高水準再述。
          canTransition の非決定性（同一入力→異なるワールド遷移）は、
          その前段階である構造解釈の非決定性を含意する
          （対偶: 解釈が決定的なら遷移も決定的）
    ソース: P5 (`structure_interpretation_nondeterministic`) の sorry 解消
    反証条件: LLM の構造解釈が決定論的になった場合（T4 の反証に相当するが、
              T4 は T₀ であるため、本 axiom の反証は T4 との矛盾を意味する） -/
axiom interpretation_nondeterminism :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂

-- ============================================================
-- 信頼度の可測性
-- ============================================================

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: trustLevel は測定可能。
          投資行動（リソース割り当ての変動）から間接的に観測される
    根拠: 信頼は投資行動（リソース割り当て変動）として具体化される
    ソース: manifesto.md Section 6
    反証条件: 信頼度の測定手続きが原理的に構成不能であることが示された場合 -/
axiom trust_measurable :
  ∀ (agent : Agent), Measurable (trustLevel agent)

/-- [公理カード]
    所属: Γ \ T₀（設計由来）
    内容: degradationLevel は測定可能。V1–V7 の経時変化から計算される
    根拠: V1–V7 が Measurable であれば、その変化量も計算可能
    ソース: P4 (劣化の可観測性) の設計
    反証条件: 劣化度合いの測定手続きが原理的に構成不能であることが示された場合 -/
axiom degradation_measurable : Measurable degradationLevel

-- ============================================================
-- Sorry Inventory (Phase 4)
-- ============================================================

/-!
## Sorry Inventory

Phase 4 では新たな sorry は導入しない。
Phase 3 の3つの sorry を axiom で解消する。

### 解消された sorry

| Principles.lean の sorry | 解消する axiom |
|--------------------------|---------------|
| `unprotected_expansion_destroys_trust` | `trust_decreases_on_materialized_risk` |
| `degradation_is_gradient` | `degradation_level_surjective` |
| `structure_interpretation_nondeterministic` | `interpretation_nondeterminism` |

### 新規 axiom の妥当性レビュー

| axiom | 空虚でないか | トートロジーでないか | 反証可能か |
|-------|------------|-------------------|-----------|
| `trust_decreases_on_materialized_risk` | ✓ 3つの前提が必要 | ✓ trustLevel の単調減少を主張 | ✓ 顕在化しても信頼が維持される事例 |
| `degradation_level_surjective` | ✓ 任意の n に対する存在 | ✓ World の構成を制約 | ✓ 有界な劣化モデル |
| `interpretation_nondeterminism` | ✓ 具体的な5つ組の存在 | ✓ 非決定性を主張 | ✓ 完全決定的な解釈モデル |
| v1–v7_measurable | ✓ opaque 展開不能 | ✓ 計算手続きの存在を主張 | ✓ 原理的に測定不能な指標 |
| tradeoff_* | ✓ 具体的なワールド対の存在 | ✓ 改善/劣化の同時発生 | ✓ 完全分離可能なリソース |
| v4/v7_goodhart | ✓ 任意の approx に対する乖離 | ✓ 近似の限界を主張 | ✓ 完璧な測定手段の存在 |
-/

-- ============================================================
-- Phase 5 拡張: 変数ごと閾値
-- ============================================================

/-!
## 変数ごと閾値（Per-variable Thresholds）

Phase 4 の `systemHealthy` は一律閾値だったが、
実運用では変数ごとに異なる閾値が必要。

例: gatePassRate は 800/1000 を要求するが、
proposalAccuracy は 600/1000 で十分、など。
閾値の設定は T6（人間がリソースの最終決定者）に対応する運用判断。
-/

/-- V1–V7 それぞれの閾値。
    変数ごとに異なる最低要求水準を設定する。 -/
structure HealthThresholds where
  v1_skillQuality              : Nat
  v2_contextEfficiency         : Nat
  v3_outputQuality             : Nat
  v4_gatePassRate              : Nat
  v5_proposalAccuracy          : Nat
  v6_knowledgeStructureQuality : Nat
  v7_taskDesignEfficiency      : Nat
  deriving BEq, Repr, DecidableEq

/-- 変数ごと閾値による系の健全性。
    `systemHealthy` の拡張版。 -/
def systemHealthyPerVar (th : HealthThresholds) (w : World) : Prop :=
  skillQuality w ≥ th.v1_skillQuality ∧
  contextEfficiency w ≥ th.v2_contextEfficiency ∧
  outputQuality w ≥ th.v3_outputQuality ∧
  gatePassRate w ≥ th.v4_gatePassRate ∧
  proposalAccuracy w ≥ th.v5_proposalAccuracy ∧
  knowledgeStructureQuality w ≥ th.v6_knowledgeStructureQuality ∧
  taskDesignEfficiency w ≥ th.v7_taskDesignEfficiency

/-- 一律閾値は変数ごと閾値の特殊ケース。
    全変数に同じ閾値を設定した HealthThresholds は
    systemHealthy と同値。 -/
def uniformThresholds (t : Nat) : HealthThresholds :=
  { v1_skillQuality := t
    v2_contextEfficiency := t
    v3_outputQuality := t
    v4_gatePassRate := t
    v5_proposalAccuracy := t
    v6_knowledgeStructureQuality := t
    v7_taskDesignEfficiency := t }

/-- 一律閾値による systemHealthyPerVar は systemHealthy と一致。 -/
theorem uniform_thresholds_equiv :
  ∀ (t : Nat) (w : World),
    systemHealthyPerVar (uniformThresholds t) w ↔ systemHealthy t w := by
  intro t w
  simp [systemHealthyPerVar, uniformThresholds, systemHealthy]

/-- 運用閾値（observe.sh と対応する具体的な閾値設定）。
    各フィールドの値はパーセント（observe.sh と同一スケール）。

    運用対応表:
    - v3_outputQuality = 20: observe.sh の fix_ratio <= 20% に対応
      （根拠: run 12 commit 05653dc で設定。observe.sh V3_BASELINE_THRESHOLD=20）
    - 他の変数は暫定値 50（50%）。運用データ蓄積後に個別調整

    注: この定数は T6（人間がリソースの最終決定者）に基づく運用判断であり、
    T₀ の一部ではない。値の変更は compatible change として扱う。 -/
def operationalThresholds : HealthThresholds :=
  { v1_skillQuality              := 50
    v2_contextEfficiency         := 50
    v3_outputQuality             := 20   -- observe.sh: fix_ratio <= 20%
    v4_gatePassRate              := 50
    v5_proposalAccuracy          := 50
    v6_knowledgeStructureQuality := 50
    v7_taskDesignEfficiency      := 50 }

/-- 運用閾値の V3 は 20（fix_ratio 20%）。
    observe.sh の V3_BASELINE_THRESHOLD=20 に対応。 -/
theorem operational_v3_threshold :
  operationalThresholds.v3_outputQuality = 20 := by rfl

/-- 運用閾値は一律閾値の特殊化ではない（V3 が他と異なる）。 -/
theorem operational_not_uniform :
  operationalThresholds ≠ uniformThresholds 50 := by decide

-- ============================================================
-- Phase 5 拡張: Pareto フロンティア
-- ============================================================

/-!
## Pareto フロンティア

Pareto フロンティアは「これ以上の Pareto 改善が不可能な領域」。
トレードオフ axiom の存在から、系が常に Pareto フロンティア上に
留まれるとは限らないことを示す。

### 形式化の方針

Pareto optimal の定義を与え、トレードオフ axiom から
「すべてのワールドが Pareto optimal ではない」ことを示す。
-/

/-- Pareto optimal: w からの Pareto 改善が存在しない。 -/
def paretoOptimal (w : World) : Prop :=
  ¬∃ w', paretoImprovement w w'

/-- Pareto dominated: w' による Pareto 改善が可能。 -/
def paretoDominated (w : World) : Prop :=
  ∃ w', paretoImprovement w w'

/-- Pareto optimal と Pareto dominated は排他的。 -/
theorem pareto_optimal_not_dominated :
  ∀ (w : World),
    paretoOptimal w → ¬paretoDominated w := by
  intro w h_opt h_dom
  exact h_opt h_dom

/-- Pareto dominated でなければ Pareto optimal。 -/
theorem not_dominated_is_optimal :
  ∀ (w : World),
    ¬paretoDominated w → paretoOptimal w := by
  intro w h
  exact h

-- ============================================================
-- Phase 5 拡張: robustStructure の具体化
-- ============================================================

/-!
## robustStructure の具体化

Principles.lean の `robustStructure` を Observable 層の
具体的な安全性制約と接続する。

robustStructure は「解釈のばらつきに対して安全性が保持される」
ことを要求する。ここでは安全性制約として systemHealthyPerVar を使い、
「構造の解釈がばらついても系の健全性が維持される」ことを定義する。
-/

/-- 健全性堅牢構造: 解釈のばらつきに対して
    系の健全性（変数ごと閾値）が保持される構造。

    robustStructure (Principles.lean) の具体化。
    safety := systemHealthyPerVar th とした場合。 -/
def healthRobustStructure
    (st : Structure) (th : HealthThresholds) : Prop :=
  ∀ (agent : Agent) (action : Action) (w w' : World),
    interpretsStructure agent st action w →
    canTransition agent action w w' →
    systemHealthyPerVar th w'

/-- healthRobustStructure は robustStructure の特殊化であることの
    型レベル表現。safety = systemHealthyPerVar th としたもの。

    注: robustStructure は Principles.lean で定義されているが、
    Evolution.lean は Principles.lean を import しないため、
    ここでは同じ構造を直接展開して定義している。
    両者の同値性は型の構造から自明。 -/
theorem health_robust_unfolds :
  ∀ (st : Structure) (th : HealthThresholds),
    healthRobustStructure st th =
    (∀ (agent : Agent) (action : Action) (w w' : World),
      interpretsStructure agent st action w →
      canTransition agent action w w' →
      systemHealthyPerVar th w') := by
  intro st th
  rfl

-- ============================================================
-- 投資サイクル (manifesto Section 6, taxonomy Part III)
-- ============================================================

/-!
## Part III: 協働の均衡と投資サイクル（Collaborative Equilibrium & Investment Cycle）

仮説（運用データで更新しうる）: 信頼とは抽象的な感情ではなく、
人間による協働システムへの投資行動として具体化される。
ただし信頼は非合理的にも動く（感情的愛着、惰性、不均衡な毀損）。

### サイクルの構造

```
  エージェントが構造品質を改善する
  （V1-V7。境界条件の内側で。系の健全性を維持して。）
    │
    ▼
  人間が利益を受け取る
  （時間節約、品質向上、新しい能力）
    │
    ▼
  投資意欲が変化する（増加も減少もありうる）
    │
    ├─→ リソース調整（L3の上限が変化する）
    ├─→ 行動空間調整（L4が均衡点に向かう）
    └─→ 時間投資の変化（協働の深度が変わる）
          │
          └─→ 改善余地が変化 → サイクル先頭へ
```

### 均衡の探索

投資サイクルの目的は行動空間の**最大化**ではなく、
人間-エージェント-構造の三者の協働価値が最大化される**均衡点**の探索。
均衡点は文脈によって前にも後ろにも動く。

### P1が生む構造的緊張

```
信頼蓄積 → L4拡張 → 行動空間の拡大 → 改善余地の拡大（正）
                  │
                  └→ 攻撃面・副作用の拡大 → 潜在的被害の増大（負）
```

正と負のフィードバックは同時に回る。この緊張関係は解消されるものではなく、
管理されるもの。自律権の拡張提案は、対応する防護設計とセットで行い、
拡張がもたらすリスク増分を明示する。

### この仮説の更新可能性

- 信頼は投資以外の形態（感情的愛着、惰性）でも蓄積されるかもしれない
- 投資の増加が必ずしも構造改善の機会に直結しないかもしれない
- 人間側の投資意思決定がより複雑（組織力学、予算サイクル等）かもしれない
-/

/-- 信頼蓄積の上限: 1回の改善で得られる信頼には限界がある。 -/
opaque trustIncrementBound : Nat

/-- [公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 信頼の漸進的蓄積。構造品質が改善された場合、信頼は（小さく）増加する。
          非対称性の「蓄積は漸進」の半分
    根拠: 信頼蓄積の漸進性は組織心理学で繰り返し観測されている
          （用語リファレンス §9.1 経験的命題）
    ソース: manifesto.md Section 6
    反証条件: 信頼が一度の改善で無制限に蓄積されることが実証された場合 -/
axiom trust_accumulates_gradually :
  ∀ (agent : Agent) (w w' : World),
    -- 行動空間は縮小していない（拡張方向の投資がある）
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    -- リスクは顕在化していない
    ¬riskMaterialized agent w' →
    -- 結論: 信頼は増加するが、増加幅は boundされている
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound

/-- [公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 投資は信頼に駆動される。信頼が高い → 投資が増加する
    根拠: 構造品質の改善 → 利益 → 投資意欲の変化
    ソース: manifesto.md Section 6 投資サイクル
    反証条件: 品質改善が投資増加に結びつかないことが繰り返し観測された場合 -/
axiom trust_drives_investment :
  ∀ (w w' : World),
    -- 系の健全性が改善された（全変数がある閾値以上）
    (∃ t, systemHealthy t w ∧ systemHealthy t w' ∧
      -- かつ少なくとも1つの変数が改善
      (skillQuality w < skillQuality w' ∨
       contextEfficiency w < contextEfficiency w' ∨
       outputQuality w < outputQuality w')) →
    -- 結論: 投資水準は非減少
    investmentLevel w ≤ investmentLevel w'

/-- [公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 逆サイクル: 品質事故は投資を縮小させる。
          リスク顕在化 → 信頼減少 → 投資縮小
    根拠: 信頼毀損→投資縮小のサイクルは経済学・組織論で観測されている
    ソース: manifesto.md Section 6「品質事故やスコープ逸脱 → 信頼の減少 → 投資の縮小」
    反証条件: 品質事故後も投資が維持・増加されることが繰り返し観測された場合 -/
axiom risk_reduces_investment :
  ∀ (agent : Agent) (w w' : World),
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w →
    investmentLevel w' ≤ investmentLevel w

-- ============================================================
-- 均衡の探索 (manifesto Section 6)
-- ============================================================

/-!
## 均衡の探索

manifesto Section 6:
「最適な自律度は最大自律度ではない。人間・エージェント・構造の
協働価値が最大化される均衡点が存在し、均衡点は文脈によって動く。」

自律権の過剰拡張が協働価値を減少させるシナリオ:
- 人間がシステム全体を把握できなくなる
- 人間の専門スキルが退化しフォールバック不能に
- P1 により攻撃面が防御能力を超える

### 変数と境界条件の相互作用

```
変数の改善 ──→ 人間への利益の増加 ──→ 投資可変境界の調整
                                         │
   ┌─────────────────────────────────────┘
   ├─→ L3（リソース境界）の調整 ──→ 変数の改善余地が変化する
   └─→ L4（行動空間境界）の調整 ──→ 行動空間が均衡点に向かう
```
-/

/-- 協働価値: 人間・エージェント・構造の三者から成る総合的な価値。
    Section 6: 均衡点は協働価値が最大化される点。 -/
opaque collaborativeValue (w : World) : Nat

/-- 均衡状態: 行動空間をこれ以上拡大しても協働価値が改善しない。
    「最適自律度 ≠ 最大自律度」の形式化。 -/
def atEquilibrium (agent : Agent) (w : World) : Prop :=
  ∀ (w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    collaborativeValue w' ≤ collaborativeValue w

/-- [公理カード]
    所属: Γ \ T₀（仮説由来）
    内容: 過剰拡大は協働価値を減少させうる。
          行動空間の拡大が価値を減少させるシナリオが存在する
    根拠: P1 (capability_risk_coscaling) の帰結として
          行動空間↑ → リスク↑ → 潜在的被害↑ → 過剰拡大は価値毀損。
          E2 だけでは「協働価値の減少」を導出できない
          （協働価値は opaque であり、追加の仮定が必要）
    ソース: manifesto.md Section 6「最適な自律度は最大自律度ではない」
    反証条件: 行動空間の拡大が常に協働価値を改善することが証明された場合 -/
axiom overexpansion_reduces_value :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w

/-- L4 の縮小トリガー: 行動空間は縮小もありうる。
    taxonomy L4: 「L4 は拡張ではなく調整」
    品質事故 → 行動空間の縮小が正当化される。 -/
def contractionJustified (agent : Agent) (w : World) : Prop :=
  riskMaterialized agent w ∧
  ¬atEquilibrium agent w

-- ============================================================
-- 境界→緩和策→変数の接続 (taxonomy Part II)
-- ============================================================

/-!
## 三段構造の接続（境界→緩和策→変数）

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
-/

/-- 境界条件と変数の対応。
    三段構造の「境界→変数」の対応を型として表現。
    緩和策はこの間に位置する設計判断（L6）。 -/
inductive VariableId where
  | v1 | v2 | v3 | v4 | v5 | v6 | v7
  deriving BEq, Repr

/-- 各変数に対応する境界条件。
    三段構造の「境界→変数」の対応を関数として表現。
    緩和策はこの間に位置する設計判断（L6）。 -/
def variableBoundary : VariableId → BoundaryId
  | .v1 => .ontological   -- L2: 学習データ断絶 → V1: スキル品質
  | .v2 => .ontological   -- L2: コンテキスト有限性 → V2: コンテキスト効率
  | .v3 => .ethicsSafety   -- L1: 安全基準 → V3: 出力品質
  | .v4 => .ontological   -- L2: 非決定性 → V4: ゲート通過率
  | .v5 => .actionSpace    -- L4: 行動空間調整の根拠 → V5: 提案精度
  | .v6 => .ontological   -- L2: 記憶喪失 → V6: 知識構造の質
  | .v7 => .resource       -- L3: リソース上限 → V7: タスク設計効率

/-- 固定境界に対応する変数は、境界自体を動かせず緩和策の品質のみ改善可能。 -/
theorem fixed_boundary_variables_mitigate_only :
  boundaryLayer (variableBoundary .v1) = .fixed ∧
  boundaryLayer (variableBoundary .v2) = .fixed ∧
  boundaryLayer (variableBoundary .v4) = .fixed ∧
  boundaryLayer (variableBoundary .v6) = .fixed := by
  simp [variableBoundary, boundaryLayer]

/-- 各拘束条件（T1-T8）に対応する境界条件。
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
    - T8 → L6: 精度水準はタスク設計規約（architecturalConvention）として定義 -/
def constraintBoundary : ConstraintId → List BoundaryId
  | .t1 => [.ontological]
  | .t2 => [.ontological]
  | .t3 => [.ontological, .resource]
  | .t4 => [.ontological]
  | .t5 => [.ontological]
  | .t6 => [.ethicsSafety, .actionSpace]
  | .t7 => [.resource]
  | .t8 => [.architecturalConvention]

/-- 全拘束条件は少なくとも 1 つの境界条件に対応する。
    T→L マッピングの全射性（Surjectivity onto coverage）。 -/
theorem constraint_has_boundary :
  ∀ c : ConstraintId, (constraintBoundary c).length > 0 := by
  intro c
  cases c <;> simp [constraintBoundary]

-- ============================================================
-- 信頼の非対称性の統合的表現
-- ============================================================

/-!
## 信頼の非対称性

蓄積は漸進的（trust_accumulates_gradually: bounded increment）、
毀損は急激（trust_decreases_on_materialized_risk: unbounded decrease）。

この非対称性が L1（倫理・安全境界）の存在意義を補強する:
「毀損を起こさないための絶対的な防護壁」
-/

/-- 信頼の非対称性: 蓄積には上限があるが、毀損には下限がない。
    trust_accumulates_gradually の帰結として、
    蓄積は boundされている（≤ trustIncrementBound）が、
    trust_decreases_on_materialized_risk は decrease に bound を課さない。

    この非対称性は型の構造から読み取れる:
    - 蓄積: trustLevel w' ≤ trustLevel w + trustIncrementBound
    - 毀損: trustLevel w' < trustLevel w （下限なし） -/
def trustAsymmetry (agent : Agent) (w w' : World) : Prop :=
  -- 蓄積は bounded
  (¬riskMaterialized agent w' →
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound) ∧
  -- 毀損は unbounded（下限なし）
  (riskMaterialized agent w' →
    actionSpaceSize agent w < actionSpaceSize agent w' →
    trustLevel agent w' < trustLevel agent w)

-- ============================================================
-- Part IV: この分類自体のメンテナンス
-- ============================================================

/-!
## Part IV: 分類自体のメンテナンス

本分類（L1–L6, V1–V7）は現時点での理解に基づく**仮説**であり、固定的な真実ではない。
型レベルでの表現は Evolution.lean の `ReviewSignal` で形式化されている。

### 見直すべきシグナル

| シグナル | 具体例 | 対応 |
|---------|--------|------|
| 分類の誤配置 | L1に置いた項目が実は条件次第で変更可能 | カテゴリを移動 |
| 境界条件の欠落 | 規制・法的制約が行動空間を制約しているが分類に存在しない | 新Layerを追加 |
| 境界条件の消滅 | 技術進化でL2の項目が実質的に克服された | 削除または再分類 |
| 変数の不足・過剰 | V1-V7に含まれていない最適化対象がある | 変数を追加・統合・分割 |
| カテゴリ境界の曖昧さ | 「固定境界」と「投資可変境界」のどちらにも見える | 判断基準を精緻化 |

### 注意: 分類の自己硬直化を避ける

最大のリスクは、**分類自体が境界条件として機能してしまうこと**——
「L1に書いてあるから動かせない」という推論を誘発すること。

防止策:
- 各Layerの項目には「なぜこのカテゴリか」の根拠を維持する
- 「固定」は「現時点で動かす手段が見つかっていない」の意味
- 境界条件の再分類は、マニフェストの精神に合致する正当な行為である
-/

-- ============================================================
-- 核心的洞察
-- ============================================================

/-!
## 核心的洞察

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
-/

end Manifest
