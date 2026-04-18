-- Provenance 層: Verdict (B4 Hoare 4-arg post の output 型)
-- Day 8 hole-driven (Q3 案 A): inductive 3 variant minimal
-- 新 namespace AgentSpec.Provenance に先行配置 (Day 9+ で ResearchEntity/Activity/Agent + Mapping を追加してこの namespace を完成)
import Init.Core

/-!
# AgentSpec.Provenance.Verdict: 検証結果型 (Provenance 層先行配置)

Phase 0 Week 4-5 Provenance 層の最初の構成要素 (Day 8 で先行配置)。
**B4 Hoare 4-arg post の output 型** として EvolutionStep の `transition` 統合に使用。

## 設計 (Section 2.14 Q3 案 A 確定方針)

`Verdict` は研究プロセスの検証結果を 3 variant inductive で表現:
- `proven`: 主張が証明された
- `refuted`: 主張が反証された
- `inconclusive`: 結論不能 (証拠不足、未検証等)

**Q3 案 A** (Day 8 Minimal): 3 variant のみ。Day 9+ で payload 拡充候補
(`refuted (evidence : Evidence)` 等、Failure と同パターン)。

## PROV mapping (Day 9+ で実装、Day 6-7 と同パターン: docstring 注記レベル)

02-data-provenance §4.1 の `ResearchActivity` の output として位置付け:

    inductive ResearchActivity : Type where
      | Verify (input : Hypothesis) (output : Verdict)
      | ...

Day 9+ で `AgentSpec.Provenance.ResearchActivity` 内で Verdict を payload として使用。

## TyDD 原則 (Day 1-7 確立パターン適用)

- **Pattern #5** (def Prop signature): inductive 先行
- **Pattern #6** (sorry 0): inductive + deriving のみで完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 で hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `proven` / `refuted` / `inconclusive` は予約語ではない

## Day 8 意思決定ログ

### D1. inductive 3 variant minimal 採用 (Q3 案 A)
- **代案 B**: 4 variant (+保留 variant、LearningStage との対応)
- **代案 C**: payload 付き variant (`refuted (evidence : String)` 等、Failure と同パターン)
- **採用**: 案 A 3 variant minimal (proven / refuted / inconclusive)
- **理由**: Day 8 hole-driven、Day 9+ で payload 拡充可能 (Failure と同パターンで refactor)。
  保留状態は LearningStage で表現可能なので Verdict に重複させない。

### D2. 新 namespace `AgentSpec.Provenance` に配置 (Section 2.11 Day 9+ 計画の先行)
- **代案 A**: `AgentSpec.Process.Verdict` に配置 (Process 層に統合)
- **採用**: `AgentSpec.Provenance.Verdict` (新 namespace 先行配置)
- **理由**: 02-data-provenance §4.1 PROV-O の vocabulary は Provenance namespace で
  まとめる方が clean (Day 9+ で ResearchEntity/Activity/Agent + Mapping を追加して完成)。
  Day 8 で先行配置することで Section 2.11 Day 9+ deliverables の準備が整う。
-/

namespace AgentSpec.Provenance

/-- 検証結果を表現する 3 variant inductive (Q3 案 A 確定)。

    Day 8 hole-driven minimal: payload なし。Day 9+ で Failure と同パターンで
    payload 付き variant への refactor 検討 (例: `refuted (evidence : Evidence)`)。

    PROV mapping: `ResearchActivity` の output (Day 9+ 実装)。 -/
inductive Verdict where
  /-- 主張が証明された (proven)。 -/
  | proven
  /-- 主張が反証された (refuted)。 -/
  | refuted
  /-- 結論不能 (inconclusive、証拠不足 / 未検証 / 等)。 -/
  | inconclusive
  deriving DecidableEq, Inhabited, Repr

namespace Verdict

/-- 自明な verdict (test fixture / placeholder)、inconclusive を選択。 -/
def trivial : Verdict := .inconclusive

/-- proven かどうかの判定 (Bool 関数、Day 9+ で proof-relevant 化検討)。 -/
def isProven : Verdict → Bool
  | .proven => true
  | _ => false

/-- refuted かどうかの判定。 -/
def isRefuted : Verdict → Bool
  | .refuted => true
  | _ => false

/-- inconclusive かどうかの判定。 -/
def isInconclusive : Verdict → Bool
  | .inconclusive => true
  | _ => false

end Verdict

end AgentSpec.Provenance
