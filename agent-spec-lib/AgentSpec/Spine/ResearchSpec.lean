-- Spine 層: ResearchSpec (GA-S11 Hoare-style 4-arg post spec)
-- Day 53: polymorphic (State Input Output) ResearchSpec structure + helpers
-- TyDD-B4 (Liquid Haskell Hoare logic) 準拠、layer 整合性のため polymorphic で配置
import Init.Core

/-!
# AgentSpec.Spine.ResearchSpec: Hoare-style 4-arg post spec (GA-S11、Spine 層)

GA-S11 は「research node に pre/post 条件の明示的型なし」の問題。TyDD-B4
(Liquid Haskell Hoare logic) pattern で pre/post condition を型レベルで明示。

Day 53 hole-driven: polymorphic `(State Input Output : Type)` ResearchSpec
structure。concrete な State/Input/Output (e.g. LifeCyclePhase/Hypothesis/Verdict)
への instantiation は使用側で行う (layer 整合性: Spine → Process/Provenance
の逆依存を回避、Day 8 EvolutionStep 4-arg transition と同パターンで polymorphic 化)。

## 設計 (10-gap-analysis.md §GA-S11 + TyDD-B4 Liquid Haskell)

    structure ResearchSpec (State Input Output : Type) where
      pre  : State → Input → Prop
      post : State → Input → Output → State → Prop

- `pre`: transition 前の条件 (State + Input で何が成立していれば遷移可能か)
- `post`: transition 後の条件 (State + Input + Output + State' の 4-arg、frame conditions 込み)

Day 8 EvolutionStep.transition の 4-arg signature
(`(pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop`) と
構造同型、Spine 層 polymorphic spec として独立 module 化。

## TyDD 原則 (Day 1-52 確立パターン適用)

- **Pattern #5** (def Prop signature): `pre` / `post` は Prop に値を取る関数
- **Pattern #6** (sorry 0): structure + helper def のみ
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 済
- **Pattern #8** (Lean 4 予約語回避): `pre` / `post` は予約語ではない (EvolutionStep で Day 8 検証済)

## Day 53 意思決定ログ (GA-S11 conservative 着手、layer 整合性優先)

### D1. polymorphic `(State Input Output : Type)` (vs concrete LifeCyclePhase/Hypothesis/Verdict 固定)
- **代案 A**: `structure ResearchSpec { pre : LifeCyclePhase → Hypothesis → Prop, post : LifeCyclePhase → Hypothesis → Verdict → LifeCyclePhase → Prop }`
- **採用**: polymorphic `(State Input Output : Type)` で Spine 層に配置
- **理由**: (a) Spine → Process (Hypothesis) / Provenance (Verdict) の逆 layer 依存を回避。
  (b) 案 A は Day 51 LifeCyclePhase / Day 45 Hypothesis / Day 42 Verdict の具体型固定で
  柔軟性を失う。polymorphic なら `ResearchSpec LifeCyclePhase Hypothesis Verdict` として
  instantiate 可能、他の (State, Input, Output) 組み合わせも許容。
  (c) Day 8 EvolutionStep が type class でも同 polymorphic 方針 (S は generic) を採用済、
  Day 53 で pattern-symmetric 拡張。

### D2. frame conditions を post signature に含める (vs 別 structure 分離)
- **代案 B**: `structure FrameCondition { unchanged : State → State → Prop }`
- **採用**: `post` 4-arg に frame conditions を包含 (S' が post state、frame は implicit)
- **理由**: GA-S11 原文「frame conditions 込み」の読み取り、Liquid Haskell の
  Hoare 4-arg pattern 直写し、Day 8 EvolutionStep と同 signature。別 structure は
  Day 54+ で必要時に追加。

### D3. Rationale 非保持 (Spine polymorphic、Day 51 State と同方針)
- **採用**: ResearchSpec には Rationale field を追加しない
- **理由**: ResearchSpec 自体は仕様 (pre/post 条件)、仕様を立てた判断の rationale は
  上位の "ResearchNode with spec" (Day 54+ GA-S1 umbrella) で保持。Spine layer 内部で
  Rationale 依存を追加すると循環する (Rationale は Spine、spec も Spine、互いに独立)。
-/

namespace AgentSpec.Spine

/-- GA-S11 Hoare-style 4-arg post spec (Day 53、polymorphic)。

    `(State Input Output : Type)` に対して pre/post 条件を型レベルで明示する structure。
    TyDD-B4 Liquid Haskell Hoare logic pattern 忠実。 -/
structure ResearchSpec (State Input Output : Type) where
  /-- transition 前の条件 (State + Input で何が成立していれば遷移可能か)。 -/
  pre : State → Input → Prop
  /-- transition 後の条件 (State + Input + Output + State' の 4-arg、frame conditions 込み)。 -/
  post : State → Input → Output → State → Prop

namespace ResearchSpec

/-- 自明な spec (常に true pre / 常に true post、test fixture / placeholder)。 -/
def trivial {State Input Output : Type} : ResearchSpec State Input Output :=
  { pre := fun _ _ => True,
    post := fun _ _ _ _ => True }

/-- 常に false pre (どんな入力でも遷移不可、absorbing spec)。 -/
def unsatisfiable {State Input Output : Type} : ResearchSpec State Input Output :=
  { pre := fun _ _ => False,
    post := fun _ _ _ _ => False }

/-- Hoare triple の判定: spec の下で transition が valid かを Prop として表現。 -/
def Satisfies {State Input Output : Type}
    (spec : ResearchSpec State Input Output)
    (s : State) (i : Input) (o : Output) (s' : State) : Prop :=
  spec.pre s i → spec.post s i o s'

/-- spec の pre を強化 (AND 合成、より厳しい precondition)。 -/
def strengthenPre {State Input Output : Type}
    (spec : ResearchSpec State Input Output)
    (extra : State → Input → Prop) : ResearchSpec State Input Output :=
  { pre := fun s i => spec.pre s i ∧ extra s i,
    post := spec.post }

/-- spec の post を弱化 (OR 合成、より緩い postcondition、frame flexibility)。 -/
def weakenPost {State Input Output : Type}
    (spec : ResearchSpec State Input Output)
    (alt : State → Input → Output → State → Prop) : ResearchSpec State Input Output :=
  { pre := spec.pre,
    post := fun s i o s' => spec.post s i o s' ∨ alt s i o s' }

end ResearchSpec

end AgentSpec.Spine
