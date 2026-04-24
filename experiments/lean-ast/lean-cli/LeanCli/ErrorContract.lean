/-!
# Error Contract — Sub-A #656 spec

8 error_kind × 8 exit code. CLI-agnostic; shared across all subcommands.

| kind                | exit | stderr prefix              |
|---------------------|------|----------------------------|
| usage               |  64  | ERROR usage:               |
| io_read             |   1  | ERROR io_read:             |
| parse_failure       |   2  | ERROR parse_failure:       |
| ambiguous_name      |   3  | ERROR ambiguous_name:      |
| invalid_range       |   4  | ERROR invalid_range:       |
| name_not_found      |   5  | ERROR name_not_found:      |
| io_write            |   6  | ERROR io_write:            |
| internal_error      |  10  | ERROR internal_error:      |
-/

namespace LeanCli

inductive ErrorKind where
  | usage
  | io_read
  | parse_failure
  | ambiguous_name
  | invalid_range
  | name_not_found
  | io_write
  | internal_error
  deriving Repr, BEq

def ErrorKind.exitCode : ErrorKind → UInt32
  | .usage          => 64
  | .io_read        => 1
  | .parse_failure  => 2
  | .ambiguous_name => 3
  | .invalid_range  => 4
  | .name_not_found => 5
  | .io_write       => 6
  | .internal_error => 10

def ErrorKind.label : ErrorKind → String
  | .usage          => "usage"
  | .io_read        => "io_read"
  | .parse_failure  => "parse_failure"
  | .ambiguous_name => "ambiguous_name"
  | .invalid_range  => "invalid_range"
  | .name_not_found => "name_not_found"
  | .io_write       => "io_write"
  | .internal_error => "internal_error"

def reportError (kind : ErrorKind) (detail : String) : IO UInt32 := do
  IO.eprintln s!"ERROR {kind.label}: {detail}"
  return kind.exitCode

end LeanCli
