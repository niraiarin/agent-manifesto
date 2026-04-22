import AgentSpec.Manifest.T4

/-! # AgentSpec.Manifest.P6 (Week 3 Day 95、P 系列完了)

P6 Task as Constraint Satisfaction — 2 theorem (T3+T7+T8 unfolding + T4 由来)。
-/

namespace AgentSpec.Manifest

/-- P6a: タスク実行は制約充足問題 (T3 context + T7 resource + T8 precision)。 -/
theorem task_is_constraint_satisfaction :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 := by
  intro task agent _ h_res h_prec s h_task h_feas
  refine ⟨h_feas.1, ?_, ?_⟩
  · exact Nat.le_trans h_feas.2.1 (h_task ▸ h_res)
  · exact Nat.lt_of_lt_of_le h_prec (h_task ▸ h_feas.2.2)

/-- P6b: タスク設計自身も probabilistic (T4 直接、P6 が T4 の subject)。 -/
theorem task_design_is_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic

end AgentSpec.Manifest
