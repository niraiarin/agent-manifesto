import Lean
import LeanCli.Core
import LeanCli.ErrorContract

/-!
# `insert` subcommand — Sub-A #656 spec

Insert a new declaration before a target declaration, preserving every
byte outside the insertion point.

  lean-cli insert <file> --before <name> <decl> --output <file>

Insertion point = start byte of the target declaration (in input bytes).
No trailing newline is auto-added; caller controls formatting.
-/

namespace LeanCli

open Lean Parser

structure InsertOpts where
  beforeName : Option String := none
  newDecl : Option String := none
  output : Option String := none
  deriving Repr

partial def parseInsertArgs (args : List String) (acc : InsertOpts := {}) :
    Except String InsertOpts :=
  match args with
  | [] => .ok acc
  | ["--before"] | ["--before", _] =>
    .error "--before requires <name> <decl>"
  | "--before" :: name :: decl :: rest =>
    parseInsertArgs rest { acc with beforeName := some name, newDecl := some decl }
  | ["--output"] => .error "--output requires <file>"
  | "--output" :: v :: rest => parseInsertArgs rest { acc with output := some v }
  | unknown :: _ => .error s!"unknown or malformed flag: {unknown}"

def runInsert (inputPath : String) (opts : InsertOpts) : IO UInt32 := do
  let some targetName := opts.beforeName
    | return ← reportError .usage "--before requires <name> <decl>"
  let some newDecl := opts.newDecl
    | return ← reportError .usage "--before requires <name> <decl>"
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
          if startByte > inputBytes.size then
            reportError .invalid_range s!"out of bounds {startByte} size {inputBytes.size}"
          else
            let before := inputBytes.extract 0 startByte
            let after := inputBytes.extract startByte inputBytes.size
            let newBytes := newDecl.toUTF8
            let output := (before ++ newBytes) ++ after
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
            IO.println s!"OK inserted at byte={startByte} output_size={output.size}"
            return 0

end LeanCli
