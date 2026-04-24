import Lean
import LeanCli.Core
import LeanCli.ErrorContract

/-!
# `edit` subcommand — Sub-A #656 spec + Sub-E #660 algorithm + Impl-B #663 atomic rename

Replace a declaration's body by name, preserving every byte outside the
declaration's source range.

  lean-cli edit <file> --replace-body <name> <expr> --output <file>

Algorithm: identical to Sub-E PoC `RewritePoC.lean`.
Write path: tmp + `IO.FS.rename` (atomic, POSIX rename(2)).
-/

namespace LeanCli

open Lean Parser

structure EditOpts where
  replaceName : Option String := none
  replaceBody : Option String := none
  output : Option String := none
  deriving Repr

partial def parseEditArgs (args : List String) (acc : EditOpts := {}) :
    Except String EditOpts :=
  match args with
  | [] => .ok acc
  | ["--replace-body"] | ["--replace-body", _] =>
    .error "--replace-body requires <name> <expr>"
  | "--replace-body" :: name :: expr :: rest =>
    parseEditArgs rest { acc with replaceName := some name, replaceBody := some expr }
  | ["--output"] => .error "--output requires <file>"
  | "--output" :: v :: rest => parseEditArgs rest { acc with output := some v }
  | unknown :: _ => .error s!"unknown or malformed flag: {unknown}"

def runEdit (inputPath : String) (opts : EditOpts) : IO UInt32 := do
  let some targetName := opts.replaceName
    | return ← reportError .usage "--replace-body requires <name> <expr>"
  let some newDeclText := opts.replaceBody
    | return ← reportError .usage "--replace-body requires <name> <expr>"
  let some outputPath := opts.output
    | return ← reportError .usage "--output is required"
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
      match findDeclByName cmds targetName with
      | .error .name_not_found => reportError .name_not_found s!"'{targetName}'"
      | .error .ambiguous_name => reportError .ambiguous_name s!"'{targetName}' matched multiple declarations"
      | .error kind => reportError kind "lookup failed"
      | .ok cmd =>
        match cmd.getRange? (canonicalOnly := false) with
        | none => reportError .invalid_range "no source range for declaration"
        | some range =>
          let startByte := range.start.byteIdx + bomOffset
          let stopByte := range.stop.byteIdx + bomOffset
          if startByte > inputBytes.size || stopByte > inputBytes.size then
            reportError .invalid_range s!"out of bounds [{startByte},{stopByte}] size {inputBytes.size}"
          else
            let before := inputBytes.extract 0 startByte
            let after := inputBytes.extract stopByte inputBytes.size
            let newBytes := newDeclText.toUTF8
            let output := (before ++ newBytes) ++ after
            -- Atomic write (Impl-B #663)
            let pid ← IO.Process.getPID
            let heartbeats ← IO.getNumHeartbeats
            let tmpPath := outputPath ++ s!".tmp.{pid}.{heartbeats}"
            try
              IO.FS.writeBinFile tmpPath output
            catch _e =>
              return ← reportError .io_write s!"failed to write tmp '{tmpPath}'"
            try
              IO.FS.rename tmpPath outputPath
            catch _e =>
              try IO.FS.removeFile tmpPath catch _ => pure ()
              return ← reportError .io_write s!"failed to rename to '{outputPath}'"
            IO.println s!"OK range=[{startByte},{stopByte}] output_size={output.size}"
            return 0

end LeanCli
