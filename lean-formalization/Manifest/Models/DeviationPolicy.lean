import Manifest.Ontology
import Manifest.TaskClassification
import Manifest.EpistemicLayer

/-!
# DeviationPolicy — 逸脱の分類と対処方針

brownfield ワークフローにおいて、子プロジェクトの実装が親公理系から
逸脱している場合の判定フローチャートを形式化する。

## 逸脱の定義

逸脱 (Deviation) = instance-manifest.json の config_to_axiom に
エントリがあるが、対応する axiom_to_config に整合するエントリがない、
または axiom_to_config のエントリで implements が空。

## 判定フローチャート (#426)

```
Q1: ドメイン固有の制約に基づくか？ (judgmental)
  ├─ Yes → Q3 へ
  └─ No → Q2 へ

Q2: 除去するとテストが壊れるか？ (deterministic)
  ├─ Yes → Retain (テスト依存のため保持、リファクタ計画へ)
  └─ No → Remove (安全に除去可能)

Q3: 公理化すると親公理系と矛盾するか？ (#425 検出メカニズム)
  ├─ Ordering 矛盾 (deterministic) → Reject
  ├─ Assumption/Composition 矛盾 (bounded) → Reject
  └─ 矛盾なし → Adopt (公理追加で公理系を拡張)
```

## Traceability

- D13: 逸脱対処の影響波及を管理する
- #425: 矛盾検出メカニズム (Case1-3) を前提とする
-/

namespace Manifest.Models

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. 逸脱の種別
-- ============================================================

/-- 逸脱の種別。instance-manifest.json の分析から導出。 -/
inductive DeviationKind where
  /-- 公理カバレッジなし: config_to_axiom にエントリがあるが
      axiom_to_config に対応なし。実装が公理系に裏付けられていない。 -/
  | uncoveredConfig
  /-- 実装なし: axiom_to_config にエントリがあるが implements が空。
      公理は存在するが実装されていない。 -/
  | unimplementedAxiom
  /-- 逆マッピング欠如: axiom_to_config にエントリがあるが
      config_to_axiom に対応する逆参照がない。一方向トレーサビリティ。 -/
  | missingReverseMapping
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. 矛盾パターン (#425 の分類)
-- ============================================================

/-- 親公理系との矛盾パターン。#425 Case1-3 の分類。 -/
inductive ContradictionPattern where
  /-- Case 1: 意味論的矛盾。子の定理合成が親の定理と矛盾。
      検出: Interprets typeclass + Lean 証明。TaskAutomationClass: bounded。 -/
  | composition
  /-- Case 2: Assumption 矛盾。子の仮定内容が親の定理と矛盾。
      検出: ContentInterpreter + Lean 証明。TaskAutomationClass: bounded。 -/
  | assumption
  /-- Case 3: 依存順序の逆転。子の dependsOn が親と逆方向。
      検出: OrderMapping + dependsOn 比較。TaskAutomationClass: deterministic。 -/
  | ordering
  deriving BEq, Repr, DecidableEq

/-- 矛盾パターンの検出自動化レベル。 -/
def ContradictionPattern.detectionClass : ContradictionPattern → TaskAutomationClass
  | .composition => .bounded
  | .assumption  => .bounded
  | .ordering    => .deterministic

-- ============================================================
-- 3. 矛盾チェック結果
-- ============================================================

/-- 矛盾チェックの結果。 -/
inductive ContradictionResult where
  /-- 矛盾なし。公理追加が安全。 -/
  | noContradiction
  /-- 矛盾あり。パターンと証拠を含む。 -/
  | contradiction (pattern : ContradictionPattern) (evidence : String)
  deriving BEq, Repr

-- ============================================================
-- 4. 判定フローチャート (Q1-Q3)
-- ============================================================

/-- Q1 の回答: ドメイン固有の制約に基づくか。judgmental。 -/
inductive DomainSpecificity where
  | domainSpecific    -- ドメイン固有の必要性がある
  | notDomainSpecific -- ドメイン固有ではない
  deriving BEq, Repr, DecidableEq

/-- Q2 の回答: 除去するとテストが壊れるか。deterministic。 -/
inductive TestDependency where
  | testsBreak    -- テストが壊れる
  | testsSafe     -- テストは壊れない
  deriving BEq, Repr, DecidableEq

/-- 逸脱の対処方針。判定フローチャートの出力。 -/
inductive DeviationAction where
  /-- 公理追加: 逸脱を正当と認め、公理系を拡張する。 -/
  | adopt
  /-- 除去: 逸脱を不正と判定し、リファクタリングで除去する。 -/
  | remove
  /-- 保持: テスト依存のため即座に除去できない。リファクタ計画へ。 -/
  | retain
  /-- 却下: 公理化すると親公理系と矛盾するため、公理追加を拒否。 -/
  | reject
  deriving BEq, Repr, DecidableEq

/-- 判定フローチャートの入力。 -/
structure DeviationAssessment where
  /-- Q1: ドメイン固有か (judgmental) -/
  domainSpecificity : DomainSpecificity
  /-- Q2: テスト依存か (deterministic) -/
  testDependency : TestDependency
  /-- Q3: 親公理系との矛盾チェック結果 -/
  contradictionCheck : ContradictionResult
  deriving Repr

/-- 判定フローチャートの実装。
    Q1 → Q2/Q3 の分岐を deterministic に計算する。 -/
def evaluateDeviation (a : DeviationAssessment) : DeviationAction :=
  match a.domainSpecificity with
  | .notDomainSpecific =>
    -- Q2: テスト依存チェック
    match a.testDependency with
    | .testsBreak => .retain   -- テスト依存 → 保持
    | .testsSafe  => .remove   -- 安全に除去
  | .domainSpecific =>
    -- Q3: 親公理系との矛盾チェック
    match a.contradictionCheck with
    | .contradiction _ _ => .reject  -- 矛盾あり → 却下
    | .noContradiction   => .adopt   -- 矛盾なし → 公理追加

-- ============================================================
-- 5. 定理: フローチャートの性質
-- ============================================================

/-- ドメイン固有でない逸脱は adopt/reject にならない。
    公理追加の検討は Q1=domainSpecific のみ。 -/
theorem notDomainSpecific_never_adopts_or_rejects
    (a : DeviationAssessment)
    (h : a.domainSpecificity = .notDomainSpecific) :
    evaluateDeviation a ≠ .adopt ∧ evaluateDeviation a ≠ .reject := by
  simp [evaluateDeviation, h]
  cases a.testDependency <;> simp

/-- ドメイン固有の逸脱は remove/retain にならない。
    テスト依存チェックはドメイン固有でない場合のみ。 -/
theorem domainSpecific_never_removes_or_retains
    (a : DeviationAssessment)
    (h : a.domainSpecificity = .domainSpecific) :
    evaluateDeviation a ≠ .remove ∧ evaluateDeviation a ≠ .retain := by
  simp [evaluateDeviation, h]
  cases a.contradictionCheck <;> simp

/-- 矛盾がある場合、公理追加はされない。 -/
theorem contradiction_implies_reject
    (a : DeviationAssessment)
    (h1 : a.domainSpecificity = .domainSpecific)
    (h2 : ∃ p e, a.contradictionCheck = .contradiction p e) :
    evaluateDeviation a = .reject := by
  obtain ⟨p, e, h2⟩ := h2
  simp [evaluateDeviation, h1, h2]

/-- 矛盾がなくドメイン固有であれば、公理追加される。 -/
theorem noContradiction_and_domainSpecific_implies_adopt
    (a : DeviationAssessment)
    (h1 : a.domainSpecificity = .domainSpecific)
    (h2 : a.contradictionCheck = .noContradiction) :
    evaluateDeviation a = .adopt := by
  simp [evaluateDeviation, h1, h2]

/-- フローチャートは全入力に対して 4 つのアクションのいずれかを返す（全域性）。
    Lean の型システムで自動保証されるが、明示的に述べる。 -/
theorem evaluateDeviation_total (a : DeviationAssessment) :
    evaluateDeviation a = .adopt ∨
    evaluateDeviation a = .remove ∨
    evaluateDeviation a = .retain ∨
    evaluateDeviation a = .reject := by
  unfold evaluateDeviation
  cases a.domainSpecificity with
  | notDomainSpecific =>
    cases a.testDependency with
    | testsBreak => exact Or.inr (Or.inr (Or.inl rfl))
    | testsSafe  => exact Or.inr (Or.inl rfl)
  | domainSpecific =>
    cases a.contradictionCheck with
    | noContradiction   => exact Or.inl rfl
    | contradiction _ _ => exact Or.inr (Or.inr (Or.inr rfl))

-- ============================================================
-- 6. TaskAutomationClass の分類
-- ============================================================

/-- 各判定ステップの自動化分類。 -/
def questionAutomationClass : Fin 3 → TaskAutomationClass
  | 0 => .judgmental     -- Q1: ドメイン固有か（人間判断）
  | 1 => .deterministic  -- Q2: テスト依存か（テスト実行）
  | 2 => .bounded        -- Q3: 矛盾チェック（パターン依存、最大で bounded）

/-- Q3 の自動化レベルは矛盾パターンに依存する。
    Ordering は deterministic、それ以外は bounded。 -/
theorem q3_ordering_is_deterministic :
    ContradictionPattern.detectionClass .ordering = .deterministic := rfl

/-- フローチャート自体（evaluateDeviation）は deterministic。
    入力が確定すれば出力は一意に決まる。
    ただし入力の一部（Q1, Q3）は judgmental/bounded。 -/
theorem flowchart_is_deterministic :
    taskMinEnforcement .deterministic = .structural := rfl

-- ============================================================
-- 7. 逸脱データセットの構造
-- ============================================================

/-- 逸脱レコード。instance-manifest.json から生成。 -/
structure DeviationRecord where
  /-- 逸脱が検出された設定パス -/
  configPath : String
  /-- 逸脱の種別 -/
  kind : DeviationKind
  /-- 関連する公理 ID（あれば） -/
  relatedAxiomId : Option String
  /-- 判定結果（評価済みの場合） -/
  assessment : Option DeviationAssessment
  deriving Repr

/-- 逸脱データセット。 -/
structure DeviationDataset where
  /-- インスタンス名 -/
  instanceName : String
  /-- 逸脱レコードのリスト -/
  records : List DeviationRecord
  deriving Repr

/-- データセットの統計。 -/
def DeviationDataset.stats (ds : DeviationDataset) :
    Nat × Nat × Nat :=
  let uncovered := ds.records.filter (·.kind == .uncoveredConfig) |>.length
  let unimplemented := ds.records.filter (·.kind == .unimplementedAxiom) |>.length
  let missingReverse := ds.records.filter (·.kind == .missingReverseMapping) |>.length
  (uncovered, unimplemented, missingReverse)

end Manifest.Models
