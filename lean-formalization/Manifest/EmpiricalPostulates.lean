import Manifest.Ontology

/-!
# Layer 2b: Empirical Postulates (E1–E2)

経験的公準を Lean axiom として形式化する。

経験的公準は「繰り返し実証され反例が知られていないが、
原理的には覆りうる知見」であり、拘束条件（T）より弱い前提。
Lean では T と同じく `axiom` として宣言するが、
docstring に `[empirical]` マーカーを付けて区別する。

## 拘束条件との違い

- **T（Constraints）** — 否定不可能。技術非依存の事実。
- **E（Empirical Postulates）** — 繰り返し実証されているが、
  原理的には反例が発見されうる。E が反証された場合、
  E に依拠する P（P1, P2）は見直しの対象となる。

## 対応表

| axiom 名 | 対応する E | 表現する性質 |
|-----------|-----------|-------------|
| `verification_requires_independence` | E1 | 生成と評価は分離が必要 |
| `no_self_verification` | E1 | 自己検証の禁止 |
| `shared_bias_reduces_detection` | E1 | 共有バイアスが検出力を低下させる |
| `capability_risk_coscaling` | E2 | 能力の増大はリスクの増大と不可分 |
-/

namespace Manifest

-- ============================================================
-- E1: 検証には独立性が必要である
-- ============================================================

/-!
## E1: 検証には独立性が必要である

「同一プロセスによる生成と評価は、あらゆる分野（科学の査読、
  会計監査、ソフトウェアテスト）で構造的に信頼できないことが
  実証されている。T4（確率的出力）を前提として、同じバイアスを
  持つプロセスが生成と評価を兼ねると検出力が落ちることが
  経験的に支持される。」

E1 は3つの axiom に分解される:
1. 生成と評価の主体は分離されなければならない（構造的独立性）
2. 自己検証は許容されない（自己検証の禁止）
3. 内部状態を共有するエージェント間の検証は検出力が低い（バイアス相関）
-/

/-- E1a [empirical]: 生成と評価の主体は独立でなければならない。
    あるアクションを生成したエージェントと、それを検証する
    エージェントは異なる個体であり、かつ内部状態を共有しない。

    これは科学の査読、会計監査、ソフトウェアテスト等で
    繰り返し実証されている原則の形式化。 -/
axiom verification_requires_independence :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver

/-- E1b [empirical]: 自己検証の禁止。
    同一エージェントが生成と検証の両方を行うことはできない。

    E1a の系だが、明示的に宣言する。
    T4（確率的出力）により、同一プロセスのバイアスが
    生成と評価の双方に影響し、検出力が構造的に低下する。 -/
axiom no_self_verification :
  ∀ (agent : Agent) (action : Action) (w : World),
    generates agent action w →
    ¬verifies agent action w

/-- E1c [empirical]: 内部状態の共有はバイアスを相関させる。
    内部状態を共有する2つのエージェントは、一方が生成し
    他方が検証する構成であっても、独立な検証とはみなせない。

    形式化: sharesInternalState が成立する2エージェント間では、
    generates/verifies の同時成立を禁止する。 -/
axiom shared_bias_reduces_detection :
  ∀ (a b : Agent) (action : Action) (w : World),
    sharesInternalState a b →
    generates a action w →
    ¬verifies b action w

-- ============================================================
-- E2: 能力の増大はリスクの増大と不可分である
-- ============================================================

/-!
## E2: 能力の増大はリスクの増大と不可分である

「あらゆるツールにおいて、能力は正負両方の結果を可能にする
  ことが繰り返し観測されている。ただし、完璧なサンドボックス
  など、能力を増大させつつリスクを完全に封じ込める手段が
  原理的に不可能であるという証明はない。」

E2 は1つの axiom として形式化する。
行動空間（actionSpaceSize）の拡大は、必ずリスク露出度
（riskExposure）の増大を伴う。

### 経験的地位に関する注記

E2 は経験的公準であり、「完璧なサンドボックス」が将来
発見される可能性を排除しない。axiom として仮定するが、
反証された場合は P1（自律権と脆弱性の共成長）が
見直しの対象となる。
-/

/-- E2 [empirical]: 能力の増大はリスクの増大と不可分。
    エージェントの行動空間が拡大した場合、リスク露出度も
    必ず増大する。

    `actionSpaceSize` と `riskExposure` は Ontology で opaque
    として定義されており、具体的な計量方法は Phase 4+
    で Observable として定義する。

    ### 不等号の選択: `<` vs `≤`

    マニフェストの「不可分」は厳密な共成長を意味するため
    `<`（厳密増加）を採用。「リスクを完全に封じ込める手段が
    原理的に不可能であるという証明はない」という留保は、
    axiom の経験的地位（覆りうること）として表現される。 -/
axiom capability_risk_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w'

-- ============================================================
-- Sorry Inventory (Phase 2)
-- ============================================================

/-!
## Sorry Inventory (Phase 2 追加分)

| 場所 | sorry の理由 |
|------|-------------|
| `Ontology.lean: generates` | opaque — Phase 3+ で Worker の行為として具体化 |
| `Ontology.lean: verifies` | opaque — Phase 3+ で Verifier の行為として具体化 |
| `Ontology.lean: sharesInternalState` | opaque — Phase 3+ でセッション/パラメータ共有として具体化 |
| `Ontology.lean: actionSpaceSize` | opaque — Phase 4+ で Observable として計量化 |
| `Ontology.lean: riskExposure` | opaque — Phase 4+ で Observable として計量化 |
-/

end Manifest
