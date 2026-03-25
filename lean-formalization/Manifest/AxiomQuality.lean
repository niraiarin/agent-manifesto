import Manifest.Meta
import Manifest.Procedure
import Manifest.Terminology

/-!
# 公理体系の品質指標（Axiom Quality Metrics）

公理体系の品質を定量的に計測するための指標を定義する。

## Γ の構成

### T₀（外的権威に根拠）
- T₀-4: Aspinall & Kaliszyk (FASE 2016) が fan-in/fan-out を形式証明に適用
- T₀-5: De Bruijn factor は Wiedijk (2000) が定義した確立された指標
- T₀-3: 公理衛生 5 検査は手順書 §2.6 で定義

### Γ \ T₀（仮説）
本ファイルは axiom 0 で構成する。全ての指標は型定義（定義的拡大, §5.5）と
定理（§4.2）として表現される。閾値の妥当性は H7（暫定値、運用で較正）に基づく。

## 先行研究

- Aspinall & Kaliszyk, "Towards Formal Proof Metrics" (FASE 2016, Springer LNCS 9633)
  SE メトリクス（fan-in, fan-out, coupling, cohesion）を Isabelle/Mizar/HOL Light に適用
- Wiedijk, "The De Bruijn Factor" (2000)
  形式証明の膨張度: formal_size / informal_size。Lean/Coq で 2-5x が典型

## 用語リファレンスとの対応

- fan-in/fan-out → 導出可能性（§2.4）の依存構造の計量化
- coverage → 最小性（手順書 §2.6 検査 4）の計量化
- independence → 独立性（§4.3）の計量化
- compression ratio → 体系の表現力（§5.5 拡大による定理集合の増大）
-/

namespace Manifest.AxiomQuality

open Manifest.Terminology
open Manifest.Procedure

-- ============================================================
-- 品質指標の定義
-- ============================================================

/-!
## 指標 1: Compression Ratio（圧縮比）

**何を測るか:** theorems / axioms。少ない公理からどれだけ多くの定理を導出できるか。
**根拠:** H4 — axiom が少なく theorem が多いほど、体系の「表現力」が高い。
  Aspinall & Kaliszyk (T₀-4) の fan-in/fan-out フレームワークの集約版。
**健全値の根拠:** H7（暫定値）。≥ 200 (= 2.0x) は axiom より theorem が多いことの最低条件。
-/

/-- 圧縮比を計算する。100 倍スケール（Nat で精度確保）。
    例: 239 theorems / 60 axioms = 398 (= 3.98x) -/
def compressionRatio (p : AxiomSystemProfile) : Nat :=
  p.theoremCount * 100 / p.totalAxioms

/-- 現在の公理系の圧縮比は 398 (= 3.98x)。 -/
theorem current_compression :
  compressionRatio currentProfile = 398 := by rfl

/-- 圧縮比 ≥ 200 (= 2.0x) は暫定的な健全条件 (H7)。 -/
theorem current_compression_healthy :
  compressionRatio currentProfile ≥ 200 := by
  simp [compressionRatio, currentProfile, AxiomSystemProfile.totalAxioms]

-- ============================================================
-- 指標 2: Coverage（網羅率）
-- ============================================================

/-!
## 指標 2: Coverage

**何を測るか:** 少なくとも 1 つの定理で使用されている axiom の割合。
**根拠:** T₀-3 検査 4 (minimality) の計量化。H1 — fan-in > 0 は minimality の必要条件。
**健全値:** 100% = 全 axiom が使用されている。
Note: grep ベースの近似値。Lean カーネルの #print axioms とは異なる場合がある。
-/

/-- 網羅率を計算する。100 倍スケール。 -/
def coveragePercent (totalAxioms usedAxioms : Nat) : Nat :=
  usedAxioms * 100 / totalAxioms

/-- 完全網羅の定義: 全 axiom が使用されていれば coverage = 100。 -/
theorem full_coverage_example :
  coveragePercent 60 60 = 100 := by rfl

-- ============================================================
-- 指標 3: Fan-in（レバレッジ）
-- ============================================================

/-!
## 指標 3: Fan-in (Leverage)

**何を測るか:** 各 axiom が何個の theorem で使われているか。
**根拠:** T₀-4 Aspinall & Kaliszyk。H1 (fan-in > 0 = minimality), H2 (均一分布が望ましい)。
**接続:** `HygieneCheck.minimality` (Procedure.lean) — fan-in = 0 の axiom は最小性に違反。
-/

/-- レバレッジの評価。 -/
inductive LeverageGrade where
  /-- fan-in = 0: 未使用。minimality 違反 (H1) -/
  | unused
  /-- fan-in = 1: 低レバレッジ。axiom の存在意義を再検討 -/
  | low
  /-- fan-in 2-5: 適切 -/
  | moderate
  /-- fan-in ≥ 6: 高レバレッジ。この axiom は体系の基盤 -/
  | high
  deriving BEq, Repr, DecidableEq

/-- fan-in からレバレッジを評価する。 -/
def gradeFanIn : Nat → LeverageGrade
  | 0     => .unused
  | 1     => .low
  | 2 | 3 | 4 | 5 => .moderate
  | _     => .high

/-- fan-in = 0 は unused（H1 の形式化）。 -/
theorem zero_fanin_is_unused :
  gradeFanIn 0 = .unused := by rfl

-- ============================================================
-- 指標 4: Fan-out（脆弱性）
-- ============================================================

/-!
## 指標 4: Fan-out (Fragility)

**何を測るか:** 各 theorem が何個の axiom に依存するか。
**根拠:** T₀-4 Aspinall & Kaliszyk。H3 — fan-out が小さい theorem ほど堅牢。
**接続:** `DerivationBasis.robustness` (Meta.lean) — constraintOnly/structural は高堅牢性。
-/

/-- 脆弱性の評価。 -/
inductive FragilityGrade where
  /-- fan-out = 0: axiom-free。最も堅牢 -/
  | axiomFree
  /-- fan-out 1-3: 低脆弱性 -/
  | low
  /-- fan-out 4-7: 中程度 -/
  | moderate
  /-- fan-out ≥ 8: 高脆弱性。多くの仮定に依存 -/
  | fragile
  deriving BEq, Repr, DecidableEq

/-- fan-out から脆弱性を評価する。 -/
def gradeFragility : Nat → FragilityGrade
  | 0                 => .axiomFree
  | 1 | 2 | 3         => .low
  | 4 | 5 | 6 | 7     => .moderate
  | _                  => .fragile

/-- fan-out = 0 は axiom-free（最も堅牢）。
    Meta.lean の DerivationBasis.structural に対応。 -/
theorem zero_fanout_is_axiomfree :
  gradeFragility 0 = .axiomFree := by rfl

/-- axiom-free は fragile より堅牢。 -/
theorem axiomfree_not_fragile :
  gradeFragility 0 ≠ .fragile := by simp [gradeFragility]

-- ============================================================
-- 指標 5: Independence Ratio（独立性比率）
-- ============================================================

/-!
## 指標 5: Independence Ratio

**何を測るか:** 他の axiom から導出不能な axiom の割合。
**根拠:** T₀-3 検査 3 (independence)。Terminology.lean `IndependenceStatus`。
**注:** E1b (`no_self_verification`) は E1a から導出可能だが意図的に宣言されている。
  100% 独立性が理想だが、意図的冗長の例外がありうる。
-/

/-- 独立性比率を計算する。100 倍スケール。 -/
def independencePercent (totalAxioms independentCount : Nat) : Nat :=
  independentCount * 100 / totalAxioms

-- ============================================================
-- 指標 6: De Bruijn Factor
-- ============================================================

/-!
## 指標 6: De Bruijn Factor

**何を測るか:** Lean コード行数 / 非形式文書行数。形式化の膨張度。
**根拠:** T₀-5 Wiedijk (2000)。H5 — Lean/Coq で 2-5x が典型。
**接続:** ExtensionKind.strength — 定義的拡大は De Bruijn factor が低い傾向。
-/

/-- De Bruijn factor プロファイル。 -/
structure DeBruijnProfile where
  formalLines   : Nat
  informalLines : Nat
  deriving Repr

/-- De Bruijn factor を計算する。100 倍スケール。 -/
def deBruijnFactor (p : DeBruijnProfile) : Nat :=
  p.formalLines * 100 / p.informalLines

/-- De Bruijn factor の評価。H5, H7 に基づく暫定閾値。 -/
inductive DeBruijnGrade where
  /-- < 150 (1.5x): 過度に簡潔。sorry や trivial proof の疑い -/
  | suspiciouslyLow
  /-- 150-500 (1.5-5.0x): 典型的な範囲 (H5) -/
  | typical
  /-- > 500 (5.0x): 冗長な可能性 -/
  | verbose
  deriving BEq, Repr, DecidableEq

/-- De Bruijn factor からグレードを評価する。 -/
def gradeDeBruijn : Nat → DeBruijnGrade
  | n => if n < 150 then .suspiciouslyLow
         else if n ≤ 500 then .typical
         else .verbose

-- ============================================================
-- 指標 7: 公理衛生の自動化可能度
-- ============================================================

/-!
## 指標 7: Hygiene Automatability

**何を測るか:** 5 検査のうちどれだけ自動化できるか。
**根拠:** T₀-3 + H6。`#print axioms` (T₀-1) と `lake build` (T₀-2) で判定可能な検査。
-/

/-- 自動化の度合い。 -/
inductive AutomationLevel where
  /-- 完全自動化: スクリプトで機械的に判定可能 -/
  | fullyAuto
  /-- 部分自動化: ヒューリスティックまたは近似的な判定 -/
  | semiAuto
  /-- 手動: 人間の意味的判断が不可避 -/
  | manualOnly
  deriving BEq, Repr, DecidableEq

/-- 各衛生検査の自動化可能度 (H6)。 -/
def hygieneAutomation : FormalDerivationSkill.HygieneCheck → AutomationLevel
  | .nonVacuity            => .manualOnly  -- 意味的判断が必要
  | .nonLogicalValidity    => .semiAuto    -- #print axioms で近似可能
  | .independence          => .semiAuto    -- import DAG + 近似
  | .minimality            => .fullyAuto   -- #print axioms で完全判定
  | .baseTheoryPreservation => .fullyAuto  -- lake build 成功で判定

/-- H6: minimality と base theory preservation は完全自動化可能。 -/
theorem two_checks_fully_automatable :
  hygieneAutomation .minimality = .fullyAuto ∧
  hygieneAutomation .baseTheoryPreservation = .fullyAuto := by
  constructor <;> rfl

/-- 非空虚性のみ手動（意味的判断が不可避）。 -/
theorem nonvacuity_requires_manual :
  hygieneAutomation .nonVacuity = .manualOnly := by rfl

-- ============================================================
-- 定理の有用性指標
-- ============================================================

/-!
## 定理の有用性（Theorem Usefulness）

**何を測るか:** 定理が他の定理の証明でどれだけ再利用されるか。
**根拠:** T₀-4 の fan-in を theorem レベルに適用。
  「有用な定理は他の証明で再利用される」という命題。

### axiom-free ratio

axiom に依存しない theorem の割合。
これらの theorem は `propext` のみに依存するか、axiom 依存が皆無。
Meta.lean の `DerivationBasis.structural` に対応し、最も堅牢。
-/

/-- 定理の有用性グレード。他の定理から参照される回数に基づく。 -/
inductive TheoremUsefulnessGrade where
  /-- 他の定理から参照されない。独立した最終結果 -/
  | terminal
  /-- 1-2 回参照。限定的な再利用 -/
  | limited
  /-- 3+ 回参照。基盤的な補題 -/
  | foundational
  deriving BEq, Repr, DecidableEq

/-- 参照回数から有用性を評価する。 -/
def gradeUsefulness : Nat → TheoremUsefulnessGrade
  | 0     => .terminal
  | 1 | 2 => .limited
  | _     => .foundational

/-- terminal な定理は必ずしも低品質ではない。
    φ（目標命題）自体は terminal であるのが正常。 -/
theorem terminal_can_be_goal :
  gradeUsefulness 0 = .terminal := by rfl

/-- axiom-free ratio を計算する。100 倍スケール。 -/
def axiomFreePercent (totalTheorems axiomFreeCount : Nat) : Nat :=
  axiomFreeCount * 100 / totalTheorems

-- ============================================================
-- 品質プロファイル（systemHealthy パターン）
-- ============================================================

/-!
## 品質プロファイル

Observable.lean の `systemHealthy` パターンを踏襲する。
すべての指標を集約し、全体の健全性を判定する。

**閾値の根拠:** H7 — すべて暫定値。運用データで較正が必要。
-/

/-- 公理体系の品質プロファイル。
    各フィールドは 100 倍スケール（Nat で精度確保）。 -/
structure QualityProfile where
  compressionRatio    : Nat   -- theorems * 100 / axioms
  coveragePercent     : Nat   -- used_axioms * 100 / total_axioms
  axiomFreePercent    : Nat   -- axiom_free_theorems * 100 / total_theorems
  sorryCount          : Nat
  deriving Repr

/-- 品質が健全であるかの判定。
    閾値は H7（暫定値）に基づく。 -/
def qualityHealthy (q : QualityProfile) : Prop :=
  q.compressionRatio ≥ 200 ∧    -- H4: axiom より theorem が多い
  q.coveragePercent ≥ 70 ∧       -- grep 近似は型クラス解決・tactic 内使用を検出不可。70% は保守的下限
  q.sorryCount = 0               -- T₀-2: sorry なし = 型検査合格

/-- 品質不健全のシグナル。 -/
inductive QualitySignal where
  /-- axiom 膨張: compression ratio が低下 -/
  | axiomInflation
  /-- 未使用 axiom: coverage < 70% (grep 近似の保守的下限) -/
  | unusedAxioms
  /-- sorry の出現: 導出の不完全性 -/
  | sorryPresence
  /-- axiom-free ratio の低下: 体系の axiom 依存が増加 -/
  | increasedAxiomDependence
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 現在のプロファイルとの接続
-- ============================================================

/-- 現在の公理系の静的品質プロファイル（axiom count ベース）。
    fan-in/fan-out/coverage は動的計測が必要なため含まない。 -/
def currentQuality : QualityProfile :=
  { compressionRatio := compressionRatio currentProfile  -- 398
    coveragePercent  := 100  -- grep 近似: 60/60 axioms referenced (Run 27: v4/v7_goodhart now used by goodhart_no_perfect_proxy)
    axiomFreePercent := 0    -- 動的計測で確定すべき値（暫定 0）
    sorryCount       := currentProfile.sorryCount }       -- 0

/-- 現在の公理系は健全条件を満たす（静的部分: compression + coverage + sorry）。 -/
theorem current_quality_healthy_static :
  currentQuality.compressionRatio ≥ 200 ∧
  currentQuality.coveragePercent ≥ 70 ∧
  currentQuality.sorryCount = 0 := by
  simp [currentQuality, compressionRatio, currentProfile, AxiomSystemProfile.totalAxioms]

-- ============================================================
-- SelfGoverning 自己適用
-- ============================================================

/-- 品質指標の種類。本形式化自体の更新追跡用。 -/
inductive QualityMetricKind where
  | compression | coverage | fanIn | fanOut
  | independence | deBruijn | hygieneAutomation
  | theoremUsefulness | axiomFreeRatio
  deriving BEq, Repr, DecidableEq

instance : SelfGoverning QualityMetricKind where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

theorem all_metrics_enumerated :
  ∀ (m : QualityMetricKind),
    m = .compression ∨ m = .coverage ∨ m = .fanIn ∨ m = .fanOut ∨
    m = .independence ∨ m = .deBruijn ∨ m = .hygieneAutomation ∨
    m = .theoremUsefulness ∨ m = .axiomFreeRatio := by
  intro m; cases m <;> simp

end Manifest.AxiomQuality
