import AgentSpec.Spine.Reference

/-!
# AgentSpec.Test.Spine.ReferenceTest: Reference inductive の behavior test

Day 73: Day 72 で導入した inductive Reference (doi/url/arxiv/commit) の
構築・accessor・DecidableEq・Inhabited の検証。DataCite pattern 準拠。
-/

namespace AgentSpec.Test.Spine.Reference

open AgentSpec.Spine

/-! ### 各 variant の構築 -/

example : Reference := .doi "10.1145/12345"
example : Reference := .url "https://github.com/org/repo/issues/1"
example : Reference := .arxiv "2604.14572"
example : Reference := .commit "cba5db0"

/-! ### value accessor -/

example : (Reference.doi "10.1145/12345").value = "10.1145/12345" := rfl
example : (Reference.url "https://example.com").value = "https://example.com" := rfl
example : (Reference.arxiv "2604.14572").value = "2604.14572" := rfl
example : (Reference.commit "abc1234").value = "abc1234" := rfl

/-! ### DecidableEq -/

example : DecidableEq Reference := inferInstance

-- 同値判定 (同 variant 同値)
example : (Reference.doi "10.1145/x") = (Reference.doi "10.1145/x") := by decide
example : (Reference.url "a") = (Reference.url "a") := by decide

-- 異値判定 (同 variant 異値)
example : (Reference.doi "10.1145/a") ≠ (Reference.doi "10.1145/b") := by decide
example : (Reference.url "a") ≠ (Reference.url "b") := by decide

-- 異値判定 (異 variant 同値文字列)
example : (Reference.doi "x") ≠ (Reference.url "x") := by decide
example : (Reference.doi "x") ≠ (Reference.arxiv "x") := by decide
example : (Reference.doi "x") ≠ (Reference.commit "x") := by decide
example : (Reference.url "x") ≠ (Reference.arxiv "x") := by decide
example : (Reference.url "x") ≠ (Reference.commit "x") := by decide
example : (Reference.arxiv "x") ≠ (Reference.commit "x") := by decide

/-! ### Inhabited -/

example : Inhabited Reference := inferInstance

/-! ### List Reference 操作 (Rationale.references との連携) -/

-- 空リスト
example : ([] : List Reference).length = 0 := rfl

-- 混合リスト
example : ([.doi "10.1145/a", .arxiv "2604.1", .commit "abc"] : List Reference).length = 3 := rfl

-- 型で DOI と URL を区別 (List String では不可能だった情報保持)
example :
    ([.doi "10.1145/a", .url "10.1145/a"] : List Reference) ≠
    ([.doi "10.1145/a", .doi "10.1145/a"] : List Reference) := by decide

end AgentSpec.Test.Spine.Reference
