# lean-cli — Implementation-phase CLI (Impl-A #666)

Derived from Research #654 (Sub-A #656 spec + Sub-B #657 API delta + Sub-E #660 rewrite
algorithm + Sub-F #661 atomic rename + Sub-G #662 hook invocation).

## Subcommands

| subcommand | purpose | options |
|------------|---------|---------|
| `parse`    | emit JSONL summary of top-level declarations | (none) |
| `query`    | filter declarations by kind/name | `--kind <k>`, `--name-substring <s>` |
| `edit`     | byte-preserving replacement of a declaration | `--replace-body <name> <expr> --output <file>` |
| `insert`   | insert new declaration before target | `--before <name> <decl> --output <file>` |

## Usage

```
lake build
.lake/build/bin/lean-cli parse path/to/file.lean
.lake/build/bin/lean-cli query path/to/file.lean --kind axiom
.lake/build/bin/lean-cli edit path/to/file.lean --replace-body foo "axiom foo : Bool" --output out.lean
.lake/build/bin/lean-cli insert path/to/file.lean --before target "axiom inserted : Nat" --output out.lean
```

## Error contract (Sub-A #656)

All subcommands share the following exit codes (`LeanCli.ErrorContract`):

| exit | kind              | stderr prefix                 |
|------|-------------------|-------------------------------|
| 0    | ok                | (none)                        |
| 1    | io_read           | `ERROR io_read:`              |
| 2    | parse_failure     | `ERROR parse_failure:`        |
| 3    | ambiguous_name    | `ERROR ambiguous_name:`       |
| 4    | invalid_range     | `ERROR invalid_range:`        |
| 5    | name_not_found    | `ERROR name_not_found:`       |
| 6    | io_write          | `ERROR io_write:`             |
| 10   | internal_error    | `ERROR internal_error:`       |
| 64   | usage             | (usage printed on stderr)     |

## Atomic write (Sub-F #661 + Impl-B #663)

`edit` and `insert` subcommands write to `<output>.tmp.<pid>.<heartbeats>` then
`IO.FS.rename` (POSIX `rename(2)`) atomically. Concurrent writers do not produce
partial-write visibility; last rename wins.

## Operational constraints (from Sub-F)

- Binary is invoked directly (pre-built). `lake exe` path is out of scope for binary-level
  race analysis — see Impl-D #668 for lake-level concurrent verification.
- Agent Teams parallel dispatch recommended N ≤ 4 (CPU contention dominates at N ≥ 8).

## Tests

```
bash tests/run-tests.sh    # 7 integration tests covering all 4 subcommands + error paths
```

### Byte-preserving coverage (inherited from Sub-E)

The `edit` subcommand shares its core algorithm with Sub-E's
`../rewrite-poc/RewritePoC.lean`. The 14-pattern byte-preserving harness lives at
`../rewrite-poc/run-tests.sh` and was executed as part of Research #654 Sub-E #660
(commit `0d5f51e`, 14/14 PASS including CRLF / BOM / NFD / NFC edge cases). The
local `tests/run-tests.sh` here adds integration coverage for `parse`, `query`,
`edit`, `insert`, and the error contract on top of that shared foundation.

## Limitations

- Only imports `Init` (Profile A from Sub-D #659). Mathlib-dependent declarations cannot
  be edited/inserted (out-of-scope for Impl-A; covered in Profile B research if needed).
- Substring match for `query --name-substring` (regex support is a future extension).
- `parse` emits summary JSONL only; full AST dump is deferred.
