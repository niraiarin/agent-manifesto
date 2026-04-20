import AgentSpec.Test.CoreTest
import AgentSpec.Test.Spine.FolgeIDTest
import AgentSpec.Test.Spine.EdgeTest
import AgentSpec.Test.Spine.EvolutionStepTest
import AgentSpec.Test.Spine.SafetyConstraintTest
import AgentSpec.Test.Spine.LearningCycleTest
import AgentSpec.Test.Spine.ObservableTest
import AgentSpec.Test.Spine.RationaleTest
import AgentSpec.Test.Spine.StateTest
import AgentSpec.Test.Spine.ResearchSpecTest
import AgentSpec.Test.Spine.ResearchNodeTest
import AgentSpec.Test.Process.HypothesisTest
import AgentSpec.Test.Process.FailureTest
import AgentSpec.Test.Process.EvolutionTest
import AgentSpec.Test.Process.HandoffChainTest
import AgentSpec.Test.Provenance.VerdictTest
import AgentSpec.Test.Provenance.ResearchEntityTest
import AgentSpec.Test.Provenance.ResearchActivityTest
import AgentSpec.Test.Provenance.ResearchAgentTest
import AgentSpec.Test.Provenance.EvolutionMappingTest
import AgentSpec.Test.Provenance.ProvRelationTest
import AgentSpec.Test.Provenance.RetiredEntityTest
import AgentSpec.Test.Provenance.ProvRelationAuxiliaryTest
import AgentSpec.Test.Provenance.RetirementLinterTest
import AgentSpec.Test.Provenance.RetirementWatchedFixture
import AgentSpec.Test.Provenance.RetirementWatchedFixture2
import AgentSpec.Test.Provenance.RetirementLinterCommandTest
import AgentSpec.Test.Cross.SpineProcessTest

/-!
# AgentSpecTest: agent-spec-lib の test 専用ルート

本番ライブラリ `AgentSpec` から分離された test lib。
Verifier Round 3 informational 指摘 3 と /verify Round 1 指摘 4、
Day 1 /verify R1 I1 の対処として Week 2 Day 2 で導入。

## 設計

- 本ファイルは production `AgentSpec.lean` から **import されない**
- lakefile.lean で `lean_lib AgentSpecTest` として独立 build target を持つ
- 全ての behavior assertion (`example`) は本 lib 経由で build される

## ビルド

```bash
lake build AgentSpec      # 本番のみ (Test 不含)
lake build AgentSpecTest  # Test のみ (本番依存)
```
-/
