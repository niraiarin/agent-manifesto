import Lean

/-!
# Byte-Preserving Rewrite PoC — Sub-E #660 + Sub-F #661 CONDITIONAL resolution (Impl-B #663)

Demonstrates that a Lean declaration can be replaced while preserving
every byte outside the declaration's source range.

## Algorithm

1. Read input file as raw ByteArray (preserves CRLF, BOM, non-newline-terminated, etc.)
2. Also read as String for parsing (UTF-8 decoding; round-trips for valid UTF-8)
3. Parse via `Lean.Parser.Module.testParseFile`
4. Find target declaration by name
5. Get `Syntax.getRange?` → byte offsets (start, stop) — these are UTF-8 byte indices
6. Output = inputBytes[0..start] ++ newDeclBytes ++ inputBytes[stop..end]
7. Write output to `<outputPath>.tmp.<pid>.<heartbeats>` (same directory for rename atomicity)
8. `IO.FS.rename` to replace outputPath atomically (POSIX rename(2))

Atomic rename (step 7-8) is the Sub-F CONDITIONAL mitigation:
concurrent writers write to process-unique tmp files then atomically publish
via rename(2). Last writer wins; no partial-write visibility.

## Usage

  lake exe rewrite-poc <input.lean> <decl-name> <new-decl-text> <output.lean>

Exit codes (aligning with Sub-A #656 error contract):
  0  = ok
  2  = parse_failure
  5  = name_not_found
  10 = internal_error
-/

open Lean Parser

partial def declNameOf (cmd : Syntax) : Option String :=
  let rec walk (s : Syntax) : Option String :=
    match s with
    | .ident _ _ val _ => some val.toString
    | .node _ _ args => args.findSome? walk
    | _ => none
  walk cmd

/-- Check if a command kind represents a top-level declaration we care about. -/
def isTopDecl (cmd : Syntax) : Bool :=
  match cmd with
  | .node _ kind _ =>
    let k := kind.toString
    k == "Lean.Parser.Command.declaration"
  | _ => false

def main (args : List String) : IO UInt32 := do
  match args with
  | [inputPath, targetName, newDeclText, outputPath] => do
    -- 1. Read raw bytes (preserves CRLF, BOM, etc.)
    let inputBytes ← IO.FS.readBinFile inputPath
    -- 2. Detect UTF-8 BOM (EF BB BF) and strip for parsing while preserving in output
    let bomOffset : Nat :=
      if inputBytes.size ≥ 3
         && inputBytes.get! 0 == 0xEF
         && inputBytes.get! 1 == 0xBB
         && inputBytes.get! 2 == 0xBF
      then 3 else 0
    let parseBytes :=
      if bomOffset > 0 then inputBytes.extract bomOffset inputBytes.size else inputBytes
    let parseContents := String.fromUTF8! parseBytes
    -- 3. Initialize parser environment
    initSearchPath (← findSysroot)
    let env ← importModules #[{ module := `Init }] {} (trustLevel := 1024)
    -- 4. Parse (via testParseModule which takes string content, so BOM-stripped)
    let stx ← try
      testParseModule env inputPath parseContents
    catch e =>
      IO.eprintln s!"ERROR parse_failure: {e.toString}"
      IO.Process.exit 2
    let raw : Syntax := stx.raw
    let moduleArgs := raw.getArgs
    if moduleArgs.size < 2 then
      IO.eprintln "ERROR internal_error: unexpected module structure"
      return 10
    let cmds := moduleArgs[1]!.getArgs
    -- 5. Find target declaration
    let target? := cmds.findSome? fun cmd =>
      if isTopDecl cmd then
        match declNameOf cmd with
        | some n => if n == targetName then some cmd else none
        | none => none
      else none
    match target? with
    | none =>
      IO.eprintln s!"ERROR name_not_found: '{targetName}'"
      return 5
    | some cmd =>
      match cmd.getRange? (canonicalOnly := false) with
      | none =>
        IO.eprintln "ERROR internal_error: no source range"
        return 10
      | some range =>
        -- Parser ranges are in parseBytes coordinate space; add bomOffset to map to inputBytes
        let startByte := range.start.byteIdx + bomOffset
        let stopByte := range.stop.byteIdx + bomOffset
        if startByte > inputBytes.size || stopByte > inputBytes.size then
          IO.eprintln s!"ERROR internal_error: range out of bounds [{startByte},{stopByte}] size {inputBytes.size}"
          return 10
        -- 6. Build output via byte-level slicing (BOM is preserved in `before` if present)
        let before := inputBytes.extract 0 startByte
        let after := inputBytes.extract stopByte inputBytes.size
        let newBytes := newDeclText.toUTF8
        let output := (before ++ newBytes) ++ after
        -- 7. Atomic write: write to process-unique tmp, then rename(2) (Impl-B #663)
        let pid ← IO.Process.getPID
        let heartbeats ← IO.getNumHeartbeats
        let tmpPath := outputPath ++ s!".tmp.{pid}.{heartbeats}"
        IO.FS.writeBinFile tmpPath output
        try
          IO.FS.rename tmpPath outputPath
        catch e =>
          try IO.FS.removeFile tmpPath catch _ => pure ()
          throw e
        IO.println s!"OK range=[{startByte},{stopByte}] original_size={inputBytes.size} output_size={output.size}"
        return 0
  | _ =>
    IO.eprintln "Usage: rewrite-poc <input.lean> <decl-name> <new-decl-text> <output.lean>"
    return 64
