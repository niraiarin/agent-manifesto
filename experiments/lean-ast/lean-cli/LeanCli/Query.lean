import Lean
import LeanCli.Core
import LeanCli.ErrorContract

/-!
# `query` subcommand — Sub-A #656 spec

Filter declarations by kind and/or name substring. Output is same JSONL
format as `parse`, but restricted.

  lean-cli query <file> [--kind <kind>] [--name-substring <s>]

For MVP we use substring match (not regex). Regex support is a future
extension; the error contract already reserves `invalid_range` for
malformed pattern inputs.
-/

namespace LeanCli

open Lean Parser

structure QueryOpts where
  kind : Option String := none
  nameSubstring : Option String := none
  deriving Repr

partial def parseQueryArgs (args : List String) (acc : QueryOpts := {}) :
    Except String QueryOpts :=
  match args with
  | [] => .ok acc
  | "--kind" :: v :: rest => parseQueryArgs rest { acc with kind := some v }
  | "--name-substring" :: v :: rest =>
    parseQueryArgs rest { acc with nameSubstring := some v }
  | unknown :: _ => .error s!"unknown flag: {unknown}"

def runQuery (inputPath : String) (opts : QueryOpts) : IO UInt32 := do
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
        if !isTopDecl cmd then continue
        let name := (declNameOf cmd).getD ""
        let kind := (declKind cmd).getD "unknown"
        let kindOk : Bool := match opts.kind with
          | none   => true
          | some k => kind == k
        let nameOk : Bool := match opts.nameSubstring with
          | none   => true
          | some s => decide ((name.splitOn s).length > 1)
        if kindOk && nameOk then
          let rangeStr := match cmd.getRange? (canonicalOnly := false) with
            | none => "null"
            | some r => s!"\{\"start\": {r.start.byteIdx}, \"stop\": {r.stop.byteIdx}}"
          IO.println s!"\{\"name\": \"{escapeJsonString name}\", \"kind\": \"{kind}\", \"range\": {rangeStr}}"
      return 0

end LeanCli
