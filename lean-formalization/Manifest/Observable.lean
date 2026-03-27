import Manifest.Ontology
import Manifest.Axioms

/-!
# Epistemic Layer: boundary (strength 2) — V1–V7 可観測変数の基盤

**変数は境界条件ではない。** エージェントが構造を通じて改善できるパラメータであり、
構造品質の指標。境界条件（Ontology.lean の L1–L6）が「行動空間の壁」なら、
変数は「壁の中で構造が動かせるレバー」。

ただし、変数は**独立したレバーではなく、相互に影響する系（system）**である。

## 層分離

本ファイルは **boundary 層（strength 2）** に属する定義のみを含む:
- V1–V7 の opaque 定義と Measurable axiom（可測性の保証）
- trust/degradation の可測性 axiom
- systemHealthy（系の健全性の基本定義）
- 境界→変数→拘束条件のマッピング構造
- Measurable → Observable ブリッジ定理

designTheorem 層（strength 1）の定義 — トレードオフ、Goodhart、投資サイクル、
HealthThresholds、Pareto 等 — は **ObservableDesign.lean** に分離されている。

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
-- Proxy 成熟度分類
-- ============================================================

/-- Proxy 成熟度段階。observe.sh の各 V proxy に分類を付与する。
    - provisional: 暫定代理指標。正式測定方法が未実装。
    - established: 安定代理指標。運用上の十分性が確認済み（T6 判断）。
    - formal: 正式測定方法が実装済み。-/
inductive ProxyMaturityLevel where
  | provisional : ProxyMaturityLevel
  | established : ProxyMaturityLevel
  | formal : ProxyMaturityLevel
  deriving BEq, Repr, DecidableEq

/-- V1 の現在の proxy 成熟度。
    provisional → formal (2026-03-27, #77):
    - GQM チェーン定義済み (R1 #85): Q1 structural contribution, Q2 verification quality, Q3 operational stability
    - benchmark.json に正式スキーマ実装済み (G1 #78)
    - observe.sh で自動計測 (G2 #79)
    - 63 runs の後ろ向き検証で全 metric が仮説を充足
    - Goodhart 5 層防御: ガバナンス指標 (R2), 相関監視 (R3), 非自明性ゲート (R5), 飽和検出 (R6), bias レビュー義務 (G1b-2)
    - 旧 proxy (success_rate) は新 benchmark と無相関 (r=0.006-0.069) であることを確認 (G3 #80) -/
def v1ProxyMaturity : ProxyMaturityLevel := .formal

/-- V3 の現在の proxy 成熟度。
    provisional → formal (2026-03-27, #77):
    - GQM チェーン定義済み (R1 #85): Q1 acceptance criteria, Q2 structural integrity, Q3 error trend
    - benchmark.json に正式スキーマ実装済み (G1 #78)
    - observe.sh で自動計測 (G2 #79)
    - 旧 proxy (test_pass_rate) は分散 0 で品質信号として無効であることを確認 (G3 #80)
    - hallucination proxy (Run 54+) が error trend の新指標として機能 -/
def v3ProxyMaturity : ProxyMaturityLevel := .formal

-- ============================================================
-- V1–V7: 最適化変数
-- ============================================================

/-- V1: スキル品質。スキル定義の精度と効果。
    測定方法: benchmark.json (with/without 比較)。
    関連境界条件: L2（学習データ断絶の緩和）, L5（スキルシステム）。
    observe.sh proxy: evolve_success_rate（成功run比率）, lean_health（sorry=0判定）,
    skill_count（スキルファイル数）。
    proxy 成熟度分類:
    - provisional_proxy: 暫定代理指標。正式測定方法が未実装。
    - established_proxy: 安定代理指標。運用上十分と判断。
    - formal_measurement: 正式測定方法が実装済み。
    現在の V1 proxy は provisional_proxy。卒業条件: benchmark.json 実装 OR 運用的相関証拠（T6 判断）。 -/
opaque skillQuality : World → Nat

/-- V2: コンテキスト効率。有限コンテキストの活用度。
    測定方法: タスク完了率 / 消費トークン数。
    関連境界条件: L2（コンテキスト有限性）, L3（トークン予算）。
    observe.sh proxy: recent_avg（直近10セッションデルタ中央値、primary）,
    cumulative_avg（全履歴マイクロセッション除外平均、baseline）。
    primary_metric: recent_median（中央値ベース、外れ値にロバスト）。
    運用注記: recent_avg が cumulative_avg の ±20% 以上乖離した場合にトレンド変化と判定。
    divergence 解釈: V2 は 5 変数とトレードオフ関係を持つハブ変数（定理 tradeoff_context_is_hub）。
    evolve セッション（大量ツール使用）が recent_avg を押し上げるため、
    divergence_percent > 100% は必ずしも問題ではない。
    evolve の深さと頻度が増すほど recent_avg が上昇する傾向は想定内。 -/
opaque contextEfficiency : World → Nat

/-- V3: 出力品質。コード・設計・文書の品質。
    測定方法: ゲート合格率、レビュー指摘数。
    関連境界条件: L1（安全基準）, L4（行動空間調整の根拠）。
    observe.sh proxy: fix_ratio_percent（プレフィクスパターン fix/bugfix/hotfix のコミット比率）+
    test_pass_rate（テスト全通過率）。
    proxy 成熟度分類:
    - provisional_proxy: 暫定代理指標。正式測定方法が未実装。
    - established_proxy: 安定代理指標。運用上十分と判断。
    - formal_measurement: 正式測定方法が実装済み。
    現在の V3 proxy は provisional_proxy。卒業条件: ゲート合格率の実装 OR 運用的相関証拠（T6 判断）。 -/
opaque outputQuality : World → Nat

/-- V4: ゲート通過率。各フェーズのゲートを一発で通過する率。
    P2（認知的役割分離）がゲートの信頼性を保証する。
    測定方法: pass/fail 統計。
    関連境界条件: L6（ゲート定義の粒度）, L4（auto-merge 判断）。
    observe.sh proxy: Bash passed / (passed + blocked)。
    tool-usage.jsonl の "tool":"Bash" イベント数 / (Bash + gate_blocked イベント数)。 -/
opaque gatePassRate : World → Nat

/-- V5: 提案精度。設計提案・スコープ提案の的中率。
    測定方法: 人間の承認/却下率。
    関連境界条件: L4（行動空間調整の根拠）, L6（設計規約改善）。
    observe.sh proxy: v5-approvals.jsonl の approved / total エントリ比率。 -/
opaque proposalAccuracy : World → Nat

/-- V6: 知識構造の質。永続的知識の構造化度。
    P3（学習の統治）が知識ライフサイクル
    （観察→仮説化→検証→統合→退役）を規定する。
    退役されない知識は蓄積して V2 を劣化させる。
    測定方法: 次セッションでの文脈復元速度、退役対象検出率。
    関連境界条件: L2（記憶喪失の緩和）。
    observe.sh proxy: memory_entries（MEMORY.md エントリ数）, memory_files（記憶ファイル数）,
    last_update_days_ago（最終更新からの経過日数）, retired_count（退役済みエントリ数）。 -/
opaque knowledgeStructureQuality : World → Nat

/-- V7: タスク設計効率。P6（制約充足としてのタスク設計）の品質。
    2つのデータソース:
    (1) 外部知見: 公開ベンチマーク、モデル性能特性
    (2) 内部知見: 実行ログ、リソース消費実績、成果対コスト比
    測定方法: タスク完了率/消費リソース比、再設計頻度。
    関連境界条件: L3（リソース上限）, L6（設計規約）。
    observe.sh proxy: completed（v7-tasks.jsonl タスク完了数）, unique_subjects（ユニーク主題数）,
    teamwork_percent（teammate フィールドあり比率）。
    運用注記: teamwork_percent は single-agent 運用では suppressed（teamwork_status="suppressed_single_agent"）。
    マルチエージェント/人間協働が必要なフィールドのため、single-agent 環境では観察報告に含めない。 -/
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
    Phase 5 で変数ごとの閾値に拡張（ObservableDesign.lean の
    HealthThresholds / systemHealthyPerVar）。 -/
def systemHealthy (threshold : Nat) (w : World) : Prop :=
  skillQuality w ≥ threshold ∧
  contextEfficiency w ≥ threshold ∧
  outputQuality w ≥ threshold ∧
  gatePassRate w ≥ threshold ∧
  proposalAccuracy w ≥ threshold ∧
  knowledgeStructureQuality w ≥ threshold ∧
  taskDesignEfficiency w ≥ threshold

-- ============================================================
-- 信頼度・劣化度の可測性
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
    - T8 → L6: 精度水準はタスク設計規約（architecturalConvention）として定義

    注: L5 (platform) は意図的に除外されている。
    L5 はプロバイダ固有の環境制約（Claude Code, Codex CLI 等）であり、
    T1-T8 は技術非依存の拘束条件。L5 は T から導かれるのではなく、
    プラットフォーム選択という人間の判断（T6 の上位）から生じる。
    variableBoundary でも V1-V7 は L5 にマッピングされない。 -/
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

/-- L5 (platform) は T1-T8 のいずれの constraintBoundary にも含まれない。
    L5 はプロバイダ固有の環境制約であり、技術非依存の拘束条件 T から導かれない。 -/
theorem platform_not_in_constraint_boundary :
  ∀ c : ConstraintId, BoundaryId.platform ∉ constraintBoundary c := by
  intro c
  cases c <;> simp [constraintBoundary]

/-- L5 以外の全境界条件は、少なくとも 1 つの拘束条件の constraintBoundary に含まれる。
    constraintBoundary は L5 を除いて L1-L6 を網羅する。 -/
theorem constraint_boundary_covers_except_platform :
  (∃ c, BoundaryId.ethicsSafety ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.ontological ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.resource ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.actionSpace ∈ constraintBoundary c) ∧
  (∃ c, BoundaryId.architecturalConvention ∈ constraintBoundary c) := by
  refine ⟨⟨.t6, ?_⟩, ⟨.t1, ?_⟩, ⟨.t3, ?_⟩, ⟨.t6, ?_⟩, ⟨.t8, ?_⟩⟩ <;>
    simp [constraintBoundary]

-- ============================================================
-- Derived theorems: Measurable → Observable bridge
-- ============================================================

/-!
## Measurable → Observable ブリッジ

Measurable な指標の閾値比較は Observable であるという汎用定理。
V1–V7 の Measurable axiom を集約する aggregation lemma。
-/

/-- Measurable な指標の閾値比較は Observable である（Measurable→Observable bridge）。
    Measurable m から、m w ≥ t の判定手続きを構成する。 -/
theorem measurable_threshold_observable {m : World → Nat} (hm : Measurable m) (t : Nat) :
    Observable (fun w => m w ≥ t) := by
  obtain ⟨f, hf⟩ := hm
  exact ⟨fun w => decide (f w ≥ t), fun w => by simp [hf w]⟩

/-- 全 7 変数が Measurable（aggregation lemma）。 -/
theorem all_variables_measurable :
    Measurable skillQuality ∧ Measurable contextEfficiency ∧
    Measurable outputQuality ∧ Measurable gatePassRate ∧
    Measurable proposalAccuracy ∧ Measurable knowledgeStructureQuality ∧
    Measurable taskDesignEfficiency :=
  ⟨v1_measurable, v2_measurable, v3_measurable, v4_measurable,
   v5_measurable, v6_measurable, v7_measurable⟩

-- ============================================================
-- Derived theorems: Observable conjunction + system health
-- ============================================================

/-- Observable の conjunction closure。2 つの Observable 性質の conjunction も Observable。-/
theorem observable_and {P Q : World → Prop} (hp : Observable P) (hq : Observable Q) :
    Observable (fun w => P w ∧ Q w) := by
  obtain ⟨fp, hfp⟩ := hp
  obtain ⟨fq, hfq⟩ := hq
  refine ⟨fun w => fp w && fq w, fun w => ?_⟩
  simp [Bool.and_eq_true]
  exact ⟨fun ⟨a, b⟩ => ⟨(hfp w).mp a, (hfq w).mp b⟩,
         fun ⟨a, b⟩ => ⟨(hfp w).mpr a, (hfq w).mpr b⟩⟩

/-- 系の健全性は Observable（二値判定可能）。
    各 Vi が Measurable であることから、閾値比較は決定可能。
    measurable_threshold_observable + observable_and で証明。
    （元は axiom だったが、Run 27 で theorem に降格） -/
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

-- ============================================================
-- Derived theorems: Quality measurement priority (G1b-1 #91)
-- ============================================================

/-!
## 品質測定の優先順位

G1b-1 (#91) の分析により、マニフェストの公理系から以下の品質優先順位が導出可能と判明。
これらは T6（人間の判断）に依存せず、既存の公理・設計原則から論理的に帰結する。

### 導出不可能な領域
V1-V7 間の相互優先順位は導出不可能。TradeoffExists は対称関係であり、
「V1 > V3」のような順序を含意しない。これは意図的な設計判断であり、
V 間の優先順位は T6 判断に帰着する（G1b-2 #92）。
-/

/-- 品質測定カテゴリ: 構造的変化の測定 vs プロセス成功率の測定。
    R1 (GQM 再定義) で特定された proxy ミスマッチの形式化。 -/
inductive QualityMeasureCategory where
  | structuralOutcome   -- 構造的成果: theorem delta, test delta, axiom count
  | processSuccess      -- プロセス成功率: evolve success rate, skill invocation rate
  deriving BEq, Repr

/-- 品質測定カテゴリの優先度。構造的成果はプロセス成功率より品質の直接的指標。
    根拠:
    - 最上位使命「永続する構造が自身を改善し続ける」→ 構造の変化が改善の定義
    - D5（仕様層順序）の類推: 成果（what was produced）> 過程（how it was produced）
    - Anthropic eval guide: "grade what the agent produced, not the path it took" -/
def qualityMeasurePriority : QualityMeasureCategory → Nat
  | .structuralOutcome => 1  -- higher priority
  | .processSuccess    => 0  -- lower priority

/-- 構造的成果の測定は、プロセス成功率の測定より品質指標として優先される。
    「スキルが動くこと」より「スキルが構造的に改善を生むこと」が品質。 -/
theorem structural_outcome_gt_process_success :
    qualityMeasurePriority .structuralOutcome >
    qualityMeasurePriority .processSuccess := by
  native_decide

/-- 検証信号の分類: 独立検証 vs 自己評価。
    P2 + E1 + ICLR 2024 (Huang et al.) の形式化。 -/
inductive VerificationSignalType where
  | independentlyVerified  -- P2: 独立エージェントまたは構造的テストによる検証
  | selfAssessed           -- 同一インスタンスによる自己評価
  deriving BEq, Repr

/-- 検証信号の信頼度。独立検証は自己評価より信頼性が高い。
    根拠:
    - P2: 認知的関心事の分離（Worker と Verifier の分離）
    - E1: 経験は理論に先行する — 自己生成した理論での自己評価は循環
    - ICLR 2024 Huang et al.: intrinsic self-correction は精度を劣化させる -/
def verificationReliability : VerificationSignalType → Nat
  | .independentlyVerified => 1  -- higher reliability
  | .selfAssessed          => 0  -- lower reliability

/-- 独立検証された品質信号は、自己評価による品質信号より信頼性が高い。 -/
theorem independent_verification_gt_self_assessment :
    verificationReliability .independentlyVerified >
    verificationReliability .selfAssessed := by
  native_decide

/-- 品質保証の層: 欠陥不在（defect absence）vs 価値創出（value creation）。
    D6 の DesignStage 順序の品質次元への適用。 -/
inductive QualityAssuranceLayer where
  | defectAbsence    -- 壊れていないことの確認（test pass, Lean build, sorry=0）
  | valueCreation    -- 良いことの確認（改善の実質性、有用性）
  deriving BEq, Repr

/-- 品質保証の測定優先度。欠陥不在の確認が価値創出の確認に先行する。
    根拠:
    - D6: Boundary（制約充足）> Variable（品質改善）
    - D4: Safety > Governance — 安全（壊れていない）が統治（良くする）に先行
    - 論理的帰結: 壊れているシステムの「改善の実質性」は測定しても無意味 -/
def qualityAssurancePriority : QualityAssuranceLayer → Nat
  | .defectAbsence  => 1  -- higher measurement priority
  | .valueCreation  => 0  -- lower measurement priority (but not less important)

/-- 欠陥不在の測定は、価値創出の測定より優先される（測定順序として）。
    注: これは「欠陥不在の方が重要」ではなく「先に測るべき」を意味する。
    価値創出の測定は欠陥不在が確認された後に有意義になる。 -/
theorem defect_absence_measurement_gt_value_creation :
    qualityAssurancePriority .defectAbsence >
    qualityAssurancePriority .valueCreation := by
  native_decide

end Manifest
