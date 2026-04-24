import Lean
import LeanCli.Core
import LeanCli.ErrorContract

/-!
# `parse` subcommand — Sub-A #656 spec

Read a .lean file, output top-level declaration summary as JSONL on stdout.
One JSON object per top-level declaration:

  {"name": "foo", "kind": "axiom", "range": {"start": N, "stop": N}}

Range is in byte offsets of the BOM-stripped parse stream. For the full AST
dump, a `--full` flag is reserved for future expansion.
-/

namespace LeanCli

open Lean Parser

def runParse (inputPath : String) : IO UInt32 := do
  match ← readInputBytes inputPath with
  | .error kind => reportError kind s!"failed to read '{inputPath}'"
  | .ok inputBytes =>
    let bomOffset := detectBOM inputBytes
    let parseBytes :=
      if bomOffset > 0 then inputBytes.extract bomOffset inputBytes.size else inputBytes
    let contents := String.fromUTF8! parseBytes
    let env ← initParser
    match ← parseModuleString env inputPath contents with
    | .error kind => reportError kind "parser rejected input"
    | .ok raw =>
      let cmds := moduleCommands raw
      for cmd in cmds do
        if isTopDecl cmd then
          let name := (declNameOf cmd).getD "<anonymous>"
          let kind := (declKind cmd).getD "unknown"
          let rangeStr := match cmd.getRange? (canonicalOnly := false) with
            | none => "null"
            | some r => s!"\{\"start\": {r.start.byteIdx}, \"stop\": {r.stop.byteIdx}}"
          IO.println s!"\{\"name\": \"{escapeJsonString name}\", \"kind\": \"{kind}\", \"range\": {rangeStr}}"
      return 0

end LeanCli
