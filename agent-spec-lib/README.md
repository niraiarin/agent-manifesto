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
