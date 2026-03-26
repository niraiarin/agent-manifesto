/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **quantum_axiom** (ord=6): 量子力学の基本公理。ユニタリ発展・測定公理・重ね合わせ原理 [C1]
- **error_theory** (ord=5): 量子エラーの数学的理論。Knill-Laflamme 条件・閾値定理 [C2, H1]
- **code_family** (ord=4): エラー訂正符号族。Surface code/Steane code 等の確立された構成 [C4, H2, H3]
- **decoder** (ord=3): デコーダアルゴリズム。MWPM/Union-Find/ML デコーダ [H4, H5]
- **hardware_model** (ord=2): 物理キュビット特性。ノイズモデル・接続性・ゲート忠実度 [C3, H6]
- **optimization** (ord=1): リアルタイム訂正最適化。レイテンシ・リソース割当 [C5, H7, H8]
- **hypothesis** (ord=0): 次世代符号・量子 LDPC・フォールトトレランス閾値改善の仮説 [H9]
-/

namespace QuantumErrorCorrection

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | qax_unitary
  | qax_measurement
  | qax_no_cloning
  | err_knill_laflamme
  | err_threshold
  | err_pauli_channel
  | code_surface
  | code_steane
  | code_distance
  | code_logical_op
  | dec_mwpm
  | dec_union_find
  | dec_ml
  | dec_belief_prop
  | hw_noise_model
  | hw_connectivity
  | hw_gate_fidelity
  | hw_readout
  | opt_latency
  | opt_resource
  | opt_adaptive
  | opt_schedule
  | opt_calibration
  | hyp_qldpc
  | hyp_ft_threshold
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .qax_unitary => []
  | .qax_measurement => []
  | .qax_no_cloning => []
  | .err_knill_laflamme => [.qax_unitary, .qax_measurement]
  | .err_threshold => [.err_knill_laflamme]
  | .err_pauli_channel => [.qax_unitary]
  | .code_surface => [.err_knill_laflamme, .qax_no_cloning]
  | .code_steane => [.err_knill_laflamme]
  | .code_distance => [.err_threshold, .code_surface]
  | .code_logical_op => [.code_surface, .code_steane]
  | .dec_mwpm => [.code_surface, .err_pauli_channel]
  | .dec_union_find => [.code_surface]
  | .dec_ml => [.dec_mwpm, .err_pauli_channel]
  | .dec_belief_prop => [.code_steane, .err_pauli_channel]
  | .hw_noise_model => [.err_pauli_channel]
  | .hw_connectivity => [.code_surface]
  | .hw_gate_fidelity => [.err_threshold, .hw_noise_model]
  | .hw_readout => [.qax_measurement, .hw_noise_model]
  | .opt_latency => [.dec_mwpm, .dec_union_find, .hw_connectivity]
  | .opt_resource => [.code_distance, .hw_gate_fidelity]
  | .opt_adaptive => [.dec_ml, .hw_noise_model, .opt_latency]
  | .opt_schedule => [.opt_resource, .opt_latency]
  | .opt_calibration => [.hw_gate_fidelity, .hw_readout]
  | .hyp_qldpc => [.code_distance, .err_threshold]
  | .hyp_ft_threshold => [.err_threshold, .opt_adaptive, .hw_gate_fidelity]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 量子力学の基本公理。ユニタリ発展・測定公理・重ね合わせ原理 (ord=6) -/
  | quantum_axiom
  /-- 量子エラーの数学的理論。Knill-Laflamme 条件・閾値定理 (ord=5) -/
  | error_theory
  /-- エラー訂正符号族。Surface code/Steane code 等の確立された構成 (ord=4) -/
  | code_family
  /-- デコーダアルゴリズム。MWPM/Union-Find/ML デコーダ (ord=3) -/
  | decoder
  /-- 物理キュビット特性。ノイズモデル・接続性・ゲート忠実度 (ord=2) -/
  | hardware_model
  /-- リアルタイム訂正最適化。レイテンシ・リソース割当 (ord=1) -/
  | optimization
  /-- 次世代符号・量子 LDPC・フォールトトレランス閾値改善の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .quantum_axiom => 6
  | .error_theory => 5
  | .code_family => 4
  | .decoder => 3
  | .hardware_model => 2
  | .optimization => 1
  | .hypothesis => 0

/-- 認識論的層構造の typeclass（スタンドアロン版）。 -/
class EpistemicLayerClass (α : Type) where
  ord : α → Nat
  bottom : α
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .hypothesis
  nontrivial := ⟨.quantum_axiom, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- quantum_axiom
  | .qax_unitary | .qax_measurement | .qax_no_cloning => .quantum_axiom
  -- error_theory
  | .err_knill_laflamme | .err_threshold | .err_pauli_channel => .error_theory
  -- code_family
  | .code_surface | .code_steane | .code_distance | .code_logical_op => .code_family
  -- decoder
  | .dec_mwpm | .dec_union_find | .dec_ml | .dec_belief_prop => .decoder
  -- hardware_model
  | .hw_noise_model | .hw_connectivity | .hw_gate_fidelity | .hw_readout => .hardware_model
  -- optimization
  | .opt_latency | .opt_resource | .opt_adaptive | .opt_schedule | .opt_calibration => .optimization
  -- hypothesis
  | .hyp_qldpc | .hyp_ft_threshold => .hypothesis

-- ============================================================
-- 4. 証明
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

end QuantumErrorCorrection
