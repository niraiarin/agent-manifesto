import Lean
import AgentSpec.Tooling.VerifyToken

/-\!
# VerifyTokenLoader — p2-verified.jsonl bridge foundation (Phase 0 Week 5-6、Day 136)

p2-verified.jsonl の token を Lean 側で読み込み、将来 IsVerifyToken (Day 134) instance に
変換するための foundation。

現状 (Day 136 minimal):
- VerifiedTokenRaw struct (token の Lean 表現)
- loadVerifiedTokens IO function (jsonl path → token array)
- countIndependentTokens helper (evaluator_independent=true の件数)

将来拡張:
- elab macro で「特定 token id」 → 「IsVerifyToken instance auto-generate」
- p2-verify-on-commit.sh hook と Lean 側 verify の bidirectional bridge
- token TTL を Lean 側でも enforce
-/

namespace AgentSpec.Tooling

open Lean

/-- p2-verified.jsonl の 1 行を表す raw struct。 -/
structure VerifiedTokenRaw where
  epoch                : Nat
  files                : Array String
  verdict              : String
  evaluator            : String
  evaluatorIndependent : Bool
  deriving Repr

/-- p2-verified.jsonl path から VerifiedTokenRaw のリストを読み込む。
    各行を Lean.Json.parse で処理、parse 失敗・field 不在は skip。 -/
def loadVerifiedTokens (jsonlPath : System.FilePath) : IO (Array VerifiedTokenRaw) := do
  let content ← IO.FS.readFile jsonlPath
  let lines := content.splitOn "\n" |>.filter (·.length > 0)
  let mut tokens : Array VerifiedTokenRaw := #[]
  for line in lines do
    match Json.parse line with
    | .ok json =>
      match json.getObjValAs? Nat "epoch",
            json.getObjValAs? (Array String) "files",
            json.getObjValAs? String "verdict",
            json.getObjValAs? String "evaluator",
            json.getObjValAs? Bool "evaluator_independent" with
      | .ok e, .ok f, .ok v, .ok ev, .ok ei =>
        tokens := tokens.push { epoch := e, files := f, verdict := v, evaluator := ev, evaluatorIndependent := ei }
      | _, _, _, _, _ => continue
    | .error _ => continue
  return tokens

/-- evaluator_independent=true で verdict=PASS の token 件数を数える。 -/
def countIndependentTokens (tokens : Array VerifiedTokenRaw) : Nat :=
  tokens.foldl (init := 0) fun acc t =>
    if t.evaluatorIndependent && t.verdict == "PASS" then acc + 1 else acc

end AgentSpec.Tooling
