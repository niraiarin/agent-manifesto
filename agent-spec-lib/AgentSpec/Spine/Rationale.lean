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

-- Day 70 人間判断: Nat 維持 (deferred 継続)。Fin 101 は Fin.add mod wrap で score
-- 算術に不適切。Score structure (val : Nat; h : val ≤ 100) は consumer (算術/順序証明)
-- 出現時 (GA-S15 Lattice 導入) に再検討。DataCite 等の先行調査で confidence 型強制の
-- production 標準は newtype + smart constructor (Stan/Pyro UnitInterval pattern)。

### D4. `deriving DecidableEq, Inhabited, Repr` (Day 38-40 パターン踏襲)
- Day 35-42 で確立した recursive inductive / structure DecidableEq derive 可能性を踏襲。
  Rationale は field 全てが DecidableEq (String / List String / Nat) のため自動 derive 成立。

## Day 49 意思決定ログ (Rationale attribution 拡張、Day 44 D2 deferred 解消)

### D5. author / timestamp を Option field として conservative 追加
- **代案 A**: `author : ResearchAgent` 必須化 (Day 44 D2 原案)
- **Day 49 採用**: `author : Option String := none` / `timestamp : Option Nat := none`
- **理由**: (1) ResearchAgent は Provenance 層、Rationale (Spine 層) から import すると逆 layer 依存。
  (2) 既存の Rationale.trivial / ofText / mk' / 4 type 必須化コードを壊さない conservative
  extension を優先。(3) author は Day 44 Hypothesis.rationale 当初案と同じく String hole-driven、
  Day N+ で ResearchAgent 型化検討 (layer 境界設計を伴うため別 Day で別議論)。
- **timestamp を Option Nat**: Unix timestamp 0 (= epoch) を default にすると意味が曖昧、
  `none` で「記録なし」を型で明示する方が clean。
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
  /-- Day 49: attribution (誰の判断か、Day N+ で ResearchAgent 型化候補)。
      layer 境界のため Spine 層では String、Option で「記録なし」を型表現。 -/
  author : Option String := none
  /-- Day 49: 判断時刻 (Unix timestamp 相当 Nat、Option で「記録なし」を型表現)。 -/
  timestamp : Option Nat := none
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

/-- Day 49: author を設定 (既存 rationale を更新)。 -/
def withAuthor (r : Rationale) (author : String) : Rationale :=
  { r with author := some author }

/-- Day 49: timestamp を設定。 -/
def withTimestamp (r : Rationale) (ts : Nat) : Rationale :=
  { r with timestamp := some ts }

/-- Day 49: attributed? (author が記録されているか判定)。 -/
def isAttributed (r : Rationale) : Bool :=
  r.author.isSome

/-- Day 52: 全 5 field 必須の strict smart constructor (production 利用推奨)。
    Day 50 empirical I2 (attribution 欠損率 100% 実測) 対応。
    text / references / confidence / author / timestamp 全指定。 -/
def strict (text : String) (references : List String) (confidence : Nat)
    (author : String) (timestamp : Nat) : Rationale :=
  { text := text,
    references := references,
    confidence := confidence,
    author := some author,
    timestamp := some timestamp }

/-- Day 52: properly attributed 判定 (5 field 全て意味ある値、production 利用の目安)。
    text non-empty + references non-empty + confidence > 0 + author some + timestamp some。 -/
def isProperlyAttributed (r : Rationale) : Bool :=
  !r.text.isEmpty && !r.references.isEmpty && r.confidence > 0 &&
    r.author.isSome && r.timestamp.isSome

/-! ### Day 52 A-Minimal linter fixture (Day 14 RetirementLinter と同 pattern)

Rationale の production 利用で不完全な attribution を構造的に可視化するため、placeholder
fixture を `@[deprecated]` 付きで提供する。Day 50 empirical I2 起因、attribution 欠損率
100% (156/156 site) の構造的可視化。実利用時は `Rationale.strict` を推奨、
trivial/ofText は test fixture 向け。

`set_option linter.deprecated false in` で warning 抑制可能 (test 用途)。 -/

/-- Day 52 A-Minimal: unattributed rationale fixture (deprecated、production 非推奨)。
    Day 14 RetiredEntity.refutedTrivialDeprecated と同 pattern、
    実利用は `Rationale.strict` or attribution 明示版を使う。 -/
@[deprecated "Unattributed rationale - use Rationale.strict for production (Day 52 A-Minimal linter)" (since := "2026-04-21")]
def trivialDeprecated : Rationale := trivial

/-- Day 52 A-Minimal: unauthored ofText fixture (deprecated、production 非推奨)。 -/
@[deprecated "Unauthored ofText rationale - use Rationale.strict for production (Day 52 A-Minimal linter)" (since := "2026-04-21")]
def ofTextUnauthoredDeprecated (text : String) (confidence : Nat) : Rationale :=
  ofText text confidence

/-- 信頼度が 0 の rationale 判定 (trivial/placeholder 検出)。 -/
def isTrivial (r : Rationale) : Bool :=
  r.text == "" && r.references.isEmpty && r.confidence == 0

end Rationale

end AgentSpec.Spine
