import LeanCli.ErrorContract
import LeanCli.Core
import LeanCli.Parse
import LeanCli.Query
import LeanCli.Edit
import LeanCli.Insert

/-!
# lean-cli — main dispatcher (Impl-A #666 derived from Sub-A #656)

Subcommands:
  parse   <file>
  query   <file> [--kind <k>] [--name-substring <s>]
  edit    <file> --replace-body <name> <expr> --output <file>
  insert  <file> --before <name> <decl> --output <file>

Exit codes are defined by `LeanCli.ErrorKind` (Sub-A #656 error contract).
-/

open LeanCli

def printUsage : IO Unit := do
  IO.eprintln "Usage:"
  IO.eprintln "  lean-cli parse  <file>"
  IO.eprintln "  lean-cli query  <file> [--kind <k>] [--name-substring <s>]"
  IO.eprintln "  lean-cli edit   <file> --replace-body <name> <expr> --output <file>"
  IO.eprintln "  lean-cli insert <file> --before <name> <decl> --output <file>"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["parse", file] =>
    runParse file
  | "query" :: file :: rest =>
    match parseQueryArgs rest with
    | .error msg => do
      printUsage
      reportError .usage msg
    | .ok opts => runQuery file opts
  | "edit" :: file :: rest =>
    match parseEditArgs rest with
    | .error msg => do
      printUsage
      reportError .usage msg
    | .ok opts => runEdit file opts
  | "insert" :: file :: rest =>
    match parseInsertArgs rest with
    | .error msg => do
      printUsage
      reportError .usage msg
    | .ok opts => runInsert file opts
  | _ =>
    printUsage
    return ErrorKind.usage.exitCode
