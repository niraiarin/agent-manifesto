import AgentSpec.Provenance.RationaleLinter
import AgentSpec.Spine.Rationale

/-!
# AgentSpec.Test.Provenance.RationaleWatchedFixture: 運用 register fixture (Day 63 F1 sprint 4/4)

Day 22-23 RetirementWatchedFixture pattern を Rationale 側に複製。
helper module で `register_rationale_watched_namespace` を実行、import 経由で
consumer 側の `#check_unattributed_rationale_auto` で watched list に appear することを実証。
-/

namespace AgentSpec.Test.Provenance.RationaleWatchedFixture

open AgentSpec.Spine

-- helper module 側で register を実行、import 経由で watched list に追加される
register_rationale_watched_namespace AgentSpec.Test.Provenance.RationaleWatchedFixture

/-- test-scope unattributed fixture (scanner がこの fixture を flag することで
    import 経由の watched propagation を実証)。 -/
def unattributedPlaceholderFixture : Rationale := Rationale.trivial

end AgentSpec.Test.Provenance.RationaleWatchedFixture
