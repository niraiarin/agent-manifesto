import Lean
import LeanCli.ErrorContract

/-!
# Core — shared parser primitives (Sub-B #657 + Sub-E #660 derived)

- BOM detection + strip
- Parser environment initialization (Init only; Mathlib scope = Sub-D Profile B, deferred)
- Module parse with error handling
- Syntax → declaration name extraction
-/

namespace LeanCli

open Lean Parser

/-- UTF-8 BOM prefix `EF BB BF`. Returns 3 if present, else 0. -/
def detectBOM (bytes : ByteArray) : Nat :=
  if bytes.size ≥ 3
     && bytes.get! 0 == 0xEF
     && bytes.get! 1 == 0xBB
     && bytes.get! 2 == 0xBF
  then 3 else 0

/-- Read input file as raw bytes (no re-encoding). -/
def readInputBytes (path : String) : IO (Except ErrorKind ByteArray) := do
  try
    let bytes ← IO.FS.readBinFile path
    return .ok bytes
  catch _e =>
    return .error .io_read

/-- Initialize parser environment with Init only (Profile A, ~100ms warm). -/
def initParser : IO Environment := do
  initSearchPath (← findSysroot)
  importModules #[{ module := `Init }] {} (trustLevel := 1024)

/-- Parse a module source string, returning module Syntax or parse_failure.
The concrete type of `testParseModule` is `TSyntax \`Lean.Parser.Module.module`;
we project to `Syntax` via `.raw` at the call site. -/
def parseModuleString (env : Environment) (fname : String) (contents : String) :
    IO (Except ErrorKind Syntax) := do
  try
    let stx ← testParseModule env fname contents
    return .ok stx.raw
  catch _ =>
    return .error .parse_failure

/-- Get the top-level commands from a parsed module's raw Syntax. -/
def moduleCommands (raw : Syntax) : Array Syntax :=
  let moduleArgs := raw.getArgs
  if moduleArgs.size < 2 then #[]
  else moduleArgs[1]!.getArgs

/-- Check if a syntax node is a top-level declaration. -/
def isTopDecl (cmd : Syntax) : Bool :=
  match cmd with
  | .node _ kind _ => kind.toString == "Lean.Parser.Command.declaration"
  | _ => false

/-- Extract the declaration name (first identifier in the syntax tree). -/
partial def declNameOf (cmd : Syntax) : Option String :=
  let rec walk (s : Syntax) : Option String :=
    match s with
    | .ident _ _ val _ => some val.toString
    | .node _ _ args   => args.findSome? walk
    | _ => none
  walk cmd

/-- Classify a top-level declaration by its kind keyword (axiom/def/theorem/...).
The `declaration` syntax node wraps a `declModifiers` node followed by the actual
kind node (axiom/def/theorem/...). Skip `declModifiers` and report the first
`Lean.Parser.Command.<kind>` child that is not the modifiers wrapper. -/
partial def declKind (cmd : Syntax) : Option String :=
  match cmd with
  | .node _ _ args =>
    args.findSome? fun child =>
      match child with
      | .node _ k _ =>
        let ks := k.toString
        let prefixStr := "Lean.Parser.Command."
        if ks.startsWith prefixStr && ks != "Lean.Parser.Command.declModifiers" then
          -- Use Substring for version-stable slicing (avoids String.Pos.mk API churn).
          some ((ks.toSubstring.drop prefixStr.length).toString)
        else none
      | _ => none
  | _ => none

/-- Look up a declaration by name. Returns `.ok cmd` on unique match, `.error .ambiguous_name`
on multiple matches, `.error .name_not_found` if missing. -/
def findDeclByName (cmds : Array Syntax) (targetName : String) :
    Except ErrorKind Syntax :=
  let hits := cmds.filter fun cmd =>
    isTopDecl cmd && (declNameOf cmd == some targetName)
  if hits.size == 0 then .error .name_not_found
  else if hits.size > 1 then .error .ambiguous_name
  else .ok hits[0]!

/-- Escape a string for JSON output. Shared by `parse` and `query` subcommands. -/
def escapeJsonString (s : String) : String :=
  s.foldl (init := "") fun acc c =>
    match c with
    | '"'  => acc ++ "\\\""
    | '\\' => acc ++ "\\\\"
    | '\n' => acc ++ "\\n"
    | '\r' => acc ++ "\\r"
    | '\t' => acc ++ "\\t"
    | _    =>
      if c.toNat < 0x20 then
        acc ++ s!"\\u{String.ofList (Nat.toDigits 16 c.toNat)}"
      else acc.push c

end LeanCli
