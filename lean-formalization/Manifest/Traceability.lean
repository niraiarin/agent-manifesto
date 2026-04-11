import Manifest.Ontology
import Manifest.DesignFoundation

/-!
# Closed-Loop Traceability - Full Correspondence of Conditional Axioms and Artifacts

Research #191, Sub-Issue #193. 命題↔テスト↔実装の閉じた環を型レベルで定義する。
Conservative extension: 新しい axiom は追加しない。
-/

namespace Manifest.Traceability
open Manifest

inductive TestAxis where
  | structural | behavioral | metrics | depgraph | quality
  deriving BEq, Repr, DecidableEq

structure TestCaseId where
  phase : Nat
  axis : TestAxis
  seq : Nat
  deriving BEq, Repr, DecidableEq

inductive ArtifactType where
  | hook | skill | agent | rule | test | document | config | leanModule
  deriving BEq, Repr, DecidableEq

inductive ArtifactScope where
  | implementation | config | document | data | formalization
  deriving BEq, Repr, DecidableEq

structure ArtifactId where
  type : ArtifactType
  name : String
  scope : ArtifactScope
  deriving BEq, Repr

inductive TraceLinkKind where
  | validates | verifies | justifies
  deriving BEq, Repr, DecidableEq

structure PropTestLink where
  proposition : PropositionId
  testCase : TestCaseId
  enforcement : EnforcementLayer
  deriving Repr

structure TestArtifactLink where
  testCase : TestCaseId
  artifact : ArtifactId
  deriving Repr

structure ArtifactPropLink where
  artifact : ArtifactId
  propositions : List PropositionId
  deriving Repr

structure TraceMatrix where
  propTests : List PropTestLink
  testArtifacts : List TestArtifactLink
  artifactProps : List ArtifactPropLink
  deriving Repr

def TraceMatrix.propositionCovered (m : TraceMatrix) (p : PropositionId) : Bool :=
  m.propTests.any (fun l => l.proposition == p)

def TraceMatrix.testLinked (m : TraceMatrix) (t : TestCaseId) : Bool :=
  m.testArtifacts.any (fun l => l.testCase == t)

def TraceMatrix.artifactJustified (m : TraceMatrix) (a : ArtifactId) : Bool :=
  m.artifactProps.any (fun l => l.artifact == a && !l.propositions.isEmpty)

def TraceMatrix.fullPropositionCoverage (m : TraceMatrix) : Prop :=
  ∀ p : PropositionId, m.propositionCovered p = true

def TraceMatrix.fullTestLinkage (m : TraceMatrix) : Prop :=
  ∀ l : PropTestLink, l ∈ m.propTests → m.testLinked l.testCase = true

def TraceMatrix.fullArtifactJustification (m : TraceMatrix) : Prop :=
  ∀ l : TestArtifactLink, l ∈ m.testArtifacts → m.artifactJustified l.artifact = true

def TraceMatrix.closedLoop (m : TraceMatrix) : Prop :=
  m.fullPropositionCoverage ∧ m.fullTestLinkage ∧ m.fullArtifactJustification

def TraceMatrix.impactedTests (m : TraceMatrix) (changed : PropositionId) : List TestCaseId :=
  let affectedProps := Manifest.affected changed
  let allAffected := changed :: affectedProps
  m.propTests.filter (fun l => allAffected.any (· == l.proposition)) |>.map (·.testCase)

def TraceMatrix.impactedArtifacts (m : TraceMatrix) (changed : PropositionId) : List ArtifactId :=
  let tests := m.impactedTests changed
  m.testArtifacts.filter (fun l => tests.any (· == l.testCase)) |>.map (·.artifact)

theorem closedLoop_implies_impact_covered
  (m : TraceMatrix) (p : PropositionId) (h : m.closedLoop) :
  ∀ q ∈ Manifest.affected p, m.propositionCovered q = true := by
  intro q _; exact h.1 q

theorem closedLoop_no_uncovered
  (m : TraceMatrix) (h : m.closedLoop) :
  ¬ ∃ p : PropositionId, m.propositionCovered p = false := by
  intro ⟨p, hp⟩; have := h.1 p; simp [this] at hp

-- L1 PoC
def l1_test_s1_1 : TestCaseId := ⟨1, .structural, 1⟩
def l1_test_s1_5 : TestCaseId := ⟨1, .structural, 5⟩
def l1_test_s1_6 : TestCaseId := ⟨1, .structural, 6⟩
def l1_test_b1_1 : TestCaseId := ⟨1, .behavioral, 1⟩
def l1_test_b1_2 : TestCaseId := ⟨1, .behavioral, 2⟩

def l1_hook : ArtifactId := ⟨.hook, "l1-safety-check", .implementation⟩
def l1_deny : ArtifactId := ⟨.config, "settings-deny-list", .config⟩
def l1_rule : ArtifactId := ⟨.rule, "l1-safety", .implementation⟩

def l1TraceMatrix : TraceMatrix :=
  { propTests := [
      ⟨.l1, l1_test_s1_6, .structural⟩, ⟨.l1, l1_test_b1_1, .structural⟩,
      ⟨.l1, l1_test_b1_2, .structural⟩, ⟨.t6, l1_test_s1_5, .structural⟩,
      ⟨.t6, l1_test_b1_2, .procedural⟩, ⟨.p1, l1_test_s1_1, .structural⟩ ]
    testArtifacts := [
      ⟨l1_test_s1_1, l1_deny⟩, ⟨l1_test_s1_5, l1_deny⟩, ⟨l1_test_s1_6, l1_hook⟩,
      ⟨l1_test_b1_1, l1_hook⟩, ⟨l1_test_b1_2, l1_hook⟩ ]
    artifactProps := [
      ⟨l1_hook, [.l1, .t6]⟩, ⟨l1_deny, [.l1, .t6, .p1]⟩, ⟨l1_rule, [.l1]⟩ ] }

theorem l1_poc_l1_covered : l1TraceMatrix.propositionCovered .l1 = true := by native_decide
theorem l1_poc_t6_covered : l1TraceMatrix.propositionCovered .t6 = true := by native_decide
theorem l1_poc_p1_covered : l1TraceMatrix.propositionCovered .p1 = true := by native_decide
theorem l1_poc_s1_1_linked : l1TraceMatrix.testLinked l1_test_s1_1 = true := by native_decide
theorem l1_poc_s1_5_linked : l1TraceMatrix.testLinked l1_test_s1_5 = true := by native_decide
theorem l1_poc_s1_6_linked : l1TraceMatrix.testLinked l1_test_s1_6 = true := by native_decide
theorem l1_poc_b1_1_linked : l1TraceMatrix.testLinked l1_test_b1_1 = true := by native_decide
theorem l1_poc_b1_2_linked : l1TraceMatrix.testLinked l1_test_b1_2 = true := by native_decide
theorem l1_poc_hook_justified : l1TraceMatrix.artifactJustified l1_hook = true := by native_decide
theorem l1_poc_deny_justified : l1TraceMatrix.artifactJustified l1_deny = true := by native_decide
theorem l1_poc_t6_impacts_tests :
  l1TraceMatrix.impactedTests .t6 ≠ [] := by native_decide

end Manifest.Traceability
