-- Provenance 層: ResearchEntity (PROV-O 三項の主要要素、Day 9 で先行配置)
-- Q3 案 A: 4 constructor、既存 Process type を embed
-- Q4 案 A: Mapping は本ファイル内で namespace AgentSpec.Process 配下に定義 (循環依存回避)
import Init.Core
import AgentSpec.Process.Hypothesis
import AgentSpec.Process.Failure
import AgentSpec.Process.Evolution
import AgentSpec.Process.HandoffChain

/-!
# AgentSpec.Provenance.ResearchEntity: PROV-O 三項の Entity 統合

Phase 0 Week 4-5 Provenance 層の Day 9 メイン成果。02-data-provenance §4.1 PROV-O
の `ResearchEntity` を Lean 化、既存 Process 層 4 type (Hypothesis / Failure /
Evolution / Handoff) を embed する 4 constructor inductive で実装。

## 設計 (Section 2.16 Q3 案 A 確定)

    inductive ResearchEntity where
      | Hypothesis (h : AgentSpec.Process.Hypothesis)
      | Failure (f : AgentSpec.Process.Failure)
      | Evolution (e : AgentSpec.Process.Evolution)
      | Handoff (h : AgentSpec.Process.Handoff)

各 constructor は既存 Process type を payload として持ち、TyDD-S1 types-first を遵守。
案 B (opaque variant + lookup) や案 C (02-data-provenance §4.1 通り 7 variant) は
将来拡張候補 (Day 10+ で検討、Section 2.16)。

## Mapping 関数 (Q4 案 A、本ファイル内に配置で循環依存回避)

`Hypothesis.toEntity` / `Failure.toEntity` / `Evolution.toEntity` / `Handoff.toEntity`
の dot notation method は本ファイル末尾の `namespace AgentSpec.Process` 内で定義。
これにより Process 層 → Provenance 層への import 不要 (循環依存回避、Section 2.16 確定方針)。

利用者は Process 層側で `hyp.toEntity : ResearchEntity` のように dot notation で呼出可能
(Lean 4 namespace extension 機能)。

## 層依存性 (Day 9 で確定)

- ResearchEntity (Provenance) imports Process 4 type ✓
- Process 4 type は ResearchEntity を import しない (循環依存回避)
- Day 8 EvolutionStep の Spine → Process / Provenance import と同様、layer は
  「core abstraction (Spine)」「具体型 (Process)」「entity 統合 (Provenance)」の
  役割再定義 (Q4 案 A D4 受容方針の継続)

## TyDD 原則 (Day 1-8 確立パターン適用)

- **Pattern #5** (def Prop signature): inductive 先行
- **Pattern #6** (sorry 0): inductive + deriving + 4 toEntity def で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `Hypothesis` / `Failure` / `Evolution` / `Handoff`
  は予約語ではない (Process 層 type 名と name collision あるが、`.Hypothesis` dot notation
  は expected type で解決されるので問題なし)

## Day 9 意思決定ログ

### D1. 4 constructor (既存 Process type embed) 採用 (Q3 案 A)
- **代案 B**: opaque variant + 別 lookup 関数
- **代案 C**: 02-data-provenance §4.1 通り 7 variant (Survey / Gap / Hypothesis /
  Decomposition / Spec / Implementation / Failure)
- **採用**: 案 A 4 constructor (Hypothesis / Failure / Evolution / Handoff embed)
- **理由**: TyDD-S1 types-first 遵守、既存 Process type 再利用、Mapping 関数 natural。
  案 C 7 variant は Survey / Gap / Decomposition / Spec / Implementation の type 未定義 (Day 10+ 拡充検討)。

### D2. Mapping 関数を本ファイル内に配置 (Q4 案 A、循環依存回避)
- **代案**: Mapping 関数を Process 層各 .lean 内に追加 (Hypothesis.lean に
  `def Hypothesis.toEntity ...` 等)
- **採用**: 本ファイル内で `namespace AgentSpec.Process` を開いて dot notation method 定義
- **理由**: Process 層 → Provenance 層 import が循環依存になる (Process が Provenance.ResearchEntity
  を import + ResearchEntity が Process types を import)。本ファイル内配置で Process 層は
  Provenance に非依存のまま、Lean 4 namespace extension で dot notation も維持。

### D3. DecidableEq 派生せず (Evolution の recursive inductive 制約)
- **代案**: 手動で DecidableEq 実装
- **採用**: Inhabited / Repr のみ deriving、DecidableEq は省略
- **理由**: Evolution は recursive inductive で `deriving DecidableEq` 不可 (Day 7 D3 同問題)。
  ResearchEntity も含む field のため deriving 失敗。手動実装は Day 10+ で必要時検討。
-/

namespace AgentSpec.Provenance

/-- 02-data-provenance §4.1 PROV-O `ResearchEntity` (Day 9 Q3 案 A: 4 constructor)。

    既存 Process 層 4 type (Hypothesis / Failure / Evolution / Handoff) を payload として embed。
    Day 10+ で 02-data-provenance §4.1 通り 7 variant (Survey / Gap / Decomposition / Spec /
    Implementation 追加) への拡張検討。 -/
inductive ResearchEntity where
  /-- 主張 (Process 層 Hypothesis を embed)。 -/
  | Hypothesis (h : AgentSpec.Process.Hypothesis)
  /-- 失敗 (Process 層 Failure を embed)。 -/
  | Failure (f : AgentSpec.Process.Failure)
  /-- 進化 (Process 層 Evolution を embed、recursive inductive)。 -/
  | Evolution (e : AgentSpec.Process.Evolution)
  /-- 引き継ぎ (Process 層 Handoff を embed、HandoffChain ではなく単一 Handoff)。 -/
  | Handoff (h : AgentSpec.Process.Handoff)
  deriving Inhabited, Repr

namespace ResearchEntity

/-- 自明な ResearchEntity (test fixture / placeholder)、trivial Hypothesis を embed。 -/
def trivial : ResearchEntity := .Hypothesis AgentSpec.Process.Hypothesis.trivial

/-- ResearchEntity が Hypothesis variant かを判定 (Bool)。 -/
def isHypothesis : ResearchEntity → Bool
  | .Hypothesis _ => true
  | _ => false

/-- ResearchEntity が Failure variant かを判定。 -/
def isFailure : ResearchEntity → Bool
  | .Failure _ => true
  | _ => false

/-- ResearchEntity が Evolution variant かを判定。 -/
def isEvolution : ResearchEntity → Bool
  | .Evolution _ => true
  | _ => false

/-- ResearchEntity が Handoff variant かを判定。 -/
def isHandoff : ResearchEntity → Bool
  | .Handoff _ => true
  | _ => false

end ResearchEntity

end AgentSpec.Provenance

/-! ### Mapping 関数 (Q4 案 A、循環依存回避のため本ファイル内に配置)

Process 層各 type に `.toEntity` dot notation method を追加。Lean 4 の namespace
extension 機能で、Process 層側のコードからは `hyp.toEntity` で利用可能。 -/

namespace AgentSpec.Process

/-- `Hypothesis.toEntity` (Q4 案 A): Hypothesis を ResearchEntity に変換。 -/
def Hypothesis.toEntity (h : Hypothesis) : AgentSpec.Provenance.ResearchEntity :=
  .Hypothesis h

/-- `Failure.toEntity` (Q4 案 A): Failure を ResearchEntity に変換。 -/
def Failure.toEntity (f : Failure) : AgentSpec.Provenance.ResearchEntity :=
  .Failure f

/-- `Evolution.toEntity` (Q4 案 A): Evolution を ResearchEntity に変換。 -/
def Evolution.toEntity (e : Evolution) : AgentSpec.Provenance.ResearchEntity :=
  .Evolution e

/-- `Handoff.toEntity` (Q4 案 A): Handoff を ResearchEntity に変換 (HandoffChain ではなく単一)。 -/
def Handoff.toEntity (h : Handoff) : AgentSpec.Provenance.ResearchEntity :=
  .Handoff h

end AgentSpec.Process
