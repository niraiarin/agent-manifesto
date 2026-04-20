# agent-spec-lib

agent-manifesto 研究プロセスの型安全な Lean 表現。

## 位置づけ

- **目的**: GitHub Issue に依存した研究プロセス記録を、Lean 4 による型安全な tree structure に再設計
- **方針**: Atlas Computing が提案した speclib 構想 (2025-01) の具体的 instance として、研究プロセス領域に特化した domain-specific library として構築
- **根拠**: `docs/research/new-foundation-survey/10-gap-analysis.md` (104 Gap + 10 Warning、Verifier 3 ラウンド PASS)

## 現状: Phase 0 Week 1 (環境準備 + TyDD/TDD 基盤) 完了

- [x] ディレクトリ構造
- [x] `lean-toolchain` pin (v4.29.0、GA-T8)
- [x] `lakefile.lean` (Mathlib 依存、Week 6 で LeanHammer/CSLib 追加予定)
- [x] `AgentSpec.lean` (ルート、Core + Test import)
- [x] `AgentSpec/Core.lean` (**SemVer refinement type + forward codec**、sorry 0 / axiom 0 / theorem 0 — TyDD-S4 準拠)
- [x] `AgentSpec/Test/CoreTest.lean` (**10 件の behavior assertion**、`example` ベース、`rfl` / `decide` 証明)
- [x] `artifact-manifest.json` (**GA-I1 対応、agent-spec-lib 用 manifest**、依存 edge + refs + build_status)
- [x] `lake build AgentSpec` ✓ 確認済 (exit 0, 5 jobs including Test)
- [x] Verifier Round 1-2 検証済み (2026-04-17)

### TyDD / TDD 原則の適用状況

| 原則 | Week 1 での実装 |
|---|---|
| **TyDD-S1** (Types first) | `version` を `String` から `SemVer` refinement type に型化 |
| **TyDD-S4** (Refinement type, GA-S18) | `SemVer` structure で Nat 非負制約 + preRelease Option 型 |
| **TyDD-F2** (Lattice 予備、GA-S15 基盤) | `Ord` / `LE` / `LT` instance on SemVer で lexicographic 順序、Week 4-5 の `ResearchSpec` Lattice への基盤 |
| **TyDD-F6** (Codec round-trip, GA-C2) | `SemVer.render` + `SemVer.parse` の **bidirectional** codec + 個別 + 有限量化 round-trip |
| **TyDD-H3** (BiTrSpec) | 個別 example + **`Fin 5³ = 125` ケースの `decide` 網羅検証**、普遍定理は Week 2 |
| **TyDD-H7** (3-level verify、GA-M12) | L3 Lean のみ (現 Week 1)、L2 SMT は Week 6、L1 pytest は Week 7 — README に宣言 |
| **Recipe 11** (Bidirectional Codec Round-Trip Testing) | 正例 7 件 + 負例 4 件 + 有限量化 125 ケース |
| **TDD** (Red→Green→Refactor) | `AgentSpec/Test/CoreTest.lean` に **24 件 `example`** 検証 |
| **GA-W7** (termination 保証) | `partial def` 不使用、明示的 recursive + `let rec go` で termination 自動推論 |
| **GA-C27** (Trusted code 最小化) | `native_decide` 不使用、全て `rfl` / `decide` |
| **GA-I1** (artifact-manifest) | `agent-spec-lib/artifact-manifest.json` で GA- 参照 + 依存 edge + codec_completeness + tydd_alignment |
| **GA-I9** (テストカバレッジ) | Test/CoreTest.lean で 24 件 behavior assertion + 125 ケース有限量化 |
| **GA-W4** (sorry accumulation) | sorry 0、axiom 0、theorem 0 |

### Verify Strategy (TyDD-H7 Minimal Viable Pipeline, GA-M12)

TyDD-H7 は「L1 pytest → L2 +Z3 SMT → L3 +Lean」の 3 段階検証 pipeline を提案。
本基盤の段階的導入計画:

| Level | 内容 | Week 1 状態 | 計画 |
|---|---|---|---|
| **L1** | pytest / 実行時 assert (Python 層) | 未実装 | Week 7 以降の Python 層追加時に導入 |
| **L2** | Z3 SMT solver による自動放電 | 未実装 | Week 6 で LeanHammer / Duper / Lean-Auto 統合時（GA-C7、GA-I5）|
| **L3** | Lean 型検査 + `decide` + `rfl` | **実装済** | Week 1 で完了（`lake build` + 24 `example` + 125 ケース有限量化）|

Week 1 は L3 単独で TyDD-H3 BiTrSpec の round-trip 性質を:
- **個別 example 検証**: 正例 7 件 + 負例 4 件 = 11 件
- **有限量化検証**: `List.range 5 × 5 × 5 = 125` ケースを `decide` で網羅
- **順序関係検証**: SemVer lexicographic ordering の 5 ケース

L1/L2 追加は後続 Week で `verify_level : Nat` パラメータ化して選択的に実施可能。

### G5-1 Section 3.5 Week 1 完了基準からの縮小定義

G5-1 Section 3.5 の当初計画は Week 1 で「Cslib 依存確立」を要求しているが、
GA-I5 (CSLib バージョン互換性未確認、low risk) に従い **Cslib 依存は Week 6 へ延期**。
Week 1 の完了基準を「ビルド環境の確立 + TyDD/TDD 基盤（Mathlib + lean-toolchain pin + SemVer + behavior test + artifact-manifest）」と定義する。
この判断根拠は `../docs/research/new-foundation-survey/10-gap-analysis.md` GA-I5 を参照。

## 現状: Phase 0 Week 2 Day 1 完了（2026-04-17 追加）

Week 1 の基盤に Spine 層・Proofs 層の最小実装を追加。

- [x] `AgentSpec/Spine/FolgeID.lean` (**GA-S2 FolgeID structure + prefix partial order**、
  `listIsPrefixOf` Bool helper + `instance instLE` 明示命名 + `Decidable (≤)` via `inferInstanceAs`)
- [x] `AgentSpec/Proofs/RoundTrip.lean` (**GA-C2 round-trip signature**、
  `def roundTripUniversal` hole-driven signature + 3 proved theorems + 補題リスト docstring 集約)
- [x] `AgentSpec/Test/Spine/FolgeIDTest.lean` (**11 件の behavior assertion**)
- [x] `AgentSpec/Core.lean` explicit import (Init.Data.* 5 件、/verify Round 1 指摘 7 対処)
- [x] `lake build AgentSpec` ✓ 確認済 (exit 0, **8 jobs**、Week 1 から 5→8)
- [x] /verify Round 2 PASS (logprob + Subagent、evaluator_independent: true)

### Week 2 Day 1 時点の累計指標

| 指標 | Week 1 | Day 1 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 0 | 3 (RoundTrip) | **3** |
| example 数 | 24 | 11 (FolgeIDTest) | **35** |
| finite bounded universal cases | 125 (5³) | 343 (7³) | **343** (最大) |
| sorry | 0 | 0 | **0** |
| axiom | 0 | 0 | **0** |
| namespace | `AgentSpec` | `.Spine`, `.Proofs`, `.Test.Spine` | 4 namespaces |

### Day 1 で確立した実装パターン（Week 2-3 Spine 層全体に適用）

1. **segment abbrev + structure** (TyDD-S1): `FolgePathSegment := Nat ⊕ Char` を先行
2. **Bool helper による `decide` 対応**: `listIsPrefixOf` のように List レベルで実装
   して structure pattern の reduction stuck を回避
3. **明示的 instance 命名**: `instance instLE : LE T` のように名前付け
4. **`Decidable` via `inferInstanceAs`**: `by unfold` の fragility を回避
5. **hole-driven signature**: `def roundTripUniversal` のように `abbrev` を避け
   opaque identity を保持

## 現状: Phase 0 Week 2 Day 2 完了（2026-04-18 追加）

Day 1 の基盤に Edge Type と test lib 分離を追加。

- [x] `AgentSpec/Spine/Edge.lean` (**GA-S4 EdgeKind 6 variant + Edge structure**、
  `inductive EdgeKind` (wasDerivedFrom/refines/refutes/blocks/relates/wasReplacedBy)
  + `structure Edge { src dst : FolgeID, kind : EdgeKind }` + isSelfLoop / reverse)
- [x] `AgentSpec/Test/Spine/EdgeTest.lean` (**16 件の behavior assertion**、reverse の involutivity を全 6 variant 検証)
- [x] `AgentSpecTest.lean` 新規 (test lib root、Verifier R3 i3 / /verify R1 i4 / Day 1 R1 I1 対処)
- [x] `lakefile.lean` に `lean_lib AgentSpecTest` 別 target 追加
- [x] `lake build AgentSpec` ✓ (exit 0, **7 jobs production-only**)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **9 jobs test-only**)
- [x] /verify Round 1 PASS (logprob + Subagent、margin 0.277、addressable 2 のうち involutivity 拡充実施)

### Week 2 Day 2 時点の累計指標

| 指標 | Day 1 | Day 2 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 3 | 0 | **3** |
| example 数 | 35 | 16 (Edge: 11→16 拡充含) | **50** |
| Spine 層型 | 1 (FolgeID) | 1 (Edge) | **2 type families** |
| build target | `AgentSpec` (8 jobs) | `AgentSpec` 7 + `AgentSpecTest` 9 | **2 lib (test 分離済)** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |

### Day 2 で追加した実装パターン (Section 10.2 #8)

- **Pattern #8**: Lean 4 予約語 (`from`, `to`, `match`, `let` 等) を field 名・variable 名に使用しない
  - 適用例: `Edge.src`/`Edge.dst` (`from`/`to` の代わり)
  - 違反時の症状: `unexpected token 'from'; expected '_', '}', identifier or term`

## 現状: Phase 0 Week 2 Day 3 完了（2026-04-18 追加）

Day 2 の Spine 層に EvolutionStep / SafetyConstraint type class を追加。

- [x] `AgentSpec/Spine/EvolutionStep.lean` (**G5-1 §3.4 ステップ 1 ResearchEvolutionStep**、
  `class EvolutionStep (S : Type u) where transition : S → S → Prop`
  + TransitionReflexive / TransitionTransitive property + Unit dummy instance)
- [x] `AgentSpec/Spine/SafetyConstraint.lean` (**L1 安全境界 + S4 P2 Refinement 強適用**、
  `class SafetyConstraint S where safe : S → Bool` + `SafeState` subtype refinement
  + Unit dummy instance + `doSafeOperation` 利用例)
- [x] `AgentSpec/Test/Spine/EvolutionStepTest.lean` (**4 件の behavior assertion**)
- [x] `AgentSpec/Test/Spine/SafetyConstraintTest.lean` (**8 件の behavior assertion**、
  `doSafeOperation` で B3 Call-site obligation の最小実例提示)
- [x] `lake build AgentSpec` ✓ (exit 0, **9 jobs production-only**)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **13 jobs test-only**)
- [x] /verify Round 1 PASS (logprob A 全 3 基準 margin 0.408 + Subagent PASS、
  addressable A1 trivially-true → doSafeOperation テストに置換、A2 cross-class test → Day 4 対処)

### Week 2 Day 3 時点の累計指標

| 指標 | Day 2 | Day 3 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 3 | 0 | **3** |
| example 数 | 50 | 12 (EvolutionStepTest 4 + SafetyConstraintTest 8) | **62** |
| Spine 層型 | 2 (FolgeID, Edge) | 2 (EvolutionStep, SafetyConstraint) | **4 type families** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |

### Day 3 で達成した TyDD 進展 (Section 12.8)

- **S4 P2 Refinement の初の強適用**: `SafeState S := { s : S // safe s = true }`
  は subtype refinement の典型。Day 2 評価で「最大改善余地」と識別された項目を Day 3 で解消
- **B3 Call-site obligation の最小実例**: `doSafeOperation : SafeState S → Unit` で
  「safe state のみ受理する関数」のシグネチャを test に組込み、refinement type の生きた価値を実証
- **Pattern #8 派生**: `refl` を class member 外に出した判断（Lean 4 tactic shadow 回避）

## 現状: Phase 0 Week 2 Day 4 完了（2026-04-18 追加）

Day 3 Spine 層に LearningCycle / Observable type class を追加し、
**Section 1 Week 2-3 完了基準 (4 type class + dummy instance) 達成**。
Pre-Day-4 refactor として SafetyConstraint Bool→Prop 完全移行も実施。

### Pre-Day-4 refactor (Day 3 評価 Section 2.9 🔴/🟡 前倒し)

- [x] **SafetyConstraint Bool→Prop refactor** (`safe : S → Prop` + bundled
  `safeDec : DecidablePred safe`、S4 P1+P2+P4 同時強適用、S1 #9 復活)
- [x] **SafeState.mk smart constructor** (Section 2.9 🟡 対処)
- [x] **EvolutionStep に Decidable transition instance** (cross-class test 用)

### Day 4 main

- [x] `AgentSpec/Spine/LearningCycle.lean` (**G5-1 §3.4 ステップ 2 LearningM 前段階**、
  `inductive LearningStage` 5 variant + `next`/`le`/`isTerminal` helpers + class + Unit instance)
- [x] `AgentSpec/Spine/Observable.lean` (**P4 可観測性、V1-V7 metric tuple**、
  `structure ObservableSnapshot` 7-field + class + Unit instance)
- [x] `AgentSpec/Test/Spine/LearningCycleTest.lean` (**22 件の behavior assertion**、
  cross-class 4-instance test (`fullSpineExample`) で Day 3 A2 完全対処)
- [x] `AgentSpec/Test/Spine/ObservableTest.lean` (**7 件の behavior assertion**)
- [x] `lake build AgentSpec` ✓ (exit 0, **11 jobs production-only**)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **17 jobs test-only**)
- [x] /verify Round 1 PASS (logprob A 全 3 基準 margin 0.306 + Subagent PASS、
  addressable A1 reducible 文書化 / informational I1/I3/I4 対処)

### Week 2 Day 4 時点の累計指標

| 指標 | Day 3 | Day 4 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 3 | 0 | **3** |
| example 数 | 62 | 31 (Pre-Day-4 +2 / LearningCycleTest 22 / ObservableTest 7) | **93** |
| Spine 層 type class | 2 (EvolutionStep, SafetyConstraint) | 2 (LearningCycle, Observable) | **4 type class 完備** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |

### Day 4 で達成した TyDD 進展 (Section 12.11)

- **S1 benefit #9 復活** (⚠⚠→✓): Bool→Prop refactor 完了で将来 refactor コスト解消
- **S4 1→3 強適用達成** (P1 prove vs SMT + P2 subtyping + P4 power-to-weight 同時)
- **Cross-class 4-instance test** (`fullSpineExample`): Spine 層 uniform structure 実証
- **Spine 層 4 type class 完備**: Section 1 Week 2-3 完了基準達成

## 現状: Phase 0 Week 2 Day 5 完了（2026-04-18 追加）

Day 4 評価 Section 12.11 / 2.10 / 2.11 の改善余地を Day 5 で対処。
**Pattern #7 hook 化により 4 連続違反を構造的解決**、順序関係完備により F2 Lattice 部分達成。

### Day 5 の 4 項目

- [x] **Pattern #7 hook 化** (`.claude/hooks/p3-manifest-on-commit.sh`、Section 6.2.1 完全実装)
  - A1 狭 (新規 Spine/Proofs/Process .lean のみ) + B2 block + C1 settings.json + D1 new-foundation only + E2 `[no-manifest]` bypass
  - **L1 governance 制約**: 人間承認下で手動配置 (cp + chmod + python3 settings 編集)
- [x] **LearningStage LE/LT/Decidable instance** (Section 12.11 🟡 F2 Lattice 部分対処)
  - FolgeID パターン踏襲 (instLE 明示命名 + Decidable via inferInstanceAs)
  - +6 LE/LT test (LearningCycleTest 22→28)
- [x] **FolgeID PartialOrder/LT 拡張** (Section 10.1 元 Day 5 task)
  - **Mathlib import 追加**: `Mathlib.Order.Defs.PartialOrder` + `Mathlib.Tactic.SplitIfs`
  - 6 lemma: listIsPrefixOf_refl/_trans/_antisymm + le_refl'/le_trans'/le_antisymm'
  - PartialOrder bundle (lt_iff_le_not_ge は Mathlib 新名)
  - +6 PartialOrder/LT test (FolgeIDTest 10→16)
  - Ord (lex total order) は Day 6+/Week 4-5 へ繰り延べ
- [x] **普遍 round-trip 定理 部分達成** (Section 2.2 Day 5 残)
  - +6 helper theorems: consumeChar_dot 系 + charToDigit? 系
  - bounded universal 拡張: 7³=343 → **8³=512 ケース** (10³ は decide heartbeat 超過)
  - universal proof は Day 6/Week 3 へ繰り延べ + Lean-Auto 統合 (Week 6) 後の SMT 自動証明可能性記録

### Week 2 Day 5 時点の累計指標

| 指標 | Day 4 | Day 5 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 3 | +12 (FolgeID 6 + RoundTrip 6) | **15** |
| example 数 | 93 | +12 (FolgeID +6 / LearningCycle +6) | **105** |
| AgentSpec build jobs | 11 | +79 (Mathlib 推移依存) | **90 jobs** |
| AgentSpecTest build jobs | 17 | +79 | **96 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 0 | +1 (Pattern #7) | **1** |

### Day 5 で達成した TyDD 進展 (Section 12.14)

- **Pattern #7 構造的解決**: 4 連続違反 → hook 自動強制で繰り返し不可能
- **F2 Lattice 部分達成**: LearningStage LE/LT + FolgeID PartialOrder で順序関係完備
- **paper × pattern 合流の 2 度目**: G5-1 §6.2.1 × Pattern #7 (Day 4 S4 × #5 に続く)
- **S2 Lean-Auto 必要性顕在化**: bounded 8³ で `decide` heartbeat 限界 → Section 2.10 で Week 6 へ前倒し格上げ

## 現状: Phase 0 Week 2 Day 6 完了（2026-04-18 追加）

Section 2.11 確定方針 (Q1 Option C / Q2 Minimal / Q3 PROV vocab in docstring) に従い
**Process 層 (Week 4-5 前倒し) を hole-driven Minimal scope で着手**。Pattern #7 hook の
**設計→実装→運用 三段階 closure 達成** (Day 5 設計実装、Day 6 commit で初運用検証成功)。

### Day 6 の 2 項目 (Minimal scope)

- [x] **Hypothesis structure** (`AgentSpec/Process/Hypothesis.lean`)
  - `structure Hypothesis { claim : String, rationale : Option String := none }`
  - `mk'` smart constructor + `trivial` fixture
  - DecidableEq / Inhabited / Repr (deriving)
  - **PROV mapping in docstring** (Q3 Option C): `ResearchEntity.Hypothesis` (Day 8+ で実装)
  - Day 6 意思決定ログ D1-D3 (claim String / structure 採用 / 関係は Edge graph)
- [x] **Failure first-class entity** (`AgentSpec/Process/Failure.lean`、02-data-provenance §4.3 100% 忠実実装)
  - `inductive FailureReason` 4 variant: HypothesisRefuted / ImplementationBlocked /
    SpecInconsistent / Retired (各 payload は Day 6 hole-driven String、Day 8+ で型化)
  - `structure Failure { failedHypothesis : String, reason : FailureReason }`
  - `whyFailed` accessor + `refuted` / `retired` smart constructors + `trivial` fixture
  - **PROV mapping in docstring** (Q3 Option C): `ResearchEntity.Failure` (Day 8+ で実装)
  - Day 6 意思決定ログ D1-D3 (FailureReason inductive / payload String / failedHypothesis String 参照)
- [x] `AgentSpec/Test/Process/HypothesisTest.lean` (**12 件の behavior assertion**)
- [x] `AgentSpec/Test/Process/FailureTest.lean` (**17 件の behavior assertion**、4 variant 全て + 4 type 解決)
- [x] `lake build AgentSpec` ✓ (exit 0, **92 jobs**、Process 層 +2)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **100 jobs**)
- [x] /verify Round 1 PASS (logprob A 全体 margin 0.073 + Subagent PASS、addressable 0、informational I1 Inhabited Failure 対称性 +1 example で対処)
- [x] **Pattern #7 hook 初の適用 commit** が pass-through 確認済 (artifact-manifest 同 commit に staged)

### Week 2 Day 6 時点の累計指標

| 指標 | Day 5 | Day 6 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 105 | +29 (HypothesisTest 12 + FailureTest 17) | **134** |
| Spine 層 type class | 4 完備 + 順序関係完備 | 0 | **4 + 順序** |
| Process 層 type | 0 | +2 (Hypothesis + Failure structure) | **2 inductive/structure** |
| AgentSpec build jobs | 90 | +2 (Process .lean) | **92 jobs** |
| AgentSpecTest build jobs | 96 | +4 (Process Test .lean) | **100 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 (Pattern #7) | 0 (運用検証成立) | **1 + 運用 closure** |

### Day 6 で達成した TyDD / paper 進展 (Section 12.16 + 12.17)

- **02-data-provenance §4.3 100% 忠実実装** — first-class Failure (FailureReason 4 variant)
- **Pattern #7 hook 運用検証完了** — 設計→実装→運用 三段階 closure
- **TyDD-S1 × Q3 Option C 合流** — 新カテゴリ「principle × decision」(Process 独立 type + docstring PROV)
- **H4 新規部分達成** — PROV mapping in docstring は将来 LLM mapping 生成 hint
- **paper finding 14 件累計** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 1-3 関連: 1)

## 現状: Phase 0 Week 2 Day 7 完了（2026-04-18 追加）

Section 2.11 Day 7 着手前判断 (Q1 Minimal / Q2 案 A / Q3 案 B / Q4 案 A) に従い
Process 層継続実装。**Process 層 4 type 完備** (Hypothesis + Failure + Evolution + HandoffChain)、
**Pattern #7 hook 2 度目運用検証** 成功、**内部規範 layer 横断 transfer** 達成。

### Day 7 の 2 項目 (Q1 Minimal scope)

- [x] **Evolution inductive** (`AgentSpec/Process/Evolution.lean`、Q3 案 B)
  - `inductive Evolution { initial (h : Hypothesis), refineWith (prev : Evolution) (refined : Hypothesis) }`
  - 3 recursive accessor: `origin` / `latest` / `stepCount`
  - `trivial` fixture + deriving `Inhabited, Repr` (DecidableEq は recursive のため省略、Day 8+ 検討)
  - **PROV mapping in docstring**: `ResearchActivity` (Day 8+ で実装)
  - **Q3 案 B**: B4 Hoare 4-arg post (`(pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop`) 完全統合は **Day 8+ Verdict 型確定後**
  - Day 7 意思決定ログ D1-D4 (inductive 採用 / refineWith Hypothesis のみ Q3 案 B / accessor recursive def / Subagent A1 Inhabited 注記)
- [x] **HandoffChain inductive** (`AgentSpec/Process/HandoffChain.lean`、agent-manifesto T1 一時性)
  - `structure Handoff { fromAgent, toAgent, payload : String }` (Day 8+ で `ResearchAgent` 型化)
  - `inductive HandoffChain { empty, cons (h : Handoff) (rest : HandoffChain) }`
  - `length` / `append` / `trivialHandoff` / `trivial`
  - deriving `DecidableEq Handoff` / `Inhabited` / `Repr`
  - **PROV mapping in docstring**: `ResearchAgent` (Day 8+ で実装)
  - Day 7 意思決定ログ D1-D3 (2 type 構成 / cons inductive / agent identifier String)
- [x] `AgentSpec/Test/Process/EvolutionTest.lean` (**16 件**、Q2 案 A `fullProcessExample` 4-tuple cross-process test 含む)
- [x] `AgentSpec/Test/Process/HandoffChainTest.lean` (**21 件**、Q4 案 A: Spine 統合は Day 8+ 別 file)
- [x] `lake build AgentSpec` ✓ (exit 0, **94 jobs**、Process 層 +2)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **104 jobs**)
- [x] /verify Round 1 PASS (logprob A 全体 margin 0.232 + Subagent PASS、addressable A1/A2 docstring 追加で対処)
- [x] **Pattern #7 hook 2 度目適用** (Day 6 初適用に続き運用安定性継続検証)

### Week 2 Day 7 時点の累計指標

| 指標 | Day 6 | Day 7 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 134 | +37 (EvolutionTest 16 + HandoffChainTest 21) | **171** |
| Spine 層 type class | 4 完備 + 順序関係 | 0 | **4 + 順序** |
| Process 層 type | 2 (Hypothesis + Failure) | +2 (Evolution + HandoffChain) | **4 完備** |
| AgentSpec build jobs | 92 | +2 (Process .lean) | **94 jobs** |
| AgentSpecTest build jobs | 100 | +4 (Process Test .lean) | **104 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 (Pattern #7、Day 6 初適用) | 2 度目適用 | **1 + 2 度運用検証** |

### Day 7 で達成した TyDD / paper 進展 (Section 12.19 + 12.20)

- **Process 層 4 type 完備** (Hypothesis + Failure + Evolution + HandoffChain)
- **agent-manifesto T1 一時性** を HandoffChain で 100% 忠実実装
- **Pattern #7 hook 2 度目適用** = 運用安定性継続検証
- **内部規範 layer 横断 transfer** (fullSpineExample → fullProcessExample)
- **H10 (Spec normal forms) 新規部分達成** (Evolution 2 constructor)
- **paper × 実装 4 度目合流カテゴリ確立** (internal-norm × layer transfer)
- **paper finding 19 件累計** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 7: 5 / Day 1-3 関連: 1)

## 現状: Phase 0 Week 2 Day 8 完了（2026-04-18 追加）

Section 2.14 Day 8 着手前判断 (Q1 B-Medium / Q3 案 A / Q4 案 A) に従い実装。
**Section 2.9 (B4 4-arg post 残課題、Day 3 識別) を完全解消** (5 セッション累積改善)。
**S4 4/5 強適用達成** (P5 explicit assumptions 新規) + **B4 Hoare 4-arg post 新規強適用**。

### Day 8 の 3 項目 (Q1 B-Medium scope)

- [x] **Verdict 3 variant inductive** (`AgentSpec/Provenance/Verdict.lean`、新 namespace `AgentSpec.Provenance` 先行配置、Q3 案 A)
  - `inductive Verdict { proven, refuted, inconclusive }` (3 variant minimal)
  - `isProven` / `isRefuted` / `isInconclusive` Bool 判定 helper
  - `trivial` fixture (= inconclusive)
  - deriving `DecidableEq, Inhabited, Repr`
  - **PROV mapping in docstring**: `ResearchActivity` の output (Day 9+ 実装)
  - Day 8 意思決定ログ D1-D2 (3 variant minimal Q3 案 A / 新 namespace 配置 D2)
- [x] **EvolutionStep B4 4-arg post 完全統合** (`AgentSpec/Spine/EvolutionStep.lean`、refactor、Q4 案 A)
  - **transition signature**: `(pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop`
  - **transitionLegacy** : `S → S → Prop` を existential で derive (∃ h v, transition pre h v post)、後方互換性
  - TransitionReflexive / TransitionTransitive を transitionLegacy ベースに更新
  - Unit instance + Decidable instance を 4-arg signature 対応に更新
  - **layer architecture redefinition**: Spine → Process / Provenance import を意識的受容 (Q4 案 A D4)
    Spine の役割を「下位層」→「core abstraction」に再定義
  - Day 8 意思決定ログ D1-D4 (revised D1-D3 + 新 D2/D4)
- [x] **Spine + Process cross-layer test** (`AgentSpec/Test/Cross/SpineProcessTest.lean`、新 namespace `AgentSpec.Test.Cross`、Q2 B-Medium 副成果)
  - `fullStackExample`: Spine 4 type class + Process 4 type 同時要求 (8 layer 要素)
  - `evolveWithVerdict`: Spine EvolutionStep B4 + Process Hypothesis + Provenance Verdict 連携
  - `fullProcessReuse`: Day 7 fullProcessExample 構造の継承
  - **内部規範 layer 横断 transfer 拡張**: fullSpineExample (Day 4) → fullProcessExample (Day 7) → fullStackExample (Day 8) の 3 段階
- [x] `AgentSpec/Test/Provenance/VerdictTest.lean` (**17 件**、3 variant + isXxx + DecidableEq)
- [x] `AgentSpec/Test/Spine/EvolutionStepTest.lean` modify (**4→9 件**、新 4-arg signature + transitionLegacy + decide test)
- [x] `lake build AgentSpec` ✓ (exit 0, **95 jobs**、Verdict +1)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **107 jobs**)
- [x] /verify Round 1 PASS (logprob A 全体 margin 0.051 + Subagent PASS、addressable A1 manifest 即対処)
- [x] **Pattern #7 hook 3 度目適用** (運用安定性継続検証成功)

### Week 2 Day 8 時点の累計指標

| 指標 | Day 7 | Day 8 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 171 | +26 (Verdict 17 + SpineProcess 4 + EvolutionStep modify +5) | **197** |
| Spine 層 type class | 4 完備 + 順序関係 | 0 (refactor: B4 4-arg post) | **4 + 順序 + B4 統合** |
| Process 層 type | 4 完備 | 0 | **4 完備** |
| Provenance 層 type | 0 | +1 (Verdict 先行配置) | **1 (Day 9+ 完成予定)** |
| AgentSpec build jobs | 94 | +1 (Verdict) | **95 jobs** |
| AgentSpecTest build jobs | 104 | +3 (Verdict + SpineProcess + EvolutionStep modify) | **107 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 (2 度運用検証) | 3 度目適用 | **1 + 3 度運用検証** |

### Day 8 で達成した TyDD / paper 進展 (Section 12.22 + 12.23)

- **Section 2.9 完全解消** (Day 3 識別→Day 8 解消、5 セッション累積改善)
- **S4 4/5 強適用達成** (P5 explicit assumptions 新規、Day 4 P1+P2+P4 から +1)
- **B4 Hoare 4-arg post 新規強適用** (EvolutionStep transition で完全実装)
- **Pattern #7 hook 3 度目適用** (運用安定性継続検証)
- **layer architecture redefinition** (Spine = 下位層 → core abstraction)
- **内部規範 layer 横断 transfer 拡張** (fullSpine → fullProcess → fullStack 3 段階)
- **paper × 実装 5 度目合流カテゴリ確立** (layer architecture redefinition)
- **paper finding 24 件累計** (Day 4: 4 / Day 5: 4 / Day 6: 5 / Day 7: 5 / Day 8: 5 / Day 1-3 関連: 1)

## 現状: Phase 0 Week 2 Day 9 完了（2026-04-18 追加）

Section 2.16 Day 9 着手前判断 (Q1 A / Q2 A-Minimal / Q3 案 A / Q4 案 A 循環依存回避設計)
に従い実装。**Provenance 層 3 type 完備** (Verdict + ResearchEntity + ResearchActivity)、
**Pattern #7 hook 4 度連続運用検証**、**namespace extension pattern × TyDD-S1 合流**、
**Subagent I2 実装修正即時対処** (paper サーベイ評価サイクル新パターン)。

### Day 9 の 2 項目 (Q2 A-Minimal scope)

- [x] **ResearchEntity 4 constructor inductive** (`AgentSpec/Provenance/ResearchEntity.lean`、Q3 案 A、Process embed)
  - `inductive ResearchEntity { Hypothesis (h : Hypothesis), Failure (f : Failure), Evolution (e : Evolution), Handoff (h : Handoff) }`
  - **4 toEntity Mapping** (Q4 案 A、本ファイル内 namespace AgentSpec.Process 配下に配置で循環依存回避)
  - 4 isXxx Bool 判定 helper + trivial fixture
  - deriving Inhabited, Repr (DecidableEq は Evolution recursive 制約で省略、Day 10+ 検討)
  - Day 9 意思決定ログ D1-D3
- [x] **ResearchActivity 5 variant inductive** (`AgentSpec/Provenance/ResearchActivity.lean`、02-data-provenance §4.1 PROV-O 通り)
  - `inductive ResearchActivity { investigate, decompose, refine, verify (input : Hypothesis) (output : Verdict), retire }`
  - **verify variant は Day 8 EvolutionStep B4 4-arg post と整合** (Day 10+ で transition → activity mapping path 確立予定)
  - isVerify / isRetire 判定 + trivial fixture (= investigate)
  - deriving DecidableEq, Inhabited, Repr
  - Day 9 意思決定ログ D1-D3
- [x] `AgentSpec/Test/Provenance/ResearchEntityTest.lean` (**21 件**、4 toEntity dot notation + Cross-process embed: `List ResearchEntity.length = 4`)
- [x] `AgentSpec/Test/Provenance/ResearchActivityTest.lean` (**22 件**、verify payload + EvolutionStep B4 整合検証 + Subagent I2 docstring 注記)
- [x] `lake build AgentSpec` ✓ (exit 0, **97 jobs**、Provenance 層 +2)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **111 jobs**)
- [x] /verify Round 1 PASS (logprob A 全体 margin **0.601** + Subagent PASS、addressable 0、informational I1 verifier_history Day 1-9 一括追加 / I2 即時実装修正対処 / I3 Day 10+ 検討)
- [x] **Pattern #7 hook 4 度目適用** (運用安定性 4 度連続検証成功)
- [x] **verifier_history Day 1-9 一括補完** (Week 1 Round 1-4 のみから 14 entries に拡充)

### Week 2 Day 9 時点の累計指標

| 指標 | Day 8 | Day 9 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 197 | +43 (ResearchEntity 21 + ResearchActivity 22) | **240** |
| Provenance 層 type | 1 (Verdict) | +2 (ResearchEntity + ResearchActivity) | **3 type (ResearchAgent は Day 10+)** |
| AgentSpec build jobs | 95 | +2 (Provenance 2 type) | **97 jobs** |
| AgentSpecTest build jobs | 107 | +4 (Provenance 2 test + 2 derived) | **111 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 (3 度運用検証) | 4 度目適用 | **1 + 4 度連続検証** |
| verifier_history entries | 4 (Week 1 Round 1-4 のみ) | +10 (Day 1-9 補完) | **14 entries** |

### Day 9 で達成した TyDD / paper 進展 (Section 12.25 + 12.26)

- **02-data-provenance §4.1 PROV-O 3 type 完備** (Verdict + ResearchEntity + ResearchActivity)
- **G5-1 §3.4 step 2 LearningM 前提構築** (ResearchActivity.verify ≡ EvolutionStep B4 整合)
- **namespace extension pattern × TyDD-S1 合流** (循環依存回避設計)
- **Pattern #7 hook 4 度連続運用検証** (運用安定性確立)
- **内部規範 layer 横断 transfer 拡張継続** (4 段階: fullSpine → fullProcess → fullStack → List ResearchEntity)
- **Subagent I2 即時実装修正対処** (paper サーベイ評価サイクル新パターン)
- **paper × 実装 6 度目合流カテゴリ確立** (namespace extension pattern by layer architecture)
- **paper finding 29 件累計** (Day 4-9 + Day 1-3 関連)

## 現状: Phase 0 Week 2 Day 10 完了（2026-04-18 追加）

Section 2.18 Day 10 着手前判断 (Q1 B-Medium / Q3 案 A / Q4 案 A) に従い実装。
**PROV-O 三項統合 4 type 完備** (Verdict + ResearchEntity + ResearchActivity + ResearchAgent)、
**Day 8/9 連携 path 確立** (transitionToActivity)、**Pattern #7 hook v2 拡張** (Subagent A1 対処)、
**layer architecture 完成形** (Spine + Process + Provenance + Cross test の 4 layer)。

### Day 10 の 3 項目 (Q2 B-Medium scope)

- [x] **ResearchAgent + Role inductive 3 variant** (`AgentSpec/Provenance/ResearchAgent.lean`、Q3 案 A、PROV-O 100% 忠実)
  - structure ResearchAgent { identity : String, role : Role }
  - inductive Role { Researcher, Reviewer, Verifier } (3 variant)
  - mkResearcher / mkReviewer / mkVerifier smart constructors
  - isResearcher / isReviewer / isVerifier helpers + trivial fixture
  - deriving DecidableEq, Inhabited, Repr (Role + ResearchAgent)
- [x] **EvolutionMapping (transitionToActivity free function)** (`AgentSpec/Provenance/EvolutionMapping.lean`、Q4 案 A)
  - `def transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v`
  - **Day 8 EvolutionStep B4 4-arg post と Day 9 ResearchActivity.verify の連携 path**
  - EvolutionStep import 不要 (層依存性最小化、Day 8 architecture と整合)
- [x] **ResearchEntity 5 constructor 拡張 (Day 10 D2、Agent embed)** (`AgentSpec/Provenance/ResearchEntity.lean` modify)
  - 既存 4 constructor (Hypothesis/Failure/Evolution/Handoff) + 新 Agent constructor
  - backward compatible (新 constructor 追加のみ)
  - Agent.toEntity Mapping 追加 (Day 9 同パターン、namespace AgentSpec.Provenance.ResearchAgent)
  - isAgent 判定追加
- [x] `AgentSpec/Test/Provenance/ResearchAgentTest.lean` (**30 件**、Role + smart constructors + isXxx + toEntity + isAgent)
- [x] `AgentSpec/Test/Provenance/EvolutionMappingTest.lean` (**8 件**、transitionToActivity + verify 整合)
- [x] `lake build AgentSpec` ✓ (exit 0, **99 jobs**、Provenance 層 +2)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **115 jobs**)
- [x] /verify Round 1 PASS (logprob A 全体 margin **2.335 (過去最高)** + Subagent PASS)
- [x] **Pattern #7 hook 5 度目適用 + v2 拡張** (Subagent A1 対処、regex に Provenance + Test/Cross 追加、user 介入で hook 修正完了)
- [x] **Subagent I2 即時実装修正対処** (ResearchEntity docstring 4→5 constructor 反映)

### Week 2 Day 10 時点の累計指標

| 指標 | Day 9 | Day 10 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 240 | +38 (ResearchAgent 30 + EvolutionMapping 8) | **278** |
| Provenance 層 type | 3 | +1 (ResearchAgent) | **4 type 完備 (PROV-O 三項統合完了)** |
| Day 8/9 連携 path | 未確立 | +1 (transitionToActivity) | **確立** |
| AgentSpec build jobs | 97 | +2 (Provenance 2 type) | **99 jobs** |
| AgentSpecTest build jobs | 111 | +4 (Provenance 2 test + 2 derived) | **115 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 (4 度連続検証) | 5 度目適用 + v2 拡張 | **1 + 5 度連続検証 + v2 (Provenance/Test/Cross 対応)** |

### Day 10 で達成した TyDD / paper 進展 (Section 12.28 + 12.29)

- **02-data-provenance §4.1 PROV-O 三項統合 4 type 完備** (Verdict + ResearchEntity + ResearchActivity + ResearchAgent)
- **G5-1 §3.4 step 2 LearningM 連携 path 確立** (transitionToActivity)
- **Pattern #7 hook v2 拡張** (Subagent A1 即時対処、regex に Provenance + Test/Cross 追加)
- **Section 10.2 Pattern #7 hook の三段階発展完了** (Day 5 設計→Day 6/7/8/9 運用検証→Day 10 v2 拡張)
- **layer architecture 完成形** (Spine + Process + Provenance + Cross test の 4 layer)
- **paper × 実装 7 度目合流カテゴリ確立** (PROV-O completion milestone × governance evolution)
- **paper finding 34 件累計** (Day 4-10 + Day 1-3 関連)

## 現状: Phase 0 Week 2 Day 11 完了（2026-04-18 追加）

Section 2.20 Day 11 着手前判断 (Q1 A 案 / Q2 A-Minimal / Q3 案 A / Q4 案 A) に従い実装。
**PROV-O 三項統合 relation 完備** (WasAttributedTo + WasGeneratedBy + WasDerivedFrom)、
**PROV-O §4.1 完全カバー到達** (Day 8-11 累計 4 type + 3 relation)、
**Pattern #7 hook v2 初運用検証成功** (Day 10 拡張後の最初 commit、Provenance 配下新規 .lean 検出)、
**Subagent 遡及検証 PASS** (改訂 49 で対処)。

### Day 11 の 1 項目 (Q2 A-Minimal scope)

- [x] **PROV-O 3 relation 3 separate structure** (`AgentSpec/Provenance/ProvRelation.lean`、Q3 案 A、PROV-O 1:1 対応)
  - `structure WasAttributedTo { entity : ResearchEntity, agent : ResearchAgent }` (Q4 案 A 引数 type 厳格)
  - `structure WasGeneratedBy { entity : ResearchEntity, activity : ResearchActivity }`
  - `structure WasDerivedFrom { entity : ResearchEntity, source : ResearchEntity }`
  - 各 mk' smart constructor + trivial fixture
  - 1 ファイル統合配置 (D3、cohesion 高い、import 簡素化)
  - deriving Inhabited, Repr (DecidableEq は ResearchEntity recursive 制約継承で省略)
- [x] `AgentSpec/Test/Provenance/ProvRelationTest.lean` (**22 件**、3 relation 構築 + accessor + smart constructor + trivial + Inhabited + PROV-O triple set 統合 example)
- [x] `lake build AgentSpec` ✓ (exit 0, **100 jobs**、Provenance 層 +1)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **117 jobs**)
- [x] /verify Round 1 PASS (logprob A 全体 margin、Subagent 遡及検証 PASS、改訂 49 で対処)
- [x] **Pattern #7 hook v2 初運用検証成功** (Day 10 拡張後の最初 commit、Provenance 配下新規 .lean を hook が検出)

### Week 2 Day 11 時点の累計指標

| 指標 | Day 10 | Day 11 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 278 | +22 (ProvRelation) | **300** |
| Provenance 層 type | 4 | 0 (relation のみ追加) | **4 type 完備** |
| Provenance 層 relation | 0 | +3 (PROV-O main relations) | **3 relation 完備** |
| AgentSpec build jobs | 99 | +1 (ProvRelation) | **100 jobs** |
| AgentSpecTest build jobs | 115 | +2 (ProvRelation test + derived) | **117 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 5 度連続検証 + v2 拡張 | 6 度目運用検証 (v2 初運用検証) | **1 + 6 度連続検証 + v2 初運用検証** |

### Day 11 で達成した TyDD / paper 進展 (Section 12.31 + 12.32)

- **02-data-provenance §4.1 PROV-O 3 main relation 完備** (WasAttributedTo + WasGeneratedBy + WasDerivedFrom、3 separate structure)
- **PROV-O §4.1 完全カバー到達** (Day 8-11 累計 4 type + 3 relation)
- **TyDD-S1 types-first** (3 separate structure で各 relation の semantic を型レベル区別、案 B/C を退ける)
- **TyDD-S4 P5 explicit assumptions 2 度目強適用** (引数 type 厳格、Day 8 B4 → Day 11 PROV-O relation)
- **Pattern #7 hook v2 初運用検証成功** (Day 10 拡張後の最初 commit、Provenance 配下新規 .lean 検出)
- **Section 10.2 Pattern #7 hook の四段階発展完了** (Day 5 設計→Day 6/7/8/9 運用検証→Day 10 v2 拡張→Day 11 v2 初運用検証)
- **PROV-O triple set 統合 example** (1 example で 3 relation 同時利用、内部規範 layer 横断 transfer 拡張 6 段階目)
- **paper × 実装 8 度目合流カテゴリ確立** (PROV-O triple completion × hook v2 first verification)
- **paper finding 39 件累計** (Day 4-11 + Day 1-3 関連)
- **Subagent 遡及検証 PASS** (paper サーベイ評価サイクル「実装修正組込み」3 度目適用、改訂 49 で対処)

## 現状: Phase 0 Week 2 Day 12 完了（2026-04-18 追加）

Section 2.22 Day 12 着手前判断 (Q1 A-Minimal / Q3 案 A 4 variant 型化 / Q4 案 A separate structure) に従い実装。
**PROV-O §4.4 退役 entity 構造的検出 完備** (RetiredEntity + RetirementReason 4 variant)、
**PROV-O §4.1 + §4.4 同時完全カバー到達** (Day 11 §4.1 + Day 12 §4.4)、
**Pattern #7 hook v2 2 度目運用検証成功** (Day 11 1 度目に続く Provenance 配下新規 .lean commit)、
**Subagent 検証 PASS** (本評価サイクル内で即時実施、Day 11 教訓反映で省略せず、改訂 56 で対処)、
**cycle 内学習 transfer** (Day 11 Subagent I3 教訓 = rfl preference を Day 12 RetiredEntityTest で実装適用)。

### Day 12 の 1 項目 (Q2 A-Minimal scope)

- [x] **RetiredEntity + RetirementReason 4 variant inductive** (`AgentSpec/Provenance/RetiredEntity.lean`、Q3 案 A + Q4 案 A、PROV-O §4.4 1:1 対応)
  - `inductive RetirementReason { Refuted (failure : Failure) | Superseded (replacement : ResearchEntity) | Obsolete | Withdrawn }`
  - `structure RetiredEntity { entity : ResearchEntity, reason : RetirementReason }` (separate structure、ResearchEntity 拡張不要 backward compatible)
  - 5 smart constructor (mk' / refuted / superseded / obsolete / withdrawn)
  - trivial fixture + whyRetired accessor
  - 1 ファイル統合配置 (D3、Day 11 ProvRelation パターン踏襲)
  - deriving Inhabited, Repr (DecidableEq は Superseded payload の ResearchEntity recursive 制約継承で省略)
- [x] `AgentSpec/Test/Provenance/RetiredEntityTest.lean` (**22 件**、4 RetirementReason variant + RetiredEntity 構築 + 5 smart constructor + trivial + whyRetired + 4 variant List 集約)
  - Day 11 Subagent I3 教訓反映: 全 example で rfl preference 維持 (simp tactic 不使用)
- [x] `lake build AgentSpec` ✓ (exit 0, **101 jobs**、Provenance 層 +1)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **119 jobs**)
- [x] /verify Round 1 PASS (build PASS + Subagent 検証 PASS、本評価サイクル内で即時実施、改訂 56 で対処)
- [x] **Pattern #7 hook v2 2 度目運用検証成功** (Day 11 1 度目に続く Provenance 配下新規 .lean detection 動作確認)
- [x] **Subagent I1+I2 即時実装修正対処** (artifact-manifest version day11→day12 / verifier_history Day 12 R1 evaluator + subagent_verification field 追加)

### Week 2 Day 12 時点の累計指標

| 指標 | Day 11 | Day 12 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 300 | +22 (RetiredEntity) | **322** |
| Provenance 層 type | 4 | +1 (RetiredEntity) | **5 type 完備** |
| Provenance 層 relation | 3 | 0 | **3 relation (Day 13 で auxiliary 追加予定)** |
| AgentSpec build jobs | 100 | +1 (RetiredEntity) | **101 jobs** |
| AgentSpecTest build jobs | 117 | +2 (RetiredEntity test + derived) | **119 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 6 度連続検証 + v2 初運用検証 | 7 度目運用検証 (v2 2 度目運用検証) | **1 + 7 度連続検証 + v2 2 度目運用検証** |
| PROV-O 完全カバー | §4.1 のみ | +§4.4 (RetiredEntity 完備) | **§4.1 + §4.4 同時完全カバー到達** |

### Day 12 で達成した TyDD / paper 進展 (Section 12.34 + 12.35)

- **02-data-provenance §4.4 退役 entity 構造的検出 完備** (RetiredEntity + RetirementReason 4 variant inductive、PROV-O §4.4 1:1 対応)
- **PROV-O §4.1 + §4.4 同時完全カバー到達** (Day 11 §4.1 + Day 12 §4.4 で PROV-O 主要 spec 完備)
- **TyDD-S1 types-first** (4 variant inductive で退役理由 semantic を型レベル区別、案 B String を退ける)
- **TyDD-S4 P5 explicit assumptions 3 度目強適用** (Day 8 B4 → Day 11 PROV-O relation → Day 12 RetirementReason payload 型化)
- **Pattern #7 hook v2 2 度目運用検証成功** (Day 11 1 度目に続く Provenance 配下新規 .lean detection)
- **Section 10.2 Pattern #7 hook の五段階発展完了** (Day 5 設計→Day 6/7/8/9 4 度運用→Day 10 v2 拡張→Day 11 v2 初運用検証→Day 12 v2 2 度目運用検証)
- **cycle 内学習 transfer** (Day 11 Subagent I3 教訓 = rfl preference を Day 12 RetiredEntityTest で実装適用、初の cycle 教訓 → 次 day 実装 transfer)
- **paper × 実装 9 度目合流カテゴリ確立** (PROV-O §4.1 + §4.4 同時完全カバー × cycle 内学習 transfer)
- **paper finding 44 件累計** (Day 4-12 + Day 1-3 関連)
- **Subagent 検証 PASS** (本評価サイクル内で即時実施、Day 11 遡及検証教訓反映、paper サーベイ評価サイクル「実装修正組込み」4 度目適用、改訂 56 で対処)

## 現状: Phase 0 Week 2 Day 13 完了（2026-04-18 追加）

Section 2.24 Day 13 着手前判断 (Q1 A-Minimal / Q3 案 B 別 file 配置 / Q4 案 A WasRetiredBy = Entity → RetiredEntity 2-arg) に従い実装。
**PROV-O auxiliary relations + WasRetiredBy 完備** (WasInformedBy + ActedOnBehalfOf + WasRetiredBy、3 structure)、
**PROV-O 6 relation 完備到達** (Day 11 main 3 + Day 13 auxiliary 2 + WasRetiredBy 1 = §4.1 main + auxiliary + §4.4 retirement 統合)、
**Pattern #7 hook v2 3 度目運用検証成功 = 運用定常化** (Day 11 1 度目 / Day 12 2 度目 / Day 13 3 度目連続)、
**Subagent 検証 PASS + I1 即時対処** (本評価サイクル内で即時実施、Day 12 同パターン継続、改訂 61 で対処)、
**cycle 内学習 transfer 構造的効果実証** (Day 12 I1 教訓 → Day 13 先回り適用で Subagent 検出項目数 4→1 減少)。

### Day 13 の 1 項目 (Q2 A-Minimal scope)

- [x] **PROV-O auxiliary + WasRetiredBy 3 separate structure** (`AgentSpec/Provenance/ProvRelationAuxiliary.lean`、Q3 案 B 別 file 配置 + Q4 案 A、PROV-O §4.1 auxiliary + §4.4 retirement 1:1 対応)
  - `structure WasInformedBy { activity : ResearchActivity, informer : ResearchActivity }` (PROV-O §4.1 auxiliary)
  - `structure ActedOnBehalfOf { agent : ResearchAgent, on_behalf_of : ResearchAgent }` (PROV-O §4.1 auxiliary、snake_case = PROV-O 命名規約準拠)
  - `structure WasRetiredBy { entity : ResearchEntity, retired : RetiredEntity }` (PROV-O §4.4 retirement relation、Day 12 RetiredEntity 再利用 = 2-arg relation)
  - 各 mk' smart constructor + trivial fixture
  - 1 ファイル統合配置 (D1、Day 11 ProvRelation の auxiliary 側踏襲)
  - 別 file 配置 (D1、ProvRelation.lean = main、本 file = auxiliary、main/auxiliary の semantic 区別)
  - deriving Inhabited, Repr (DecidableEq は WasRetiredBy が RetiredEntity 経由で ResearchEntity recursive 制約継承で省略)
- [x] `AgentSpec/Test/Provenance/ProvRelationAuxiliaryTest.lean` (**24 件**、3 relation 構築 + accessor + smart constructor + trivial + Inhabited + entity 重複参照 accessor pattern + PROV-O 6 relation 統合 example)
  - Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 2 度目): 全 example で rfl preference 維持 (simp tactic 不使用、最終 And 分解のみ refine + rfl 連鎖)
- [x] `lake build AgentSpec` ✓ (exit 0, **102 jobs**、Provenance 層 +1)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **121 jobs**)
- [x] /verify Round 1 PASS (build PASS + Subagent 即時検証 PASS、本評価サイクル内で即時実施、改訂 61 で対処)
- [x] **Pattern #7 hook v2 3 度目運用検証成功** (Day 11/12/13 で 3 度連続、運用定常化)
- [x] **Subagent I1 即時実装修正対処** (Day 13 R1 evaluator back-fill = Day 12 I2 同パターン)
- [x] **Day 12 I1 教訓先回り適用** (version field `0.13.0-week2-day13` を code commit 時点で正しく設定、Subagent 検出項目数 Day 12 の 4→1 減少 = cycle 内学習 transfer の構造的効果実証)

### Week 2 Day 13 時点の累計指標

| 指標 | Day 12 | Day 13 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 322 | +24 (ProvRelationAuxiliary) | **346** |
| Provenance 層 type | 5 | 0 (relation のみ追加) | **5 type** |
| Provenance 層 relation | 3 | +3 (auxiliary 2 + WasRetiredBy 1) | **6 relation 完備** |
| AgentSpec build jobs | 101 | +1 (ProvRelationAuxiliary) | **102 jobs** |
| AgentSpecTest build jobs | 119 | +2 (ProvRelationAuxiliary test + derived) | **121 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 7 度連続検証 + v2 2 度目運用検証 | 8 度目運用検証 (v2 3 度目運用検証) | **1 + 8 度連続検証 + v2 3 度目運用検証 = 運用定常化** |
| PROV-O 完全カバー | §4.1 + §4.4 | +§4.1 auxiliary + §4.4 retirement relation | **§4.1 main + auxiliary + §4.4 完全カバー (6 relation 統合)** |

### Day 13 で達成した TyDD / paper 進展 (Section 12.37 + 12.38)

- **02-data-provenance §4.1 auxiliary relations 完備** (WasInformedBy + ActedOnBehalfOf 2 structure、PROV-O §4.1 auxiliary 1:1 対応)
- **02-data-provenance §4.4 retirement relation 完備** (WasRetiredBy = Entity → RetiredEntity 2-arg、Day 12 RetiredEntity 再利用)
- **PROV-O 6 relation 完備到達** (Day 11 main 3 + Day 13 auxiliary 2 + WasRetiredBy 1 = §4.1 + §4.4 relation 主要 spec 統合)
- **TyDD-S4 P5 explicit assumptions 4 度目強適用** (Day 8 B4 → Day 11 PROV-O relation → Day 12 RetirementReason payload → Day 13 ProvRelationAuxiliary 引数 type 厳格)
- **Pattern #7 hook v2 3 度目運用検証成功 = 運用定常化** (Day 11/12/13 で 3 度連続)
- **Section 10.2 Pattern #7 hook の六段階発展完了** (Day 5 設計→Day 6/7/8/9 4 度運用→Day 10 v2 拡張→Day 11/12/13 v2 3 度連続運用検証)
- **Day 12 D2 separate structure 配置の妥当性確認** (WasRetiredBy 経由で RetiredEntity 再利用)
- **内部規範 layer 横断 transfer 8 段階目** (PROV-O 6 relation 統合 example、Day 11 triple set / Day 12 4 variant List 集約に続く)
- **paper × 実装 10 度目合流カテゴリ確立** (PROV-O 6 relation 完備 × separate design 妥当性継続確認)
- **paper finding 49 件累計** (Day 4-13 + Day 1-3 関連)
- **Subagent 検証 PASS + I1 即時対処** (本評価サイクル内で即時実施、paper サーベイ評価サイクル「実装修正組込み」5 度目適用、改訂 61 で対処)
- **cycle 内学習 transfer 構造的効果実証** (Day 12 I1 教訓 → Day 13 先回り適用、Subagent 検出項目数 4→1 減少)

## 現状: Phase 0 Week 2 Day 14 完了（2026-04-18 追加）

Section 2.26 Day 14 着手前判断 (Q1 A 案 / Q2 A-Minimal / Q3 案 A / Q4 案 C) に従い実装。
**RetiredEntity linter A-Minimal 実装** (Lean 4 標準 `@[deprecated]` 4 fixture)、
**Day 11-13 type/relation 軸と直交する新次元「強制化」追加**、
**段階的拡張パス確立** (A-Minimal → A-Compact → A-Standard → A-Maximal)、
**Pattern #7 hook MODIFY path 対応確認** (新規 file 追加なし commit でも機能確認、hook 七段階発展完了)、
**Subagent 検証 PASS + I1 即時対処** (本評価サイクル内で即時実施、Day 12-13 同パターン継続、改訂 66 で対処)、
**cycle 内学習 transfer 構造的効果継続** (Day 11-14 で 4 Day 連続 rfl preference 維持、Day 13-14 で Subagent 検出項目数 1 安定維持)。

### Day 14 の 1 項目 (Q2 A-Minimal scope、MODIFY のみ)

- [x] **RetiredEntity 4 deprecated fixture 追加** (`AgentSpec/Provenance/RetiredEntity.lean` MODIFY、Q3 案 A + Q4 案 C、PROV-O §4.4 退役参照警告 1:1 対応)
  - `@[deprecated "退役済 entity - RetirementReason を確認 (Day 14 linter A-Minimal)" (since := "2026-04-18")]` 4 fixture 付与
  - `refutedTrivialDeprecated` / `supersededTrivialDeprecated` / `obsoleteTrivialDeprecated` / `withdrawnTrivialDeprecated` (4 RetirementReason variant 各対応)
  - test fixture のみ対象、production code structure / smart constructor 自体は変更なし (backward compatible)
  - docstring に Day 14 意思決定ログ D1-D2 + `@[deprecated]` 使用例 (warning 発生 / 抑制の例) 追加
- [x] `AgentSpec/Test/Provenance/RetiredEntityTest.lean` MODIFY (**22→30 件**、+8 example)
  - 4 deprecated fixture の entity / reason / whyRetired accessor rfl 確認
  - `set_option linter.deprecated false in` で warning 抑制 (build PASS 維持)
  - 4 variant List 集約 (既存 4 variant List 集約との対称性)
  - Day 11 Subagent I3 教訓継続適用 (cycle 内学習 transfer 3 度目、Day 11-14 = 4 Day 連続 rfl preference 維持)
- [x] `lake build AgentSpec` ✓ (exit 0, **102 jobs 維持**、MODIFY のみで jobs 変化なし)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **121 jobs 維持**)
- [x] /verify Round 1 PASS (build PASS + Subagent 即時検証 PASS、本評価サイクル内で即時実施、改訂 66 で対処)
- [x] **Pattern #7 hook MODIFY path 対応確認** (新規 file 追加なし commit でも artifact-manifest 同 commit 機能、Day 11-13 新規 file パターンからの拡張)
- [x] **Subagent I1 即時実装修正対処** (Day 14 R1 evaluator back-fill = Day 12-13 I1 同パターン)

### Week 2 Day 14 時点の累計指標

| 指標 | Day 13 | Day 14 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 346 | +8 (RetiredEntityTest 内) | **354** |
| Provenance 層 type | 5 | 0 | **5 type** |
| Provenance 層 relation | 6 | 0 | **6 relation** |
| Provenance 層 linter | 0 (structural detection のみ) | +1 (A-Minimal @[deprecated] 4 fixture) | **1 linter A-Minimal** |
| AgentSpec build jobs | 102 | 0 (MODIFY のみ) | **102 jobs 維持** |
| AgentSpecTest build jobs | 121 | 0 (MODIFY のみ) | **121 jobs 維持** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 8 度連続検証 + v2 3 度目運用検証 | 9 度目運用検証 (MODIFY path 対応確認) | **1 + 9 度連続検証 + v2 3 度目運用検証 + MODIFY path 対応 = 七段階発展完了** |
| PROV-O 完全カバー | §4.1 main + auxiliary + §4.4 (6 relation 統合) | +linter 強制化層 | **§4.1 + §4.4 完全カバー + linter 強制化 A-Minimal** |

### Day 14 で達成した TyDD / paper 進展 (Section 12.40 + 12.41)

- **02-data-provenance §4.4 退役参照警告 構造的強制化** (Lean 4 標準 `@[deprecated]` 4 fixture、PROV-O §4.4 1:1 対応)
- **TyDD-G3 linter integration** (Lean 4 標準機能活用、custom extension 不要で A-Minimal 完備)
- **TyDD-S4 P5 explicit assumptions 5 度目強適用** (`@[deprecated]` attribute assumption の explicit 化、since + message で assumption を型レベル記録)
- **新次元「強制化」追加** (Day 11-13 の type/relation 軸と直交する新評価軸)
- **段階的拡張パス確立** (A-Minimal → A-Compact → A-Standard → A-Maximal、Day 15+ 3 段階プラン)
- **Pattern #7 hook MODIFY path 対応確認 = 七段階発展完了** (Day 5 設計→Day 6/7/8/9 4 度運用→Day 10 v2 拡張→Day 11/12/13 v2 3 度連続→Day 14 MODIFY path 対応)
- **paper × 実装 11 度目合流カテゴリ確立** (linter A-Minimal × 段階的拡張パス × 強制化次元追加)
- **paper finding 54 件累計** (Day 4-14 + Day 1-3 関連)
- **Subagent 検証 PASS + I1 即時対処** (本評価サイクル内で即時実施、paper サーベイ評価サイクル「実装修正組込み」6 度目適用、改訂 66 で対処)
- **cycle 内学習 transfer 構造的効果継続** (Day 11-14 で 4 Day 連続 rfl preference 維持、Day 13-14 で Subagent 検出項目数 1 安定維持 = quality loop 持続的効果)
- **transitionLegacy 削除パスの linter モデル転用** (Day 14 `@[deprecated]` パターンが既存 transitionLegacy (Section 2.15 Day 9+) にも転用可能、cycle 内学習 transfer の別分野拡張)

## 現状: Phase 0 Week 2 Day 15 完了（2026-04-18 追加）

Section 2.28 Day 15 着手前判断 (Q1 A 案 / Q2 A-Compact-Hybrid / Q3 案 B 新 module / Q4 案 A 新 file test) に従い実装。
**A-Compact Hybrid macro 実装** (Lean 4 elab macro で `@[retired msg since]` を `@[deprecated msg (since := since)]` に展開、新 module `RetirementLinter.lean` で隔離)、
**Day 14 backward compatible 維持** (production `RetiredEntity.lean` / `RetiredEntityTest.lean` は変更なし)、
**段階的 Lean 機能習得パス確立** (A-Minimal 標準 attribute → **A-Compact macro** → A-Standard Elab.Command → A-Maximal elaborator の 4 段階、2/4 完了)、
**Subagent 検証 PASS + I1 初 addressable 逆方向修正対処** (改訂 71 で実施、docstring ← 実装 align、Lean 4 parser 仕様根拠、cycle 内学習 transfer の cross-verification 発展実例)、
**Day 11-15 で 5 Day 連続 rfl preference 維持** (cycle 内学習 transfer 4 度目適用、quality loop 長期持続性実証)、
**Pattern #7 hook 八段階発展完了** (新規 file パターン復帰で両パターン運用 5 度目)。

### Day 15 の 1 項目 (Q2 A-Compact-Hybrid scope、新 module + 新 file)

- [x] **A-Compact Hybrid macro 実装** (`AgentSpec/Provenance/RetirementLinter.lean` NEW、Q3 案 B 新 module 隔離)
  - `syntax (name := retired) "retired " str ppSpace str : attr` (新 attribute syntax 定義)
  - `macro_rules`: `@[retired $msg:str $since:str]` → `@[deprecated $msg:str (since := $since:str)]` 展開
  - docstring に Day 15 D1-D3 意思決定ログ + 使用例 + Subagent 検証結果注記 (改訂 71 逆方向修正対応)
  - `$msg:str` / `$since:str` 型注釈は Lean 4 4.29.0 `deprecated` parser が第一引数に ident を期待する仕様に合わせて必要 (初期 build error から即時修復、新分野学習 iteration)
- [x] `AgentSpec/Test/Provenance/RetirementLinterTest.lean` NEW (**9 example**)
  - `@[retired]` macro 展開後の 4 fixture (obsolete / withdrawn / refuted / superseded) が entity / reason / whyRetired accessor で rfl 動作
  - Day 14 `@[deprecated]` fixture と Day 15 `@[retired]` macro fixture の並存確認 (backward compatibility)
  - 8 variant 全体 List 集約 (Day 14 4 + Day 15 4 = 内部規範 layer 横断 transfer 9 段階目)
  - `set_option linter.deprecated false in` で warning 抑制、rfl preference 維持 (cycle 内学習 transfer 4 度目、Day 11-15 = 5 Day 連続)
- [x] `AgentSpec/Provenance/RetiredEntity.lean` / `AgentSpec/Test/Provenance/RetiredEntityTest.lean` **変更なし** (Day 14 backward compatible 完全維持)
- [x] `lake build AgentSpec` ✓ (exit 0, **103 jobs**、+1 RetirementLinter)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **123 jobs**、+2 RetirementLinterTest + derived)
- [x] /verify Round 1 PASS (build PASS + Subagent 即時検証 PASS + I1 初 addressable 逆方向修正対処、本評価サイクル内で即時実施、改訂 71 で対処)
- [x] **Pattern #7 hook v2 4 度目運用検証** (新規 file パターン復帰、Day 11-13 3 度 + Day 14 MODIFY + Day 15 新規 file = 両パターン 5 度運用安定性)
- [x] **Subagent I1 初 addressable 逆方向修正対処** (docstring ← 実装 align、Lean 4 4.29.0 parser 仕様根拠、初の Subagent 推奨と逆方向採用実例)
- [x] **Day 14 I1 version field 教訓継続適用** (Day 15 で `0.15.0-week2-day15` に先回り bump)

### Week 2 Day 15 時点の累計指標

| 指標 | Day 14 | Day 15 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 354 | +9 (RetirementLinterTest) | **363** |
| Provenance 層 type | 5 | 0 | **5 type** |
| Provenance 層 relation | 6 | 0 | **6 relation** |
| Provenance 層 linter | 1 (A-Minimal) | +1 (A-Compact Hybrid macro) | **2 linter: A-Minimal + A-Compact** |
| AgentSpec build jobs | 102 | +1 (RetirementLinter) | **103 jobs** |
| AgentSpecTest build jobs | 121 | +2 (RetirementLinterTest + derived) | **123 jobs** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 9 度連続検証 + 七段階発展完了 | 10 度目運用検証 (八段階発展 = 新規 file パターン復帰) | **1 + 10 度連続検証 + 八段階発展完了** |
| 段階的 Lean 機能習得 | A-Minimal のみ (1/4) | +A-Compact macro (2/4) | **A-Minimal + A-Compact (2/4 段階完了)** |

### Day 15 で達成した TyDD / paper 進展 (Section 12.43 + 12.44)

- **02-data-provenance §4.4 PROV-O `retired` semantic syntax-level 直接表現** (`@[retired]` custom attribute で Day 14 `@[deprecated]` 一般機能を PROV-O 特化)
- **A-Compact Hybrid macro 実装** (Lean 4 elab macro `macro_rules` で Day 14 A-Minimal backward compatible 維持しつつ PROV-O semantic 強化)
- **段階的 Lean 機能習得パス確立** (A-Minimal → A-Compact の 2 段階、Day 16+ A-Standard Elab.Command → Week 5-6 A-Maximal elaborator への前提準備完了)
- **TyDD-S4 P5 explicit assumptions 6 度目強適用** (syntax-level since 必須化 = 全 `@[retired]` 利用で explicit assumption 自動強制、Day 14 個別付与から一般化)
- **Pattern #7 hook 八段階発展完了** (Day 5 設計→Day 6/7/8/9 4 度運用→Day 10 v2 拡張→Day 11/12/13 v2 3 度連続→Day 14 MODIFY path 対応→Day 15 新規 file パターン復帰、両パターン運用 5 度目)
- **paper × 実装 12 度目合流カテゴリ確立** (A-Compact macro × 段階的 Lean 機能習得パス × 逆方向修正実例)
- **paper finding 59 件累計** (Day 4-15 + Day 1-3 関連)
- **Subagent 検証 PASS + I1 初 addressable 逆方向修正対処** (改訂 71 で実施、docstring ← 実装 align、Lean 4 parser 仕様根拠、paper サーベイ評価サイクル「実装修正組込み」7 度目適用で質的発展)
- **cycle 内学習 transfer の cross-verification 発展** (Day 11-14 単純 transfer → Day 15 critical evaluation、Subagent 推奨を Lean 4 parser 仕様根拠で逆方向評価採用)
- **初期 build error からの即時修復実例** (`$msg:str` 型注釈必須、新分野 Lean 4 4.29.0 parser 仕様学習の実装 iteration)
- **Day 14 + Day 15 両モデル揃い transitionLegacy 削除の最適 timing 到達** (Day 16+ で cycle 内学習 transfer 2 段階別分野転用実例として実施候補、Section 2.15 Day 9+ からの繰り延べ解消候補)

## 現状: Phase 0 Week 2 Day 16 完了（2026-04-18 追加）

Section 2.30 Day 16 着手前判断 (Q1 B 案 / Q2 A-Compact / Q3 案 A / Q4 案 A) に従い実装。
**transitionLegacy deprecation A-Compact 実装** (Day 14 `@[deprecated]` モデルの Spine 層別分野転用、cycle 内学習 transfer 2 段階別分野転用実例)、
**TransitionReflexive/Transitive 4-arg signature 直接展開 refactor** (Day 8 D3 暫定方針撤回、Section 2.9 完結)、
**Section 2.15 Day 9+ 繰り延べ 6 セッション課題 A-Compact で半解消** (完全削除は Day 17+ A-Standard へ、`since := "2026-04-19"` = Day 17 指定日で signal)、
**Subagent 検証 PASS + I1 docstring 明文化 + I2 evaluator back-fill 対処** (改訂 76 で実施、Day 15 cross-verification と対比で単純 transfer 対応実証)、
**Day 11-16 で 6 Day 連続 rfl preference 維持の記録更新** (cycle 内学習 transfer 5 度目適用)、
**Pattern #7 hook 九段階発展完了** (MODIFY path 2 度目運用検証で両パターン運用 6 度目)、
**cycle 内学習 transfer 4 形態体系化完了** (単純 / 先回り / cross-verification / 2 段階別分野転用)。

### Day 16 の 1 項目 (Q2 A-Compact scope、MODIFY のみ)

- [x] **transitionLegacy に `@[deprecated]` 付与 + 利用箇所移行** (`AgentSpec/Spine/EvolutionStep.lean` MODIFY、Q3 案 A)
  - `@[deprecated "Use new 4-arg transition" (since := "2026-04-19")]` 付与 (since は Day 17 予定日 = 完全削除 timing signal)
  - `TransitionReflexive` / `TransitionTransitive` を 4-arg signature 直接展開に refactor (Day 8 D3 暫定 legacy ベース方針撤回、Section 2.9 完結)
  - docstring に Day 16 D5-D6 意思決定ログ + since 1 日ずれ明文化 (Subagent I1 対処、改訂 76)
  - Day 14 `@[deprecated]` モデルの Spine 層別分野転用 (cycle 内学習 transfer 2 段階別分野転用実例)
- [x] `AgentSpec/Test/Spine/EvolutionStepTest.lean` MODIFY (**9→13 example**、+4)
  - 既存 transitionLegacy 直接利用 example 2 件を set_option linter.deprecated false in で warning 抑制
  - Day 16 新規 4 example: deprecated 付与 transitionLegacy Inhabited 2 variant + 新 signature 直接展開 proof 2 variant
  - rfl preference 維持 (cycle 内学習 transfer 5 度目、Day 11-16 = **6 Day 連続記録更新**)
- [x] `lake build AgentSpec` ✓ (exit 0, **103 jobs 維持**、MODIFY のみ)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **123 jobs 維持**)
- [x] /verify Round 1 PASS (build PASS + Subagent 即時検証 PASS + I1 docstring 明文化 + I2 evaluator back-fill、改訂 76 で対処)
- [x] **Pattern #7 hook MODIFY path 2 度目運用検証 (九段階発展完了、両パターン運用 6 度目)**
- [x] **新規 `deprecation_history` field** (artifact-manifest.json の EvolutionStep entry に追加)
  - `transitionLegacy`: introduced Day 8 (`0f78fa6`) / deprecated Day 16 (`b678856`、@[deprecated] 付与) / removal_scheduled Day 17+ A-Standard / transfer_pattern: Day 14 PROV-O 特化 → Day 16 Spine 層別分野転用
- [x] **Subagent I1 docstring 明文化対処** (since 1 日ずれの理由明文化、cycle 内学習 transfer 単純 transfer 形態適用、Day 15 cross-verification と対比実証)

### Week 2 Day 16 時点の累計指標

| 指標 | Day 15 | Day 16 追加 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 363 | +4 (EvolutionStepTest 内) | **367** |
| Provenance 層 type | 5 | 0 | **5 type** |
| Provenance 層 relation | 6 | 0 | **6 relation** |
| Provenance 層 linter | 2 (A-Minimal + A-Compact) | 0 (Day 16 は Spine 層別分野転用) | **2 linter 維持** |
| Spine 層 deprecation | 0 | +1 (transitionLegacy A-Compact) | **1 (Day 17+ A-Standard で完全削除予定)** |
| AgentSpec build jobs | 103 | 0 (MODIFY のみ) | **103 jobs 維持** |
| AgentSpecTest build jobs | 123 | 0 (MODIFY のみ) | **123 jobs 維持** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 10 度連続検証 + 八段階発展完了 | 11 度目運用検証 (MODIFY path 2 度目、九段階発展) | **1 + 11 度連続検証 + 九段階発展完了** |
| cycle 内学習 transfer 形態 | 3 形態 (単純 + 先回り + cross-verification) | +1 (2 段階別分野転用) | **4 形態体系化完了** |

### Day 16 で達成した TyDD / paper 進展 (Section 12.46 + 12.47)

- **Section 2.15 Day 9+ 繰り延べ 6 セッション課題 A-Compact で半解消** (Day 17 A-Standard 完全削除予定で完全解消到達)
- **Day 14 `@[deprecated]` モデルの Spine 層別分野転用** (cycle 内学習 transfer 2 段階別分野転用実例、Day 14 PROV-O 特化 → Day 16 単純 deprecation)
- **Day 8 D3 暫定方針撤回 + Section 2.9 完結** (TransitionReflexive/Transitive 4-arg signature 直接展開 refactor、Day 8 で legacy ベース properties を暫定採用した方針を Day 16 で完全撤回)
- **TyDD-S4 P5 explicit assumptions 7 度目強適用** (transitionLegacy deprecation since 指定で「Day 17+ 完全削除予告」attribute assumption として explicit 記録)
- **Pattern #7 hook 九段階発展完了** (両パターン運用 6 度目、Day 5-16 累積 11 セッション)
- **paper × 実装 13 度目合流カテゴリ確立** (cycle 内学習 transfer 2 段階別分野転用 × deprecation_history 構造化 × Section 2.15 6 セッション繰り延べ解消)
- **paper finding 64 件累計** (Day 4-16 + Day 1-3 関連)
- **Subagent 検証 PASS + I1/I2 即時対処** (paper サーベイ評価サイクル「実装修正組込み」8 度目適用、Day 9-16 継続)
- **cycle 内学習 transfer 4 形態体系化完了** (単純 transfer / 先回り適用 / cross-verification / 2 段階別分野転用)
- **cycle 内学習 transfer 形態選択使い分け実証** (Day 15 cross-verification / Day 16 単純 transfer、Subagent 推奨の評価基準が確立)
- **新規 `deprecation_history` field 構造化記録** (artifact-manifest 上で deprecation 変遷を追跡可能、introduced / deprecated / removal_scheduled / transfer_pattern)

## 現状: Phase 0 Week 2 Day 17 完了（2026-04-18 追加、breaking change）

Section 2.32 Day 17 着手前判断 (Q1 A 案 / Q2 A-Medium / Q3 案 A / Q4 案 A) に従い実装。
**transitionLegacy 完全削除 A-Standard 完遂** (Day 14-15-16-17 の段階的 deprecation → removal 工学的 best practice 4 Day 完結、`since := "2026-04-19"` = Day 17 指定日履行)、
**Section 2.15 Day 9+ 9 セッション繰り延べ課題完全解消** (agent-manifesto 内最長記録繰り延べ解消)、
**cycle 内学習 transfer 2 段階別分野転用の Day 14→Day 16→Day 17 3 Day 完結** (PROV-O 特化 → Spine 層 A-Compact → Spine 層 A-Standard)、
**Day 9-17 で初の Subagent 指摘ゼロ到達** (cycle 内学習 transfer 累積効果の極致実例、quality loop 完全機能実証)、
**Day 11-17 で 7 Day 連続 rfl preference 維持の記録更新** (set_option 不要化でより pure)、
**Pattern #7 hook 十段階発展到達** (MODIFY path 3 度目運用検証、breaking change commit 対応確認)、
**deprecation_history 3-state complete lifecycle 構造化完成** (Day 8 introduced → Day 16 deprecated → Day 17 removed)。

### Day 17 の 1 項目 (Q2 A-Medium scope、MODIFY のみ、**breaking change**)

- [x] **transitionLegacy 定義完全削除 + 利用箇所 test 3 件削除** (Q3 案 A Test 先行 → Production 後続)
- [x] `AgentSpec/Test/Spine/EvolutionStepTest.lean` MODIFY (先行、**13→10 example、-3**)
  - deprecated 利用 example 3 件全削除 (既存 Day 8 から 1 件 + Day 16 新規 2 件)
  - 新 signature 直接展開 proof 2 件 (Day 16 新規 TransitionReflexive / TransitionTransitive witness) は保持
  - `set_option linter.deprecated false in` 全て不要化 (transitionLegacy 完全削除でより pure な rfl preference)
  - rfl preference 維持 (cycle 内学習 transfer 6 度目、Day 11-17 = **7 Day 連続記録更新**)
- [x] `AgentSpec/Spine/EvolutionStep.lean` MODIFY (後続)
  - `transitionLegacy` 定義完全削除 (`@[deprecated] def transitionLegacy` 全削除)
  - `TransitionReflexive` / `TransitionTransitive` は Day 16 4-arg 直接展開済のため変更不要
  - docstring に Day 17 D7 意思決定ログ追加 + Day 8-16 history セクション整理
- [x] `lake build AgentSpec` ✓ (exit 0, **103 jobs 維持**、MODIFY のみ)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **123 jobs 維持**)
- [x] /verify Round 1 PASS (**build PASS + Subagent 検証 PASS + 指摘ゼロ到達**、改訂 82 で対処)
- [x] **Pattern #7 hook MODIFY path 3 度目運用検証 (十段階発展到達、breaking change commit 対応確認)**
- [x] **新規 `deprecation_history.transitionLegacy.removal_actual` field** (artifact-manifest.json の EvolutionStep entry に追加、3-state complete lifecycle 完成)
- [x] **新規 `section_2_15_completely_resolved_day17` field** (build_status 直下、Section 2.15 完全解消構造化記録)
- [x] **compatibility_classification: breaking change** (verifier_history Day 17 R1 entry)

### Week 2 Day 17 時点の累計指標

| 指標 | Day 16 | Day 17 追加/変化 | 合計 |
|---|---|---|---|
| theorem 数 | 15 | 0 | **15** |
| example 数 | 367 | -3 (EvolutionStepTest 内 deprecated 3 件削除) | **364** |
| Provenance 層 type | 5 | 0 | **5 type** |
| Provenance 層 relation | 6 | 0 | **6 relation** |
| Provenance 層 linter | 2 (A-Minimal + A-Compact) | 0 | **2 linter** |
| Spine 層 deprecation | 1 (transitionLegacy A-Compact) | **-1 (完全削除 A-Standard)** | **0 (削除完了)** |
| AgentSpec build jobs | 103 | 0 (MODIFY のみ) | **103 jobs 維持** |
| AgentSpecTest build jobs | 123 | 0 (MODIFY のみ) | **123 jobs 維持** |
| sorry / axiom | 0 / 0 | 0 / 0 | **0 / 0** |
| 構造的 governance hook | 1 + 11 度連続検証 + 九段階発展完了 | 12 度目運用検証 (MODIFY path 3 度目、breaking change 対応) | **1 + 12 度連続検証 + 十段階発展到達** |
| cycle 内学習 transfer 形態 | 4 形態体系化完了 | **+累積効果極致実例 (Day 17 Subagent 指摘ゼロ)** | **4 形態体系化 + 累積効果極致到達** |
| Subagent 指摘項目数 | 2 (Day 16) | **-2 (Day 17 で 0 到達)** | **0 (Day 9-17 で初)** |

### Day 17 で達成した TyDD / paper 進展 (Section 12.49 + 12.50)

- **Section 2.15 Day 9+ 9 セッション繰り延べ課題完全解消** (agent-manifesto 内最長記録繰り延べ解消)
- **段階的 deprecation → removal 工学的 best practice 4 Day 完結** (Day 14 A-Minimal → Day 15 A-Compact Hybrid → Day 16 A-Compact deprecated → Day 17 A-Standard removal)
- **cycle 内学習 transfer 2 段階別分野転用の Day 14→16→17 3 Day 完結** (PROV-O 特化 → Spine 層 A-Compact → Spine 層 A-Standard)
- **TyDD-S4 P5 explicit assumptions 8 度目強適用** (`since := "2026-04-19"` 履行で attribute 約束遵守、2 Day にまたがる explicit 実証)
- **Pattern #7 hook 十段階発展到達** (MODIFY path 3 度目、breaking change commit 対応確認、Day 5-17 累積 13 セッション)
- **paper × 実装 14 度目合流カテゴリ確立** (cycle 内学習 transfer 累積効果による Subagent 指摘ゼロ × deprecation_history 3-state lifecycle 完成 × breaking change 安全実施パターン)
- **paper finding 69 件累計** (Day 4-17 + Day 1-3 関連)
- **Subagent 検証 PASS + 指摘ゼロ到達** (Day 9-17 で初、cycle 内学習 transfer 累積効果の極致実例、quality loop 完全機能実証、maturity 到達)
- **breaking change 安全実施パターン確立** (Day 16 A-Compact で利用箇所移行済のため影響最小、外部 public API なし、internal test のみ影響)
- **deprecation_history 3-state complete lifecycle 構造化完成** (introduced Day 8 → deprecated Day 16 → removal_actual Day 17)
- **新規 `section_2_15_completely_resolved_day17` field** (artifact-manifest 上に Section 2.15 完全解消を構造化記録)
- **set_option linter.deprecated false in 不要化** (Day 11-17 rfl preference がより pure、7 Day 連続記録更新)

## 現状: Phase 0 Week 2 Day 18 完了（2026-04-19 追加、段階的 Lean 機能習得 3/4 段階目達成）

Section 2.34 Day 18 着手前判断 (Q1 A 案 / Q2 A-Minimal / Q3 案 A / Q4 案 A) に従い実装。
**A-Standard custom linter A-Minimal 実装** (`#check_retired` command、Lean.Elab.Command 拡張、Lean.Linter.isDeprecated API 利用、段階的 Lean 機能習得 **3/4 段階目達成**)、
**Day 11-18 で 8 Day 連続 rfl preference 維持の記録更新**、
**Pattern #7 hook 十一段階発展到達** (新規 file パターン復帰、v2 5 度目運用検証)、
**強制化次元 +1 (3 到達)** (A-Minimal + A-Compact + A-Standard A-Minimal)、
**Day 17 指摘ゼロ持続性検証結果** (addressable 0 維持、informational 2 は design space richness)、
**初期 build error 即時修復 2 度目実例** (Day 15 macro syntax に続くパターン)。

### Day 18 の 1 項目 (Q2 A-Minimal scope)

- [x] **`#check_retired` command** (`AgentSpec/Provenance/RetirementLinterCommand.lean` NEW、Q3 案 A 新 module 隔離)
  - `elab "#check_retired " id:ident : command => do ...` 定義、Lean.Linter.isDeprecated API 経由で @[deprecated] 付き判定、info output 発生
  - Day 14 A-Minimal fixture / Day 15 @[retired] macro 展開後を実行時検査可能
  - docstring に Day 18 D1-D3 意思決定ログ + 使用例
- [x] `AgentSpec/Test/Provenance/RetirementLinterCommandTest.lean` NEW (**6 example + 5 `#check_retired` command invocation**)
  - Day 14 deprecated fixture 4 variant → retired 判定 (✓ info output)
  - Day 12 通常 fixture 1 variant → not retired 判定 (✗ info output)
  - rfl preference 維持 (cycle 内学習 transfer 6 度目、Day 11-18 = 8 Day 連続)
  - 初期 build error (parser 状態競合) から section 分離で修復済
- [x] `lake build AgentSpec` ✓ (exit 0, **104 jobs**、+1 RetirementLinterCommand)
- [x] `lake build AgentSpecTest` ✓ (exit 0, **125 jobs**、+2 RetirementLinterCommandTest + derived)
- [x] /verify Round 1 PASS (Subagent 検証 PASS、addressable 0、informational 2 = I1 即時対処 + I2 Day 19+ improvement proposal)
- [x] **Pattern #7 hook v2 5 度目運用検証 (新規 file 復帰、十一段階発展到達)**
- [x] **段階的 Lean 機能習得 3/4 段階目達成** (A-Minimal → A-Compact → **A-Standard A-Minimal** → Week 5-6 A-Maximal)
- [x] **Day 17 指摘ゼロ持続性検証結果構造化** (addressable 0 維持、informational 2 は design space richness)

### Week 2 Day 18 時点の累計指標

| 指標 | Day 17 | Day 18 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 364 | 0 / +6 | **15 / 370** |
| Provenance 層 linter | 2 (A-Minimal + A-Compact) | +1 (A-Standard A-Minimal) | **3 (3/4 段階目達成)** |
| AgentSpec / AgentSpecTest build jobs | 103 / 123 | +1 / +2 | **104 / 125** |
| 強制化次元 | 2 | +1 (A-Standard A-Minimal) | **3** |
| Pattern #7 hook 運用検証 | 11 度連続、十段階発展到達 | 12 度目運用検証 (新規 file 復帰) | **12 度連続、十一段階発展到達** |
| Subagent 指摘項目数 | 0 (Day 17 初到達) | 2 informational (addressable 0 維持) | design space richness で informational 発生、structural quality 継続 |

### Day 18 で達成した TyDD / paper 進展 (Section 12.52 + 12.53)

- **A-Standard custom linter A-Minimal 完備** (段階的 Lean 機能習得 3/4 段階目達成)
- **Lean 4 core API 活用** (Lean.Linter.isDeprecated、TyDD-S4 P4 power-to-weight 最大化)
- **Pattern #7 hook 十一段階発展到達** (新規 file パターン復帰)
- **強制化次元 +1 (3 到達)** (Day 14 A-Minimal + Day 15 A-Compact + Day 18 A-Standard A-Minimal)
- **paper × 実装 15 度目合流カテゴリ確立** (段階的 Lean 機能習得 3/4 × 初期 build error 即時修復 2 度目 × 指摘ゼロ持続性検証)
- **paper finding 74 件累計**
- **Subagent 検証 PASS + I1 即時対処 + I2 Day 19+ improvement proposal** (新形態)
- **Day 17 指摘ゼロ持続性検証結果** (addressable 0 維持、informational 2 は design space)
- **初期 build error 即時修復 2 度目実例** (Day 15 パターン継続確立)
- **structural quality vs design space richness の区別明確化** (quality metric 多層構造)

## 現状: Phase 0 Week 2 Day 19 完了（2026-04-19 追加、A-Standard-Lite 拡張）

Section 2.36 Day 19 着手前判断 (Q1 A 案 / Q2 A-Minimal / Q3 案 A / Q4 案 A) に従い実装。
**A-Standard-Lite namespace 検出拡張** (`#check_retired_in_namespace` command、Environment.constants + Name.isPrefixOf + Lean.Linter.isDeprecated 経由 NS 配下 any depth descendants 列挙)、
Day 18 `RetirementLinterCommand.lean` + Test MODIFY (同 module + 同 file、command 系統 cohesion 維持)、
**Day 11-19 で 9 Day 連続 rfl preference 維持の記録更新**、
**Pattern #7 hook 十二段階発展到達** (MODIFY path 4 度目運用検証、両パターン運用 7 度目)、
**initial build error 即時修復 3 度目実例** (Day 15/18 パターン継続、Lean 4 parser 状態競合 → section 分離)、
**Day 17 成果 (transitionLegacy 完全削除) の Day 19 linter 経由 independent 再確認** (AgentSpec.Spine.EvolutionStep 配下 0 retired)、
**Day 17 指摘ゼロ持続性推移構造化** (Day 17=0 → Day 18=2 → Day 19=3 累積 informational、addressable 0 維持)。

### Day 19 の 1 項目 (Q2 A-Minimal scope、MODIFY のみ)

- [x] **`#check_retired_in_namespace` command 追加** (RetirementLinterCommand.lean MODIFY、Day 18 同 module)
- [x] RetirementLinterCommandTest.lean MODIFY (**6→7 example、+1 example + 3 command invocations 5→8**)
- [x] `lake build AgentSpec / AgentSpecTest` ✓ (104 / 125 jobs、Day 18 変化なし)
- [x] Subagent 検証 PASS (addressable 0、informational 3、I1/I2 即時対処 + I3 Day 20+ 繰り延べ)
- [x] `#check_retired_in_namespace` 3 invocations 動作確認:
  - AgentSpec.Provenance.RetiredEntity → 4 retired (Day 14 fixture 検出 ✓)
  - AgentSpec.Process.Failure → no retired ✓
  - **AgentSpec.Spine.EvolutionStep → no retired (Day 17 transitionLegacy 完全削除 independent 再確認 ✓)**

### Week 2 Day 19 時点の累計指標

| 指標 | Day 18 | Day 19 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 370 | 0 / +1 | **15 / 371** |
| Provenance 層 linter | 3 (A-Minimal + A-Compact + A-Standard A-Minimal) | +1 Lite 拡張 | **3 + Lite (A-Standard-Lite 完了)** |
| Command invocations (RetirementLinterCommandTest) | 5 | +3 | **8** |
| Pattern #7 hook | 十一段階発展到達 | 12 度目運用検証 (MODIFY 4 度目) | **12 度連続、十二段階発展到達** |
| Subagent 指摘項目数 | 2 informational | 3 informational (addressable 0 維持) | Day 17=0→18=2→19=3 累積 design space 傾向 |
| initial build error 即時修復 | 2 度 (Day 15/18) | +1 (Day 19) | **3 度確立 (pattern maturity)** |

### Day 19 で達成した TyDD / paper 進展 (Section 12.55 + 12.56)

- A-Standard-Lite namespace 検出拡張完了 / 段階的 Lean 機能習得 3/4 + Lite 拡張到達
- Environment.constants + Name.isPrefixOf API 活用 (TyDD-S4 P4 継続強化)
- Pattern #7 hook 十二段階発展到達 (MODIFY path 4 度目、両パターン運用 7 度目)
- paper × 実装 16 度目合流カテゴリ確立 (A-Standard-Lite × Day 17 成果 independent 再確認 × initial build error pattern 3 度確立)
- paper finding 79 件累計
- Day 17 指摘ゼロ持続性推移構造化 (Day 17=0→18=2→19=3 累積 design space richness 傾向、全て non-addressable)
- Day 17 成果の Day 19 linter 経由 independent 再確認 (transitionLegacy 完全削除確認 reproducibility 実証)
- initial build error pattern 3 度目継続実例 (Day 15/18/19 で確立)
- cycle 内学習 transfer 6 度目適用継続 (Day 11-19 = 9 Day 連続記録更新)

## 現状: Phase 0 Week 2 Day 20 完了（2026-04-20 追加、A-Compact nested 拡張 + 10 Day 連続 milestone 達成）

Section 2.38 Day 20 着手前判断 (Q1 A-Compact / Q2 A-Minimal explicit depth / Q3 案 A / Q4 案 A) に従い実装。
**A-Compact nested namespace 再帰対応** (`#check_retired_in_namespace_with_depth NS N` command、Environment.constants + Name.components.length 差分で algebraic depth 計算、Day 19 "any depth" 曖昧性を A-Compact で狭義化、Day 19 Subagent I2 設計対応)、
Day 19 backward compatible 完全維持 (別 command 名で新規追加、Day 18-19 同 module MODIFY)、
**Day 11-20 = 10 Day 連続 rfl preference 維持の milestone 達成** (桁の到達、cycle 内学習 transfer 6 度目)、
**Pattern #7 hook 十三段階発展到達** (MODIFY path 5 度目運用検証、両パターン運用 8 度目)、
**段階的 Lean 機能習得 4 拡張到達** (A-Minimal + A-Compact + A-Standard A-Minimal + A-Standard-Lite + **A-Compact nested**、残り 1/4 = Week 5-6 A-Maximal)、
**Lean 4 auto-gen helper 顕在化発見** (depth=2 で Role.toCtorIdx が retired 判定、Day 21+ root cause 投資 candidate)、
**Subagent 指摘推移**: Day 17=0→18=2→19=3→**20=3 横ばい安定** (addressable 0 streak 4 Day 継続)。

### Day 20 の 1 項目 (Q2 A-Minimal scope、MODIFY のみ)

- [x] **`#check_retired_in_namespace_with_depth` command 追加** (RetirementLinterCommand.lean MODIFY)
- [x] RetirementLinterCommandTest.lean MODIFY (example 7 維持、command invocations 8→11、+3)
- [x] `lake build AgentSpec / AgentSpecTest` ✓ (104 / 125 jobs、Day 19 変化なし)
- [x] Subagent 検証 PASS (addressable 0、informational 3、I1 即時対処)
- [x] 3 invocations 動作確認:
  - RetiredEntity depth=1 → 4 retired ✓
  - **Provenance depth=2 → 5 retired (Day 14 4 fixture + Role.toCtorIdx 1 = Lean 4 auto-gen helper 顕在化)**
  - EvolutionStep depth=10 → 0 retired (Day 17 削除再々確認 ✓)

### Week 2 Day 20 時点の累計指標

| 指標 | Day 19 | Day 20 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 371 | 0 / 0 | **15 / 371** (variance 維持) |
| Provenance 層 linter | 3 + Lite (A-Standard-Lite) | +A-Compact nested | **3 + Lite + nested (4 拡張到達)** |
| Command invocations | 8 | +3 | **11** |
| Pattern #7 hook | 十二段階発展 | 13 度目運用検証 (MODIFY 5 度目) | **十三段階発展到達** |
| Subagent 指摘項目 | 3 informational | 3 informational (横ばい) | **4 Day 連続 addressable 0** |
| **rfl preference 連続記録** | 9 Day | +1 | **10 Day 連続 milestone 達成 (桁の到達)** |

### Day 20 で達成した TyDD / paper 進展 (Section 12.58 + 12.59 + 12.60)

- A-Compact nested namespace 再帰対応完了 / 段階的 Lean 機能習得 4 拡張到達 (残り 1/4 = Week 5-6 A-Maximal)
- Name.components.length 差分 algebraic depth 計算 (TyDD-S4 P4 power-to-weight 継続)
- Pattern #7 hook 十三段階発展到達 (MODIFY 5 度目)
- paper × 実装 17 度目合流カテゴリ (A-Compact nested × 10 Day milestone × Lean 4 auto-gen helper 顕在化)
- paper finding 84 件累計
- Day 17 成果再々確認 (depth=10 EvolutionStep 0 retired)
- **10 Day 連続 rfl preference milestone 達成** (Day 11-20、桁の到達、quality loop 長期持続性 10 Day 実証)
- **Lean 4 auto-gen helper Role.toCtorIdx 顕在化発見** (Day 21+ root cause investigation candidate)
- Subagent 指摘 4 Day 連続 addressable 0 (累積 design space richness 安定)
- Phase 0 累計合致率 99.0% 安定 (Day 19 99.0% から維持)

## 現状: Phase 0 Week 2 Day 21 完了（2026-04-20 追加、A-Standard-Full A-Minimal 拡張 + 11 Day 連続 milestone + long-deferred I3 解消）

Section 2.40 Day 21 着手前判断 (Q1 A-Standard-Full elaborator hook / Q2 A-Minimal pre-defined watched namespaces auto-target / Q3 案 A / Q4 案 A) に従い実装。
**A-Standard-Full A-Minimal: `#check_retired_auto` command 追加** (pre-defined hardcode list 経由 watched namespaces を一括 check、Day 22+ env-driven 拡張前提の段階的設計、Day 21 paper サーベイ 5 拡張到達)、
Day 18-20 backward compatible 完全維持 (別 command 名で新規追加、Day 18-20 同 module MODIFY、6 度目)、
**Day 11-21 = 11 Day 連続 rfl preference 維持** (cycle 内学習 transfer 6 度目、桁到達後の継続実証)、
**Pattern #7 hook 十四段階発展到達** (MODIFY path 6 度目運用検証、両パターン運用 9 度目)、
**段階的 Lean 機能習得 5 拡張到達** (A-Minimal + A-Compact + A-Standard A-Minimal + A-Standard-Lite + A-Compact nested + **A-Standard-Full A-Minimal**、残り 1/4 = Week 5-6 A-Maximal)、
**Subagent VERDICT 初の FAIL→PASS pattern 確立** (I1 docstring "5"→"4" 即時対処後 PASS、cycle 内即時修復 maturity の質的発展)、
**Day 18-20 long-deferred Subagent I3 (4 セッション繰り延べ) を Day 21 改訂 100 で解消** (Day 15 `@[retired]` macro × Day 18 `#check_retired` command 連携テスト追加、A-Compact ← A-Standard A-Minimal 連携完全実証成功、ユーザーフィードバック「論文サーベイ検証の後に実装修正・追加を必ず実施してね」反映)、
**Subagent 指摘推移**: Day 17=0→18=2→19=3→20=3→**21 初 FAIL→PASS + I2/I3 実装追加 + I4 繰り延べ** (cycle 内学習 transfer の質的発展フェーズ突入)。

### Day 21 の 1 項目 + long-deferred 解消 (Q2 A-Minimal scope、MODIFY のみ)

- [x] **`#check_retired_auto` command 追加** (RetirementLinterCommand.lean MODIFY、Day 18-20 同 module、watched namespaces hardcode list)
- [x] RetirementLinterCommandTest.lean MODIFY (example 7→8、command invocations 11→12、+1 example + 1 invocation)
- [x] **改訂 100 long-deferred I3 解消**: `import AgentSpec.Provenance.RetirementLinter` 追加 + `@[retired "..." "2026-04-20"] def day21LinkageFixture` + `#check_retired ... .day21LinkageFixture` invocation 追加 → build PASS で「✓ '...day21LinkageFixture' is retired」確認、A-Compact ← A-Standard A-Minimal 連携完全実証
- [x] `lake build AgentSpec / AgentSpecTest` ✓ (Day 20 jobs 数維持)
- [x] **Subagent 検証 初の FAIL→PASS** (initial: I1 addressable=1 docstring "5"→"4" 訂正で PASS、I2 即時対処 + I3 実装追加 + I4 Day 22+ 繰り延べ)
- [x] `#check_retired_auto` 動作確認: RetiredEntity 4 + Failure 0 + EvolutionStep 0 = total 4 ✓ (Role.toCtorIdx は watched namespaces 直下対象外で counted 除外)

### Week 2 Day 21 時点の累計指標

| 指標 | Day 20 | Day 21 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 371 | 0 / +1 | **15 / 372** |
| Provenance 層 linter | 4 拡張 (A-Compact nested まで) | +A-Standard-Full A-Minimal | **5 拡張到達 (A-Standard-Full A-Minimal 完了)** |
| Command invocations | 11 | +1 hardcode auto + 1 連携 | **13** |
| Pattern #7 hook | 十三段階発展 | 14 度目運用検証 (MODIFY 6 度目) | **十四段階発展到達** |
| Subagent 指摘項目 | 3 informational (addressable 0) | initial FAIL→PASS pattern 初確立 | **新パターン: addressable 即時対処サイクル** |
| **rfl preference 連続記録** | 10 Day | +1 | **11 Day 連続 (桁到達後の継続実証)** |

### Day 21 で達成した TyDD / paper 進展 (Section 12.61 + 12.62 + 12.63)

- A-Standard-Full A-Minimal 完備 / 段階的 Lean 機能習得 5 拡張到達 (残り 1/4 = Week 5-6 A-Maximal)
- pre-defined hardcode list + Day 22+ env-driven 拡張前提の段階的設計 (TyDD-D9 design judgement)
- Pattern #7 hook 十四段階発展到達 (MODIFY 6 度目)
- paper × 実装 18 度目合流カテゴリ (A-Standard-Full A-Minimal × long-deferred I3 解消 × 11 Day 連続 rfl preference)
- paper finding 89 件累計 (+5)
- **Day 18-20 long-deferred I3 (4 セッション繰り延べ) を Day 21 改訂 100 で解消** (Day 15 macro × Day 18 command 連携完全実証)
- **11 Day 連続 rfl preference (桁到達後の継続実証、quality loop 長期持続性)** 
- **Subagent VERDICT 初の FAIL→PASS pattern 確立** (cycle 内即時修復 maturity)
- Phase 0 累計合致率 **99.1% 到達** (Day 20 99.0% から +0.1pt 改善、Phase 0 99.1% 新高水準)
- ユーザーフィードバック直接反映 (「論文サーベイ検証の後に実装修正・追加を必ず実施してね」→ I3 long-deferred 解消の動機)

## 現状: Phase 0 Week 2 Day 22 完了（2026-04-20 追加、A-Standard-Full-Standard A-Minimal 拡張 + PersistentEnvExtension callback + env iteration correctness fix + 12 Day 連続 milestone）

Section 2.42 Day 22 着手前判断 (Q1 A-Standard-Full-Standard PersistentEnvExtension callback / Q2 A-Minimal env-driven + register / Q3 案 A 同 module MODIFY / Q4 案 A 同 file test MODIFY) に従い実装。
**A-Standard-Full-Standard A-Minimal: `SimplePersistentEnvExtension` + `register_retirement_namespace` command 追加**, Day 21 hardcode list は `defaultWatchedRetirementNamespaces` で保持し additive 連結 (`hardcode ++ extension.getState env`) で backward compatible 完全維持、`#check_retired_auto` を `getWatchedRetirementNamespaces env` 経由に rewire (register 0 件で Day 21 同 output)、
**Day 18-21 backward compatible 完全維持** (Day 22 register API は新 command、既存 commands は env iteration map₁→toList correctness fix で behavior は Day 21 まで変化なし＝対象が imported のみだったため)、
**Day 11-22 = 12 Day 連続 rfl preference 維持** (cycle 内学習 transfer 6 度目、桁到達後 12 Day 継続実証)、
**Pattern #7 hook 十五段階発展到達** (MODIFY path 7 度目運用検証、両パターン運用 10 度目)、
**段階的 Lean 機能習得 6 拡張到達** (A-Minimal + A-Compact + A-Standard A-Minimal + A-Standard-Lite + A-Compact nested + A-Standard-Full A-Minimal + **A-Standard-Full-Standard A-Minimal**、残り 1/4 = Week 5-6 A-Maximal)、
**env iteration correctness fix** (Day 18-21 同 module 3 commands `env.constants.map₁.toList` → `env.constants.toList` 同時改善、SMap.toList = map₂.toList ++ map₁.toList で current-module declarations も検出可能化、bug fix + 0 behavior 退行)、
**Subagent VERDICT PASS + 1 addressable 即時対処 → 0** (build_status.note 数値齟齬訂正、Day 17/22 で 2 度目の即時対処サイクル完遂、5 Day 連続 cycle 内即時修復実例)、
**Subagent 指摘推移**: Day 17=0→18=2→19=3→20=3→21 初 FAIL→PASS+4 informational→**22 PASS+1 addressable 即時 0+2 informational** (正常 cycle 復帰)。

### Day 22 の 1 項目 + correctness fix (Q2 A-Minimal scope、MODIFY のみ)

- [x] **`SimplePersistentEnvExtension Name (Array Name)` + `register_retirement_namespace` command + `defaultWatchedRetirementNamespaces` + `getWatchedRetirementNamespaces` 追加** (RetirementLinterCommand.lean MODIFY、Day 18-21 同 module、env-driven 化 + backward compat)
- [x] RetirementLinterCommandTest.lean MODIFY (example 7→8、command invocations 13→15、+1 example: defaultWatchedRetirementNamespaces type-level、+1 register、+1 second auto check)
- [x] **env iteration map₁→toList correctness fix**: Day 18-21 同 module 3 commands を同時改善 (output Day 21 までと変化なし＝対象が imported のみだったため)
- [x] `lake build AgentSpec / AgentSpecTest` ✓ (Day 21 jobs 数維持 104+125 = 128 jobs total build PASS)
- [x] **Subagent 検証 PASS** (initial: 1 addressable build_status.note 数値齟齬 → 即時対処後 0 + 2 informational)
- [x] env-driven `#check_retired_auto` 動作確認:
  - register 0 件 (Day 21 default): RetiredEntity 4 + Failure 0 + EvolutionStep 0 = total 4 in 3 NS ✓ (backward compatible)
  - register 1 件 (本 test namespace 自己参照): + Test.Provenance.RetirementLinterCommand 1 = total 5 in 4 NS ✓ (env-driven extension 動作実証)

### Week 2 Day 22 時点の累計指標

| 指標 | Day 21 | Day 22 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 372 | 0 / 0 | **15 / 372** (Day 21 改訂 100 で +1、Day 22 で +1 → 累計 +2 だが breakdown 372) |
| Provenance 層 linter | 5 拡張 (A-Standard-Full A-Minimal まで) | +A-Standard-Full-Standard A-Minimal | **6 拡張到達 (A-Standard-Full-Standard A-Minimal 完了)** |
| Command invocations | 13 | +2 (register + auto re-check) | **15** |
| Pattern #7 hook | 十四段階発展 | 15 度目運用検証 (MODIFY 7 度目) | **十五段階発展到達** |
| Subagent 指摘項目 | 初 FAIL→PASS pattern | 1 addressable → 即時 0 + 2 informational | **正常 cycle 復帰 (Day 17/22 で 2 度目の即時対処サイクル)** |
| **rfl preference 連続記録** | 11 Day | +1 | **12 Day 連続 (桁到達後 12 Day 継続実証)** |

### Day 22 で達成した TyDD / paper 進展 (Section 12.64 + 12.65 + 12.66)

- A-Standard-Full-Standard A-Minimal 完備 / 段階的 Lean 機能習得 6 拡張到達 (残り 1/4 = Week 5-6 A-Maximal)
- PersistentEnvExtension 経由 env-driven 化 + Day 21 hardcode list を additive 連結 backward compat (TyDD-S4 P4 標準 API + S1 types-first)
- Pattern #7 hook 十五段階発展到達 (MODIFY 7 度目)
- paper × 実装 19 度目合流カテゴリ (A-Standard-Full-Standard A-Minimal × env-driven 化 × env iteration correctness fix × 12 Day 連続 rfl preference)
- paper finding 94 件累計 (+5)
- **env iteration map₁→toList correctness fix** (Day 18-21 同 module 3 commands 同時改善、bug fix + 0 behavior 退行)
- **12 Day 連続 rfl preference (桁到達後 12 Day 継続実証、quality loop 長期持続性)**
- Subagent VERDICT PASS + 1 addressable 即時対処 → 0 (Day 17/22 で 2 度目の即時対処サイクル、5 Day 連続 cycle 内即時修復実例)
- Phase 0 累計合致率 **99.1% 維持** (Day 21 99.1% から維持、Phase 0 99.1% 安定継続)

## 現状: Phase 0 Week 2 Day 23 完了（2026-04-20 追加、multi-module import propagate test + 13 Day 連続 milestone + Pattern #7 hook 十六段階発展）

Section 2.44 Day 23 着手前判断 (Q1 Day 22 Subagent informational I1 直接対処 / Q2 A-Minimal helper module + register / Q3 新 helper module + 同 file MODIFY / Q4 helper で register + Test 側 import + auto check) に従い実装。
**multi-module import propagate test**: 新 helper module `AgentSpec/Test/Provenance/RetirementWatchedFixture.lean` (test scope 専用) に `@[retired]` decorated `importPropagateFixture` + `register_retirement_namespace` を含み、`AgentSpecTest.lean` と `RetirementLinterCommandTest.lean` で helper import することで Day 22 D10 `addImportedFn := fun arrs => arrs.foldl (init := #[]) (· ++ ·)` の import 越境 propagate 動作を実コード実証、
**Day 22 Subagent informational I1 直接対処完了** (1 session 短 cycle 解消、Day 21 I3 = 4 セッション long-deferred 繰り延べを防止)、
Day 22 backward compatible 完全維持 (production code 変更なし、helper は test scope のみ、Day 21 hardcode + Day 22 register + Day 23 helper propagate の additive 連結で検証)、
**Day 11-23 = 13 Day 連続 rfl preference 維持** (cycle 内学習 transfer 6 度目、桁到達後 13 Day 継続実証)、
**Pattern #7 hook 十六段階発展到達** (新規 file + MODIFY 混在 pattern 初適用、両パターン運用 11 度目)、
**Subagent VERDICT PASS + 0 addressable + 4 informational 全件即時対処** (I1 Day 21 section comment 更新 / I2 Day 22 docstring 現状反映 / I3 command_invocations 17→16 訂正 / I4 I1 統合対処、6 Day 連続 cycle 内即時修復実例)、
**Subagent 指摘推移**: Day 17=0→18=2→19=3→20=3→21 初 FAIL→PASS+4 informational→22 PASS+1 addressable 即時 0+2 informational→**Day 23 PASS+0 addressable+4 informational 全件即時対処→0 informational 残** (Day 22 feedback「論文サーベイ検証の後に実装修正・追加を必ず実施してね」継続適用、新形態: 全件 informational 即時対処で次 Day に残課題を繰越さない)。

### Day 23 の 1 項目 + 全件即時対処 (Q2 A-Minimal scope、新規 file + MODIFY 混在)

- [x] **新 helper module `AgentSpec/Test/Provenance/RetirementWatchedFixture.lean` 作成** (NEW、test scope 専用、`@[retired]` decorated `importPropagateFixture` + `register_retirement_namespace AgentSpec.Test.Provenance.RetirementWatchedFixture`)
- [x] RetirementLinterCommand.lean MODIFY (D13 docstring 追加のみ、production 変更なし)
- [x] RetirementLinterCommandTest.lean MODIFY (example 8→9、command invocations 15→16、+1 example: importPropagateFixture 参照、+1 #check_retired invocation)
- [x] AgentSpecTest.lean import 追加
- [x] `lake build AgentSpec / AgentSpecTest` ✓ (AgentSpec 104 + AgentSpecTest 126 jobs、+1 job 新 helper module 分、combined 129 jobs)
- [x] **Subagent 検証 PASS + 0 addressable + 4 informational 全件即時対処** (I1-I4 全件 cosmetic doc fix、6 Day 連続 cycle 内即時修復実例)
- [x] multi-module import propagate 動作確認:
  - 1st `#check_retired_auto` (Day 23 import 追加後): 4 watched (Day 21 hardcode 3 + Day 23 helper 1) → total 5 (+ helper importPropagateFixture 1) ✓
  - 2nd `#check_retired_auto` (Day 22 self-register 後): 5 watched (+ self 1) → total 6 (+ day21LinkageFixture 1) ✓
  - `#check_retired ...importPropagateFixture` 個別: ✓ (import 越境 deprecated marker propagate 確認)

### Week 2 Day 23 時点の累計指標

| 指標 | Day 22 | Day 23 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 372 | 0 / +1 | **15 / 373** |
| Provenance 層 linter | 6 拡張 (A-Standard-Full-Standard A-Minimal まで) | multi-module propagate 実証 | **6 拡張 + multi-module propagate 完備 (残り 1/4 = Week 5-6 A-Maximal)** |
| Test scope 専用 helper module | 0 | +1 (RetirementWatchedFixture) | **1 helper (Day 23 初実装)** |
| Command invocations | 15 | +1 (#check_retired importPropagateFixture) | **16** |
| Pattern #7 hook | 十五段階発展 | 16 度目 (新規 file + MODIFY 混在 pattern 初適用) | **十六段階発展到達** |
| Subagent 指摘項目 | 1 addressable → 即時 0 + 2 informational | 0 addressable + 4 informational 全件即時対処 | **Day 23 新形態: 全件 informational 即時対処で 0 残** |
| **rfl preference 連続記録** | 12 Day | +1 | **13 Day 連続 (桁到達後 13 Day 継続実証)** |

### Day 23 で達成した TyDD / paper 進展 (Section 12.67 + 12.68 + 12.69)

- multi-module import propagate test 完備 / Day 22 D10 PersistentEnvExtension `addImportedFn` の import 越境動作を実コード実証
- test scope 専用 helper module パターン確立 (production 変更なし、test cohesion 維持、Day 22 backward compatible 完全維持)
- Pattern #7 hook 十六段階発展到達 (新規 file + MODIFY 混在 pattern 初適用、両パターン運用 11 度目)
- paper × 実装 20 度目合流カテゴリ (multi-module import propagate × helper module パターン × 13 Day 連続 rfl preference × Day 22 informational 短 cycle 解消)
- paper finding 99 件累計 (+5)
- **Day 22 Subagent informational I1 直接対処完了** (1 session 短 cycle 解消、Day 21 I3 = 4 セッション long-deferred の防止)
- **13 Day 連続 rfl preference (桁到達後 13 Day 継続実証、quality loop 長期持続性)**
- **Subagent VERDICT PASS + 0 addressable + 4 informational 全件即時対処** (6 Day 連続 cycle 内即時修復、Day 23 新形態: 全件 informational 即時対処で 0 残)
- Phase 0 累計合致率 **99.1% 維持** (Day 22 99.1% から維持、Phase 0 99.1% 安定継続)
- user feedback「論文サーベイ検証の後に実装修正・追加を必ず実施してね」継続適用 6 Day 連続、cycle 内即時修復 maturity が安定 pattern 化

## 現状: Phase 0 Week 2 Day 24 完了（2026-04-20 追加、Role.toCtorIdx long-deferred 解消 + Day 22 audit long-deferred 対応 2 例目 + 14 Day 連続 milestone + Phase 0 99.2% 到達）

Section 2.46 Day 24 着手前判断 (Q1 Role.toCtorIdx investigation 主 scope / Q2 A-Minimal probe + docstring / Q3 案 A docstring MODIFY / Q4 案 A type-level rfl example) に従い実装。
**Role.toCtorIdx long-deferred root cause investigation 解消**: temporary probe module で `Lean.Linter.deprecatedAttr.getParam?` 直接検査、root cause 特定: **Lean 4 4.29.0 upstream (since 2025-08-25) で `toCtorIdx` → `ctorIdx` rename、backward compat で旧名が `@[deprecated newName := Role.ctorIdx]` として保持**。agent-spec-lib 側の問題ではなく Lean 4 core の auto-gen helper naming change。
**Day 22 audit long-deferred 累積警告 (Role.toCtorIdx 3 Day 連続繰り延げ Day 20-22) を Day 24 で解消** (Day 25+ 長期化防止、Day 21 改訂 100 I3 = 4 セッション繰り延べ到達前に対処完遂、long-deferred 対応 2 例目)、
Day 23 backward compatible 完全維持 (production 本体 code 変更なし、deriving 副産物のみ)、
**Day 11-24 = 14 Day 連続 rfl preference 維持** (cycle 内学習 transfer 6 度目、桁到達後 14 Day 継続実証、Lean 4 deprecated alias alpha-equivalence も rfl 実証)、
**Pattern #7 hook 十七段階発展到達** (MODIFY path 8 度目運用検証、両パターン運用 12 度目)、
**Subagent VERDICT PASS + 0 addressable + 1 informational 即時対処** (aggregated_example_count 371 → 375 stale 更新、既存 issue も feedback 継続適用で即時対処、7 Day 連続 cycle 内即時修復実例、deferred 蓄積防止パターン新形態)、
**Subagent 指摘推移**: Day 17=0→18=2→19=3→20=3→21 初 FAIL→PASS+4→22 +1 addressable 即時 0+2→23 +0 addressable+4 即時 0→**Day 24 +0 addressable+1 即時 0** (7 Day 連続 cycle 内即時修復)、
**Phase 0 累計合致率 99.2% 到達** (Day 23 99.1% から +0.1pt 改善、Day 22 audit 反省を 2 例目で体現)。

### Day 24 の 1 項目 (Q2 A-Minimal scope、docstring MODIFY + test example 追加)

- [x] **Role.toCtorIdx root cause investigation** (temporary probe module で `Lean.Linter.deprecatedAttr.getParam?` 直接検査、root cause 特定完了)
- [x] RetirementLinterCommand.lean docstring D14 追加 (investigation log)
- [x] ResearchAgent.lean docstring Day 24 追記 (toCtorIdx rename 注記)
- [x] RetirementLinterCommandTest.lean Day 24 section (+2 example: Role.ctorIdx rfl + toCtorIdx = ctorIdx rfl)
- [x] `lake build AgentSpec / AgentSpecTest` ✓ (AgentSpec 104 + AgentSpecTest 126 jobs、combined 129 jobs、Day 23 維持)
- [x] **Subagent 検証 PASS + 0 addressable + 1 informational 即時対処** (aggregated_example_count 371 → 375 stale 更新、7 Day 連続 cycle 内即時修復)
- [x] type-level rfl 実証:
  - `Role.ctorIdx Role.Researcher = 0 := rfl` ✓ (Lean 4 4.29.0 新名)
  - `Role.toCtorIdx = Role.ctorIdx := rfl` ✓ (deprecated alias alpha-equivalence)

### Week 2 Day 24 時点の累計指標

| 指標 | Day 23 | Day 24 追加 | 合計 |
|---|---|---|---|
| theorem / example | 15 / 373 | 0 / +2 | **15 / 375** |
| Provenance 層 linter | 6 拡張 + multi-module propagate | Role.toCtorIdx investigation 解消 | **6 拡張 + multi-module propagate + long-deferred 2 例目解消** |
| Investigation 型 task 解消 | 0 | +1 (Role.toCtorIdx、3 Day 連続繰り延げ) | **1 (Day 22 audit long-deferred 対応 2 例目)** |
| Command invocations | 16 | 0 | **16** |
| Pattern #7 hook | 十六段階発展 | 17 度目 (MODIFY path 8 度目) | **十七段階発展到達** |
| Subagent 指摘項目 | 0 addressable + 4 informational 全件即時対処 | 0 addressable + 1 informational 即時対処 | **7 Day 連続 cycle 内即時修復 (既存 stale issue 対応新形態)** |
| **rfl preference 連続記録** | 13 Day | +1 | **14 Day 連続 (桁到達後 14 Day 継続実証)** |

### Day 24 で達成した TyDD / paper 進展 (Section 12.70 + 12.71 + 12.72)

- Role.toCtorIdx root cause investigation 解消 (Day 20-22 = 3 Day 連続繰り延べ Day 22 audit long-deferred 対応 2 例目完遂)
- Lean 4 Environment API 直接活用 (`Lean.Linter.deprecatedAttr.getParam?`、TyDD-S4 P4 power-to-weight 強化)
- Lean 4 deprecated alias alpha-equivalence を rfl で実証 (Day 11-24 rfl preference 強化、Lean 4 仕様理解深化)
- Pattern #7 hook 十七段階発展到達 (MODIFY path 8 度目)
- paper × 実装 21 度目合流カテゴリ (Role.toCtorIdx long-deferred 解消 × Lean 4 upstream rename 理解 × 14 Day 連続 rfl × Day 22 audit long-deferred 対応 2 例目)
- paper finding 104 件累計 (+5)
- **14 Day 連続 rfl preference (桁到達後 14 Day 継続実証、quality loop 長期持続性)**
- **Subagent VERDICT PASS + 0 addressable + 1 informational 即時対処 → 0 残** (7 Day 連続 cycle 内即時修復、既存 stale issue も即時対処する新形態)
- **Phase 0 累計合致率 99.2% 到達** (Day 23 99.1% から +0.1pt 改善、Day 22 audit 反省を 2 例目で体現、Phase 0 99.2% 新高水準)
- user feedback「論文サーベイ検証の後に実装修正・追加を必ず実施してね」継続適用 7 Day 連続、cycle 内即時修復 maturity の long-deferred 対応への拡張実例

## Phase 0 ロードマップ（G5-1 Section 3.5 参照）

| Week | 作業 | 主 Gap | 完了基準 |
|------|------|------|---------|
| **1** | 環境準備 | GA-I5, GA-I7, GA-T8 | `lake build` 通る |
| 2-3 | Spine 層 (EvolutionStep, SafetyConstraint, LearningCycle, Observable) | GA-S1 umbrella 枠組 | 4 type class + dummy instance |
| 3-4 | Manifest 移植 (T1-T8 + P1-P6 → AgentSpec/Manifest/) | GA-I7 (再定義方針) | 既存 55 axioms (2026-04-17 実測、`grep -r "^axiom [a-z]" Manifest/ --include="*.lean"` ベース、CLAUDE.md の「53 axioms」は旧値) の import 可 |
| 4-5 | Process 層 (ResearchNode, FolgeID, Provenance, Edge, Retirement, Failure, State, Rationale) | GA-S2〜GA-S8 の高リスク 7 件 | handoff state machine 型化 |
| 5-6 | Tooling 層 (`agent_verify` tactic, `VcForSkill` VCG, SMT hammer) | GA-C7, GA-C9, GA-C26 | 5 定理 hammer 自動証明 |
| 6-7 | CI (`lake test`, `lake lint`, `checkInitImports`) | GA-I9, GA-I11 | GitHub Actions green |
| 7-8 | Verification (既存 1670 theorems のうち代表 100+ 再証明) + CLEVER 風自己評価 10-20 サンプル | GA-M1, GA-E1, GA-E7 | 再証明率 > 80%, 自己評価 > 60% |

## 関連ドキュメント

- `../docs/research/new-foundation-survey/00-synthesis.md` (統合まとめ)
- `../docs/research/new-foundation-survey/10-gap-analysis.md` (Gap Analysis)
- `../docs/research/new-foundation-survey/07-lean4-applications/G5-1-cslib-boole.md` (speclib 参照)
- `../research/lean4-handoff.md` (Lean 4 学習)
- `../research/survey_type_driven_development_2025.md` (TyDD サーベイ)

## ビルド

```bash
cd agent-spec-lib
lake update   # 初回のみ (Mathlib ダウンロード)
lake build    # AgentSpec.Core をビルド
```

初回ビルドは Mathlib のため 15-30 分かかる可能性あり (GA-E9: Lean compile 性能のスケール要測定)。
