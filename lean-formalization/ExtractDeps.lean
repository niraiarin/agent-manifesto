import Lean

/-!
# Fine-Grained Dependency Graph Extractor

Extracts axiom/theorem-level dependency graph from the Manifest module.
Outputs JSON with nodes and edges for DAG visualization.

Usage: `lake exe extractdeps > depgraph.json`

Reference: #158, #157 (公理系の数理的基盤整備)
-/

open Lean in
/-- Classify a ConstantInfo into a human-readable kind string. -/
def constKind (ci : ConstantInfo) : String :=
  match ci with
  | .axiomInfo _  => "axiom"
  | .thmInfo _    => "theorem"
  | .defnInfo _   => "def"
  | .opaqueInfo _ => "opaque"
  | .inductInfo _ => "inductive"
  | .ctorInfo _   => "constructor"
  | .recInfo _    => "recursor"
  | .quotInfo _   => "quot"

/-- Check if a Name belongs to the Manifest module (not stdlib). -/
def isManifestName (n : Lean.Name) : Bool :=
  match n with
  | .str p _ => p == `Manifest || isManifestName p
  | .num p _ => isManifestName p
  | .anonymous => false

/-- Standard axioms that are part of Lean's foundation. -/
def isStandardAxiom (n : Lean.Name) : Bool :=
  n == ``propext ||
  n == ``Classical.choice ||
  n == ``Quot.sound ||
  n == ``Quot.mk ||
  n == ``Quot.ind ||
  n == ``Quot.lift

/-- Extract all Manifest-namespace constants referenced by an expression. -/
def manifestDeps (e : Lean.Expr) : Array Lean.Name :=
  e.getUsedConstants.filter fun n => isManifestName n

/-- Escape a string for JSON output. -/
def jsonEscape (s : String) : String :=
  s.foldl (fun acc c =>
    match c with
    | '"' => acc ++ "\\\""
    | '\\' => acc ++ "\\\\"
    | '\n' => acc ++ "\\n"
    | _ => acc.push c
  ) ""

/-- Check if name contains internal/auxiliary patterns we want to skip. -/
def isInternalName (nameStr : String) : Bool :=
  let patterns := #["._", ".match_", ".proof_", ".eq_", ".brecOn",
                     ".below", ".casesOn", ".noConfusion", ".recOn",
                     ".injEq", ".sizeOf_spec", ".mk.", ".rec.",
                     "instRepr", "instBEq", "instDecidableEq",
                     "instInhabited", "instSizeOf"]
  patterns.any fun pat => (nameStr.splitOn pat).length > 1

open Lean in
def main : IO Unit := do
  -- Initialize search path and import Manifest
  initSearchPath (← findSysroot)
  let env ← importModules
    #[{ module := `Manifest }]
    {}
    (trustLevel := 1024)

  let nodesRef ← IO.mkRef (α := Array (String × String × String)) #[]
  let edgesRef ← IO.mkRef (α := Array (String × String × String)) #[]
  let seenRef ← IO.mkRef (α := Lean.NameHashSet) {}

  let processConst (name : Lean.Name) (ci : ConstantInfo) : IO Unit := do
    if isManifestName name && !isStandardAxiom name then
      let nameStr := toString name
      if !isInternalName nameStr then
        let kind := constKind ci
        if kind != "constructor" && kind != "recursor" && kind != "quot" then
          let seen ← seenRef.get
          if !seen.contains name then
            let shortName := nameStr.stripPrefix "Manifest."
            nodesRef.modify fun arr => arr.push (nameStr, shortName, kind)
            seenRef.modify fun s => s.insert name

            -- Type dependencies
            let typeDeps := manifestDeps ci.type
            for dep in typeDeps do
              if dep != name && !isStandardAxiom dep then
                let depStr := toString dep
                if !isInternalName depStr then
                  edgesRef.modify fun arr => arr.push (nameStr, depStr, "type")

            -- Value/proof dependencies
            let valueDeps := match ci with
              | .defnInfo d   => manifestDeps d.value
              | .thmInfo t    => manifestDeps t.value
              | .opaqueInfo o => manifestDeps o.value
              | _ => #[]
            for dep in valueDeps do
              if dep != name && !isStandardAxiom dep then
                let depStr := toString dep
                if !isInternalName depStr then
                  edgesRef.modify fun arr => arr.push (nameStr, depStr, "value")

  -- Process both stages of constants
  let consts := env.constants
  consts.map₁.foldM (init := ()) fun () name ci => processConst name ci
  consts.map₂.forM fun name ci => processConst name ci

  let nodes ← nodesRef.get
  let edges ← edgesRef.get

  -- Deduplicate edges (keep strongest: value > type)
  let mut edgeMap : Std.HashMap String String := {}
  for (src, tgt, ek) in edges do
    let key := src ++ "|" ++ tgt
    match edgeMap[key]? with
    | some "value" => pure ()
    | _ => edgeMap := edgeMap.insert key ek

  -- Output JSON
  IO.println "{"
  IO.println "  \"nodes\": ["
  for i in [:nodes.size] do
    let (fullName, shortName, kind) := nodes[i]!
    let comma := if i + 1 < nodes.size then "," else ""
    IO.println s!"    \{\"name\": \"{jsonEscape shortName}\", \"fullName\": \"{jsonEscape fullName}\", \"kind\": \"{kind}\"}{comma}"
  IO.println "  ],"

  IO.println "  \"edges\": ["
  let edgeEntries := edgeMap.toArray
  for i in [:edgeEntries.size] do
    let (key, ek) := edgeEntries[i]!
    let parts := key.splitOn "|"
    let src := parts[0]!
    let tgt := parts[1]!
    let comma := if i + 1 < edgeEntries.size then "," else ""
    IO.println s!"    \{\"source\": \"{jsonEscape src}\", \"target\": \"{jsonEscape tgt}\", \"edgeKind\": \"{ek}\"}{comma}"
  IO.println "  ]"
  IO.println "}"
