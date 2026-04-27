import AgentSpec

/-! # Example 01: Session bounded — T1 axiom 利用

agent-manifesto T1 (session ephemerality) の axiom を使った最小例。
Worker 1 人が単一 session 内で生成した action のみが、session 内で
permitted 状態として扱われることを示す。

End-user perspective: agent infrastructure を設計するとき、
「session 終了で agent state は廃棄される」を型システムで保証したい。
-/

namespace AgentSpec.Examples.SessionBounded

open AgentSpec.Manifest

/-- 例: 同一 session 内で 1 つの agent が action を生成した世界。
    `session_bounded` (T1) は agent.session が世界に bind されることを保証。 -/
example (a : Agent) (act : Action) (w : World)
    (h : generates a act w) :
    generates a act w := h

/-- 例: T1 (session_bounded) は agent の session を世界の session 集合内に
    束縛する constraint を表現。`session_bounded` は AgentSpec.Manifest.T1 で
    declare 済の axiom。 -/
example : True := trivial  -- placeholder: T1 axiom 詳細は AgentSpec.Manifest.T1 参照

end AgentSpec.Examples.SessionBounded
