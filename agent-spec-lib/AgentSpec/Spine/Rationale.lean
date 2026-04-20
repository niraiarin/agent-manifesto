-- Spine 層: Rationale (GA-S8、judgmental 構造化の最重要 unresolved Gap)
-- Day 44 hole-driven minimal: text + references + confidence Nat の 3 field
-- 各 Process/Provenance constructor への attach は Day 45+ (breaking change 回避のため別 Day に分離)
import Init.Core
import Init.Data.String.Basic
import Init.Data.List.Basic

/-!
# AgentSpec.Spine.Rationale: judgmental 構造化 (GA-S8、Spine 層)

GA-S8 は「なぜそう判断したか」を Issue コメントの自然言語で放置する問題。
CLEVER/G2/G3 全先行研究で unresolved とされた最重要 Gap の着手。

Day 44 hole-driven minimal: structure のみ、field 3 つ。Day 45+ で
Hypothesis / Failure / Evolution / RetirementReason / Decomposition (GA-S1 候補)
に Rationale を attach (Day 44 は breaking change 回避のため構造のみ先行配置)。

## 設計 (Day 44 Q1 Minimal、GA-S8 対応案 synthesis §6.2 参照)

    structure Rationale where
      text : String            -- 判断の自然言語記述 (short summary)
      references : List String -- 参照 (文献 DOI / Issue URL / paper tag / commit sha)
      confidence : Nat         -- 信頼度 0-100 (Nat のため自然に 0 以上)

**Day 44 hole-driven 選択**:
- `text` は String (日本語も ASCII も混在可)。Day 45+ で Hypothesis.claim と同型
- `references` は List String (空 list = 参照なし、non-empty = 根拠あり)。
  Day 46+ で structured (DOI/URL/paper/commit 分離) 検討
- `confidence` は Nat (0-100 は convention、型で上限強制は Day 47+、Fin 101 候補)

## TyDD 原則 (Day 1-42 確立パターン適用)

- **Pattern #5** (def Prop signature): structure + def のみ (Prop なし)
- **Pattern #6** (sorry 0): structure + deriving + smart constructor で完結
- **Pattern #7** (artifact-manifest 同 commit): hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `text` / `references` / `confidence` は予約語ではない

## Day 44 意思決定ログ (Q1 Minimal、GA-S8 scope 制御)

### D1. Spine 層配置 採用 (vs Provenance 層 or 各 type 個別配置)
- **代案 A**: `AgentSpec.Provenance.Rationale` (Provenance 層 PROV-O 統合)
- **代案 B**: 各 Process/Provenance type 内で個別定義 (Hypothesis field として直接追加等)
- **採用**: `AgentSpec.Spine.Rationale` (Spine 層 core abstraction)
- **理由**: Rationale は Process (Hypothesis)・Provenance (Failure)・Retirement (reason)
  の全てから参照される judgmental abstraction。Spine 層に core 配置することで
  循環依存 (Provenance → Process / Process → Provenance) を回避。Day 8 Verdict
  Provenance 配置時の循環依存反省 (Q4 案 A 案 B 再検討) を Day 44 では Spine 配置で解決。

### D2. 3 field minimal 採用 (vs 多 field 拡張)
- **代案**: text + references + confidence + author (誰の判断か) + timestamp + ...
- **採用**: text / references / confidence のみ 3 field (Day 44 hole-driven)
- **理由**: GA-S8 対応案「text + references + confidence など」の「など」を Day 44 scope 制御で
  deferred。author は ResearchAgent との関係 (Day 45+ attribution pattern)、timestamp は
  T1 一時性との関係 (Day 47+ 検討)。まず 3 field で各 type への attach parser を確立、
  後から拡張 (TyDD conservative extension pattern)。

### D3. `confidence : Nat` (vs Fin 101 or Float)
- **代案 A**: `Fin 101` (0-100 range 型強制)
- **代案 B**: `Float` (小数許容 0.0-1.0)
- **採用**: `Nat` (Day 44 minimal、0-100 convention は docstring レベル)
- **理由**: Fin 101 は index 型として意図が紛らわしい (Day 47+ で Score structure 化検討)。
  Float は Lean 4 での DecidableEq が trivial でない。Nat は (A) 0 以上自然、(B) Inhabited
  自動解決、(C) DecidableEq 自動 derive、(D) 必要時に Fin / Rat への refactor 容易。

### D4. `deriving DecidableEq, Inhabited, Repr` (Day 38-40 パターン踏襲)
- Day 35-42 で確立した recursive inductive / structure DecidableEq derive 可能性を踏襲。
  Rationale は field 全てが DecidableEq (String / List String / Nat) のため自動 derive 成立。
-/

namespace AgentSpec.Spine

/-- GA-S8 judgmental Rationale (Day 44 hole-driven minimal、Spine 層)。

    「なぜそう判断したか」の judgmental 構造化。各 Process/Provenance constructor
    (Hypothesis / Failure / Evolution / RetirementReason) への attach は Day 45+。

    field 3:
    - `text`: 判断の自然言語要約 (short、Day 46+ で分量制約検討)
    - `references`: 参照リスト (文献/Issue/paper/commit、Day 46+ で structured 検討)
    - `confidence`: 信頼度 Nat (0-100 convention、Day 47+ で Fin/Score 型強制検討) -/
structure Rationale where
  /-- 判断の自然言語記述 (short summary、Hypothesis.claim と同型)。 -/
  text : String
  /-- 参照リスト (文献 DOI / Issue URL / paper tag / commit sha の文字列、非 structured)。 -/
  references : List String
  /-- 信頼度 (0-100 convention、Day 44 は Nat 上限強制なし)。 -/
  confidence : Nat
  deriving DecidableEq, Inhabited, Repr

namespace Rationale

/-- 自明な rationale (test fixture)、空 text / 空 references / confidence 0。 -/
def trivial : Rationale :=
  { text := "", references := [], confidence := 0 }

/-- Smart constructor: text + confidence のみ指定 (references は空 default)。 -/
def ofText (text : String) (confidence : Nat) : Rationale :=
  { text := text, references := [], confidence := confidence }

/-- Smart constructor: text + references + confidence 全指定。 -/
def mk' (text : String) (references : List String) (confidence : Nat) : Rationale :=
  { text := text, references := references, confidence := confidence }

/-- reference を append する helper (immutable、新 Rationale 返却)。 -/
def addReference (r : Rationale) (ref : String) : Rationale :=
  { r with references := r.references ++ [ref] }

/-- 信頼度が 0 の rationale 判定 (trivial/placeholder 検出)。 -/
def isTrivial (r : Rationale) : Bool :=
  r.text == "" && r.references.isEmpty && r.confidence == 0

end Rationale

end AgentSpec.Spine
