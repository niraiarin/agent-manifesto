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

### D1. inductive 3 variant minimal 採用 (Q3 案 A) → Day 42 で 6 variant に拡張
- **代案 B**: 4 variant (+保留 variant、LearningStage との対応)
- **代案 C**: payload 付き variant (`refuted (evidence : String)` 等、Failure と同パターン)
- **Day 8 採用**: 案 A 3 variant minimal (proven / refuted / inconclusive)
- **Day 8 理由**: hole-driven、Day 9+ で payload 拡充可能 (Failure と同パターンで refactor)。
  保留状態は LearningStage で表現可能なので Verdict に重複させない。
- **Day 42 (2026-04-21) 拡張**: 案 C 採用、既存 3 variant の後方互換を維持しつつ payload 付き
  3 variant (`provenWith` / `refutedWith` / `inconclusiveDueTo`) を追加 (合計 6 variant)。
  既存の 3 nullary variant は廃止せず (全コード引き続き動作、conservative extension)、
  新規 evidence/reason 付き記述は `*With` / `*DueTo` を使用。Day 26-27 ResearchActivity
  `investigateOf`/`retireOf`/`decomposeOf`/`refineOf` と同パターン (nullary + payload 共存)。

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
  /-- 主張が証明された (proven、nullary)。 -/
  | proven
  /-- 主張が反証された (refuted、nullary)。 -/
  | refuted
  /-- 結論不能 (inconclusive、nullary、証拠不足 / 未検証 / 等)。 -/
  | inconclusive
  /-- Day 42: 証明 + evidence 付記 (審査経路、引用等)。 -/
  | provenWith (evidence : String)
  /-- Day 42: 反証 + evidence 付記 (反例、失敗実験等)。Failure との接続 primary case。 -/
  | refutedWith (evidence : String)
  /-- Day 42: 結論不能 + reason 付記 (証拠不足の理由、外部依存等)。 -/
  | inconclusiveDueTo (reason : String)
  deriving DecidableEq, Inhabited, Repr

namespace Verdict

/-- 自明な verdict (test fixture / placeholder)、inconclusive を選択。 -/
def trivial : Verdict := .inconclusive

/-- proven かどうかの判定 (Day 42: provenWith も proven family として true)。 -/
def isProven : Verdict → Bool
  | .proven => true
  | .provenWith _ => true
  | _ => false

/-- refuted かどうかの判定 (Day 42: refutedWith も refuted family として true)。 -/
def isRefuted : Verdict → Bool
  | .refuted => true
  | .refutedWith _ => true
  | _ => false

/-- inconclusive かどうかの判定 (Day 42: inconclusiveDueTo も inconclusive family)。 -/
def isInconclusive : Verdict → Bool
  | .inconclusive => true
  | .inconclusiveDueTo _ => true
  | _ => false

/-- Day 42: verdict から evidence/reason を String Option として抽出
    (nullary variant には none、payload variant には some)。 -/
def payload : Verdict → Option String
  | .proven => none
  | .refuted => none
  | .inconclusive => none
  | .provenWith e => some e
  | .refutedWith e => some e
  | .inconclusiveDueTo r => some r

end Verdict

end AgentSpec.Provenance
