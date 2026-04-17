# 新研究基盤 Gap Analysis

**作成日**: 2026-04-17
**Pass 1 → Pass 2**: 命名規則改訂 (GA- 接頭辞付加)、S1/C1 の umbrella 化、前リサーチ #599 16 Gap + TyDD Recipe + 内部資産 + サーベイ細部の統合により 46 → 79 Gap に拡張
**前提**: サーベイ成果物（01-06 + G1-G5、計 74 対象 / 約 8462 行）、research/survey_type_driven_development_2025.md (TyDD)、research/lean4-handoff.md
**目的**: agent-manifesto の研究プロセス記録を GitHub Issue 依存から Lean 言語による型安全な tree structure + 半順序関係 + traceability 保証 + 自作 Pipeline に再設計するために解消すべき構造的 Gap を体系的に列挙する
**方法**: 4 パス収束 + Verifier 2 ラウンド独立検証（SKILL.md Step 1/1.5 準拠）

---

## 1. Tag Index スキーム

### 1.1 接頭辞付きカテゴリ（Pass 2 で改訂）

| Tag | 意味 | 該当範囲 |
|---|---|---|
| **GA-S** (Structure) | 型・構造の欠如 | Lean 型定義、半順序関係、不変条件 |
| **GA-C** (Capability) | 能力・機構の欠如 | Pipeline、Codec、Index、ハンマー、LLM 統合 |
| **GA-M** (Methodology) | 手法・戦略の欠如 | 開発手法、訓練、task 分解、retry |
| **GA-E** (Evaluation) | 評価・計測の欠如 | ベンチマーク、メトリクス、自己評価 |
| **GA-I** (Integration) | 既存資産との統合の欠如 | manifest、スキル、スクリプト、外部 lib |
| **GA-T** (Transition) | 移行・退役戦略の欠如 | Issue 降格、rollback、phase 計画 |
| **GA-W** (Warning / Anti-Pattern) | 実装時に避けるべき罠 | SMT false-positive、sorry 蓄積、メタコード termination 等 |

### 1.2 `GA-` 接頭辞の必要性

agent-manifesto 本体および TyDD サーベイの既存 tag との衝突を回避:

| 無接頭辞時の衝突 | 影響 |
|---|---|
| `E1-E5` (Gap) vs `E1-E2` (agent-manifesto E-axiom) vs `E1-E5` (TyDD Lean-Auto) | **三重衝突** |
| `T1-T7` (Gap) vs `T1-T8` (agent-manifesto T-axiom) | 二重衝突 |
| `C1-C27` (Gap) vs `C1-C3` (TyDD LLM×Type) | 参照混乱 |
| `M1-M10` (Gap) vs `M1-M7` (TyDD Info-theoretic) | 参照混乱 |
| `I1-I13` (Gap) vs `I1-I7` (TyDD Second-order) | 参照混乱 |
| `S1-S14` (Gap) vs `S1-S8` (TyDD Sources) | 参照混乱 |

`GA-` 接頭辞で全衝突を撤廃。

### 1.3 導出元表記ルール

- 既存 A-F: `A-3.2`, `B-4.1`, `C-4.3`, `D-4.5`, `E-3.1`, `F-Section 2`
- G1-G4: `G1-2.3`, `G2-3.6`, `G3-1.2`, `G4-2.4`
- G5: `G5-1-3.2`, `G5-2-Sec 2`, `G5-3-3.2`, `G5-4-4.3`, `G5-5-2.1`
- 既往参考: `TyDD-S4`, `TyDD-B3`, `TyDD-H7`
- handoff: `handoff-§7.2`, `handoff-§4.3`
- 前リサーチ: `#599-Gap N`（deep-research-survey の Gap 番号）
- 内部資産: `Ontology.lean:1104`, `SKILL.md:267`, `TaskClassification.lean`

---

## 2. Gap 詳細

### 2.1 GA-S: Structure Gap（型・構造の欠如）

#### GA-S1: 研究 tree 全体の Lean 型表現なし [umbrella]
- **種別**: umbrella Gap（GA-S2〜GA-S20 を統合する概念、GA-C1 と協調）
- **現状**: 研究ノード（Survey/Gap/Hypothesis/Decomposition/Implementation/Failure/Retired）は GitHub Issue の自然言語テキストのみで表現。Lean 型として存在しない
- **必要**: `inductive ResearchNode` で全ノード種別を constructor として型化。Tana supertag と Lean inductive type の同型性を利用
- **リスク**: high
- **未知**: Constructor の網羅性、rationale フィールドの型設計、Lean compile 時間のスケール
- **導出元**: A-4.1, B-4.1, C-4.1, F-Section 2, G5-1-Sec 3, G5-2-Dafny 型システム, #599-Gap 9 (知識管理構造化の型基盤として umbrella 吸収)
- **構成要素**: GA-S2 (FolgeID), GA-S3 (Provenance), GA-S4 (Edge), GA-S5 (Retirement), GA-S6 (Failure), GA-S7 (State), GA-S8 (Rationale), GA-S9 (Assumption S-type), GA-S10 (ResearchGoal), GA-S11 (Hoare 4-arg), GA-S12 (PropositionId 拡張), GA-S13 (SelfGoverning), GA-S14 (EnforcementLayer), GA-S15 (Lattice), GA-S16 (Multiplicity), GA-S17 (FiberedTypeSpec), GA-S18 (Gradual `?`), GA-S19 (Phantom scope), GA-S20 (Dynamic dependency)
- **対応案**: synthesis §4.1 #1, §2a

#### GA-S2: Folgezettel ID 型と半順序 instance なし
- **現状**: Issue 番号の魔法依存（"#599"）。親子関係は Parent Issue テーブルの手動メンテナンス
- **必要**: `structure FolgeID { path : List (Nat ⊕ Char) }` + `LE` instance で ID 自体に半順序を埋め込む
- **リスク**: high
- **未知**: `BEq (Nat ⊕ Char)` の標準化、path ソート方式
- **導出元**: A-3.3 U1, A-4.3, synthesis §2a
- **対応案**: synthesis §4.1 #2

#### GA-S3: Provenance Triple 型なし
- **現状**: Entity/Activity/Agent の関係は Issue コメントの自然言語のみ
- **必要**: `inductive ResearchEntity` / `ResearchActivity` / `structure ResearchAgent` + PROV-style edge の Lean 型
- **リスク**: high
- **未知**: PROV 11 edge の全てを網羅すべきか、研究特化 edge (refutes, blocks) との統合
- **導出元**: B-3.1, B-4.1, synthesis §4.1 #3
- **対応案**: synthesis §7.7 P0 追加

#### GA-S4: Edge Type Inductive なし
- **現状**: Issue 間の関係は "depends-on" 等の平坦なテキストラベル
- **必要**: `inductive ResearchEdge : ResearchNode → ResearchNode → Type` で wasDerivedFrom / refines / refutes / blocks / relates / wasReplacedBy を型レベルで区別
- **リスク**: high
- **未知**: Edge の推移性・反射性 axiom の設計
- **導出元**: A-Q5, B (PROV 11 種), E-Linear blocks/blocked-by/related
- **対応案**: synthesis §4.1 #6

#### GA-S5: Retirement first-class 表現なし
- **現状**: Issue close は state_reason のみ。退役の理由・後継・反証条件が構造化されていない
- **必要**: `ResearchNode` に `retired` constructor + `RetirementReason` + `replacedBy: Option NodeID` + Lean linter による参照切れ検出
- **リスク**: high（agent-manifesto P3 のコア要求、全 PKM ツール欠落）
- **未知**: 退役の推移性（retired の後継が retired の場合）
- **導出元**: A-3.2 C1, B-3.7, synthesis §4.1 #5, handoff-§4.1 「何を証明すべきか」問題
- **対応案**: synthesis §2a 独自設計、§7.7 P0

#### GA-S6: Failure first-class 表現なし
- **現状**: 失敗は Gate FAIL とコメントのみ。原因分類・反証証拠が構造化されていない
- **必要**: `Failure : ResearchEntity` constructor + `FailureReason` inductive + `whyFailed : Failure → FailureReason` total function
- **リスク**: high（全先行研究で未踏）
- **未知**: FailureReason の網羅性、根本原因分析のメタ情報
- **導出元**: B-3.5, B-3.7, B-4.3, G2-4.1, handoff-§4.2 3 段階, synthesis §4.1 #4, §7.7 P0
- **対応案**: synthesis §6.2 独自貢献領域

#### GA-S7: Type-Safe State Machine なし
- **現状**: Issue state は open/closed の 2 値のみ。Org-mode 風状態遷移なし
- **必要**: `inductive LifeCyclePhase` + `AllowedTransition : Prop` で不正遷移を compile-time error 化
- **リスク**: medium
- **未知**: Linear の 6 categories + 内部 status 二層を Lean でどう表現するか
- **導出元**: E-3.1 C, E-3.2 F, E-4.3
- **対応案**: synthesis §4.1 #9

#### GA-S8: Rationale 型（judgmental 構造化）なし
- **現状**: 「なぜそう判断したか」は Issue コメントの自然言語のみ
- **必要**: `structure Rationale` + 各 constructor に必須化（Gap/Hypothesis/Decomposition/Implementation/Failure/Retired 全てで）
- **リスク**: high（全先行研究で未解決、G2+G3 で最重要として明示）
- **未知**: Rationale の型構造（text + references + confidence など）
- **導出元**: B-5.2, G2-4.1, G3-2.1, handoff-§4.1 仕様選定問題, synthesis §6.2
- **対応案**: synthesis §6.2 独自貢献

#### GA-S9: Assumption S-type（Structure-derived）拡張なし
- **現状**: Assumptions.lean は C-type (Human Decision) と H-type (LLM Inference) のみ
- **必要**: S-type (Structure-derived — 研究 tree 構造から導出される仮定) の追加
- **リスク**: medium
- **未知**: S-type の形式的条件、C/H との関係
- **導出元**: F-Section 4 C5, G5-1-3.5
- **対応案**: Assumptions.lean 拡張

#### GA-S10: ResearchGoal / Context 型なし
- **現状**: 研究目的（`researchGoal`）と現 context が Issue 自然言語のみ。Sub-Issue 間で伝搬されない
- **必要**: `structure ResearchGoal` + `ResearchContext`、Sub-Issue 生成時に継承する型
- **リスク**: medium
- **未知**: context の境界（どこまで継承するか）、差分表現
- **導出元**: #599-Gap 15（前リサーチ）
- **対応案**: ResearchNode 生成時に context を型レベルで継承

#### GA-S11: Hoare-style 4-arg post spec なし
- **現状**: research node に pre/post 条件の明示的型なし
- **必要**: `structure ResearchSpec { pre : State → Input → Prop, post : State → Input → Output → State' → Prop }` — frame conditions 込み
- **リスク**: medium
- **未知**: State 型の抽象化レベル
- **導出元**: TyDD-B4 (Liquid Haskell Hoare logic)
- **対応案**: high-tokenizer FuncSpec の拡張

#### GA-S12: PropositionId 拡張（ResearchNode 系）なし
- **現状**: `PropositionId` は T1-T8, E1-E2, P1-P6, L1-L6, D1-D18, V1-V7 の 47 命題のみ
- **必要**: ResearchNode 系 Proposition（research tree の半順序、研究プロセスの不変条件など）を追加
- **リスク**: medium
- **未知**: 新 Proposition の数と命名、既存 D9 自己適用との関係
- **導出元**: `Ontology.lean:1104`, F-Section 2.9
- **対応案**: Ontology.lean 拡張

#### GA-S13: SelfGoverning typeclass の新基盤 node 適用なし
- **現状**: `SelfGoverning` typeclass は T/E/P/L/V/D axiom 対象、ResearchNode 未対応
- **必要**: ResearchNode 型が SelfGoverning instance を実装し、自己検証メカニズムを継承
- **リスク**: medium
- **未知**: SelfGoverning の要求条件とのギャップ
- **導出元**: `Ontology.lean SelfGoverning`
- **対応案**: SelfGoverning instance の ResearchNode 向け定義

#### GA-S14: EnforcementLayer.strength の assumption 層適用なし
- **現状**: structural(3) > procedural(2) > normative(1) は T/D axiom の enforcement のみ
- **必要**: assumption 層の enforcement strength を定義し、structural な強制（lake build 検査）を優先
- **リスク**: low
- **未知**: assumption ごとの妥当な strength 判定基準
- **導出元**: `DesignFoundation.lean:103-106`
- **対応案**: EnforcementLayer の assumption 拡張

#### GA-S15: SpecSig Lattice (meet/join on pre/post) なし
- **現状**: ResearchSpec の pre/post が個別型、lattice 構造なし
- **必要**: `instance : Lattice ResearchSpec` — pre に対する meet (∧ 強化)、post に対する join (∨ 緩和)、LLM refine loop の収束証明の基盤
- **リスク**: medium
- **未知**: ResearchSpec の partial order 定義、decidable 判定
- **導出元**: TyDD-F2, TyDD-S4 (Liquid Haskell pre/post)
- **対応案**: high-tokenizer refines partial order を lattice に拡張

#### GA-S16: Multiplicity Type Grading {0, 1, ω} なし
- **現状**: ResearchNode の使用回数に型レベル制約なし
- **必要**: Idris 2 QTT 風 — {0: type-level only / 1: linear / ω: unrestricted} を ResearchNode / Evidence に付与
- **リスク**: medium
- **未知**: Lean 4 での multiplicity 表現（直接 syntax なし、typeclass で代替）
- **導出元**: TyDD-F3 (Atkey 2018 QTT), TyDD-I4, TyDD-H1
- **対応案**: multiplicity を attribute で付与、EnvExtension で追跡

#### GA-S17: FiberedTypeSpec (constraint-indexed) なし
- **現状**: 制約ごとに異なる ResearchSpec の関係を表現できない
- **必要**: `FiberedSpec : Constraint → Type` — Scoped ResearchSpec、scope 境界での `rebase` 操作
- **リスク**: medium
- **未知**: fibration 構造の運用コスト
- **導出元**: TyDD-F8, TyDD-S4 (Liquid Haskell ScopedExp)
- **対応案**: Phase 2 で必要性を再評価

#### GA-S18: Gradual Refinement Type (`?` placeholder) なし
- **現状**: 未確定仕様の型レベル表現なし（DSL で `?` プレースホルダ相当がない）
- **必要**: `? : Refinement` — 未知の refinement を型レベルで許容、段階的に具体化
- **リスク**: medium
- **未知**: gradual guarantee の Lean での保証方法
- **導出元**: TyDD-I2 (Lehmann-Tanter 2017 POPL)
- **対応案**: research tree 未確定ノードへの適用

#### GA-S19: Phantom-type Scope Safety (well-scoped AST) なし
- **現状**: AST の scope 情報が型レベルで保持されない
- **必要**: `Expr (n : Scope)` — scope を phantom type で保持、閉じた式と開いた式を型レベルで区別
- **リスク**: low
- **未知**: 既存 Lean expr 操作との整合
- **導出元**: TyDD-I7 (Maclaurin 2022 Foil)
- **対応案**: Pipeline DSL 設計時に phantom type 導入

#### GA-S20: Dynamic Dependency の Lean 表現なし (Skyframe restart 相当)
- **現状**: Lean import graph は静的、動的に発見される依存を表現できない
- **必要**: Skyframe 風 restartable SkyFunction — 評価中に依存発見したら再 schedule、結果を cache
- **リスク**: medium
- **未知**: Lean の `elab` で restart 可能性をどう表現するか、overhead
- **導出元**: D-3.1.1 (Static vs Dynamic dependency), D-5.2 Lean 表現の未解決, synthesis §6.1 P1
- **対応案**: Phase 3 可観測性フェーズで要検証

---

### 2.2 GA-C: Capability Gap（能力・機構の欠如）

#### GA-C1: agent-spec-lib（speclib）なし [umbrella]
- **種別**: umbrella Gap（GA-S1 + GA-C7 + GA-C9 他の成果物統合）
- **現状**: 公理系は Manifest/ に散在。domain-specific library としての packaging なし
- **必要**: CSLib 風の独立 Lean library として公理系・研究プロセスの型を体系化
- **リスク**: high（G3 CLEVER 0.621% の根本対策、Atlas speclib の instance）
- **未知**: CSLib 依存するか independent package にするか、Mathlib 依存の程度
- **導出元**: G3-1.6, G5-1-3 全体, handoff-§4.3 speclib 構想, synthesis §7.5 Phase 0
- **構成要素**: GA-C7 (SMT hammer), GA-C9 (EnvExt Auto-Register), GA-C22 (Call-site obligation), GA-C23 (PipelineMethods), GA-C26 (agent_verify tactic), GA-C28 (Functoriality), GA-C29 (Qualifier inference), GA-C31 (termination guard), GA-C34 (Spec lockfile), GA-C35 (auto-formalization), GA-C37 (Error Diagnosis), GA-S1-S20 (型群全般), GA-M14 (Self-hosting), GA-M15 (Repair Loop)
- **対応案**: G5-1 Section 3 の 3 層設計 + 8 週ロードマップ

#### GA-C2: Bidirectional Codec (Lean → gh issue) なし
- **現状**: Issue ↔ Lean 間の変換は LLM による手動メンテナンス
- **必要**: 片方向 export (Lean → gh issue) のみ、developmentFlag 付き leaf のみ Issue 化、冪等性保証、**round-trip invariant (`parse ∘ pretty = id`) の証明**、**functoriality（refines 関係保存）**
- **リスク**: high
- **未知**: Issue body の diff 管理、冪等性の content-hash 比較方式、round-trip 証明の stage 毎コスト
- **導出元**: E-4.2, A-3.3 U4 (TiddlyWiki SyncAdaptor), TyDD-F6 (Codec with round-trip proofs), TyDD-H3 (BiTrSpec bidirectional translation), synthesis §4.1 #10
- **対応案**: synthesis §3.3 外部接点層

#### GA-C3: Reverse Deps Index in artifact-manifest なし
- **現状**: D13 影響波及は forward 伝播のみ。reverse deps の index 保持なし
- **必要**: artifact-manifest に `invalidates: [artifactId]` field 追加、Skyframe 風 rdeps index
- **リスク**: medium
- **未知**: 更新コスト、index の consistency 保証
- **導出元**: D-4.3, D-4.4, synthesis §4.1 #11
- **対応案**: synthesis §4.3 artifact-manifest 拡張案

#### GA-C4: Semantic Hash なし
- **現状**: artifact-manifest に content hash なし。format 整形で再評価走る
- **必要**: `content_hash` (SHA-256) + `semantic_hash` (Lean normal form) の二系統、**spec normal forms によって意味論的に等価な DSL 記述を canonicalize**
- **リスク**: medium
- **未知**: Lean normal form 計算コスト、Repr structural hash との使い分け、canonical form の決定可能性
- **導出元**: D-3.1.2, Unison/Dhall, TyDD-H10 (Spec normal forms), synthesis §4.1 #12
- **対応案**: synthesis §4.3

#### GA-C5: Content-addressed artifact storage なし
- **現状**: artifact は git で管理、hash addressing なし
- **必要**: Nix/Bazel 風 CA store、metadata (git) と artifact (CA) の二層分離
- **リスク**: medium
- **未知**: 外部 storage 依存の運用コスト、git との整合
- **導出元**: B-3.2, D-1.2 Nix, synthesis §3.3
- **対応案**: artifact-manifest 拡張 + 別 storage backend

#### GA-C6: Append-only Event Log + Reducer なし
- **現状**: Issue body 編集で canonical state を上書き。event log なし
- **必要**: `inductive LeafEvent` で全変更を event として保存、`snapshot = events.foldl applyEvent initial`
- **リスク**: medium
- **未知**: event の同期と compaction、過去 log の参照効率
- **導出元**: E-3.1 A, E-4.1, synthesis §4.1 #8
- **対応案**: Fossil global/local 分離方式

#### GA-C7: SMT ハンマー統合（Boole / LeanHammer / Duper / Lean-Auto）なし
- **現状**: Lean 証明は手動 tactic のみ。SMT 自動放電なし
- **必要**: 上記いずれかを統合し Dafny 空証明 44.7% 相当の自動化を導入、**proof triage tactic chain** (`first | omega | simp | auto | sorry`)、**decidableBySMT predicate による auto-classification**（SMT で処理すべき spec vs 帰納で処理すべき spec の自動仕分け）
- **リスク**: high（G5-2 が示す Lean vs Dafny 差の本質）
- **未知**: hammer 性能 (Boole 33.3% vs Dafny 44.7%)、失敗モード、classification accuracy
- **導出元**: G5-1-1.6 LeanHammer, G5-2 全体, G4 AMO-Lean, TyDD-E4, TyDD-H2 (Proof triage), TyDD-F4 (decidableBySMT), TyDD-I6 (Duper), synthesis §7.10
- **対応案**: synthesis §7.10 Duper/Lean-Auto/Boole 統合

#### GA-C8: ProofWidget Visualizer なし
- **現状**: 研究 tree の可視化は ASCII 表示のみ
- **必要**: ProofWidgets4 で React による tree graph UI
- **リスク**: low
- **未知**: widget のスケーラビリティ（数千ノード）
- **導出元**: C-4.5, C-3.1 P3, synthesis §4.1 #13
- **対応案**: synthesis §3.1 Layer 4

#### GA-C9: EnvExtension Auto-Register なし
- **現状**: Sub-Issues テーブル更新を LLM が手動実施
- **必要**: `@[research_node]` attribute で EnvExtension に自動登録、集約処理はスキャン
- **リスク**: high（deterministic 負荷撤廃の核心）
- **未知**: attribute 実装の詳細、CompileM での集約処理
- **導出元**: C-3.1 P2, C-4.1, synthesis §4.1 #7
- **対応案**: synthesis §2b 機械化パターン

#### GA-C10: Typed Holes / LLM Prompt 生成なし
- **現状**: sorry の goal type を LLM プロンプトに変換する機構なし
- **必要**: sorry 位置の goal を構造化プロンプトに変換、LLM 提案を受け取る、**constrained decoding** (prefix automaton による文法制約で ill-typed token を masking) で compilation error を >50% 削減
- **リスク**: medium
- **未知**: LLM 統合のコスト、正答率、constrained decoding のオーバーヘッド
- **導出元**: TyDD-H4, TyDD-I5 (Mundler et al. 2025 PLDI, Constrained Decoding), G2-1.5 Lean Copilot, synthesis §2c
- **対応案**: Lean Copilot / APOLLO パターン + constrained decoding

#### GA-C11: Coverage Verification なし
- **現状**: Gap の見落とし検知なし。意味的重複検出もない
- **必要**: 構造的カバレッジ保証（SurveyG EA 相当）+ Unification modulo isomorphisms による意味的重複検出
- **リスク**: medium
- **未知**: Coverage 定義、false positive/negative 管理
- **導出元**: #599-Gap 6, #599-Gap 10 (比較検討フェーズ構造化の一部), TyDD-C3 Unification modulo isomorphisms
- **対応案**: 独立機能として実装

#### GA-C12: Perspective Generation の不在
- **現状**: Gap Analysis で視点が単一化しがち
- **必要**: 多視点生成モジュール（STORM persona_generator 風）
- **リスク**: high
- **未知**: 視点の網羅性保証
- **導出元**: #599-Gap 1, A-4.1 (Perspective Gen)
- **対応案**: `/research` Step 1b 拡張

#### GA-C13: Iterative Search Loop の不在
- **現状**: 単発の Gap 探索で終了、反復ループなし
- **必要**: 質問→検索→回答→フォローアップ質問のループ（STORM の会話シミュレーション）
- **リスク**: high
- **未知**: 反復回数の停止条件、コスト制約
- **導出元**: #599-Gap 2
- **対応案**: `/research` Step 1 に反復機構導入

#### GA-C14: Saturation Detection の不在
- **現状**: 情報利得の飽和検知なし
- **必要**: FIRE の cosine>0.9, tolerance=2 相当の飽和検出
- **リスク**: high
- **未知**: 飽和閾値の校正
- **導出元**: #599-Gap 3
- **対応案**: 埋め込み類似度による自動停止

#### GA-C15: Schema-Driven Extraction の不在
- **現状**: 精読は自由形式、スキーマ駆動でない
- **必要**: SPIRES 風のスキーマ駆動再帰的抽出（精度 30x 向上の実績）
- **リスク**: high
- **未知**: スキーマ定義のコスト
- **導出元**: #599-Gap 4, #599-Gap 9 (知識管理構造化の中核), #599-Gap 14 (精読品質保証の中核)
- **対応案**: LinkML YAML スキーマ + Lean 型との対応

#### GA-C16: Source Curation の不在
- **現状**: SEO コンテンツファーム混入のリスクあり
- **必要**: GPT-Researcher SourceCurator 風の専用フィルタ
- **リスク**: medium
- **未知**: フィルタ精度、ドメイン調整
- **導出元**: #599-Gap 5
- **対応案**: Phase 4 で実装

#### GA-C17: Citation & Attribution の弱さ
- **現状**: 引用帰属の構造化不十分
- **必要**: 全主張にソース帰属保証（Anthropic CitationAgent）
- **リスク**: medium
- **未知**: 引用正確性検証の自動化
- **導出元**: #599-Gap 7
- **対応案**: Phase 4 で実装

#### GA-C18: Effort Scaling の不在
- **現状**: breadth/depth 一律、タスク複雑度への適応なし
- **必要**: Anthropic Effort Scaling / dzhng breadth 半減の適応制御、**resource-aware compression** (`decompression_cost × usage_count ≤ budget` の MDL scoring)
- **リスク**: medium
- **未知**: 複雑度指標の定義、budget の単位
- **導出元**: #599-Gap 8, TyDD-H8 (Resource-aware compression)
- **対応案**: Phase 5 で実装

#### GA-C19: 検索戦略ガイダンスの不在（Proactive 戦略、3 層分類）
- **現状**: 検索戦略の体系的ガイダンスなし
- **必要**: Proactive / Reactive 戦略の使い分け、Foundation/Development/Frontier の 3 層分類
- **リスク**: medium
- **未知**: 戦略選択の判断基準
- **導出元**: #599-Gap 11
- **対応案**: `/research` Step 1 にガイダンス追加

#### GA-C20: 既存知識のウォームスタート機構の不在
- **現状**: 毎回ゼロから Gap Analysis
- **必要**: 既存知識から視点・Gap を導出する機構
- **リスク**: medium
- **未知**: 既存知識の構造化度合い
- **導出元**: #599-Gap 13
- **対応案**: Phase 2 で実装

#### GA-C21: マルチモーダルソース処理のガイダンスなし
- **現状**: テキストのみ、画像・表・コード等の扱い未定義
- **必要**: マルチモーダル対応の段階的ガイダンス（コード→画像→表）
- **リスク**: low
- **未知**: マルチモーダル LLM の成熟度
- **導出元**: #599-Gap 16
- **対応案**: Phase 後期 / スコープ後回し

#### GA-C22: Call-site obligation generation なし
- **現状**: Pipeline 各 stage (DSL→AST→Lean→SMT→Test→Code) で pre-check がない
- **必要**: 各 stage 境界で Z3 proof obligation を自動生成、caller-satisfies-callee-precondition
- **リスク**: medium
- **未知**: obligation の粒度、性能
- **導出元**: TyDD-B3 (Liquid Haskell core), G5-2 Pipeline 設計
- **対応案**: Pipeline 各 stage に pre-check 挿入

#### GA-C23: PipelineMethods record なし
- **現状**: Pipeline の stage swappability なし、固定実装
- **必要**: `structure PipelineMethods` で cutpoint function を record 化（Lean4Lean Methods パターン）
- **リスク**: medium
- **未知**: swap 時の consistency 保証
- **導出元**: TyDD-B5, Lean4Lean (G5-5)
- **対応案**: `/research` Worker の拡張

#### GA-C24: Symbolic Compiler の健全性・完全性証明なし
- **現状**: 自作 Pipeline の各 stage に証明なし
- **必要**: Cedar Symbolic Compiler 相当 — Pipeline 各 stage の健全性・完全性を Lean で証明
- **リスク**: medium
- **未知**: 証明コスト、証明済み stage の維持負荷
- **導出元**: G1-2.6 Symbolic Compiler パターン
- **対応案**: Phase 3 以降で優先 stage から適用

#### GA-C25: AMO-Lean `#compile_rules` パターン未適用
- **現状**: 公理系の theorem が実行可能 lint になっていない
- **必要**: `#compile_rules` で Lean 内ルールを実行可能形式にコンパイル、運用ツール自動化
- **リスク**: medium
- **未知**: compile_rules の成熟度、適用範囲
- **導出元**: G4-1.1, G4-3.2, handoff-§3.3
- **対応案**: Phase 4-5 で導入

#### GA-C26: agent_verify tactic / VcForSkill VCG なし
- **現状**: 新基盤独自の tactic / VCG が未定義
- **必要**: G5-1 が提案する `agent_verify` tactic と `VcForSkill` VCG の実装
- **リスク**: medium
- **未知**: tactic の抽象度、VCG の一般性
- **導出元**: G5-1-3.4 Tooling 層
- **対応案**: G5-1 ロードマップ Week 5-6 で実装

#### GA-C27: Trusted code 最小化なし（native_decide / reduceBool 回避）
- **現状**: `native_decide` / `reduceBool` の使用制約なし
- **必要**: 新基盤内で trusted code を最小化する運用ルール（Lean4Lean 非検証範囲の回避）
- **リスク**: medium
- **未知**: 性能影響（native_decide 回避でどれだけ遅くなるか）
- **導出元**: G5-5-2.2 divergences.md, synthesis §7.13
- **対応案**: lint / hook で使用禁止化

#### GA-C28: Pipeline Functoriality Test なし
- **現状**: Pipeline 各 stage (DSL → AST → Lean → SMT → Test → Code) の functor 性質が検証されない
- **必要**: `A ≤ B in DSL ⟹ lean_gen(A) ≤ lean_gen(B)` の functoriality test、Lean での結合性・単位律の証明
- **リスク**: medium
- **未知**: functoriality 検査のコスト、失敗時の diagnostics
- **導出元**: TyDD-H6 (Translation as refinement)
- **対応案**: 各 stage の transformation に functor instance を付与

#### GA-C29: Qualifier-based Refinement Inference なし
- **現状**: 精読スキーマや仕様の「よくあるパターン」を qualifier 集合として再利用する機構なし
- **必要**: Liquid Haskell の qualifier set 風 — DSL predicate を qualifier 集合から auto-infer
- **リスク**: medium
- **未知**: qualifier 辞書の構築方法、自動推論精度
- **導出元**: TyDD-I3 (Vazou et al. 2018)
- **対応案**: agent-spec-lib の qualifier library 構築

#### GA-C30: マルチエージェント協調機構なし
- **現状**: 複数 LLM session が同時に research tree を更新する際の merge 戦略未定義
- **必要**: Lamport 時計 / CRDT / git-bridge 風の協調機構、single-writer 制限回避（Nextflow LevelDB の轍を踏まない）
- **リスク**: medium
- **未知**: 実運用での協調頻度、競合解決コスト
- **導出元**: B-5.3-4 (マルチエージェント協調), E-3.1 B (Lamport / 因果順序), G1-2.1 (Cedar differential testing の並列性)
- **対応案**: Phase 5 以降で multi-instance 対応

#### GA-C31: Lean メタコード termination / compile-time 保証なし
- **現状**: 新基盤の自作 DSL elaborator は `partial def` を多用する可能性、無限ループで Lean server crash リスク
- **必要**: メタコードの stack depth 制限、fuel ベースの保護、停止性検査の補完機構
- **リスク**: medium
- **未知**: 既存 elaborator との統合、デバッグ困難性
- **導出元**: C-1.1 (macro/elab), C-5.1 Lean メタプロの一般的限界, C-3.3 避けるべき罠
- **対応案**: Phase 2 で fuel ベース guard 導入

#### GA-C32: Capability-separated import（prompt injection 対策）なし
- **現状**: 外部資料を研究 tree に取り込む際、外部 spec が local artifact を参照できる（prompt injection リスク）
- **必要**: Dhall 風の capability 制約 — Remote import は file/env にアクセス不可、外部 spec の作用範囲を型レベルで制限
- **リスク**: medium（L1 安全境界の深層防御）
- **未知**: capability 型の設計、既存 Lean import 機構への統合
- **導出元**: D-3.3.2 (Dhall capability-separated import), L1 safety
- **対応案**: Phase 2 検証層で import capability 制限

#### GA-C33: Aspect-style 直交解析 attachment なし
- **現状**: 全 ResearchNode に verifier 評価 / metric 計算 を後付けで attach する機構なし
- **必要**: Bazel aspects / Buck2 BXL 相当 — 既存 graph に直交する解析を後付け実装
- **リスク**: low
- **未知**: aspect の Lean での表現、既存解析との干渉
- **導出元**: D-3.3.4 (Bazel aspects = shadow graph)
- **対応案**: Phase 3 可観測性で aspect 機構導入

#### GA-C34: Spec snapshot lockfile なし
- **現状**: spec の依存バージョン・入力 hash・cmd を再現性保証付きで固定する lockfile がない
- **必要**: DVC `dvc.lock` / Cargo.lock 風の `agent-spec.lock` — stage 別 input/output hash + cmd を git tracked
- **リスク**: medium
- **未知**: spec 変更時の lockfile 更新戦略、diff の可読性
- **導出元**: B-1.8 DVC dvc.lock, synthesis §3.3
- **対応案**: artifact-manifest.json と並列で agent-spec.lock を git tracked 化

#### GA-C35: Research Node auto-formalization なし
- **現状**: 自然言語の Gap/Hypothesis を Lean ResearchNode 型に自動変換する機構なし
- **必要**: AlphaProof パターン — 自然言語 → Lean 形式化を LLM + Lean compiler で段階的検証
- **リスク**: medium（CLEVER 0.621% の現実を踏まえ、完全自動化は非現実的 → augment 戦略必須）
- **未知**: 人間介入頻度、失敗時の recovery、自然言語曖昧性の扱い
- **導出元**: G2-3.1 (AlphaProof), G3-2.3 Atlas augment, GA-M2 との統合
- **対応案**: Phase 2-3 で人間-LLM 共同編集機構として実装

#### GA-C36: Meaning-based search engine (ReProver 風) なし
- **現状**: 研究 tree 内の意味検索エンジンなし、premise selection ができない
- **必要**: BM25 + Transformer embedding による意味検索、関連 premise の自動提案
- **リスク**: low
- **未知**: embedding モデルの選定、index サイズ、検索遅延
- **導出元**: G5-4-2.1 ReProver (ByT5 + BM25), synthesis §7.12
- **対応案**: LeanDojo (GA-I6) 統合時に ReProver pipeline を採用

#### GA-C37: Error Diagnosis + unsat core 活用なし
- **現状**: proof/spec 失敗時の自動診断メカニズムなし、SMT 失敗理由が DSL ソース位置に mapping されない
- **必要**: named constraint + unsat core 抽出 → DSL source mapping（Recipe 3 パターン）、失敗原因の構造化 diagnose
- **リスク**: medium
- **未知**: unsat core の粒度、人間可読性への変換
- **導出元**: TyDD Recipe 3 (unsat core for spec debugging), G5-2 ATLAS Dafny (Z3 活用)
- **対応案**: GA-C7 (SMT ハンマー) 統合時に unsat core 活用

---

### 2.3 GA-M: Methodology Gap（手法・戦略の欠如）

#### GA-M1: CLEVER 風自己評価ベンチマークなし
- **現状**: 新基盤達成度の定量評価機構なし
- **必要**: 研究プロセス 10-20 サンプルで人手評価、最先端 LLM スコア記録
- **リスク**: high（G3 CLEVER が 0.621% の厳しい現実を示す）
- **未知**: サンプル選定基準、評価指標
- **導出元**: G3-1.2, G3-4.3, synthesis §7.6
- **対応案**: Phase 0 で構築

#### GA-M2: Atlas augment 戦略の具体化なし（X3DH 風 IDE）
- **現状**: 完全自動化前提の設計が残る
- **必要**: 人間-LLM 共同編集の境界明示、T6 人間権威強化、X3DH 風 IDE 設計
- **リスク**: high
- **未知**: 人間介入ポイントの最小化戦略
- **導出元**: G3-1.6 Atlas, G3-2.3, handoff-§4.3, synthesis §7.6
- **対応案**: IDE 設計 + user consent フロー

#### GA-M3: ATLAS-style Task 分解パターン未適用
- **現状**: `/research` Worker は単一タスク実行、ATLAS の 19K 訓練例分解手法なし
- **必要**: 研究ノードを小 subtask に分解、soundness/completeness lemma パターン、Qwen 7B LoRA fine-tune 参照
- **リスク**: medium
- **未知**: 分解粒度、Lean への適応性
- **導出元**: G5-2 全体, #599-Gap 10 (比較検討フェーズの task 分解形式), synthesis §7.10
- **対応案**: `/research` Worker 拡張

#### GA-M4: Verification-Guided Development (VGD) + Differential Random Testing 未適用
- **現状**: モデル/実装分離なし、DRT なし
- **必要**: Cedar VGD — Lean モデル (1/9.4) / Python/Rust 実装の分離、ランダム入力による差分検証（21 bug 検出実績）
- **リスク**: medium
- **未知**: 新基盤規模での適用コスト
- **導出元**: G1-2.1, G1-3.5, #599-Gap 14 (精読品質保証の DRT 的側面), synthesis §7.2
- **対応案**: 新基盤の全 stage に DRT 導入

#### GA-M5: LeanAgent-style lifelong learning なし
- **現状**: 過去研究知識の構造化再利用なし（MEMORY.md は平坦リスト）
- **必要**: 累積 DB + Fisher Information 重み付け、curriculum
- **リスク**: low（MVP 範囲外の可能性）
- **未知**: agent-manifesto スケールで有効か
- **導出元**: G5-4-4.2 LeanAgent, synthesis §7.12
- **対応案**: Phase 5 以降で検討

#### GA-M6: LeanProgress-style 残ステップ予測 + isOverthinking 判定なし
- **現状**: Gate 打ち切りは max_steps 固定、予測なし
- **必要**: DeepSeek Coder 1.3B 風の残ステップ予測モデル（75.8% 精度）、**isOverthinking** 判定（proof search の gain < threshold なら停止して assumed mark）
- **リスク**: low
- **未知**: 訓練データ量、転用可能性、threshold の校正
- **導出元**: G5-4-4.3 LeanProgress, TyDD-H9 (isOverthinking as proof budget), synthesis §7.12
- **対応案**: Gate 判定への応用

#### GA-M7: VeriSoftBench 4 層階層化 context 未活用
- **現状**: Lean import 依存のみ、4 層 (Library/Project/Local/Theorem) 意識なし
- **必要**: context を 4 層に分類し、各層の accessed_inputs を記録
- **リスク**: medium
- **未知**: 4 層境界定義、overhead
- **導出元**: G5-3-3.2 4 層階層, synthesis §7.11
- **対応案**: artifact-manifest 拡張

#### GA-M8: Schedule combinators + Fuel による Gate retry 戦略なし
- **現状**: Gate 判定は max retry 固定、戦略的 retry なし
- **必要**: Effect-TS Schedule 風の composable retry policy、fuel でコスト制御
- **リスク**: low
- **未知**: retry 戦略の妥当性
- **導出元**: TyDD-B6 (Effect-TS + Lean4Lean fuel)
- **対応案**: Gate 判定の拡張

#### GA-M9: AI × Lean 4-layer architecture 統合概念の独立化なし
- **現状**: tactic/theorem/proof-search/informal-formal hybrid が散在
- **必要**: G2-3.6 の 4-layer architecture を新基盤の統合設計概念として独立記述
- **リスク**: medium
- **未知**: 各 layer の責務境界
- **導出元**: G2-3.6, synthesis §7.3
- **対応案**: design document 作成

#### GA-M10: Domain-specific corpus 構築戦略なし
- **現状**: Mathlib 特化モデル（Goedel-V2）が Mathlib 外で 0% に崩壊する問題への対策なし
- **必要**: agent-manifesto 固有の corpus（研究プロセス、公理系、事例）を LeanDojo Benchmark 形式で構築
- **リスク**: medium
- **未知**: corpus 規模の必要下限
- **導出元**: G5-3-3.2, G5-4-4.4, synthesis §7.11-12
- **対応案**: Phase 4 以降で corpus 構築

#### GA-M11: Fixed-point iteration による LLM refine loop 収束証明なし
- **現状**: `S_{n+1} = Fix(LLM(S_n), Verify)` の収束が経験則ベース、形式証明なし
- **必要**: SpecSig lattice 上の monotone function として、Knaster-Tarski fixed-point theorem で収束を証明
- **リスク**: medium
- **未知**: LLM 出力が monotone であるための制約、実用レベルでの convergence speed
- **導出元**: TyDD-F7 (Fixed-point iteration on SpecSig lattice), TyDD-S2, TyDD-S4
- **対応案**: GA-S15 (SpecSig Lattice) 導入後に収束証明構築

#### GA-M12: 3-level Verify Strategy なし
- **現状**: Lean 検証は一本道（lake build のみ）、段階的 fallback なし
- **必要**: Minimal viable pipeline の 3 段階 — L1: pytest のみ / L2: +Z3 SMT / L3: +Lean full proof、`verify_level` パラメータで制御
- **リスク**: medium
- **未知**: 各 level の適用基準、level 間の互換性
- **導出元**: TyDD-H7 (Minimal viable pipeline)
- **対応案**: Phase 3 で verify_level DSL 導入

#### GA-M13: Hybrid Type Checking (static kernel + runtime cast) なし
- **現状**: Lean 型検査のみ、runtime cast fallback なし
- **必要**: Flanagan 2006 Hybrid TC — 静的に決定不能な制約を runtime に降ろし、pytest/実行時 assert で補完
- **リスク**: medium
- **未知**: static / dynamic の境界判定、cast failure の取扱
- **導出元**: TyDD-I1 (Flanagan 2006 POPL)
- **対応案**: GA-M12 (3-level Verify) と組み合わせて L2 で cast 導入

#### GA-M14: Self-hosting recursion 原則なし
- **現状**: 「speclib で speclib 自体の仕様を記述」する自己適用ループの確立なし
- **必要**: Pipeline が自分自身を spec する構造（D9 自己適用と同型）— spec system の spec を spec system で書く
- **リスク**: medium
- **未知**: self-hosting 到達時点の境界条件、鶏卵問題の解決方法
- **導出元**: TyDD-J5 (Self-hosting recursion), high-tokenizer Phase A-1 自己ホスティング達成 (spec_system_core.spec, dsl_spec.spec), D9 自己適用
- **対応案**: Phase 4 以降で agent-spec-lib 自身の spec を Lean で記述

#### GA-M15: APOLLO-style Repair Loop Engine なし
- **現状**: proof 失敗時の自動 repair loop が未定義
- **必要**: APOLLO パターン — 失敗分析 → repair 戦略生成 → 再試行の自動 engine、base LLM の sample efficiency 改善
- **リスク**: medium
- **未知**: repair 戦略のカバレッジ、無限ループ回避方式（GA-W7 termination と連携必須）
- **導出元**: G2-1.6 APOLLO (NeurIPS 2025, miniF2F 84.9%), G2-3.4
- **対応案**: Phase 2-3 で repair loop engine を実装、GA-C37 (Error Diagnosis) と連携

---

### 2.4 GA-E: Evaluation Gap（評価・計測の欠如）

#### GA-E1: Self-benchmark (manifesto を 24 番目 repo) なし
- **現状**: agent-manifesto 自体が評価対象となっていない
- **必要**: `lean-formalization/Manifest/` (55 axioms / 1670 theorems / 0 sorry) を VeriSoftBench 形式に packaging、D9 自己適用
- **リスク**: medium
- **未知**: 評価コスト（40,080 呼び出し推定）、curation 戦略
- **導出元**: G5-3-3.2, synthesis §7.11
- **対応案**: Phase 5 以降で実装

#### GA-E2: Phase 別メトリクス未定義
- **現状**: Phase 0-5 各段階で何を測るか未定義
- **必要**: proof_success_rate, dependency_depth, cross-module 検証成功率等を目標値付きで設計
- **リスク**: medium
- **未知**: 目標値の現実性
- **導出元**: G5-3-3.3 Phase 別メトリクス, synthesis §4.4
- **対応案**: G5-3 Section 3.3 表を直接採用

#### GA-E3: V6 (知識構造品質) / V7 (タスク設計効率) の新基盤適用未定義
- **現状**: V-metrics は既存ワークフロー前提
- **必要**: V6/V7 の before/after 比較、新しい構造での測定方法
- **リスク**: medium
- **未知**: 既存との連続性、測定自動化
- **導出元**: F-Section 5, `/metrics` skill
- **対応案**: Phase 3 (可観測性) で整備

#### GA-E4: judgmental rationale 評価指標なし
- **現状**: rationale 品質の評価方法なし
- **必要**: rationale の完全性・一貫性・更新履歴の構造的メトリクス
- **リスク**: medium
- **未知**: rationale 品質の定量化
- **導出元**: GA-S8, G2-4.1
- **対応案**: Judge G1-G5 に G6 「rationale 品質」を追加検討

#### GA-E5: 仕様等価性の自動検証なし
- **現状**: 同じ仕様の異なる表現が一致するか検証する機構なし
- **必要**: CLEVER 風の spec certification、Lean 定義的等価性 + semantic equivalence
- **リスク**: high（CLEVER 1/161 の根本困難）
- **未知**: そもそも可能か、人間介入度合い
- **導出元**: G3-1.2, G3-2.1, handoff-§4.3, CLEVER arxiv 2505.13938
- **対応案**: 完全自動化を諦め human-in-the-loop

#### GA-E6: パイプライン中間段階の可観測性の不在
- **現状**: end-to-end Judge 評価のみ、中間失敗が不可視
- **必要**: 各能力の独立評価指標（FIRE Failure Case 分析、SurveyG ablation 方式）
- **リスク**: high（P4 可観測性の根幹、全 Deep Research 系で未整備）
- **未知**: 各段階の品質指標
- **導出元**: #599-Gap 12, synthesis §6.2 P0
- **対応案**: Phase 3 可観測性で中核導入

#### GA-E7: 外部ベンチマーク比較（FLTEval / miniF2F / DafnyBench / CLEVER / VeriBench）なし
- **現状**: 新基盤を外部ベンチマークに照合する戦略なし
- **必要**: FLTEval (Leanstral 26.3), miniF2F (Goedel 90.4%), DafnyBench, CLEVER, VeriBench, VeriSoftBench に対するスコア取得
- **リスク**: medium
- **未知**: Benchmark 適用コスト、訓練データリーク
- **導出元**: G2 全体, G3 全体, G5-2 DafnyBench, G5-3 VeriSoftBench
- **対応案**: Phase 5 評価で実施

#### GA-E8: Time-to-proof メトリクスなし
- **現状**: proof 完成までの時間を計測する仕組みなし
- **必要**: 各 research node の proof obligation 完了時間の追跡
- **リスク**: low
- **未知**: 時間計測の粒度
- **導出元**: G2 benchmarks (Leanstral, Aristotle 等で採用), VeriSoftBench r=3
- **対応案**: metrics skill 拡張

#### GA-E9: Lean compile 性能のスケール未測定
- **現状**: 数千ノード規模の Lean tree compile 時間が不明
- **必要**: Lean elaborator の scaling ベンチマーク、incremental compile の限界把握
- **リスク**: medium
- **未知**: 上限ノード数、lake の parallel build 効果、.olean cache miss rate
- **導出元**: A-Q4 (大規模 graph の Lean compile 性能), B-5.3-1 Lean tree スケール, D-3.1.3 Lake 規模, D-5.2.1 Semantic hash コスト
- **対応案**: Phase 0 着手時にベンチマーク実施

#### GA-E10: Benchmark 適用範囲制約 + 訓練データリーク対策なし
- **現状**: agent-manifesto が "verified software" とは性質が異なる（research process が対象）。既存 Lean benchmark（miniF2F, VeriSoftBench 等）の適用範囲が不明確
- **必要**: benchmark 適用範囲の明示、**訓練データリーク回避**（Goedel-Prover-V2 が Mathlib 外で 0% 崩壊した原因と同じ失敗を避ける）
- **リスク**: low
- **未知**: 公開 benchmark との重複度、データリーク検出方法
- **導出元**: G5-3-Sec 4 (agent-manifesto と verified software の違い、訓練データリーク)
- **対応案**: Phase 5 評価時に scope boundary を明示

---

### 2.5 GA-I: Integration Gap（既存資産との統合の欠如）

#### GA-I1: artifact-manifest.json に assumption refs layer なし
- **現状**: artifact-manifest は axiom refs のみ
- **必要**: `{assumptions: [{id, refs, temporalValidity}]}` の layer 追加
- **リスク**: medium
- **未知**: schema migration、既存 manifest との後方互換
- **導出元**: F-Section 2 重複 1, synthesis §3.3
- **対応案**: conservative extension

#### GA-I2: /trace の assumption-level 拡張なし
- **現状**: manifest-trace は axiom 単位のみ
- **必要**: `manifest-trace coverage --assumption` 等の CLI 拡張
- **リスク**: low
- **未知**: 既存 coverage 計算との整合
- **導出元**: F-Section 2.2, synthesis §3.3
- **対応案**: /trace skill 拡張

#### GA-I3: /ground-axiom の S-type assumption 対応なし
- **現状**: ground-axiom は T/E axiom 対象
- **必要**: S-type assumption も Foundation/ 対応表に追加、grounding 拡張
- **リスク**: low
- **未知**: S-type の数理根拠識別
- **導出元**: F-Section 5, synthesis §4.4 Phase 2
- **対応案**: /ground-axiom skill 拡張

#### GA-I4: propagate.sh の assumption-aware 化なし
- **現状**: propagate.sh は Issue 依存グラフのみ
- **必要**: assumption propagation 対応、affected 計算拡張
- **リスク**: medium
- **未知**: assumption ↔ Issue の対応
- **導出元**: F-Section 3.3, synthesis §3.3
- **対応案**: propagate.sh 拡張

#### GA-I5: CSLib / LeanHammer / LeanDojo 依存未追加
- **現状**: lakefile.lean は Mathlib のみ
- **必要**: `require CSLib`, `require LeanHammer`, `require LeanDojo` を lakefile に追加
- **リスク**: low
- **未知**: バージョン pin、ビルド時間増加
- **導出元**: G5-1-3.2, G5-1-3.5, G5-4-4.1
- **対応案**: Phase 0 で実施

#### GA-I6: LeanDojo API 統合なし
- **現状**: LeanDojo 未使用、Lean trace は lake build のみ
- **必要**: LeanDojo Python API を観測レイヤとして採用、trace() で manifest を traced dataset 化
- **リスク**: low
- **未知**: Python 依存追加、lean-version 制約
- **導出元**: G5-4-4.1 方針 A, synthesis §7.12
- **対応案**: サブモジュール統合

#### GA-I7: high-tokenizer SpecSystem の移植/再定義なし
- **現状**: SpecSystem.Basic.lean (62 行, 0 sorry) は外部プロジェクト
- **必要**: (a) lakefile で external package として require、または (b) 62 行を再定義
- **リスク**: medium
- **未知**: 依存管理方式、アップストリーム追従
- **導出元**: C-1.8, synthesis 前提資産
- **対応案**: Phase 0 で (b) 再定義を推奨

#### GA-I8: 既存 3 重複の共通抽出なし
- **現状**: Gate 判定 / 修正ループ / 依存グラフ走査が 3 系統に散在
- **必要**: `gate-judgment-template.sh` / `repair-loop-engine.sh` / `graph-traverse.sh` に抽出
- **リスク**: low
- **未知**: 抽出対象の正確な境界
- **導出元**: F-Section 3 重複 1-3
- **対応案**: 新基盤移行と同時に DRY 化

#### GA-I9: 既存テストカバレッジの新基盤対応なし
- **現状**: Phase 1-5 テストは既存ワークフロー対象
- **必要**: assumption system, research tree, Lean formalization, integration の 15-20 個テスト
- **リスク**: medium
- **未知**: テスト実行時間、CI 統合
- **導出元**: F-Section 5
- **対応案**: Phase 2 で追加

#### GA-I10: Rust/Python 実装層の分離統合なし
- **現状**: Lean と Python Pipeline が直結
- **必要**: VGD Cedar 方式 — Lean モデル (軽量) と Rust/Python 実装 (重量) の分離、DRT
- **リスク**: medium
- **未知**: 実装言語の選択（Rust vs Python）
- **導出元**: G1-2.1, G1-3.5
- **対応案**: Phase 2-3 で層分離

#### GA-I11: CI/CD hook の新基盤対応なし
- **現状**: 既存 CI は旧ワークフロー前提
- **必要**: 新基盤向け lake build / lint / test / deploy hook
- **リスク**: medium
- **未知**: CI 実行時間（新基盤スケールで）
- **導出元**: F-Section 3/4
- **対応案**: Phase 2 で CI 整備

#### GA-I12: `.claude/hooks/` の新基盤対応なし
- **現状**: 既存 hook は Issue ベース前提（worktree-guard.sh 等）
- **必要**: 新基盤の Lean canonical 前提に改訂
- **リスク**: medium
- **未知**: 既存 hook の修正範囲
- **導出元**: F-Section 3 既存 hooks
- **対応案**: Phase 3 で hook 群の一斉更新

#### GA-I13: Pantograph への移行統合なし
- **現状**: LeanDojo v1 想定、Pantograph (Docker-free) 未考慮
- **必要**: LeanDojo-v2 / Pantograph を直接採用、Docker 依存回避
- **リスク**: low
- **未知**: Pantograph の成熟度、未公開機能
- **導出元**: G5-4-2.5 Pantograph
- **対応案**: GA-I6 統合時に Pantograph 優先

#### GA-I14: JSON-LD / RO-Crate bidirectional 変換なし
- **現状**: Lean tree → JSON-LD への schema-preserving 変換なし
- **必要**: Provenance Run Crate として export 可能化、WorkflowHub / Galaxy との interop
- **リスク**: low
- **未知**: Lean ↔ JSON-LD lossless mapping の完全性
- **導出元**: B-4.7 (RO-Crate 互換 export), B-5.3-2 JSON-LD bidirectional 変換, synthesis §3.3
- **対応案**: Phase 5 以降で Lean meta-program として実装

---

### 2.6 GA-T: Transition Gap（移行・退役戦略の欠如）

#### GA-T1: #599 を新基盤上で再起動するパスなし
- **現状**: #599 は「新基盤待機」コメント投稿済だが、再起動手順未定義
- **必要**: 16 Gap の Lean 文書化、Phase マッピングの型化、再起動手順書
- **リスク**: medium
- **未知**: 既存 Verifier 検証結果の扱い
- **導出元**: handoff-599-pending-rebase.md
- **対応案**: 新基盤完成後の dogfooding

#### GA-T2: Phase 0 (speclib 構築) のロードマップ未確定
- **現状**: agent-spec-lib 構築は概念提案のみ
- **必要**: G5-1 Section 3.5 の 8 週ロードマップを採用、**実装順序**（Validators → Estimators → Producers → Core の power-to-weight ratio 降順、TyDD-H11）
- **リスク**: medium
- **未知**: リソース割当、LeanHammer 成熟度への依存
- **導出元**: G5-1-3.5, TyDD-H11 (Spec coding → implementation order), synthesis §7.5
- **対応案**: G5-1 ロードマップ採用 + H11 順序ルール

#### GA-T3: 既存 GitHub Issue → Lean canonical の migration 戦略なし
- **現状**: 既存 Issue (#599 など) の Lean 文書への変換方法未定義
- **必要**: 一括 migration スクリプト or 手動 cherry-pick の判断基準
- **リスク**: low
- **未知**: 変換の自動化度、情報損失
- **導出元**: E-4.2, synthesis §7.5
- **対応案**: Phase 5 (bidirectional codec) で実施

#### GA-T4: /generate-plugin の新基盤向け再設計なし
- **現状**: D17 state machine は plugin 規模向け
- **必要**: Phase/Step 定義の再設計（research tree validation が derive phase を precede）
- **リスク**: low
- **未知**: 既存 /generate-plugin 利用事例の影響
- **導出元**: F-Section 2.3 /generate-plugin
- **対応案**: Phase 3-4 で対応

#### GA-T5: rollback 戦略なし（新基盤が失敗した場合）
- **現状**: 新基盤構築失敗時の退却路未定義
- **必要**: Phase ごとの判断基準 (Go/No-Go)、既存ワークフローへの復帰手順
- **リスク**: medium
- **未知**: 判断基準の客観性
- **導出元**: 原則 T6, 新リサーチ
- **対応案**: Phase 1 完了時に最初の Go/No-Go

#### GA-T6: MEMORY.md の Lean 化 migration なし
- **現状**: 既存 MEMORY.md は平坦 markdown リスト
- **必要**: Lean 型として structured knowledge に移行、feedback/project/reference/user の型化
- **リスク**: low
- **未知**: 既存メモリとの後方互換、auto-memory 機構との統合
- **導出元**: CLAUDE.md auto memory, F-Section 2
- **対応案**: Phase 4 で実施

#### GA-T7: Python 依存 (uv, pyproject) 追加管理なし
- **現状**: agent-manifesto は Lean のみ、Python 依存なし
- **必要**: LeanDojo / ReProver 統合用に uv + pyproject.toml 追加、version pin
- **リスク**: low
- **未知**: 既存ビルドへの影響
- **導出元**: G5-4 LeanDojo, GA-I6
- **対応案**: GA-I6 と併せて Phase 3 で導入

#### GA-T8: Lean バージョン管理戦略なし
- **現状**: Lean バージョン pin 戦略が未定（Cedar は v4.7.0 固定、CSLib は別バージョン、Lean4Lean は mathlib rev 固定）
- **必要**: lean-toolchain 固定ポリシー、依存 library（CSLib, LeanHammer, Mathlib, Lean4Lean 等）とのバージョン互換性マトリクス、upgrade 戦略
- **リスク**: low
- **未知**: 外部 dependency の upgrade cadence、互換性破壊の頻度
- **導出元**: G1-1.1 (Cedar Lean v4.7.0 pinning), G5-5 (Lean4Lean 進展との同期), C-1.8 (Lake), synthesis §3.3
- **対応案**: Phase 0 で lean-toolchain 固定 + 依存マトリクス文書化

---

### 2.7 GA-W: Warning / Anti-Pattern（実装時に避けるべき罠）

Gap（解決すべき欠落）とは性質が異なり、「新基盤実装時に意識して避けるべきパターン」を独立カテゴリとして整理する。各 Warning は関連する Gap に結び付けて管理する。

#### GA-W1: SMT solver silent false-positive
- **内容**: SMT 未対応 predicate を silent に skip すると誤った PASS が生まれる
- **重大度**: Critical
- **対応**: 未対応 predicate には明示的 "unparseable" status を返し、blame tracking で DSL 位置を追跡
- **出典**: TyDD-G1 + Paper 4 (Gradual Metaprogramming)
- **関連 Gap**: GA-C22 (Call-site obligation)

#### GA-W2: Lean-Auto Z3 backend = "smart sorry"
- **内容**: Z3/CVC5/Zipperposition backend は proof reconstruction なし。kernel 検証を通らないため「smart sorry」に等しい
- **重大度**: High
- **対応**: 本番証明は **Duper only**（kernel-verified）を使用、Z3 は探索用に限定
- **出典**: TyDD-G2 (Lean-Auto S2)
- **関連 Gap**: GA-C7 (SMT ハンマー統合)

#### GA-W3: Over-specification threshold
- **内容**: Z3 >5s 経過、Lean >3 lemma 展開で立ち止まる仕様は over-specified
- **重大度**: Medium
- **対応**: 仕様を簡素化するか `assume` パターンで降格（TyDD-S4 Principle 4）
- **出典**: TyDD-G3
- **関連 Gap**: GA-C18 (Effort Scaling)

#### GA-W4: sorry accumulation without tracking
- **内容**: `sorry` が蓄積されて誰も気づかない
- **重大度**: Medium
- **対応**: CI で sorry count grep、**threshold=10** を超えたら fail。AssumptionTracker で管理（Recipe 12）
- **出典**: TyDD-G4
- **関連 Gap**: GA-I9 (テストカバレッジ)

#### GA-W5: Python Result types vs standard exceptions
- **内容**: Python で Result 型を強制すると生態系が合わない
- **重大度**: Medium
- **対応**: Python 側は標準 raise/except を使用、Effect-TS 風の Result を持ち込まない
- **出典**: TyDD-G5
- **関連 Gap**: GA-I10 (Rust/Python 実装層)

#### GA-W6: DSL error messages in Lean/Z3 terms
- **内容**: DSL 書いたユーザに Lean/Z3 の内部語彙でエラーが返される
- **重大度**: Medium
- **対応**: エラーを DSL ソース位置 + DSL 語彙にマッピング
- **出典**: TyDD-G6
- **関連 Gap**: GA-C2 (Bidirectional Codec)

#### GA-W7: メタコードの termination 保証なし
- **内容**: `partial def` で無限ループすると Lean server crash
- **重大度**: High
- **対応**: fuel ベース保護、stack depth 制限
- **出典**: C-5.1 (Lean メタプロの一般的限界)
- **関連 Gap**: GA-C31 (Lean メタコード compile-time 保証)

#### GA-W8: Aesop safe rule で metavariable assign → 90% 降格
- **内容**: `safe` ルールが metavariable を assign すると自動的に `unsafe` 90% に降格
- **重大度**: Medium
- **対応**: safe rule 設計時に metavariable 生成を避ける、明示的に unsafe にする
- **出典**: C-3.2 (ベストプラクティス), TyDD-L4 (Liquid Haskell bugs)
- **関連 Gap**: GA-C7 (SMT ハンマー統合)

#### GA-W9: ProofWidgets widget 1 個変更で全再ビルド
- **内容**: Lake issue #86 — widget を 1 個修正すると全 widget 再ビルド
- **重大度**: Low
- **対応**: 開発フロー設計時に widget を細分化、CI で差分ビルド活用
- **出典**: C-3.3 (避けるべき罠), Lake issue #86
- **関連 Gap**: GA-C8 (ProofWidget Visualizer)

#### GA-W10: Verso cross-document cross-reference は experimental
- **内容**: Verso の cross-doc reference は未安定、将来 breaking change の可能性
- **重大度**: Low
- **対応**: 重要依存にしない、または breaking を受容する設計
- **出典**: C-5.2 (Verso の現状リスク)
- **関連 Gap**: GA-I5 (CSLib/LeanHammer/LeanDojo 依存)

---

## 3. Tag Index Matrix

### 3.1 カテゴリ別集計（Pass 6 最終版）

#### Gap 集計 (解決すべき欠落)

| Tag | 件数 | high | medium | low | umbrella |
|---|---|---|---|---|---|
| GA-S (Structure) | 20 | 7 (**S1**, S2-S6, S8) | 11 (S7, S9-S13, S15-S18, S20) | 2 (S14, S19) | S1 |
| GA-C (Capability) | 37 | 8 (**C1**, C2, C7, C9, C12-C15) | 24 (C3-C6, C10-C11, C16-C20, C22-C26, C28-C32, C34, C35, C37) | 5 (C8, C21, C27, C33, C36) | C1 |
| GA-M (Methodology) | 15 | 2 (M1, M2) | 11 (M3, M4, M7-M15) | 2 (M5, M6) | — |
| GA-E (Evaluation) | 10 | 2 (E5, E6) | 6 (E1-E4, E7, E9) | 2 (E8, E10) | — |
| GA-I (Integration) | 14 | 0 | 7 (I1, I4, I7, I9, I10, I11, I12) | 7 (I2, I3, I5, I6, I8, I13, I14) | — |
| GA-T (Transition) | 8 | 0 | 4 (T1, T2, T5, T6) | 4 (T3, T4, T7, T8) | — |
| **Gap 合計** | **104** | **19** | **63** | **22** | 2 |

(注: umbrella Gap は high 枠に算入。構成要素とは別カウント。GA-C15 は SPIRES 30x 精度向上という強い根拠から high 分類 — synthesis §2a に位置付け)

**検算**: 20+37+15+10+14+8 = 104 ✓ / 7+8+2+2+0+0 = 19 ✓ / 11+24+11+6+7+4 = 63 ✓ / 2+5+2+2+7+4 = 22 ✓

#### Warning 集計 (避けるべき罠、別建て)

| Tag | 件数 | Critical | High | Medium | Low |
|---|---|---|---|---|---|
| GA-W (Warning) | 10 | 1 (W1) | 2 (W2, W7) | 5 (W3, W4, W5, W6, W8) | 2 (W9, W10) |

**総計 (Gap + Warning)**: **114 項目**

#### スコープ外確定 (Pass 6 で検討後、追加見送り)

| 候補 | 理由 |
|---|---|
| GA-E11 (Human-in-the-loop metrics) | GA-M2 augment で実質カバー、運用フェーズ課題 |
| GA-T9 (CSLib upstream 貢献戦略) | Phase 5 以降の発展課題、MVP 不要 |
| Implementation2Spec / InputOutput2Spec / InterFramework (Atlas 未実現 3 projects) | 新基盤 MVP スコープ外、将来の研究貢献候補 |

### 3.2 導出元別クロスリファレンス

| 導出元 | 参照 Gap |
|---|---|
| A (知識グラフ) | GA-S1, GA-S2, GA-S5, GA-C2, GA-C8, GA-C11 |
| B (Provenance) | GA-S1, GA-S3, GA-S6, GA-C4, GA-C5, GA-C34, GA-E1 |
| C (Lean メタプロ) | GA-S1, GA-C8, GA-C9, GA-C10 |
| D (Build Graph) | GA-C3, GA-C4, GA-C5, GA-S20, GA-C32, GA-C33 |
| E (Issue Tracker) | GA-S7, GA-C2, GA-C6, GA-T3 |
| F (内部資産) | GA-S9, GA-I1-I9, GA-T4, GA-S12-S14 |
| G1 (Cedar) | GA-M4, GA-E1, GA-C24 |
| G2 (AI × Lean) | GA-C10, GA-E4, GA-S8, GA-M9, GA-C35, GA-M15 |
| G3 (仕様生成) | GA-C1, GA-C7, GA-M1, GA-M2, GA-E5, GA-S8 |
| G4 (メタ視点) | GA-C7, GA-C25 |
| G5-1 (CSLib) | GA-C1, GA-C7, GA-I5, GA-T2, GA-C26 |
| G5-2 (ATLAS) | GA-C7, GA-M3, GA-C22 |
| G5-3 (VeriSoftBench) | GA-E1, GA-E2, GA-M7, GA-M10 |
| G5-4 (LeanDojo) | GA-I6, GA-M5, GA-M6, GA-I13, GA-C36 |
| G5-5 (Lean4Lean) | GA-C27, GA-C23 |
| TyDD-B | GA-S11 (B4), GA-C22 (B3), GA-C23 (B5), GA-M8 (B6) |
| TyDD-C | GA-C10 (H4 via C2 constrained decoding), GA-C11 (C3) |
| TyDD-F | GA-S15 (F2), GA-S16 (F3), GA-S17 (F8), GA-C7 (F4), GA-C2 (F6), GA-M11 (F7) |
| TyDD-H | GA-S16 (H1), GA-C7 (H2), GA-C2 (H3), GA-C10 (H4), GA-C28 (H6), GA-M12 (H7), GA-C18 (H8), GA-M6 (H9), GA-C4 (H10), GA-T2 (H11) |
| TyDD-I | GA-M13 (I1), GA-S18 (I2), GA-C29 (I3), GA-S16 (I4), GA-C10 (I5), GA-C7 (I6), GA-S19 (I7) |
| TyDD-G (Anti-Pattern) | GA-W1 (G1), GA-W2 (G2), GA-W3 (G3), GA-W4 (G4), GA-W5 (G5), GA-W6 (G6) |
| TyDD-J | GA-M14 (J5 Self-hosting), 他 J1-J4, J6-J7 は GA-M/GA-E で部分参照 |
| TyDD-L | L1-L11 は GA-C7, GA-S13, GA-C29, GA-S16, GA-I10, GA-C4 等で個別対応済 |
| handoff | GA-T1, GA-C1, GA-S5, GA-S8, GA-E5 |
| #599 前リサーチ | GA-C11〜C21 (11 件, #1-#7, #11, #13, #16), GA-S10 (#15), GA-E6 (#12) = 13 件明示マッピング + #9/#10/#14 は GA-S1 / GA-S3 / GA-M3 / GA-M4 / GA-C11 / GA-C15 / GA-C37 に構造的吸収 |

### 3.3 リスク降順ランキング（high 19 件、Pass 7 + Verifier Round 1 修正版）

実装着手順序の基礎:

1. **GA-S1**: 研究 tree Lean 型表現（umbrella） — 全ての起点
2. **GA-S2**: FolgeID 型と半順序
3. **GA-S3**: Provenance Triple
4. **GA-S4**: Edge Type Inductive
5. **GA-S5**: Retirement first-class — 独自貢献
6. **GA-S6**: Failure first-class — 独自貢献
7. **GA-S8**: Rationale 型 — 最重要 unresolved (CLEVER)
8. **GA-C1**: agent-spec-lib（umbrella）
9. **GA-C2**: Bidirectional Codec (round-trip 証明付)
10. **GA-C7**: SMT ハンマー統合 — Dafny 44.7% 差の対策 (+ proof triage + decidableBySMT)
11. **GA-C9**: EnvExtension Auto-Register — deterministic 負荷撤廃
12. **GA-C12**: Perspective Generation
13. **GA-C13**: Iterative Search Loop
14. **GA-C14**: Saturation Detection
15. **GA-C15**: Schema-Driven Extraction — SPIRES 30x 精度向上
16. **GA-M1**: CLEVER 風自己評価
17. **GA-M2**: Atlas augment 戦略（X3DH IDE）
18. **GA-E5**: 仕様等価性自動検証 — CLEVER 根本困難
19. **GA-E6**: 中間段階可観測性 — P4 可観測性の根幹

medium-low リスク Gap の実装優先度は Phase 1-3 の型基盤期に S15/S16/S19、Phase 2 の検証期に M11/M12/M13、Phase 3 の可観測期に C28/C29/S17/S18 を想定。

---

## 4. 4 パス収束判定

### パス 1 (2026-04-17 初版)

- 新規識別: **46 Gap**
- カテゴリ分布: S×9, C×11, M×7, E×5, I×9, T×5
- 収束状態: 未収束

### パス 2 (2026-04-17 改訂)

**改訂内容**:
1. 全 tag に `GA-` 接頭辞を付加（agent-manifesto E/T、TyDD 全 tag との衝突撤廃）
2. GA-S1, GA-C1 を umbrella Gap として明示、構成要素への相互参照追加
3. **33 件の新規 Gap 追加**:
   - #599 前リサーチ 16 Gap 統合: GA-C11〜C21（11 件、うち C11 は #599-Gap 6 Coverage Verification 由来）, GA-S10 (#599-Gap 15)（1 件）, GA-E6 (#599-Gap 12)（1 件） = **13 件**
     - 明示マッピング: #1→C12, #2→C13, #3→C14, #4→C15, #5→C16, #6→C11, #7→C17, #8→C18, #11→C19, #12→E6, #13→C20, #15→S10, #16→C21
     - **構造的吸収**（独立 GA- なし、既存へ統合）: #9 (知識管理構造化) → GA-S1 umbrella + GA-S3 Provenance + GA-C15 Schema / #10 (比較検討フェーズ) → GA-M3 Task 分解 + GA-M4 VGD + GA-C11 Coverage / #14 (精読品質保証) → GA-C15 Schema + GA-M4 DRT + GA-C37 Error Diagnosis
   - TyDD Recipe 未参照: GA-S11 (B4), GA-C22 (B3), GA-C23 (B5), GA-M8 (B6) = 4 件
   - 内部資産: GA-S12 (PropositionId), GA-S13 (SelfGoverning), GA-S14 (EnforcementLayer) = 3 件
   - G1-G5 サーベイ細部: GA-C24 (Symbolic Compiler 証明), GA-C25 (AMO compile_rules), GA-C26 (agent_verify tactic), GA-C27 (trusted code 最小化), GA-M9 (4-layer architecture), GA-M10 (domain-specific corpus) = 6 件
   - 統合・実装層: GA-I10 (Rust/Python 分離), GA-I11 (CI/CD hook), GA-I12 (.claude/hooks 更新), GA-I13 (Pantograph) = 4 件
   - 評価層: GA-E7 (外部ベンチマーク比較), GA-E8 (time-to-proof) = 2 件
   - 移行層: GA-T6 (MEMORY migration), GA-T7 (Python dep) = 2 件
4. 既存 Gap の導出元充実（GA-S1, GA-S5, GA-S6, GA-S8, GA-C1, GA-C7, GA-E5 の 7 件改訂）

**パス 2 結果**:
- 総計: **79 Gap**
- カテゴリ分布: S×14, C×27, M×10, E×8, I×13, T×7
- 収束状態: 未収束（パス 3 で追加探索、パス 4 で 0 件になり収束判定）

### パス 3 (2026-04-17 改訂)

**改訂内容**: TyDD サーベイの F1-F8, H1-H11, I1-I7 を 79 Gap に照合し、未参照の 10 件を新規追加。既存 Gap 6 件に導出元追補。

**追加 Gap 10 件**:
- **TyDD-F 由来** (4 件): GA-S15 (F2 Lattice), GA-S16 (F3 Multiplicity), GA-S17 (F8 FiberedTypeSpec), GA-M11 (F7 Fixed-point)
- **TyDD-H 由来** (2 件): GA-C28 (H6 Functoriality), GA-M12 (H7 3-level Verify)
- **TyDD-I 由来** (4 件): GA-M13 (I1 Hybrid TC), GA-S18 (I2 `?` Gradual), GA-C29 (I3 Qualifier Inference), GA-S19 (I7 Phantom scope)

**導出元追補** 6 件:
- GA-C2: TyDD-F6 (Codec round-trip), TyDD-H3 (BiTrSpec) 追加
- GA-C4: TyDD-H10 (Spec normal forms) 追加
- GA-C7: TyDD-H2 (Proof triage), TyDD-F4 (decidableBySMT), TyDD-I6 (Duper) 追加
- GA-C10: TyDD-I5 (Constrained decoding) 追加
- GA-C18: TyDD-H8 (Resource-aware budget) 追加
- GA-M6: TyDD-H9 (isOverthinking) 追加
- GA-T2: TyDD-H11 (Implementation order) 追加

**スコープ外確定**:
- TyDD-H5 CompressedTerm: high-tokenizer 固有の研究課題、新基盤スコープ外

**パス 3 結果**:
- 総計: **79 → 89 Gap** (+10)
- カテゴリ分布: S×19, C×29, M×13, E×8, I×13, T×7
- 収束状態: 未収束（追加あり）

### パス 4 (2026-04-17 改訂)

**改訂内容**: 未照合エリア (TyDD-G/J/L/M, サーベイ Section 5) を走査し、8 件の Gap 追加 + Warning カテゴリ新設 (10 件)。

**追加 Gap 8 件**:
- **TyDD-J5 由来** (1 件): GA-M14 (Self-hosting recursion)
- **サーベイ Section 5 由来** (7 件):
  - GA-S20 (Dynamic dependency): D-3.1.1, D-5.2
  - GA-C30 (マルチエージェント協調): B-5.3-4
  - GA-C31 (Lean メタコード termination): C-5.1
  - GA-E9 (Lean compile 性能スケール): A-Q4, B-5.3-1, D-3.1.3
  - GA-E10 (Benchmark 適用範囲 + データリーク): G5-3-Sec 4
  - GA-I14 (JSON-LD / RO-Crate 変換): B-4.7, B-5.3-2
  - GA-T8 (Lean バージョン管理戦略): G1-1.1, G5-5

**Warning カテゴリ新設 GA-W1〜W10 (10 件)**:
- **TyDD-G1-G6 由来**: GA-W1〜W6
- **サーベイ直接抽出**: GA-W7 (メタコード termination) / W8 (Aesop safe rule) / W9 (ProofWidgets rebuild) / W10 (Verso experimental)

**明確にスコープ外とした項目**:
- TyDD-D1-D5 (Types=Compression quotes): 理論的根拠、Gap 直結せず
- TyDD-S1-S8 (Source summaries): Recipe 参照元、個別 Gap 不要
- TyDD-N1-N4 (TyDe 2025 papers deep dive): G1-G5 で間接参照済
- TyDD-L8-L10 (Combinatorics / Conatural / mutual recursion): agent-manifesto スコープ外
- G2-4.3 (Combinatorics 領域の弱さ): agent-manifesto はそれ自体を対象としない

**パス 4 結果**:
- Gap 総計: **89 → 97 Gap** (+8)
- Warning: 0 → **10 件** (新設)
- **総項目**: **107 項目**
- カテゴリ分布 (Gap): S×20, C×31, M×14, E×10, I×14, T×8
- high リスク Gap: 18（Pass 2 から不変、追加はすべて medium-low）
- 収束状態: 未収束（追加あり）

### パス 5 (2026-04-17 最終走査)

**改訂内容**: 全 107 項目 (Pass 4 時点 97 Gap + 10 Warning) を再走査し、最終確認。検出された修正と追加。

**Pass 5 検出事項**:

1. **追加 Gap 2 件** (サーベイ 04 D Section 3.3 Unconverged 領域から抽出):
   - GA-C32: Capability-separated import (prompt injection 対策) — D-3.3.2 (Dhall)
   - GA-C33: Aspect-style 直交解析 attachment — D-3.3.4 (Bazel aspects)

2. **Tag Index Matrix 集計の誤り修正**:
   - GA-S の medium 件数を「12」→ **11** に修正（S15-S18 + S20 を正しく medium 算入）
   - GA-S の low 件数を「1」→ **2** に修正（S14, S19）
   - GA-C の medium 件数を「20」→ **22** に修正（C32 追加）
   - GA-C の low 件数を「4」→ **4** （C33 追加により維持）

3. **Umbrella Gap 構成要素の更新**:
   - GA-S1 構成要素: S2-S14 → **S2-S20 全件**
   - GA-C1 構成要素: C7/C9/S1-S14 → **C7/C9/C22/C23/C26/C28/C29/C31/S1-S20/M14** 全件

4. **クロスリファレンス更新**:
   - `D (Build Graph)` の参照 Gap に GA-S20, GA-C32, GA-C33 追加

**明確にスコープ外とした項目（Pass 4 で確定、本パスで再確認）**:
- TyDD-D1-D5 (Types=Compression quotes)
- TyDD-S1-S8 (Source summaries)
- TyDD-N1-N4 (TyDe 2025 papers deep dive)
- TyDD-L8-L10 (Combinatorics / Conatural / mutual recursion)
- G2-4.3 (Combinatorics 領域の弱さ)
- handoff §5 (学習リソース) / §6 (サーベイ論文) / §8 (書籍)

**Pass 5 結果**:
- Gap 総計: **97 → 99 Gap** (+2)
- Warning: 10 件（変化なし）
- **総項目**: **107 → 109 項目**
- カテゴリ分布 (Gap): S×20, C×33, M×14, E×10, I×14, T×8
- high リスク Gap: 18（Pass 2 以降不変）
- 収束状態: **未収束**（2 件追加あり）

### 収束ペース分析

```
Pass 1: 46 Gap
Pass 2: +33 → 79 Gap (前リサーチ 16 + TyDD Recipe + 内部資産統合)
Pass 3: +10 → 89 Gap (TyDD F/H/I 照合)
Pass 4: +8 → 97 Gap + Warning 10 新設
Pass 5: +2 → 99 Gap + Warning 10 (整合性修正 + Dhall/Bazel aspect)
```

減衰傾向は明確（33→10→8→2）。Pass 6 で 0 件到達の見込み。

### パス 6 (2026-04-17 深掘り再レビュー)

**改訂内容**: 「軽量走査」ではなく深掘りレビューとして実施。サーベイ 01-06 + G1-G5 の細部再走査、synthesis §7 Atlas 未実現 projects の扱い確認、新基盤独自観点のブレインストームを通じて追加 Gap 候補を精査。ユーザー判断 B を採用し Important 4 件 + Optional 1 件を追加。

**追加 Gap 5 件**:
- **Important (判断 B 採用)**:
  - GA-C34 (Spec snapshot lockfile): B-1.8 DVC dvc.lock
  - GA-C35 (Research Node auto-formalization): G2-3.1 AlphaProof
  - GA-C37 (Error Diagnosis + unsat core): TyDD Recipe 3
  - GA-M15 (APOLLO-style Repair Loop Engine): G2-1.6, G2-3.4
- **Optional (判断 B 採用)**:
  - GA-C36 (Meaning-based search engine): G5-4-2.1 ReProver

**スコープ外確定 (判断 B で見送り)**:
- GA-E11 (Human-in-the-loop metrics): GA-M2 augment で実質カバー、運用課題
- GA-T9 (CSLib upstream 貢献戦略): Phase 5 以降の発展課題
- GA-C38 (Implementation2Spec), GA-C39 (InputOutput2Spec), GA-T10 (InterFramework): Atlas 未実現 projects、MVP スコープ外

**クロスリファレンス更新**:
- B 導出元: GA-C34 追加
- G2 導出元: GA-C35, GA-M15 追加
- G5-4 導出元: GA-C36 追加
- GA-C1 (umbrella) 構成要素: C34, C35, C37, M15 追加

**Pass 6 結果**:
- Gap 総計: **99 → 104 Gap** (+5)
- Warning: 10 件（変化なし）
- **総項目**: **109 → 114 項目**
- カテゴリ分布 (Gap): S×20, C×37, M×15, E×10, I×14, T×8
- high リスク Gap: 18（Pass 2 以降不変）
- 収束状態: **未収束**（5 件追加あり）

### 収束ペース分析（更新）

```
Pass 1: 46
Pass 2: +33 → 79   (前リサーチ統合)
Pass 3: +10 → 89   (TyDD F/H/I)
Pass 4: +8  → 97   (Section 5 限界 + Warning 10 新設)
Pass 5: +2  → 99   (Dhall/Bazel aspect + 整合性)
Pass 6: +5  → 104  (深掘り再レビュー: DVC lockfile + auto-formalization + Repair + Error Diagnosis + ReProver)
```

減衰率: 33→10→8→2→5。Pass 5 で +2 だったが Pass 6 で +5 に増加。これは Pass 6 を「軽量走査」ではなく **深掘り再レビュー** として実施した結果であり、レビュー深度の上方修正による。

### パス 7 (2026-04-17 軽量整合確認)

**目的**: Pass 6 で追加した 5 Gap の重複・整合性確認、Tag Index Matrix 検算、クロスリファレンス完全性、新規追加候補の最終走査。

**検証結果**:

1. **Pass 6 追加 5 Gap の重複チェック**: 全て別概念 / 階層関係 / 補完関係を確認、重複なし
   - GA-C34 (lockfile) vs GA-C5 (CA storage): 別 (C5=backend, C34=lockfile)
   - GA-C35 (auto-formalization) vs GA-C10 (Typed Holes): 階層関係 (C35 が上位)
   - GA-C36 (Meaning-based search) vs GA-C3 (Reverse Deps Index): 別概念
   - GA-C37 (Error Diagnosis) vs GA-C7 (SMT hammer): 補完 (C7=証明, C37=失敗診断)
   - GA-M15 (Repair Loop) vs GA-C7, GA-M8: 別レイヤ (M15=loop engine, M8=retry policy)

2. **Tag Index Matrix 検算**: 全カテゴリで整合（S:20, C:37, M:15, E:10, I:14, T:8 / 合計 104 Gap + 10 Warning = 114 項目）

3. **クロスリファレンス完全性**: 全導出元タグ (A-F, G1-G5, TyDD-B/C/F/G/H/I/J/L, handoff §3/4/7, #599 全件) で参照あり、孤立 Gap / 未参照タグなし

4. **新規追加候補**: **検出されず (0 件)**

**パス 7 結果**:
- Gap 総計: **104 → 104** (±0)
- Warning: 10 件（変化なし）
- **総項目**: 114 項目（変化なし）
- 収束状態: **収束判定 PASS**

### 収束判定

**7 パスで収束達成**。

```
Pass 1: 46
Pass 2: +33 → 79   (前リサーチ統合)
Pass 3: +10 → 89   (TyDD F/H/I)
Pass 4: +8  → 97   (Section 5 限界 + Warning 10 新設)
Pass 5: +2  → 99   (Dhall/Bazel aspect + 整合性)
Pass 6: +5  → 104  (深掘り再レビュー: DVC/auto-formalization/Repair/Error/ReProver)
Pass 7: +0  → 104  ★収束★
```

減衰率: 33→10→8→2→5→0。

**最終確定**（Verifier Round 1 修正反映、GA-C15 を high に昇格）:
- Gap 104 件（6 カテゴリ: S=20, C=37, M=15, E=10, I=14, T=8、うち high=19, medium=63, low=22, umbrella=2）
- Warning 10 件（Critical=1, High=2, Medium=5, Low=2）
- 総項目 **114**

---

---

## 5. Verifier 検証履歴（Step 1.5）

### Round 1 予定

本パス 2 全体を対象に Verifier 独立検証を実施。addressable = 0 + 修正後変更なしまでループ。

### 完了条件

SKILL.md Step 1.5 準拠:
1. Verifier の最終ラウンドで addressable = 0 件
2. その最終ラウンド以降に Gap Analysis テキストへの変更がないこと

---

## 出典一覧（参照タグ）

- 既存 6 グループ: `docs/research/new-foundation-survey/01-06` + `00-synthesis.md`
- G1-G5 補遺: `docs/research/new-foundation-survey/07-lean4-applications/`
- TyDD サーベイ: `research/survey_type_driven_development_2025.md`
- Lean 4 handoff: `research/lean4-handoff.md`
- 前リサーチ（#599 16 Gap）: `.claude/handoffs/handoff-599-pending-rebase.md`
- 内部資産: `lean-formalization/Manifest/*.lean`, `.claude/skills/*/SKILL.md`, `artifact-manifest.json`, `tests/test-all.sh`, `.claude/hooks/`, `CLAUDE.md`
