import Manifest.Ontology
import Manifest.DesignFoundation

/-!
# 形式的導出スキルの自己検証

`docs/formal-derivation-procedure.md` が定義する構造的要件を型としてエンコードし、
`.claude/skills/formal-derivation/SKILL.md` がそれらを実装していることを
Γ ⊢ φ として導出する。

## 形式化の構造

- **論議領域**: 手順書の構成要素（Phase, Step, Check, TerminationKind）
- **φ**: skill_implements_procedure — スキルが手順書の全要件を実装する
- **T₀**: 手順書の構造的要件。型定義（定義的拡大）として T₀ をエンコードする。
  列挙型の網羅性は CIC の帰結であり、axiom ではなく theorem で証明する。
- **Γ \ T₀**: SKILL.md の各セクションが要件に対応するという主張（axiom）

## 公理衛生の自己適用

初版では T₀ を axiom で表現したが、公理衛生検査 2（非論理的妥当性）に違反していた。
列挙型の網羅性は `by intro x; cases x <;> simp` で証明可能であり、
ドメイン固有の仮定ではない。修正ループ（Phase 3）を経て theorem に変換した。

## SelfGoverning 自己適用

このモジュール自体が形式的導出スキルの Phase 4（監査）に相当する。
スキルが自身の手順に従って自身を検証する構造。
-/

namespace Manifest.FormalDerivationSkill

-- ============================================================
-- 論議領域 (Step 1.1)
-- ============================================================

/-!
## 論議領域

手順書の構成要素を Lean の型として定義する。
これらの型定義自体が T₀（基底理論）をエンコードする。
手順書が「Phase は 4 つある」と定めていることは、
`Phase` 型に 4 つの構成子があることで表現される。
-/

/-- 手順書が定義する Phase。Phase 1–4。 -/
inductive Phase where
  | leanConstruction   -- Phase 1: Lean での構築
  | derivation         -- Phase 2: Γ ⊢ φ の導出の構成
  | correctionLoop     -- Phase 3: 修正ループ
  | audit              -- Phase 4: 監査
  deriving BEq, Repr, DecidableEq

/-- Phase 1 の Step。手順書 §3 Phase 1 の 6 ステップ。 -/
inductive ConstructionStep where
  | domainDefinition         -- 論議領域の定義 (§2.1)
  | goalFormulation          -- φ の定式化 (§2.2)
  | baseTheoryConstruction   -- T₀ の構築 (§2.4)
  | consistencyCheck         -- T₀ の無矛盾性簡易検査
  | extensionConstruction    -- Γ \ T₀ の拡大 (§2.4)
  | auxiliaryDefinitions     -- 補助定義の追加
  deriving BEq, Repr, DecidableEq

/-- Phase 2 の Step。手順書 §3 Phase 2 の 3 ステップ。 -/
inductive DerivationStep where
  | decomposition    -- φ の分解
  | bottomUp         -- ボトムアップ導出
  | composition      -- φ の導出完成
  deriving BEq, Repr, DecidableEq

/-- Phase 3 の構成要素。修正ループの 3 サブフェーズ。 -/
inductive CorrectionComponent where
  | errorInterpretation   -- 3a: エラー解釈と修正アクション
  | modificationDiscipline -- 3b: 修正の規律
  | terminationCriteria   -- 3c: 終了判定
  deriving BEq, Repr, DecidableEq

/-- Phase 3b: 修正の分類。手順書が定義する 4 種。 -/
inductive ModificationKind where
  | definitionalExtension    -- 定義的拡大（常に安全）
  | extensionChange          -- Γ \ T₀ の追加・変更
  | baseTheoryContraction    -- T₀ の縮小（禁止）
  | goalWeakening            -- φ の弱化
  deriving BEq, Repr, DecidableEq

/-- Phase 3c: 戦略変更トリガー。
    D15d（計算飽和定理）の操作的インスタンス。
    各トリガーは飽和点に到達した（限界収益がゼロになった）ことを示すヒューリスティック:
    - sameErrorRepetition: 同一エラーの反復 = 精度改善なし（R6 飽和シグナル）
    - axiomInflation: 公理の膨張 = 構造的複雑度のみ増大、精度非改善
    - complexityIncrease: 単調複雑度増大 = リソース消費のみ増大
    E1 制約により飽和点の正確な位置は内部決定不可能なため、
    これらの閾値ベースのヒューリスティクスで近似する。 -/
inductive StrategyChangeTrigger where
  | sameErrorRepetition  -- 同一エラー 3 回連続（D15d: marginalReturn = 0 の反復検出）
  | axiomInflation       -- 公理数が 2 倍超過（D15d: コスト増大、精度非改善）
  | complexityIncrease   -- 複雑度の単調増大（D15d: リソース消費のみの増大）
  deriving BEq, Repr, DecidableEq

/-- Phase 3c: 戦略変更の選択肢。手順書 §3 Phase 3c (lines 360-363)。 -/
inductive StrategyChangeOption where
  | reviseExtension        -- Γ \ T₀ の見直し
  | redefDomain            -- 論議領域の再定義
  | changeDecomposition    -- φ の分解方法を変更
  | weakenGoal             -- φ の弱化（最終手段）
  deriving BEq, Repr, DecidableEq

/-- 公理ソースカテゴリ。手順書 §2.4 (lines 135-137, 153-154)。
    公理カードの「所属」フィールドで使用される根拠の種類。 -/
inductive AxiomSourceCategory where
  | contract      -- 契約由来（T₀）
  | naturalLaw    -- 自然科学由来（T₀）
  | environment   -- 環境由来（T₀）
  | hypothesis    -- 仮説由来（Γ \ T₀）
  | design        -- 設計由来（Γ \ T₀）
  deriving BEq, Repr, DecidableEq

/-- Phase 3a: Lean コンパイラのエラー種別。手順書 §3 Phase 3a (lines 316-322)。 -/
inductive LeanErrorKind where
  | typeMismatch       -- type mismatch
  | unknownIdentifier  -- unknown identifier
  | simpFailed         -- tactic 'simp' failed
  | unsolvedGoals      -- unsolved goals
  | usesSorry          -- declaration uses 'sorry'
  deriving BEq, Repr, DecidableEq

/-- Phase 3c: バックトラック時の構成要素カテゴリ。
    手順書 §3 Phase 3c (lines 365-369)。
    各カテゴリごとに保持/破棄ルールが異なる。 -/
inductive BacktrackComponent where
  | baseTheory        -- T₀: 常に保持
  | extensionAxioms   -- Γ \ T₀: 縮小・破棄可能
  | domainTypes       -- 論議領域: 戦略 2 のみ破棄
  | derivedLemmas     -- 導出済み補題: 依存先が変更されない限り保持
  deriving BEq, Repr, DecidableEq

/-- ワークフローの終了種別。手順書 §4 の 3 条件。 -/
inductive TerminationKind where
  | success    -- Γ ⊢ φ の導出完了
  | failure    -- Γ ⊬ φ の判定
  | undecided  -- 未決
  deriving BEq, Repr, DecidableEq

/-- Phase 4: 監査の構成要素。 -/
inductive AuditComponent where
  | completenessCheck        -- 4a: 導出の完全性確認
  | axiomHygiene             -- 4b: 公理衛生チェック
  | formalizationGapReview   -- 4c: 形式化ギャップ検証
  deriving BEq, Repr, DecidableEq

/-- 公理衛生の 5 検査項目。手順書 §2.6。 -/
inductive HygieneCheck where
  | nonVacuity               -- 非空虚性
  | nonLogicalValidity       -- 非論理的妥当性
  | independence             -- 独立性
  | minimality               -- 最小性
  | baseTheoryPreservation   -- 基底理論の保存
  deriving BEq, Repr, DecidableEq

/-- 形式化ギャップ検証の 3 層。手順書 §4c。 -/
inductive GapVerificationLayer where
  | docstringInspection   -- 第 1 層: docstring 検査
  | independentReview     -- 第 2 層: 独立レビュー
  | counterexampleSearch  -- 第 3 層: 反例探索
  deriving BEq, Repr, DecidableEq

/-- 公理カードの必須フィールド。手順書 §2.5。 -/
inductive AxiomCardField where
  | membership       -- 所属 (T₀ or Γ \ T₀)
  | content          -- 内容
  | rationale        -- 根拠
  | source           -- ソース
  | refutationCond   -- 反証条件 (Γ \ T₀ のみ必須)
  deriving BEq, Repr, DecidableEq

/-- 前提集合の構成区分。手順書 §2.4。 -/
inductive PremisePartition where
  | baseTheory   -- T₀: 外的権威に根拠を持つ
  | extension    -- Γ \ T₀: 構成者の推論に由来
  deriving BEq, Repr, DecidableEq

/-- T₀ のエンコード方法。手順書 §2.4 (T₀ エンコード方法)。
    T₀ の主張が型定義で表現可能か否かで選択する。 -/
inductive T0EncodingMethod where
  | definitionalTheorem  -- 型定義（定義的拡大）+ theorem で証明
  | axiomWithCard        -- axiom（公理カード必須）
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- T₀: 型定義から導出される構造的性質 (定理)
-- ============================================================

/-!
## Base Theory T0 as Theorems

手順書の構造的要件は、上記の型定義（定義的拡大）にエンコードされている。
「Phase は 4 つある」「公理衛生は 5 検査」等の主張は、
列挙型の網羅性として CIC のもとで証明可能であり、
公理衛生検査 2（非論理的妥当性）に従い axiom ではなく theorem とする。

T₀ の権威（手順書）は型定義の構成子の選択に反映されている:
型の構成子を手順書と異なるように定義すれば、ここで証明される定理も変わる。
すなわち、T₀ は型定義のレベルで固定されている。
-/

/-- T₀: 手順書は Phase 1–4 の 4 フェーズで構成される。
    Source: docs/formal-derivation-procedure.md §3 -/
theorem procedure_has_four_phases :
  ∀ (p : Phase),
    p = .leanConstruction ∨ p = .derivation ∨
    p = .correctionLoop ∨ p = .audit := by
  intro p; cases p <;> simp

/-- T₀: Phase 1 は 6 つの Step で構成される。
    Source: docs/formal-derivation-procedure.md §3 Phase 1 (lines 268-276) -/
theorem phase1_has_six_steps :
  ∀ (s : ConstructionStep),
    s = .domainDefinition ∨ s = .goalFormulation ∨
    s = .baseTheoryConstruction ∨ s = .consistencyCheck ∨
    s = .extensionConstruction ∨ s = .auxiliaryDefinitions := by
  intro s; cases s <;> simp

/-- T₀: Phase 2 は 3 つの Step で構成される。
    Source: docs/formal-derivation-procedure.md §3 Phase 2 (lines 286-298) -/
theorem phase2_has_three_steps :
  ∀ (s : DerivationStep),
    s = .decomposition ∨ s = .bottomUp ∨ s = .composition := by
  intro s; cases s <;> simp

/-- T₀: Phase 3 は 3 つのサブフェーズで構成される。
    Source: docs/formal-derivation-procedure.md §3 Phase 3 (lines 300-368) -/
theorem phase3_has_three_components :
  ∀ (c : CorrectionComponent),
    c = .errorInterpretation ∨ c = .modificationDiscipline ∨
    c = .terminationCriteria := by
  intro c; cases c <;> simp

/-- T₀: Phase 3b の修正は 4 種に分類される。
    Source: docs/formal-derivation-procedure.md §3 Phase 3b (lines 315-335) -/
theorem phase3b_has_four_modification_kinds :
  ∀ (m : ModificationKind),
    m = .definitionalExtension ∨ m = .extensionChange ∨
    m = .baseTheoryContraction ∨ m = .goalWeakening := by
  intro m; cases m <;> simp

/-- T₀: Phase 3c は 3 つの戦略変更トリガーを定義する。
    Source: docs/formal-derivation-procedure.md §3 Phase 3c (lines 344-348) -/
theorem phase3c_has_three_strategy_triggers :
  ∀ (t : StrategyChangeTrigger),
    t = .sameErrorRepetition ∨ t = .axiomInflation ∨
    t = .complexityIncrease := by
  intro t; cases t <;> simp

/-- T₀: Phase 3c の戦略変更は 4 つの選択肢で構成される。
    Source: docs/formal-derivation-procedure.md §3 Phase 3c (lines 360-363) -/
theorem phase3c_has_four_strategy_options :
  ∀ (o : StrategyChangeOption),
    o = .reviseExtension ∨ o = .redefDomain ∨
    o = .changeDecomposition ∨ o = .weakenGoal := by
  intro o; cases o <;> simp

/-- T₀: 公理ソースは 5 カテゴリで構成される。
    Source: docs/formal-derivation-procedure.md §2.4 (lines 135-137, 153-154) -/
theorem axiom_sources_have_five_categories :
  ∀ (s : AxiomSourceCategory),
    s = .contract ∨ s = .naturalLaw ∨ s = .environment ∨
    s = .hypothesis ∨ s = .design := by
  intro s; cases s <;> simp

/-- T₀: Phase 3a のエラー種別は 5 つで構成される。
    Source: docs/formal-derivation-procedure.md §3 Phase 3a (lines 316-322) -/
theorem phase3a_has_five_error_kinds :
  ∀ (e : LeanErrorKind),
    e = .typeMismatch ∨ e = .unknownIdentifier ∨
    e = .simpFailed ∨ e = .unsolvedGoals ∨ e = .usesSorry := by
  intro e; cases e <;> simp

/-- T₀: バックトラック時の構成要素は 4 カテゴリで構成される。
    Source: docs/formal-derivation-procedure.md §3 Phase 3c (lines 365-369) -/
theorem phase3c_has_four_backtrack_components :
  ∀ (b : BacktrackComponent),
    b = .baseTheory ∨ b = .extensionAxioms ∨
    b = .domainTypes ∨ b = .derivedLemmas := by
  intro b; cases b <;> simp

/-- T₀: ワークフローは 3 種の終了条件を持つ。
    Source: docs/formal-derivation-procedure.md §4 (lines 432-456) -/
theorem workflow_has_three_terminations :
  ∀ (t : TerminationKind),
    t = .success ∨ t = .failure ∨ t = .undecided := by
  intro t; cases t <;> simp

/-- T₀: Phase 4 は 3 つの監査構成要素を持つ。
    Source: docs/formal-derivation-procedure.md §3 Phase 4 (lines 370-428) -/
theorem phase4_has_three_audit_components :
  ∀ (a : AuditComponent),
    a = .completenessCheck ∨ a = .axiomHygiene ∨
    a = .formalizationGapReview := by
  intro a; cases a <;> simp

/-- T₀: 公理衛生チェックは 5 つの検査項目で構成される。
    Source: docs/formal-derivation-procedure.md §2.6 (lines 192-257) -/
theorem axiom_hygiene_has_five_checks :
  ∀ (h : HygieneCheck),
    h = .nonVacuity ∨ h = .nonLogicalValidity ∨
    h = .independence ∨ h = .minimality ∨
    h = .baseTheoryPreservation := by
  intro h; cases h <;> simp

/-- T₀: 形式化ギャップ検証は 3 層で構成される。
    Source: docs/formal-derivation-procedure.md §4c (lines 396-428) -/
theorem gap_verification_has_three_layers :
  ∀ (g : GapVerificationLayer),
    g = .docstringInspection ∨ g = .independentReview ∨
    g = .counterexampleSearch := by
  intro g; cases g <;> simp

/-- T₀: 公理カードは 5 つの必須フィールドで構成される。
    Source: docs/formal-derivation-procedure.md §2.5 (lines 156-190) -/
theorem axiom_card_has_five_fields :
  ∀ (f : AxiomCardField),
    f = .membership ∨ f = .content ∨ f = .rationale ∨
    f = .source ∨ f = .refutationCond := by
  intro f; cases f <;> simp

/-- T₀: 前提集合 Γ は T₀ と Γ \ T₀ の 2 区分で構成される。
    Source: docs/formal-derivation-procedure.md §2.4 (lines 125-154) -/
theorem premise_has_two_partitions :
  ∀ (p : PremisePartition),
    p = .baseTheory ∨ p = .extension := by
  intro p; cases p <;> simp

/-- T₀: T₀ のエンコード方法は 2 つの選択肢で構成される。
    Source: docs/formal-derivation-procedure.md §2.4 (lines 139-146) -/
theorem t0_has_two_encoding_methods :
  ∀ (e : T0EncodingMethod),
    e = .definitionalTheorem ∨ e = .axiomWithCard := by
  intro e; cases e <;> simp

-- ============================================================
-- Γ \ T₀: SKILL.md の実装に関する主張 (非論理的公理)
-- ============================================================

/-!
## Extension Part Beyond T0

SKILL.md が手順書の各要件を実装しているという主張。
これらは LLM の分析に基づく仮説であり、純粋な論理からは導出不能。
Lean コンパイラはこれらの真偽を判定できない（SKILL.md の内容は型体系の外）。

公理衛生検査の結果:
- 検査 1 (非空虚性): 各公理の前件は非空列挙型のメンバーシップのみ。充足可能。OK
- 検査 2 (非論理的妥当性): SKILL.md の内容に関する主張は論理のみでは導出不能。OK
- 検査 3 (独立性): 各公理は異なる型を対象とし、互いに独立。OK
- 検査 4 (最小性): φ が各公理に対応する合取項を含むため、全公理が必要。OK
- 検査 5 (基底理論の保存): T₀ は型定義に固定され、axiom は Γ \ T₀ のみ。OK
-/

/-- スキルが手順書の構成要素を実装しているかを表す述語。
    α は構成要素の型（Phase, ConstructionStep 等）。
    opaque にすることで、Lean がこの命題を自動的に証明・反証することを防ぐ。
    真偽は Γ \ T₀ の公理によってのみ決定される。 -/
opaque skillCovers : {α : Type} → α → Prop

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 1–4 の全 Phase をセクションとして含む
    Basis: SKILL.md lines 51-285 に Phase 1–4 が記述されている
    Source: .claude/skills/formal-derivation/SKILL.md (Phase 1: L51, Phase 2: L158,
            Phase 3: L178, Phase 4: L242)
    Refutation condition: SKILL.md にいずれかの Phase のセクションが存在しない場合 -/
axiom skill_covers_all_phases :
  ∀ (p : Phase), skillCovers p

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 1 の全 6 Step を Steps 1.1–1.7 として含む
    Basis: SKILL.md Steps 1.1(L55), 1.2(L71), 1.3(L90), 1.4(L99),
          1.5(L112: T₀ 無矛盾性), 1.6(L125: 公理カード), 1.7(L148: コンパイル)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかの Step が存在しない場合。
              注: 手順書の step 5 (Γ\T₀ 拡大) と step 6 (補助定義) は
              Step 1.4 内に統合されている -/
axiom skill_covers_phase1_steps :
  ∀ (s : ConstructionStep), skillCovers s

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 2 の全 3 Step を含む
    Basis: SKILL.md Steps 2.1(L163), 2.2(L167), 2.3(L171)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかの Step が存在しない場合 -/
axiom skill_covers_phase2_steps :
  ∀ (s : DerivationStep), skillCovers s

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 3 の全 3 構成要素を含む
    Basis: SKILL.md 3a(L183), 3b(L193), 3c(L215)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかのサブフェーズが存在しない場合 -/
axiom skill_covers_phase3_components :
  ∀ (c : CorrectionComponent), skillCovers c

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 3b の 4 種の修正分類を含む
    Basis: SKILL.md L197(定義的拡大), L201(Γ\T₀変更), L206(T₀縮小禁止), L210(φ弱化)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかの修正分類が存在しない場合 -/
axiom skill_covers_modification_kinds :
  ∀ (m : ModificationKind), skillCovers m

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 3c の 3 つの戦略変更トリガーを含む
    Basis: SKILL.md L220(同一エラー), L221(公理膨張), L222(複雑度増大)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかのトリガーが存在しない場合 -/
axiom skill_covers_strategy_triggers :
  ∀ (t : StrategyChangeTrigger), skillCovers t

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 3c の 4 つの戦略変更選択肢を含む
    Basis: SKILL.md L224-228 に 4 選択肢が列挙されている
    Source: .claude/skills/formal-derivation/SKILL.md Phase 3c
    Refutation condition: SKILL.md にいずれかの選択肢が存在しない場合 -/
axiom skill_covers_strategy_options :
  ∀ (o : StrategyChangeOption), skillCovers o

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は 3 つの終了条件を含む
    Basis: SKILL.md L289(成功), L297(失敗), L302(未決)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかの終了条件が存在しない場合 -/
axiom skill_covers_terminations :
  ∀ (t : TerminationKind), skillCovers t

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 4 の全 3 監査構成要素を含む
    Basis: SKILL.md 4a(L247), 4b(L253), 4c(L261)
    Source: .claude/skills/formal-derivation/SKILL.md
    Refutation condition: SKILL.md にいずれかの監査構成要素が存在しない場合 -/
axiom skill_covers_audit_components :
  ∀ (a : AuditComponent), skillCovers a

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は公理衛生チェックの全 5 検査項目を含む
    Basis: SKILL.md L255-259 に 5 項目すべてが列挙されている
    Source: .claude/skills/formal-derivation/SKILL.md Phase 4b
    Refutation condition: SKILL.md にいずれかの検査項目が存在しない場合 -/
axiom skill_covers_hygiene_checks :
  ∀ (h : HygieneCheck), skillCovers h

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は形式化ギャップ検証の全 3 層を含む
    Basis: SKILL.md L263(docstring), L268(独立レビュー), L282(反例探索)
    Source: .claude/skills/formal-derivation/SKILL.md Phase 4c
    Refutation condition: SKILL.md にいずれかの層が存在しない場合 -/
axiom skill_covers_gap_layers :
  ∀ (g : GapVerificationLayer), skillCovers g

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は公理カードの全 5 フィールドを定義している
    Basis: SKILL.md L130-146 に所属/内容/根拠/ソース/反証条件が記載
    Source: .claude/skills/formal-derivation/SKILL.md Step 1.6
    Refutation condition: SKILL.md にいずれかのフィールドが存在しない場合 -/
axiom skill_covers_axiom_card_fields :
  ∀ (f : AxiomCardField), skillCovers f

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は T₀ / Γ \ T₀ の 2 区分を明示している
    Basis: SKILL.md Step 1.4 (L99-110) に基底理論と拡大部分が記述
    Source: .claude/skills/formal-derivation/SKILL.md Step 1.4
    Refutation condition: SKILL.md に T₀ と Γ \ T₀ の区分が存在しない場合 -/
axiom skill_covers_premise_partitions :
  ∀ (p : PremisePartition), skillCovers p

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は T₀ エンコード方法の 2 選択肢を明示している
    Basis: SKILL.md Step 1.4 に「T₀ のエンコード方法の選択」セクションがあり、
          型定義 + theorem と axiom の 2 選択肢が記述されている
    Source: .claude/skills/formal-derivation/SKILL.md Step 1.4
    Refutation condition: SKILL.md に T₀ エンコード方法の選択肢が存在しない場合 -/
axiom skill_covers_t0_encoding_methods :
  ∀ (e : T0EncodingMethod), skillCovers e

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は公理ソースの 5 カテゴリを明示している
    Basis: SKILL.md Step 1.4 に T₀ の 3 カテゴリ（契約/科学/環境）と
          Γ \ T₀ の 2 カテゴリ（仮説/設計）が記述されている
    Source: .claude/skills/formal-derivation/SKILL.md Step 1.4
    Refutation condition: SKILL.md にいずれかのカテゴリが存在しない場合 -/
axiom skill_covers_axiom_source_categories :
  ∀ (s : AxiomSourceCategory), skillCovers s

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 3a の 5 つのエラー種別を含む
    Basis: SKILL.md Phase 3a のテーブルに 5 種のエラーが列挙されている
    Source: .claude/skills/formal-derivation/SKILL.md Phase 3a
    Refutation condition: SKILL.md にいずれかのエラー種別が存在しない場合 -/
axiom skill_covers_error_kinds :
  ∀ (e : LeanErrorKind), skillCovers e

/-- [Axiom Card]
    Layer: Γ \ T₀ (Design-derived)
    Content: SKILL.md は Phase 3c のバックトラック保持/破棄ルールの 4 カテゴリを含む
    Basis: SKILL.md Phase 3c に T₀/Γ\T₀/論議領域/導出済み補題の保持/破棄ルールが記述
    Source: .claude/skills/formal-derivation/SKILL.md Phase 3c
    Refutation condition: SKILL.md にいずれかのカテゴリが存在しない場合 -/
axiom skill_covers_backtrack_components :
  ∀ (b : BacktrackComponent), skillCovers b

-- ============================================================
-- Phase 2: Γ ⊢ φ の導出 (Step 2.1–2.3)
-- ============================================================

/-!
## 目標命題 φ の分解と導出

φ（skill_implements_procedure）を以下の補題に分解する:
1. 全 Phase がカバーされている
2. 各 Phase の内部構成要素がカバーされている
3. 横断的要件（公理カード、前提区分、終了条件）がカバーされている
-/

-- --- 補題群: 各構成要素のカバレッジ ---

/-- [補題] Phase 1 の全 Step がスキルで実装されている -/
theorem phase1_coverage :
  ∀ (s : ConstructionStep), skillCovers s :=
  skill_covers_phase1_steps

/-- [補題] Phase 2 の全 Step がスキルで実装されている -/
theorem phase2_coverage :
  ∀ (s : DerivationStep), skillCovers s :=
  skill_covers_phase2_steps

/-- [補題] Phase 3 の全構成要素がスキルで実装されている -/
theorem phase3_coverage :
  ∀ (c : CorrectionComponent), skillCovers c :=
  skill_covers_phase3_components

/-- [補題] Phase 3b の全修正分類がスキルで実装されている -/
theorem phase3b_modification_coverage :
  ∀ (m : ModificationKind), skillCovers m :=
  skill_covers_modification_kinds

/-- [補題] Phase 3c の全戦略変更トリガーがスキルで実装されている -/
theorem phase3c_strategy_coverage :
  ∀ (t : StrategyChangeTrigger), skillCovers t :=
  skill_covers_strategy_triggers

/-- [補題] Phase 3c の全戦略変更選択肢がスキルで実装されている -/
theorem phase3c_option_coverage :
  ∀ (o : StrategyChangeOption), skillCovers o :=
  skill_covers_strategy_options

/-- [補題] Phase 4 の全監査構成要素がスキルで実装されている -/
theorem phase4_coverage :
  ∀ (a : AuditComponent), skillCovers a :=
  skill_covers_audit_components

/-- [補題] 公理衛生チェックの全 5 検査項目がスキルで実装されている -/
theorem hygiene_coverage :
  ∀ (h : HygieneCheck), skillCovers h :=
  skill_covers_hygiene_checks

/-- [補題] 形式化ギャップ検証の全 3 層がスキルで実装されている -/
theorem gap_verification_coverage :
  ∀ (g : GapVerificationLayer), skillCovers g :=
  skill_covers_gap_layers

/-- [補題] 公理カードの全フィールドがスキルで定義されている -/
theorem axiom_card_coverage :
  ∀ (f : AxiomCardField), skillCovers f :=
  skill_covers_axiom_card_fields

/-- [補題] 前提集合の 2 区分がスキルで明示されている -/
theorem premise_partition_coverage :
  ∀ (p : PremisePartition), skillCovers p :=
  skill_covers_premise_partitions

/-- [補題] T₀ エンコード方法の全選択肢がスキルで定義されている -/
theorem t0_encoding_coverage :
  ∀ (e : T0EncodingMethod), skillCovers e :=
  skill_covers_t0_encoding_methods

/-- [補題] 公理ソースの全カテゴリがスキルで定義されている -/
theorem axiom_source_coverage :
  ∀ (s : AxiomSourceCategory), skillCovers s :=
  skill_covers_axiom_source_categories

/-- [補題] Phase 3a の全エラー種別がスキルで定義されている -/
theorem error_kind_coverage :
  ∀ (e : LeanErrorKind), skillCovers e :=
  skill_covers_error_kinds

/-- [補題] バックトラック保持/破棄ルールの全カテゴリがスキルで定義されている -/
theorem backtrack_coverage :
  ∀ (b : BacktrackComponent), skillCovers b :=
  skill_covers_backtrack_components

/-- [補題] 全終了条件がスキルで定義されている -/
theorem termination_coverage :
  ∀ (t : TerminationKind), skillCovers t :=
  skill_covers_terminations

-- ============================================================
-- 目標命題 φ の導出 (Step 2.3)
-- ============================================================

/-- [目標命題]
    タスク: 「SKILL.md は formal-derivation-procedure.md の全要件を実装している」

    形式化の意図:
    手順書が定義する全構成要素（Phase, Step, Check, TerminationKind,
    AxiomCardField, PremisePartition）に対して、SKILL.md に対応する
    実装が存在することを導出する。

    構造: 各構成要素のカバレッジ補題の合取 (conjunction)。 -/
theorem skill_implements_procedure :
  -- Phase 構造の網羅
  (∀ (p : Phase), skillCovers p) ∧
  -- Phase 1 の Step 網羅
  (∀ (s : ConstructionStep), skillCovers s) ∧
  -- Phase 2 の Step 網羅
  (∀ (s : DerivationStep), skillCovers s) ∧
  -- Phase 3 の構成要素網羅
  (∀ (c : CorrectionComponent), skillCovers c) ∧
  -- Phase 3b の修正分類網羅
  (∀ (m : ModificationKind), skillCovers m) ∧
  -- Phase 3c の戦略変更トリガー網羅
  (∀ (t : StrategyChangeTrigger), skillCovers t) ∧
  -- Phase 3c の戦略変更選択肢網羅
  (∀ (o : StrategyChangeOption), skillCovers o) ∧
  -- Phase 4 の監査構成要素網羅
  (∀ (a : AuditComponent), skillCovers a) ∧
  -- 公理衛生チェック網羅
  (∀ (h : HygieneCheck), skillCovers h) ∧
  -- 形式化ギャップ検証網羅
  (∀ (g : GapVerificationLayer), skillCovers g) ∧
  -- 公理カードフィールド網羅
  (∀ (f : AxiomCardField), skillCovers f) ∧
  -- 前提区分網羅
  (∀ (p : PremisePartition), skillCovers p) ∧
  -- T₀ エンコード方法網羅
  (∀ (e : T0EncodingMethod), skillCovers e) ∧
  -- 公理ソースカテゴリ網羅
  (∀ (s : AxiomSourceCategory), skillCovers s) ∧
  -- Phase 3a エラー種別網羅
  (∀ (e : LeanErrorKind), skillCovers e) ∧
  -- Phase 3c バックトラックカテゴリ網羅
  (∀ (b : BacktrackComponent), skillCovers b) ∧
  -- 終了条件網羅
  (∀ (t : TerminationKind), skillCovers t) :=
  ⟨skill_covers_all_phases,
   phase1_coverage,
   phase2_coverage,
   phase3_coverage,
   phase3b_modification_coverage,
   phase3c_strategy_coverage,
   phase3c_option_coverage,
   phase4_coverage,
   hygiene_coverage,
   gap_verification_coverage,
   axiom_card_coverage,
   premise_partition_coverage,
   t0_encoding_coverage,
   axiom_source_coverage,
   error_kind_coverage,
   backtrack_coverage,
   termination_coverage⟩

-- ============================================================
-- SelfGoverning 自己適用
-- ============================================================

/-- 手順書の構成要素を表す列挙型。
    スキルの更新は互換性分類を経る（D9 自己適用）。 -/
inductive ProcedureRequirement where
  | phaseStructure
  | constructionSteps
  | derivationSteps
  | correctionComponents
  | modificationKinds
  | strategyTriggers
  | strategyOptions
  | auditComponents
  | hygieneChecks
  | gapVerificationLayers
  | axiomCardFields
  | premisePartitions
  | t0EncodingMethods
  | axiomSourceCategories
  | errorKinds
  | backtrackComponents
  | terminationKinds
  deriving BEq, Repr, DecidableEq

/-- ProcedureRequirement は SelfGoverning を実装する。
    この形式化自体の更新も互換性分類を経る。 -/
instance : SelfGoverning ProcedureRequirement where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- 全要件が列挙されていることの証明。 -/
theorem all_requirements_enumerated :
  ∀ (r : ProcedureRequirement),
    r = .phaseStructure ∨ r = .constructionSteps ∨
    r = .derivationSteps ∨ r = .correctionComponents ∨
    r = .modificationKinds ∨ r = .strategyTriggers ∨
    r = .strategyOptions ∨ r = .auditComponents ∨ r = .hygieneChecks ∨
    r = .gapVerificationLayers ∨ r = .axiomCardFields ∨
    r = .premisePartitions ∨ r = .t0EncodingMethods ∨
    r = .axiomSourceCategories ∨ r = .errorKinds ∨
    r = .backtrackComponents ∨ r = .terminationKinds := by
  intro r; cases r <;> simp

end Manifest.FormalDerivationSkill
