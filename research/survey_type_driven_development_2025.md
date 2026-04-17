# Type-Driven Development Survey (2025-2026)

Conducted: 2026-04-16

8 sources surveyed covering developer experience, proof automation, self-verification, refinement types, quantitative type theory, algebraic effects, and the TyDe workshop series. 4 TyDe 2025 papers deep-dived for applicability.

---

## Part I: Source Summaries

### S1: The Way of Types (ICPC 2026)

- **Title**: "The Way of Types: A Report on Developer Experience with Type-Driven Development"
- **Authors**: Sara Juhosova, Andy Zaidman, Jesper Cockx (TU Delft)
- **Venue**: ICPC 2026
- **URL**: https://sarajuhosova.com/assets/files/2026-icpc.pdf

#### Summary

130 participants surveyed on TyDD experiences. Most used Haskell (83%), Agda, Rust, Lean.

#### Community-Based Definition of TyDD

> "Type-driven development is an approach to programming in which the developer defines a program's *types and type signatures first* in order to (1) *design* and (2) *communicate* the solution, (3) *guide* and (4) *verify* the implementation, and (5) *receive support* from related tools."

Extends Brady's original definition (types first, implementation later) with communication, verification, and tooling dimensions.

#### Key Findings

**10 Benefits** (297 entries from 108 participants):
1. Deeper understanding of the problem domain
2. More thoughtful design
3. Easier mental models composed of interfaces
4. Better collaboration through contracts and APIs
5. Maintainability
6. Clearer path towards implementation
7. Top-down development via interactive (hole-driven) development
8. Higher confidence in correctness
9. Less scary refactoring
10. Pleasure when programming (12 entries mentioned "fun")

**4 Improvement Categories** (217 entries from 72 participants):
1. **Shielding users from complexities**: Learning curve, debugging difficulty, type checker friction
2. **Improving ecosystems** (most cited): Documentation, error messages, visualization, IDE/LSP support. Rust cited as gold standard
3. **Integrating into the real world**: Business context applications, DevOps tooling, FFI, performance
4. **Adding more features**: More dependent types in practical languages, hole orientation, case splitting, inhabitation search

#### 3 Key Inhibitors to Advanced TyDD Adoption
1. Effort to satisfy type checkers increases with type system expressivity
2. Ecosystem quality of TyDD-oriented languages is insufficient
3. Libraries, tools, and performance for real-world software are lacking

Core tension: **usefulness vs. usability** (Technology Acceptance Model).

#### Future Work Directions
1. User-oriented design for type system research
2. TyDD tools for existing statically typed languages (without changing type systems)
3. Refinement types natively incorporated into language compilers
4. Hybrid compile-time + runtime type checking

#### Threats to Validity
- Convenience sampling from Agda/Rocq/Lean/Haskell communities (positive bias toward TyDD)
- Survey format cannot assess significance/severity of individual items
- Constructivist epistemological stance declared; full replication package published

---

### S2: Lean-Auto (CAV 2025)

- **Title**: "Lean-Auto: An Interface Between Lean 4 and Automated Theorem Provers"
- **Authors**: Yicheng Qian, Joshua Clune (Stanford/CMU), Clark Barrett, Jeremy Avigad
- **Venue**: CAV 2025, LNCS vol. 15933
- **DOI**: 10.1007/978-3-031-98682-6_10
- **URL**: https://link.springer.com/chapter/10.1007/978-3-031-98682-6_10

#### Summary

First general-purpose ATP-based proof automation for Lean 4. Novel monomorphization algorithm for dependent type theory.

#### Technical Architecture

4-stage translation pipeline:
1. **Preprocessing**: Lean 4 -> lambda-C (partial reduction using `Meta.transform`, `Meta.whnf`)
2. **Quantifier Instantiation**: Saturation-based instantiation of polymorphic quantifiers
3. **lambda-arrow-star Abstraction**: Essentially higher-order problems -> HOL*
4. **Universe Lifting**: HOL* -> HOL (universe level erasure)

ATP backends: Duper (native, proof-producing), Zipperposition (TPTP TH0), Z3/CVC5 (SMT)

#### Key Results (Mathlib4, 149,142 theorems, 10s timeout)

| Method | Solved | % |
|--------|--------|---|
| Aesop (best existing) | 48,413 VBS | 32.5% |
| **Lean-auto + Duper** | **54,570** | **36.6%** |
| **Lean-auto VBS** | **61,906** | **41.5%** |
| Overall VBS (all tools) | 79,396 | 53.2% |

- Lean-auto VBS achieves 22,020 unique solves (14.8%) -> high complementarity with existing tools
- Trade-off: 8-190x slower than existing tools (avg 756-1092ms vs Aesop's 92ms)

#### Soundness
- Duper backend: full proof reconstruction via verified checker -> Lean 4 kernel is sole trust base
- External ATPs (Z3, CVC5, Zipperposition): ATP output trusted (warning emitted)
- Monomorphization itself is sound (unlike CoqHammer's encoding-based approach)

#### Limitations
- Proof reconstruction only for Duper
- No premise selection (uses idealized oracle)
- Existential type quantifiers and non-leading universal type quantifiers unsupported
- Performance bottleneck: frequent definitional equality tests during monomorphization

---

### S3: Lean4Lean (arXiv 2024, WITS 2026 Keynote)

- **Title**: "Lean4Lean: Verifying a Typechecker for Lean, in Lean"
- **Author**: Mario Carneiro (Chalmers University of Technology)
- **Venues**: arXiv 2403.14064 (v3: 2025-09-14), WITS 2026 @ POPL 2026 (Keynote), TYPES 2025
- **Repository**: https://github.com/digama0/lean4lean

#### Summary

First complete Lean 4 typechecker outside the C++ reference implementation, written in Lean itself. Verifies all of Mathlib.

#### Two-Layer Architecture

**Layer 1 (Executable typechecker):**
- Carbon copy of C++ reference implementation in Lean
- `RecM` monad + fuel-based recursion (depth 1000)
- `Methods` record with 4 cutpoint functions: `isDefEqCore`, `whnfCore`, `whnf`, `inferType`

**Layer 2 (Formalized metatheory):**
- `VExpr`: simplified specification type (bvar, sort, const, app, lam, forallE)
- Unified judgment: `Gamma |- e = e' : alpha`
- `TrExpr` predicate: correspondence between kernel `Expr` and `VExpr`

#### Proven Theorems
- Closedness preservation, weakening, universe/variable substitution
- **Theorem 2.5 (Type Regularity)**: All well-typed terms have well-typed types
- `inferLambda.WF`: Correctness of lambda type inference

#### Open Conjectures
- **Conjecture 2.7 (Unique Typing)**: Each term has essentially unique type up to definitional equality
- **Conjecture 2.9 (Definitional Inversion)**: Sort injectivity, forall injectivity, sort != forall
- Blocked by: stratification of typing judgment doesn't preserve substitution

#### Performance

| Package | C++ Kernel | Lean4Lean | Ratio |
|---------|-----------|-----------|-------|
| Lean (compiler) | 37.01s | 44.61s | 1.21x |
| Std | 32.49s | 45.74s | 1.40x |
| Mathlib | 44.54min | 58.79min | 1.32x |

20-50% overhead — competitive for a Lean-in-Lean implementation.

#### Key Insights

1. **Self-verification is fundamentally limited**: Full soundness of Lean cannot be proved in Lean (Godel's incompleteness). Strategy: redundant verification via independent reimplementation
2. **Lean's type theory is genuinely non-terminating**: Impredicativity + proof irrelevance + subsingleton elimination (Coquand-Abel construction). Fuel-based practical management
3. **Recursor-based design advantage**: Unlike Coq's guard checker, Lean's recursor approach simplifies formalization and eliminates guard checker bugs
4. **Bug found**: `looseBVarRange` soundness bug discovered through formalization effort, fixed in C++ kernel

---

### S4: Refinement-Types Driven Development (IFL 2025)

- **Title**: "Refinement-Types Driven Development: A study"
- **Authors**: Facundo Dominguez, Arnaud Spiwack (Tweag France)
- **Venue**: 37th Symposium on Implementation and Application of Functional Languages (IFL 2025), October 2025, Montevideo, Uruguay
- **URL**: https://arxiv.org/html/2509.15005

#### Central Thesis

> "SMT solvers are useful to the ordinary activity of programming."

Challenges conventional wisdom that SMT solvers are only for formal methods. Argues refinement types (Liquid Haskell) enable SMT integration into mundane programming.

#### Case Study: Capture-Avoiding Substitution in Compilers

Problem: Binder scope management in compilers (canonical bug: `(lambda x.y)[y:=x]` -> `lambda x.x`)

5 invariants for correct substitution:
1. Every traversed binder must be added to scope set
2. Bindersin scope must be renamed
3. New names must not belong to scope set
4. Old bound variable occurrences need substitution with new names
5. Initial scope set must contain free variables in input and substitution range

Extended to first-order unification with skolem applications and multiple intermingled scopes.

#### Key Refinement Type Examples

```haskell
{-@ type ScopedExp S = {e:Exp | isSubsetOf (freeVars e) S} @-}

{-@ substitute :: scope:Set Int -> s:Subst (ScopedExp scope)
    -> ScopedExp (domain s) -> ScopedExp scope @-}
```

Hoare logic for State monad:
```haskell
skolemize :: sf:Set Int -> f:ScopedFormula sf
  -> State <{pre}, {post}> (IntMap (Set Int)) Formula
```

#### 5 Practical Principles
1. When easier to prove by hand than with SMT, use `assume`
2. Refinement types add a subtyping layer on top of your type system
3. Refinement types and abstract types enforce different kinds of properties
4. Start with functions having best power-to-weight ratio (incremental adoption)
5. Properties are easier when assumptions are explicit

#### Key Finding: Temporal Invariants

Basic refinement type signatures alone cannot detect certain bugs (e.g., reusing a binder already in scope). These are **temporal invariants** requiring abstract types (`Scope` newtype) for encapsulation.

#### Limitations
- **18 Liquid Haskell bugs** and **1 Z3 bug** found during case study
- No GADTs, type families, minimal type class support
- End-to-end Liquid Haskell check slow: 3 minutes for unification example (SMT queries themselves: 11s)
- SMT error messages less intuitive than type checker errors
- Custom finite maps theory implementation required

---

### S5: Idris 2 — Quantitative Type Theory in Practice (ECOOP 2021)

- **Title**: "Idris 2: Quantitative Type Theory in Practice"
- **Author**: Edwin Brady (University of St Andrews)
- **Venue**: ECOOP 2021
- **arXiv**: 2104.00480
- **URL**: https://arxiv.org/abs/2104.00480

#### QTT Core Concept

Each variable binding is annotated with a **multiplicity** from the semiring {0, 1, omega}:
- **0**: Compile-time only, erased at runtime. Used in type annotations but not executable code
- **1**: Used exactly once (linear). Enables resource tracking
- **omega**: Unrestricted use (default for explicit bindings)

Key insight: **Multiplicities are on binders, not on types**. Variable occurrences in type positions are not counted as "uses."

#### Practical Benefits

**Erasure (multiplicity 0)**:
- Type-level guarantee of what data exists at runtime
- Solves decades-old erasure problem for dependent types
- Example: `uncompress : RunLength {ty} xs -> Singleton xs` — `xs` is erased, result is typed to equal `xs`

**Resource Tracking (multiplicity 1)**:
- ATM state machine: Each operation consumes linear channel reference and returns new state
- IO implementation: `%World` token is linear, preventing world duplication/discard
- Session types: Channel consumed exactly once per protocol step

**Session Types (Chapter 5)**:
- `Channel : Actions -> Type` parameterized by protocol
- Dependent types: Protocol changes based on values sent/received
- `fork : ((1 chan : Server p) -> L ()) -> L {use=1} (Client p)`
- Dual protocols automatically derived via `AsClient`/`AsServer`

#### Dependent + Linear Type Interaction

Historical problem: Type positions reference linear variables, consuming them. QTT solution: occurrences at multiplicity-0 positions (types) don't count as uses.

```
insert : a -> (1 xs: List a) -> (0 _ : Ordered xs) -> List a
```
`Ordered xs` references `xs` but at multiplicity 0, so `xs` remains available for linear use in the body.

#### Comparison with Alternatives

| System | Dependent Types | Linear Types | Erasure |
|--------|----------------|--------------|---------|
| Idris 2 (QTT) | Full | Full (0,1,omega) | Yes (0) |
| Rust | No | Ownership/borrowing | N/A |
| Linear Haskell | No | Arrow-level linearity | No |
| Granule | Partial (research) | Graded types | Partial |
| ATS | Partial | Yes | N/A |

#### Limitations
1. **No quantity polymorphism**: Must define separate `pure`, `pure0`, `pure1` etc.
2. **Linearity + exceptions**: Cleanup requires knowing machine state; nested case blocks proliferate
3. **Performance**: Not benchmarked in the paper
4. **Session types**: Dyadic only (no multiparty); no distributed error handling

---

### S6: TyDe 2025 Workshop (ICFP/SPLASH 2025)

- **Workshop**: Workshop on Type-Driven Development (TyDe) 2025
- **Date**: October 12, 2025
- **Location**: NUS School of Computing, Singapore
- **Co-located with**: ICFP/SPLASH 2025
- **Co-Chairs**: Andras Kovacs (Gothenburg/Chalmers), Yuting Wang (Shanghai Jiao Tong)
- **URL**: https://conf.researchr.org/home/icfp-splash-2025/tyde-2025

#### Accepted Papers (9 + 1 keynote)

**Keynote**: Liang-Ting Chen (Academia Sinica) — "From Datatype-Generic Programming to Language-Generic Programming"

| # | Title | Authors | Topic |
|---|-------|---------|-------|
| 1 | Representing Data Structures with Invariants in Haskell: the cases of BST and AVL | Rodriguez, Pardo, Viera | Invariant-preserving data structures |
| 2 | Towards a Performance Comparison of Syntax and Type-Directed NbE | Gould, Bowman (UBC) | NbE performance |
| 3 | The conatural numbers form an exponential commutative semiring | Xie, Bense (ELTE) | Formalization |
| 4 | Gradual Metaprogramming | Chen, Shetty, Siek (Indiana); Chen, Ma, Venet, Liu (Meta) | Gradual typing + metaprogramming |
| 5 | Unification Modulo Isomorphisms between Dependent Types for Type-based Library Search | Takimoto, Moriguchi, Watanabe (IST) | Type-based search |
| 6 | Generating a corpus of Hazel programs from ill-typed OCaml programs | Ferris, Madhavapeddy (Cambridge) | Program corpus generation |
| 7 | Constrained generation of well-typed programs | Barreiro, Scherer (Ecole Polytechnique/Paris Cite) | Type-safe program generation |
| 8 | **Type-Driven Prompt Programming: From Typed Interfaces to a Calculus of Constraints** | Paul (Samsung R&D) | **Type theory x LLM prompting** |
| 9 | A Formalization of Opaque Definitions for a Dependent Type Theory | Danielsson, Geng (Gothenburg/Chalmers) | Dependent type formalization |

#### Trends
- **Program generation** (papers 6, 7, 8): Type-directed automatic program generation is prominent
- **LLM x Type Theory** (paper 8): Novel direction connecting typed interfaces to prompt programming
- **Formalization deepening** (papers 3, 5, 9): Core dependent type theory research continues
- **Industrial presence**: Meta (paper 4), Samsung (paper 8)

#### N1: Paper 2 — NbE Performance Comparison (Gould, Bowman, UBC)

- **Title**: "Towards a Performance Comparison of Syntax and Type-Directed NbE"
- **arXiv**: 2509.13489

Extended abstract comparing **syntax-directed** vs **type-directed** Normalization by Evaluation (NbE) in dependent type checkers. Built on `smalltt` (Kovacs 2023), a performant type checker.

**Syntax-directed equality**: Checks definitional equality using reduction rules (beta, eta) observable in program structure without explicit type information. Two terms are equal if they reduce to the same normal form.

**Type-directed equality**: Uses type information to guide equality decisions via bidirectional check/synth judgments. Enables rules like "all Unit expressions are equal" by inspecting the type. Required for eta-rules on Sigma types and Unit.

Core implementation difference:
```
-- Syntax-directed: no type parameter
unify :: Lvl -> Val -> Val -> IO ()

-- Type-directed: type parameter enables eta-expansion
unifyChk :: Cxt -> Val -> Val -> VTy -> IO ()
unifySp  :: Cxt -> VTy -> Spine -> Spine -> IO VTy
```

**Performance finding**: Type-directed NbE is **3.4x slower on average** than syntax-directed. One benchmark caused memory exhaustion. For context: Agda and Lean are 80x and 38x slower respectively than syntax-directed smalltt.

**Root cause**: Type-directed must fully normalize types to identify applicable eta-rules. Glued evaluation (exploiting equality preservation across substitution/evaluation) benefits syntax-directed more.

#### N2: Paper 3 — Conatural Numbers as Semiring (Xie, Bense, ELTE)

- **Title**: "The conatural numbers form an exponential commutative semiring"
- **DOI**: 10.1145/3759538.3759654

First proof in cubical type theory (without major extensions) that conatural numbers (N_infinity, coinductive dual of natural numbers) form an exponential commutative semiring. Key challenge: Agda's guardedness checker rejects corecursive definitions where the corecursive occurrence appears under previously defined operations.

```agda
-- Coinductive type: each value is either zero or successor of another conat
record Conat : Set where
  coinductive
  field force : Maybe Conat   -- Nothing = zero, Just n = suc n

infinity : Conat
force infinity = Just infinity
```

Key properties: infinity + 1 = infinity, infinity + infinity = infinity, forms an hSet in cubical Agda.

**Bisimulation = Equality**: In cubical type theory, bisimulation on conatural numbers is equivalent to propositional equality (via the cubical Coinductive Proof Principle).

#### N3: Paper 4 — Gradual Metaprogramming (Chen, Shetty, Siek et al.)

- **Title**: "Gradual Metaprogramming"
- **arXiv**: 2506.09043
- **DOI**: 10.1145/3759538.3759650

Defines **MetaGTLC**, a metaprogramming calculus where a gradually-typed metalanguage manipulates a statically-typed object language. Motivated by Meta's internal DSL-to-data-pipeline code generation: a Python DSL (dynamically typed) generates statically-typed pipeline code. Errors in the Python DSL are caught too late and lack source location. Gradual metaprogramming inserts runtime checks (casts) at splice boundaries to catch type errors incrementally during metaevaluation.

**Technical Architecture**:
- **Metalanguage**: Gradually-typed lambda calculus (GTLC — Siek & Taha 2006)
- **Object language**: Simply-typed lambda calculus (STLC)
- **Key operators**: `quote` (lift object code), `splice` (embed meta-result into object code)
- **Semantics**: Translation to **MetaCC** (cast calculus) — inserts casts at splice points

**Key theorem** (mechanized in Agda): Successful metaevaluation always generates a well-typed object program.

#### N4: Paper 9 — Opaque Definitions Formalization (Danielsson, Geng, Chalmers)

- **Title**: "A Formalization of Opaque Definitions for a Dependent Type Theory"
- **DOI**: 10.1145/3759538.3759653
- **URL**: https://www.cse.chalmers.se/~nad/publications/danielsson-geng-opaque-definitions.pdf

Formalizes opaque definitions for dependent type theory in Agda. Opaque definitions prevent excessive unfolding during type checking, giving programmers control over when definitions are expanded. The formalization proves subject reduction, normalization, consistency, and decidability of conversion. Notably, subject reduction fails for certain naive designs — careful treatment of the conversion judgment is required.

**Conversion judgment structure** (6 mutually defined relations):
1. Neutral equality (`Gamma |- a ~ b uparrow A`): type arbitrary
2. Neutral equality in WHNF (`Gamma |- a ~ b downarrow A`): type in weak head normal form
3. Type equality (`Gamma |- A [conv uparrow] B`): reduce then compare
4. Type equality in WHNF (`Gamma |- A [conv downarrow] B`): fully reduced
5. Term equality (`Gamma |- a [conv uparrow] b : A`): reduce then compare
6. Term equality in WHNF (`Gamma |- a [conv downarrow] b : A`): fully reduced

**Opaque definition in conversion**: The `defn-refl` rule checks `alpha mapped-to-opaque : A in Gamma.defs` — opaque definitions are only equal to themselves (not unfolded). This creates a **controlled abstraction barrier**.

**Metatheory proven**: Subject reduction, normalization, consistency, decidability of conversion. Caveat: does not handle mutually recursive definitions.

---

### S7: Effect-TS

- **Project**: Effect — TypeScript effect system library
- **URL**: https://effect.website/
- **GitHub**: https://github.com/Effect-TS/effect (13,800+ stars)
- **Current version**: v3.21.0 (stable), v4 beta (2026-02-18)
- **License**: MIT
- **Organization**: Effectful Technologies Inc.

#### Core Type: Effect<A, E, R>

- **A (Success)**: Return value type
- **E (Error)**: Compile-time tracked failure type (discriminated unions)
- **R (Requirements)**: Required dependency services (union type, covariant)

Design choice: `A` first (not ZIO's `R` first) for TypeScript generic defaults.

#### Key Abstractions

| Abstraction | Purpose |
|-------------|---------|
| Effect | Lazy, immutable program description (smart Promise) |
| Layer | Service constructor with type-safe dependency graph + memoization |
| Fiber | Lightweight virtual thread with structured concurrency |
| Stream | Zero-or-more value emission with backpressure |
| Schema | Bidirectional encode/decode (not parse-only like Zod) |
| Schedule | Declarative retry policies, composable |
| Scope | LIFO resource lifecycle management |

#### Not Algebraic Effects

Effect-TS uses monadic `flatMap` chains, not runtime continuation capture. No `perform/handle/resume`. JavaScript lacks continuation capture primitives. Function coloring problem persists.

#### v4 Beta Changes (2026-02)
- Fiber runtime rewrite: reduced memory overhead
- **71% bundle size reduction**: ~70KB -> ~20KB for minimal program
- Core consolidation: `@effect/platform`, `@effect/rpc`, `@effect/cluster` merged into `effect`
- `effect/unstable/*` namespace for evolving APIs (AI, HTTP, SQL, RPC, CLI, workflows)

#### Criticisms
- Steep learning curve
- Ecosystem friction: Node.js assumes throw/reject, Effect uses Result types
- Hiring difficulty: Engineers who understand Effect + want startup work are rare
- Overkill for simple CRUD / React apps
- Language evolution risk: `using` declarations, pattern matching proposals may reduce Effect's value proposition

---

### S8: TyDe Workshop Series (2016-2025)

- **Official site**: https://tydeworkshop.org/
- **Series page**: https://conf.researchr.org/series/tyde
- **Editions**: 10 (2016-2025), all co-located with ICFP

#### Complete History

| Year | Location | Co-Chairs |
|------|----------|-----------|
| 2016 | Nara, Japan | James Chapman, Wouter Swierstra |
| 2017 | Oxford, UK | Sam Lindley, Brent Yorgey |
| 2018 | St. Louis, USA | Richard Eisenberg, Niki Vazou |
| 2019 | Berlin, Germany | David Darais, Jeremy Gibbons |
| 2020 | Jersey City (virtual) | James McKinna, Cyrus Omar |
| 2021 | Daejeon (virtual) | Josh Ko, Dominic Orchard |
| 2022 | Ljubljana, Slovenia | Nada Amin, Harley Eades III |
| 2023 | Seattle, USA | Youyou Cong, Pierre-Evariste Dagand |
| 2024 | Milan, Italy | Sandra Alves, Jesper Cockx |
| 2025 | Singapore | Andras Kovacs, Yuting Wang |

#### Theme Evolution

- **2016-2018**: Dependent types, generic programming core (Agda/Idris/Haskell focus)
- **2019-2021**: Gradual typing, effect systems, bidirectional inference
- **2022-2023**: Quantum computing types, probabilistic programming, structure editors, refinement types
- **2024-2025**: Program generation (LLM era), prompt programming, industrial applications (Meta, Samsung)

#### Definition of TyDD

TyDe intentionally avoids a formal definition, using the broad framing:

> "how static type information may be used effectively in the development of computer programs"

This encompasses derivation, construction, calculation, analysis, tools, and language design — types as the **driver** of development.

#### Notable Researchers

Recurring PC members: Hongwei Xi (ATS), Niki Vazou (Liquid Haskell), Stephanie Weirich (Haskell dependent types), Neel Krishnaswami (bidirectional typing), Jeremy Gibbons (program calculation), Oleg Kiselyov (staged computation), Daan Leijen (Koka/algebraic effects).

Industrial presence: Jane Street, Microsoft Research, Samsung, Meta, Well-Typed, Channable.

---

## Part II: Theoretical Connections

### Types = Compression Thesis

#### Participant Quotes (S1)

Empirical evidence from 130 TyDD practitioners supporting the "types as logical compression" hypothesis:

| Tag | Quote | Participant | Interpretation |
|-----|-------|------------|----------------|
| D1 | "a mental tool to abstract away complex logic" | P39 | Types compress complex logic |
| D2 | "hold more of the program in your head when you consider just the signatures" | P211 | Signatures as compressed program representations |
| D3 | "cut down the space of possible implementations" | P6 | Constraint compression (fewer candidates = higher compression) |
| D4 | "can almost be derived from the signature" | P4 | Compressed representation sufficient to reconstruct implementation |
| D5 | "types are a good intermediate step between specification and operational code" | P10 | Types as intermediate compression between spec and impl |

Related empirical work:
- Lubin & Chasins (OOPSLA 2021): Exploratory programming uses types as compression tools for unknown domains
- Gamboa et al. (ICSE 2023): Incremental specification building validates S-expression DSL design
- Shi et al. (OOPSLA1 2025): Lean users struggle with minutiae — validates DSL->Lean auto-generation
- Crichton et al. (OOPSLA2 2023): Developers use types without fully understanding underlying semantics — types as lossy compression

#### Compression-Refinement Duality

The Singleton/RunLength pattern from S5 (Idris 2 QTT) encodes the thesis as a type:

`CompressionSpec` with `roundtrip : forall x, expand (compress x) = x`

This is literally our thesis statement expressed as a type — compression indexed by expansion, with a round-trip guarantee.

From the deep-dive analysis:
- Singleton/RunLength pattern: compression indexed by expansion (S5)
- Hybrid Type Checking (Flanagan, POPL 2006), cited in S1: Lean(compile-time) + pytest(runtime) = Hybrid Type Checking implementation
- Gradual Refinement Types (Lehmann & Tanter, POPL 2017), cited in S1: Formal basis for incremental refinement adoption in Phase A-3

#### The {0, 1, omega} Compression Semiring

A unified account of the compression level semiring, synthesizing insights from S5 (QTT), Paper 3 (conatural numbers), Paper 9 (opaque definitions), and the mathematical structures analysis.

**From QTT (S5, Atkey 2018)**: Each variable binding is annotated with a multiplicity from the semiring {0, 1, omega}:
- **0**: Compile-time only, erased at runtime (type-level existence without runtime cost)
- **1**: Used exactly once — linear, deterministic expansion
- **omega**: Unrestricted use

**From conatural numbers (Paper 3)**: The `ConceptDepth` structure in Theory.lean currently uses `Nat` with a sorry'd `finite_depth_from_bound`. Conatural numbers provide the *correct* type for potentially unbounded concept hierarchies: a coinductive type where `infinity` is a legitimate value (representing infinitely deep compression that never terminates expansion). The `depthBound` theorem then becomes: "practical compression is always finite-depth (i.e., a natural number embedded in Conat)."

The conatural numbers' exponential commutative semiring structure provides the algebraic foundation for composing compression levels:
- Compression composition (+) and nesting (*) form a semiring
- Guardedness = productivity, paralleling the pipeline's requirement that expansion always terminates
- Bisimulation as equality could formalize "equivalent compression strategies"

```agda
record Conat : Set where
  coinductive
  field force : Maybe Conat   -- Nothing = zero, Just n = suc n

infinity : Conat
force infinity = Just infinity
```

**Mapping to compression levels**:
- 0 = zero compression (erased/type-level only)
- 1 = single-use compression (linear, deterministic expand)
- omega = unbounded compression depth (conatural infinity)

**From opaque definitions (Paper 9)**: Compression IS opacity. A "high-order term" (compressed concept) is literally an opaque definition — you know its type (the concept it represents) but the body (the expanded low-order concepts) is hidden until you choose to unfold/decompress:
- `compress(concepts) = opaque_term` — create an opaque definition
- `expand(opaque_term) = concepts` — selectively unfold the opaque definition
- The semiring {0, 1, omega} maps to opacity levels: 0 = fully opaque (erased), 1 = unfold exactly once, omega = unfold freely

**Formalizability**: Very high. The compression level semiring is decidable (~20 LOC).

#### NbE = Compress-then-Expand (Paper 2)

NbE's evaluate-then-readback is structurally isomorphic to our compress-then-expand pipeline. The semantic domain in NbE corresponds to the "high-order term" representation; readback corresponds to "decompression/expansion." The 3.4x slowdown from type-direction parallels the cost of maintaining constraint validity during decompression.

Bidirectional check/synth in NbE parallels our TypeSpec.inv checking (check mode) vs FuncSpec type inference (synth mode). The performance trade-off validates our choice to separate Lean (type-directed) from Z3 (syntax-directed).

#### Information-Theoretic Structures (M1-M7)

**M1: Compression-Refinement Duality** — Refinement REDUCES inhabitants (fewer values = more info per value), while compression REDUCES distinctions (many inputs map to one representation). A technical term sits at the MDL optimum: simultaneously a compression (of the concept space) and a refinement (each use carries certified information). The MDL objective `L(T) + L(X|T)` balances these two forces.

**M2: Refinement = index space compression** — `{x : Int | x >= 0}` needs fewer bits to identify a value than `Int`. The predicate itself has information content `log2(|Int| / |{x : Int | x >= 0}|)`.

**M3: Monomorphization = lossy compression (S2)** — Lean-Auto's 4-stage translation loses provability at each stage. VBS solves 41.5% = ~41.5% of "provable information" survives HOL compression. The 22,020 unique solves show that sometimes losing information makes the remaining structure more tractable.

**M4: Singleton information content = 0 bits (S5)** — `Singleton xs` has exactly one inhabitant. `log2(1) = 0` bits. The entire information content has been pushed from value level to type level = extreme compression.

**M5: `?` unknown refinement = maximum entropy (I2)** — Gradual refinement's `?` = no information about the predicate = maximum entropy. Replacing `?` with a concrete predicate = entropy reduction = information addition.

**M6: Kolmogorov complexity and TypeSpec** — TypeSpec's `inv : α → Prop` has Kolmogorov complexity K(inv) = length of the shortest program computing the invariant. A "better" TypeSpec has shorter `inv` constraining more values = MDL principle.

**M7: Information Lattice Learning** — Liu et al. (ISIT 2024, arXiv:2404.03131) formalizes "abstraction as lossy semantic compression" using lattice theory, recovering domain principles from data. The lattice structure parallels TypeSpec's refinement partial order. Not cited by the 8 papers but directly relevant.

### Chapter Mappings (Ch 5.1-5.6)

| Survey Finding | Chapter Connection |
|---|---|
| Refinement types + SMT integration (S4) | Direct parallel to Lean specs -> Z3 SMT pipeline |
| Lean 4 industrial maturity + ACM award (S2) | Validates eDSL migration decision (#21) |
| Lean-Auto monomorphization (S2) | Informs pipeline's SMT codegen pass |
| Lean4Lean self-verification limits (S3) | Parallels our multi-layer verification strategy |
| TyDD real-world adoption gap (S1) | Phase A-3 Python TDD bridges theory-implementation gap |
| QTT resource tracking (S5) | Complementary to probabilistic type system (Ch. 5.1) |
| QTT erasure = type-level vs runtime distinction (S5) | Maps to high-order vs low-order concept distinction |
| Effect-TS typed effects (S7) | Practical validation of effect tracking in industrial TS |
| Type-Driven Prompt Programming (S6) | Direct intersection with "terminology as logical compression" thesis |
| Incremental refinement adoption principle (S4) | Aligns with Phase A-3 incremental TDD strategy |
| Temporal invariants beyond refinement types (S4) | Resonates with dynamic compression theory (Ch. 5.2) |

### Mathematical Structures (F1-F8)

| Tag | Structure | Source | Formalizability | Application |
|-----|-----------|--------|-----------------|-------------|
| F1 | Pipeline as adjoint functor chain | S2+S3 | High (Mathlib GaloisInsertion) | Pipeline correctness |
| F2 | SpecSig lattice (meet/join on pre/post) | S4 | High (~40 LOC) | LLM loop convergence proof |
| F3 | Compression level semiring {0,1,omega} | S5 (Atkey 2018) | Very high (decide) | TypeSpec usage grading |
| F4 | decidableBySMT predicate (EHOP analog) | S2 | Medium (~20 LOC) | Auto-classify specs for SMT vs induction |
| F5 | TypeSpec.toFuncSpec embedding | S3 | Trivial (~10 LOC) | Unified judgment framework |
| F6 | Codec with round-trip proofs | S7 | High (~25 LOC/stage) | Round-trip testing per codegen |
| F7 | Fixed-point iteration on SpecSig lattice | S2+S4 | High (~40 LOC) | LLM loop termination |
| F8 | FiberedTypeSpec (constraint-indexed) | S4 | Medium (~60 LOC) | Scoped specs |

---

## Part III: Pipeline Design

### Design Patterns (B1-B6)

| Tag | Pattern | Source | Priority | Description |
|-----|---------|--------|----------|-------------|
| B1 | TrSpec correspondence predicate | S3 (Lean4Lean `TrExprS`) | Very High | `TrSpec : SExpr -> SpecAST -> Prop` for Python<->Lean formal correspondence |
| B2 | Bidirectional Codec | S7 (Effect-TS Schema) | High | `encode`/`decode` round-trip testing for each codegen stage |
| B3 | Call-site obligation generation | S4 (Liquid Haskell core) | High | Z3 proof obligations for caller-satisfies-callee-precondition |
| B4 | Hoare-style 4-arg post | S4 (State monad) | Medium | `post : State -> Input -> Output -> State -> Prop` with frame conditions |
| B5 | PipelineMethods record | S3 (Lean4Lean Methods) | Medium | Cutpoint function pattern for pipeline stage swappability |
| B6 | Schedule combinators + Fuel | S7 + S3 | Medium | Composable retry with weighted cost budget |

### LLM x Type Integration (C1-C3, H4)

| Tag | Finding | Source | Description |
|-----|---------|--------|-------------|
| C1 | FuncSpec = Prompt Program | S6 (TyDe 2025 Paper 8) | lambda-Prompt `(I,O,P,C)` maps to FuncSpec `(pre,post,instruction,sound)` |
| C2 | Constrained decoding | S6 Paper 7 + Mundler et al. PLDI 2025 | Prefix automaton runs parallel to LLM decoding, masking ill-typed tokens. Compilation errors reduced >50%. Impl: github.com/eth-sri/type-constrained-code-generation |
| C3 | Unification modulo isomorphisms | S6 Paper 5 (IST) | Type-isomorphic implementation search for FuncSpec matching |
| H4 | Typed holes as LLM prompts | S1 x S6 | sorry's goal type -> structured LLM prompt. Compiler verifies output |

The Type-Driven Prompt Programming connection (S6 Paper 8) provides the theoretical basis: the lambda-Prompt calculus `(I, O, P, C)` maps directly to FuncSpec `(pre, post, instruction, sound)`. See Recipe 8 in Part IV for the implementation.

### Cross-Paper Synthesis (H1-H11)

| Tag | Combination | Key Insight |
|-----|-------------|-------------|
| H1 | S5 x S4: Multiplicity-annotated refinement | `pre:0/1/omega` tags determine codegen target (Lean/assert/guard) |
| H2 | S2 x S4: Proof triage via automation failure | `first \| omega \| simp \| auto \| sorry` in specFunc macro |
| H3 | S3 x S7: BiTrSpec (bidirectional translation) | `roundtrip : forall x, backward.f (forward.f x) = x` for abstract/expand |
| H4 | S1 x S6: Typed holes as LLM prompts | sorry's goal type -> structured LLM prompt. Compiler verifies output |
| H5 | S5 x S4: CompressedTerm with scope+roundtrip | Thesis statement as a type: scope-bounded, invertible compression |
| H6 | S3 x S4 x S6: Translation as refinement | `A <=_s B in DSL => lean_gen(A) <=_s lean_gen(B)` functoriality test |
| H7 | S1 x S7: Minimal viable pipeline (3 levels) | L1: DSL->pytest. L2: +Z3. L3: +Lean. verify_level parameter |
| H8 | S5 x S3: Resource-aware compression | `decompression_cost * usage_count <= budget` in MDL scoring |
| H9 | S5 x S3 x S2: isOverthinking as proof budget | Proof search gain < threshold -> stop and mark assumed |
| H10 | S2 x S7: Spec normal forms | Canonicalize semantically equivalent DSL specs |
| H11 | S1 x S4: Spec coding -> implementation order | Validators(6) -> Estimators(5) -> Producers(4) -> Core(1) |

---

## Part IV: Practical Guidance

### Anti-Patterns and Warnings (G1-G6)

| Tag | Warning | Source | Severity | Response |
|-----|---------|--------|----------|----------|
| G1 | smt_gen.py silent false-positive on unparseable predicates | S4 + Paper 4 | **Critical** | Return explicit "unparseable" status; add blame tracking to DSL source location (Paper 4 insight: blame tracking at splice points catches errors early) |
| G2 | Lean-Auto Z3 backend = smart sorry | S2 | High | Use Duper only for production proofs |
| G3 | Over-specification threshold (>5s Z3, >3 lemmas Lean) | S1+S4+S7 | Medium | Apply S4 Principle 4, simplify or assume |
| G4 | sorry accumulation without tracking | S2+S3+S4 | Medium | CI grep for sorry count, threshold=10 |
| G5 | Python Result types vs standard exceptions | S7 | Medium | Use standard raise/except in Phase A-3 |
| G6 | DSL error messages in Lean/Z3 terms | S1 | Medium | Implement error mapping back to DSL |

Paper 4 (Gradual Metaprogramming) deepens the G1 anti-pattern: our pipeline is *exactly* the scenario that paper addresses. Python (dynamically typed metalanguage) generates Lean 4 code (statically typed object language) via `lean_gen.py`. Currently, type errors in the generated Lean code are only caught when `lake build` runs — far from the DSL source. Gradual metaprogramming suggests inserting **cast checks at each pipeline stage boundary**:

1. DSL parse -> AST: Check well-formedness (already done)
2. AST -> Lean codegen: **Insert Z3 pre-checks** that the AST constraints are satisfiable *before* generating Lean
3. AST -> pytest: Check that test inputs satisfy pre-conditions *at generation time*
4. LLM refinement: Each splice of LLM output should be incrementally type-checked

### Lean-Auto Integration (E1-E5)

- **E1 Dependency**: `require auto` @ `v4.29.0-hammer` + `require Duper` @ `v4.29.0` in lakefile.lean
- **E2 Only Duper has proof reconstruction** (Z3/CVC5/Zipperposition = "smart sorry")
- **E3 sorry replacement**: `sound := by auto u[...] d[TypeSpec.rec, FuncSpec.rec]`
- **E4 Theory.lean targets**: `finite_depth_from_bound` and `compression_monotone` likely solvable with Nat lemma hints
- **E5 assume pattern** (S4): Add `assumed: bool` to FuncSpec DSL for sorry/assume management

See Recipes 4-6 below for concrete Lean code.

### Implementation Recipes

#### Recipe 1: Z3 Python API — Refinement Type Predicates (from S4)

Current `smt_gen.py` only handles simple comparison predicates. Extend to handle compound refinement types:

```python
# === Recipe: Compound refinement type encoding ===
import z3

def encode_refinement_type(type_name: str, base_sort: z3.SortRef,
                           predicates: list[str]) -> tuple[z3.ExprRef, list[z3.BoolRef]]:
    """Encode a refinement type {x : base | pred1(x) /\ pred2(x) /\ ...} as Z3 constraints.

    From S4 (Liquid Haskell pattern): refinement types add a subtyping
    layer on top of the base type system. Each predicate becomes a Z3
    constraint on a fresh symbolic variable.
    """
    x = z3.Const(type_name, base_sort)
    constraints = []
    for pred_str in predicates:
        z3_pred = _parse_predicate_to_z3(pred_str, x)
        if z3_pred is not None:
            constraints.append(z3_pred)
        else:
            # CRITICAL (anti-pattern from survey): never silently skip
            raise ValueError(f"Unparseable predicate for {type_name}: {pred_str}")
    return x, constraints


def check_subtype(sub_preds: list[z3.BoolRef], sup_preds: list[z3.BoolRef],
                  x: z3.ExprRef) -> tuple[bool, str | None]:
    """Check {x | sub_preds} <: {x | sup_preds} via Z3.

    From S4 Principle: f ≤ g ⟺ pre_g ⇒ pre_f ∧ post_f ⇒ post_g.
    Encoded as: ∀x. (∧ sub_preds) ⇒ (∧ sup_preds).
    Check negation: ∃x. (∧ sub_preds) ∧ ¬(∧ sup_preds).
    """
    solver = z3.Solver()
    solver.add(*sub_preds)
    if sup_preds:
        solver.add(z3.Not(z3.And(*sup_preds)))
    result = solver.check()
    if result == z3.sat:
        return False, str(solver.model())
    return True, None
```

#### Recipe 2: Z3 Array Theory for Finite Maps (from S4)

S4 required custom finite maps theory for Liquid Haskell. Z3's Array theory handles this natively:

```python
# === Recipe: Finite map encoding for scoped specs ===
import z3

def encode_scope_map() -> tuple[z3.ArrayRef, z3.SortRef, z3.SortRef]:
    """Encode a scope map (variable -> type) as a Z3 Array.

    From S4: Scoped specs require tracking which variables are in scope.
    The ScopedExp pattern: {e : Exp | isSubsetOf (freeVars e) S}.
    """
    VarId = z3.IntSort()
    InScope = z3.BoolSort()
    scope = z3.Array("scope", VarId, InScope)
    return scope, VarId, InScope


def check_scoped_constraint(scope: z3.ArrayRef, var_id: z3.ArithRef,
                            must_be_in_scope: bool = True) -> z3.BoolRef:
    """Assert that a variable is (or is not) in scope.

    Pattern from S4 invariant 5: initial scope must contain free variables.
    """
    if must_be_in_scope:
        return z3.Select(scope, var_id) == True  # noqa: E712
    return z3.Select(scope, var_id) == False  # noqa: E712
```

#### Recipe 3: Z3 Unsat Core for Error Diagnostics (from S4)

```python
# === Recipe: Unsat core extraction for spec debugging ===
import z3

def check_with_diagnostics(constraints: dict[str, z3.BoolRef]) -> tuple[bool, list[str]]:
    """Check satisfiability with named constraints for unsat core extraction.

    From S4: SMT error messages are less intuitive than type checker errors.
    Solution: name each constraint, extract unsat core, map back to DSL source.

    Args:
        constraints: Map from human-readable name to Z3 constraint.

    Returns:
        (satisfiable, unsat_core_names) — if unsat, which constraints conflict.
    """
    solver = z3.Solver()
    # Track each constraint with a boolean indicator
    indicators = {}
    for name, constraint in constraints.items():
        ind = z3.Bool(f"track_{name}")
        indicators[name] = ind
        solver.add(z3.Implies(ind, constraint))

    # Check with all indicators enabled
    result = solver.check(*indicators.values())
    if result == z3.sat:
        return True, []

    # Extract unsat core — minimal conflicting subset
    core = solver.unsat_core()
    core_names = []
    for name, ind in indicators.items():
        if ind in core:
            core_names.append(name)
    return False, core_names


# Usage with spec predicates:
def diagnose_spec_constraints(spec_name: str, predicates: list[tuple[str, str]]) -> str:
    """Diagnose which spec predicates are mutually unsatisfiable.

    Example: type ValidationScore has (>= 0) and (<= 1) and (> 2)
    -> unsat core: ["ValidationScore.(>= 0)", "ValidationScore.(> 2)"]
    -> "Conflicting constraints in ValidationScore: (>= 0) conflicts with (> 2)"
    """
    x = z3.Int("x")
    named_constraints = {}
    for i, (pred_str, source_loc) in enumerate(predicates):
        z3_expr = _parse_predicate_to_z3(pred_str, x)
        if z3_expr is not None:
            named_constraints[f"{spec_name}.{pred_str} [{source_loc}]"] = z3_expr

    sat, core = check_with_diagnostics(named_constraints)
    if sat:
        return f"{spec_name}: all constraints satisfiable"
    return f"Conflicting constraints in {spec_name}: {', '.join(core)}"
```

#### Recipe 4: Lean 4 VBS Tactic Pattern (from S2)

```lean
-- === Recipe: Virtual Best Solver tactic chain ===
-- From S2 (Lean-Auto): the `first` combinator tries tactics in order.
-- Measure auto-prove rate to track sorry elimination progress.

-- Basic VBS pattern for specFunc sound proofs:
macro "specProve" : tactic =>
  `(tactic| first
    | omega                          -- linear arithmetic (fast, Nat/Int)
    | simp [TypeSpec, FuncSpec]      -- simplification with spec unfolding
    | decide                         -- decidable propositions
    | exact fun x h => h             -- identity refinement (refines_refl)
    | sorry)                         -- fallback: deferred to formal-derivation

-- Usage in specFunc macro (replace `by sorry` with `by specProve`):
-- specFunc transfer UserId_TypeSpec Amount_TypeSpec
--   | fun x => default | fun x => x > 0 | fun x y => True

-- === With lean-auto integration (when available) ===
-- Requires: `require auto from git "..." @ "v4.29.0-hammer"`
--           `require Duper from git "..." @ "v4.29.0"`
-- macro "specProveAuto" : tactic =>
--   `(tactic| first
--     | omega
--     | simp [TypeSpec, FuncSpec]
--     | decide
--     | auto u[Nat.le_refl, Nat.le_trans] d[TypeSpec.rec, FuncSpec.rec]
--     | sorry)
```

#### Recipe 5: Lean-Auto lakefile Configuration (from S2)

```lean
-- === Recipe: lakefile.lean with lean-auto + Duper ===
-- From S2: Only Duper has proof reconstruction.
-- Z3/CVC5 backends = "smart sorry" (trusted, not kernel-verified).

import Lake
open Lake DSL

package «spec-system» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

require LSpec from git
  "https://github.com/lurk-lab/LSpec.git" @ "main"

-- lean-auto: ATP interface for Lean 4
-- Pin to matching toolchain version
require auto from git
  "https://github.com/leanprover-community/lean-auto.git" @ "v4.29.0-hammer"

-- Duper: superposition prover with proof reconstruction
-- This is the ONLY backend that produces kernel-verified proofs
require Duper from git
  "https://github.com/leanprover-community/duper.git" @ "v4.29.0"

@[default_target]
lean_lib «SpecSystem» where
  roots := #[`SpecSystem]

lean_lib «SpecTest» where
  roots := #[`SpecTest]
```

#### Recipe 6: `@[rebind]` Attribute for Duper Integration (from S2)

```lean
-- === Recipe: Rebind native prover to use Duper ===
-- From S2: lean-auto uses @[rebind] to swap ATP backends.
-- Duper is the only proof-producing backend.

-- In a file that needs auto-proved theorems:
import Auto
import Duper

-- The @[rebind] attribute tells lean-auto to use Duper
-- instead of the default prover for proof reconstruction.
-- This ensures all `auto` calls produce kernel-verified proofs.

-- Example: proving sorry'd theorems from Theory.lean
theorem finite_depth_from_bound' (cd : ConceptDepth) (h : depthBound cd) :
    cd.depth ≤ cd.totalComplexity := by
  -- auto with Nat lemma hints
  auto u[Nat.pow_le_pow_left, Nat.le_of_pow_le_pow_left] d[depthBound, ConceptDepth.rec]

theorem compression_monotone' (n₁ n₂ : Nat) (cInf beta : Nat) (h : n₁ ≤ n₂) :
    compressionCapacity n₁ cInf beta ≤ compressionCapacity n₂ cInf beta := by
  -- min monotonicity is a standard Nat lemma
  auto u[Nat.min_le_min_right, Nat.mul_le_mul_right] d[compressionCapacity]
```

#### Recipe 7: pytest Generation from Refinement Types (from S1, S4)

```python
# === Recipe: Property-based testing from type specs ===
# From S1: TyDD generates tests from types. S4: refinement types drive test generation.
# Integrate with hypothesis for property-based testing.

from hypothesis import given, strategies as st

def gen_hypothesis_strategy(type_name: str, base_type: str,
                            predicates: list[str]) -> str:
    """Generate a Hypothesis strategy from a TypeSpec.

    From S4 Principle 4: Start with best power-to-weight ratio functions.
    From S1: Type-driven test generation is a key benefit of TyDD.

    Example: (type ValidationScore Int (>= 0) (<= 1))
    -> st.integers(min_value=0, max_value=1)
    """
    if base_type == "Int":
        min_val, max_val = None, None
        for pred in predicates:
            pred = pred.strip("()")
            parts = pred.split()
            if len(parts) >= 2:
                op, *args = parts
                val = next((int(a) for a in args if a.lstrip("-").isdigit()), None)
                if val is not None:
                    if op in (">=", "≥"):
                        min_val = val
                    elif op in (">",):
                        min_val = val + 1
                    elif op in ("<=", "≤"):
                        max_val = val
                    elif op in ("<",):
                        max_val = val - 1
        kwargs = []
        if min_val is not None:
            kwargs.append(f"min_value={min_val}")
        if max_val is not None:
            kwargs.append(f"max_value={max_val}")
        return f"st.integers({', '.join(kwargs)})"
    return f"st.from_type({base_type})"


def gen_property_test(func_name: str, inputs: list[dict], output_type: str,
                      pre_conditions: list[str], post_conditions: list[str]) -> str:
    """Generate a property-based test from FuncSpec.

    Pattern: @given(inputs) -> assume(pre) -> call -> assert(post)
    From S4: Call-site obligation = caller satisfies callee precondition.
    """
    lines = [
        "from hypothesis import given, assume, strategies as st",
        "",
        "",
        f"@given({', '.join(f'{inp[\"name\"]}=st.integers()' for inp in inputs)})",
        f"def test_{func_name}_property({', '.join(inp['name'] + ': int' for inp in inputs)}) -> None:",
        f'    """Property-based test for {func_name} from FuncSpec."""',
    ]

    # Filter inputs by precondition
    for pre in pre_conditions:
        lines.append(f"    assume({_pred_to_python(pre)})")

    # Call function
    args = ", ".join(inp["name"] for inp in inputs)
    lines.append(f"    result = {func_name}({args})")

    # Assert postconditions
    for post in post_conditions:
        lines.append(f"    assert {_pred_to_python(post, var='result')}")

    return "\n".join(lines)


def _pred_to_python(pred_str: str, var: str = "x") -> str:
    """Convert S-expression predicate to Python boolean expression.

    (>= x 0) -> x >= 0
    (>= result 0) -> result >= 0
    """
    pred = pred_str.strip("()")
    parts = pred.split()
    if len(parts) < 2:
        return "True"
    op = parts[0]
    py_ops = {">": ">", ">=": ">=", "<": "<", "<=": "<=", "=": "==", "!=": "!="}
    if op in py_ops:
        lhs = parts[1] if len(parts) > 2 else var
        rhs = parts[2] if len(parts) > 2 else parts[1]
        if lhs == "result":
            lhs = var
        return f"{lhs} {py_ops[op]} {rhs}"
    return "True"
```

#### Recipe 8: LLM Prompt from Type Signatures (from S6 Paper 8, S4)

```python
# === Recipe: Type-driven prompt construction ===
# From S6 Paper 8: FuncSpec = Prompt Program. (I,O,P,C) maps to (pre,post,instruction,sound).
# From S4: Properties easier when assumptions explicit.

def funcspec_to_prompt(func_name: str, input_types: list[dict],
                       output_type: str, pre_conditions: list[str],
                       post_conditions: list[str]) -> str:
    """Convert a FuncSpec to a structured LLM prompt.

    From TyDe 2025 Paper 8 (Type-Driven Prompt Programming):
    lambda-Prompt (I, O, P, C) where:
      I = input type (from TypeSpec)
      O = output type (from TypeSpec)
      P = prompt/instruction (from FuncSpec name + description)
      C = constraints (from pre/post conditions)

    From H4 (S1 x S6 synthesis): sorry's goal type -> structured LLM prompt.
    """
    sections = []

    # Section 1: Function signature as type constraint
    input_sig = ", ".join(f"{inp['name']}: {inp['type']}" for inp in input_types)
    sections.append(f"Implement the function `{func_name}({input_sig}) -> {output_type}`.")

    # Section 2: Preconditions as input constraints
    if pre_conditions:
        sections.append("\nInput constraints (preconditions):")
        for pre in pre_conditions:
            sections.append(f"  - {pre}")

    # Section 3: Postconditions as output guarantees
    if post_conditions:
        sections.append("\nOutput guarantees (postconditions):")
        for post in post_conditions:
            sections.append(f"  - {post}")

    # Section 4: Soundness requirement
    sections.append(
        "\nThe implementation MUST satisfy: for all inputs meeting the preconditions, "
        "the output must satisfy all postconditions."
    )

    # Section 5: Verification hint
    sections.append(
        "\nThe implementation will be verified by:"
        "\n  1. Z3 SMT solver (constraint satisfiability)"
        "\n  2. pytest (property-based testing with Hypothesis)"
        "\n  3. Lean 4 proof checker (soundness proof)"
    )

    return "\n".join(sections)


def sorry_goal_to_prompt(goal_type: str, context: list[str]) -> str:
    """Convert a Lean 4 sorry goal to an LLM prompt for proof search.

    From H4 (Typed Holes as LLM Prompts): the sorry's goal type IS
    the prompt specification. The Lean compiler verifies the output.

    Args:
        goal_type: The Lean type to prove (e.g., "cd.depth ≤ cd.totalComplexity")
        context: Hypotheses in scope (e.g., ["h : depthBound cd"])
    """
    lines = [
        "Provide a Lean 4 tactic proof for the following goal.",
        "",
        f"Goal: {goal_type}",
        "",
        "Hypotheses:",
    ]
    for hyp in context:
        lines.append(f"  {hyp}")
    lines.append("")
    lines.append("Use only: omega, simp, exact, apply, intro, cases, induction.")
    lines.append("Do NOT use sorry. The proof will be verified by the Lean kernel.")
    return "\n".join(lines)
```

#### Recipe 9: Gradual Pipeline Stage Checking (from Paper 4, S4)

```python
# === Recipe: Gradual type checking at pipeline stage boundaries ===
# From Paper 4 (Gradual Metaprogramming): insert casts at splice points.
# Our pipeline: Python (meta) generates Lean (object) via lean_gen.py.

from dataclasses import dataclass
from enum import Enum


class StageCheckResult(Enum):
    """Result of a stage boundary check."""
    PASS = "pass"
    CAST_WARNING = "cast_warning"  # Gradual: unknown predicate, proceed with warning
    FAIL = "fail"


@dataclass(frozen=True)
class BlameInfo:
    """Source location for error blame tracking.

    From Paper 4: when metaevaluation fails, report the source location
    in the metalanguage (DSL .spec file) that caused the error.
    """
    spec_file: str
    line: int
    column: int
    predicate: str
    stage: str  # "dsl_parse", "ast_build", "lean_gen", "smt_check", "test_gen"


def check_stage_boundary(
    source_predicates: list[tuple[str, BlameInfo]],
    target_stage: str,
) -> list[tuple[StageCheckResult, BlameInfo, str]]:
    """Check predicates at a pipeline stage boundary.

    Gradual metaprogramming principle: check what you can at each stage.
    If a predicate is unparseable for the target stage, emit a CAST_WARNING
    (not a silent skip — the critical anti-pattern from the survey).

    Args:
        source_predicates: List of (predicate_string, blame_info) from DSL.
        target_stage: Which pipeline stage we're entering.

    Returns:
        List of (result, blame, message) for each predicate.
    """
    results = []
    for pred_str, blame in source_predicates:
        if target_stage == "smt_check":
            # Try to parse as Z3
            x = z3.Int("x")
            z3_expr = _parse_predicate_to_z3(pred_str, x)
            if z3_expr is None:
                results.append((
                    StageCheckResult.CAST_WARNING,
                    blame,
                    f"Predicate '{pred_str}' unparseable for Z3 at "
                    f"{blame.spec_file}:{blame.line} — deferring to Lean"
                ))
            else:
                results.append((StageCheckResult.PASS, blame, ""))
        elif target_stage == "lean_gen":
            # Try to parse as Lean Prop
            lean_expr = _pred_to_lean(pred_str)
            if lean_expr is None:
                results.append((
                    StageCheckResult.CAST_WARNING,
                    blame,
                    f"Predicate '{pred_str}' unparseable for Lean at "
                    f"{blame.spec_file}:{blame.line} — deferring to pytest"
                ))
            else:
                results.append((StageCheckResult.PASS, blame, ""))
    return results
```

#### Recipe 10: Opaque TypeSpec for Abstraction Barriers (from Paper 9)

```lean
-- === Recipe: Opaque TypeSpec for controlled unfolding ===
-- From Paper 9: opaque definitions prevent excessive unfolding.
-- Apply to TypeSpec invariants that should not be unfolded during proof search.

-- Mark TypeSpec invariants as opaque when they are complex
-- and should be treated as abstract predicates:
opaque complexInvariant (x : Nat) : Prop :=
  x > 0 ∧ x < 1000 ∧ x % 2 = 0

def ComplexType_TypeSpec : TypeSpec where
  α := Nat
  inv := complexInvariant

-- The type checker cannot unfold complexInvariant, so proofs
-- must use lemmas about it rather than brute-force simplification.
-- This controls proof search complexity (parallels S2 performance finding).

-- Provide controlled unfolding lemmas:
theorem complexInvariant_pos (x : Nat) (h : complexInvariant x) : x > 0 := by
  unfold complexInvariant at h
  exact h.1

theorem complexInvariant_bounded (x : Nat) (h : complexInvariant x) : x < 1000 := by
  unfold complexInvariant at h
  exact h.2.1

-- === Pattern: sorry isolation via opaque ===
-- When a specFunc has sorry in its sound proof, mark the FuncSpec opaque
-- to prevent the sorry from leaking into downstream proofs.

opaque unverified_transfer : FuncSpec UserId_TypeSpec Amount_TypeSpec := {
  f := fun x => default
  pre := fun x => x > 0
  post := fun x y => True
  sound := by sorry
}

-- Downstream code can use unverified_transfer's type (FuncSpec UserId Amount)
-- but cannot unfold it to extract the sorry.
-- This is the type-theoretic analog of "trusted but unverified module."
```

#### Recipe 11: Bidirectional Codec Round-Trip Testing (from S3, S7)

```python
# === Recipe: Round-trip testing for each codegen stage ===
# From S3 (Lean4Lean TrExpr): correspondence predicate between representations.
# From S7 (Effect-TS Schema): bidirectional encode/decode round-trip.

def test_dsl_to_ast_roundtrip(spec_text: str) -> None:
    """Test: parse(pretty_print(parse(spec_text))) == parse(spec_text).

    From H3 (BiTrSpec): roundtrip : forall x, backward.f (forward.f x) = x.
    """
    from pipeline.dsl.parser import parse_sexpr, parse_spec

    # Forward: DSL text -> AST
    sexpr = parse_sexpr(spec_text)
    ast = parse_spec(sexpr)

    # Backward: AST -> DSL text (pretty print)
    regenerated = ast.to_sexpr()  # Requires implementing to_sexpr()

    # Round-trip: regenerated text -> AST again
    sexpr2 = parse_sexpr(regenerated)
    ast2 = parse_spec(sexpr2)

    # Structural equality
    assert ast == ast2, f"Round-trip failed: {ast} != {ast2}"


def test_ast_to_lean_parseable(spec_ast) -> None:
    """Test: lean_gen output is valid Lean syntax.

    From H6 (Translation as refinement): codegen must preserve spec ordering.
    A ≤ B in DSL => lean_gen(A) ≤ lean_gen(B) in Lean.
    """
    from pipeline.codegen.lean_gen import generate_lean
    import subprocess

    lean_code = generate_lean(spec_ast)

    # Write to temp file and check with Lean
    with open("/tmp/test_spec.lean", "w") as f:
        f.write("import SpecSystem.Basic\n\n")
        f.write(lean_code)

    result = subprocess.run(
        ["lake", "env", "lean", "/tmp/test_spec.lean"],
        capture_output=True, text=True, cwd="lean/"
    )
    assert result.returncode == 0, f"Generated Lean failed to typecheck:\n{result.stderr}"
```

#### Recipe 12: Assumed Spec Tracking (from S2, S4)

```python
# === Recipe: Track sorry/assume across the pipeline ===
# From S4 Principle 1: When easier to prove by hand, use assume.
# From S2: sorry accumulation without tracking is a medium-severity anti-pattern.

from dataclasses import dataclass, field


@dataclass
class AssumptionTracker:
    """Track assumed (sorry'd) obligations across the pipeline.

    CI threshold: max 10 sorry's (from survey anti-pattern analysis).
    """
    assumptions: list[dict] = field(default_factory=list)
    max_allowed: int = 10

    def add_assumption(self, name: str, goal: str, source: str, reason: str) -> None:
        self.assumptions.append({
            "name": name,
            "goal": goal,
            "source": source,
            "reason": reason,
        })

    def check_threshold(self) -> tuple[bool, str]:
        count = len(self.assumptions)
        if count > self.max_allowed:
            return False, (
                f"Sorry count ({count}) exceeds threshold ({self.max_allowed}). "
                f"Unresolved: {[a['name'] for a in self.assumptions]}"
            )
        return True, f"Sorry count: {count}/{self.max_allowed}"

    def report(self) -> str:
        lines = [f"# Assumption Report ({len(self.assumptions)} total)"]
        for a in self.assumptions:
            lines.append(f"- **{a['name']}** ({a['source']}): {a['goal']}")
            lines.append(f"  Reason: {a['reason']}")
        ok, msg = self.check_threshold()
        lines.append(f"\n{'PASS' if ok else 'FAIL'}: {msg}")
        return "\n".join(lines)
```

---

## Part V: Strategic Implications

### Limitations to Opportunities (L1-L11)

| Tag | Limitation | Source | Opportunity |
|-----|-----------|--------|-------------|
| L1 | Lean-Auto proof reconstruction only for Duper | S2 | Use Duper exclusively; Z3/CVC5 for exploration only |
| L2 | Lean-Auto no premise selection | S2 | Manual hint lists (`u[...]`, `d[...]`) until premise selection lands |
| L3 | Lean4Lean open conjectures (unique typing, definitional inversion) | S3 | Our specs are simpler than full Lean; may not encounter these |
| L4 | 18 Liquid Haskell bugs + 1 Z3 bug | S4 | Validates our Lean-first approach over Liquid Haskell |
| L5 | No quantity polymorphism in QTT | S5 | Fixed compression levels {0,1,omega} suffice for our use case |
| L6 | Effect-TS steep learning curve | S7 | Validates our Python-first strategy for Phase A-3 |
| L7 | NbE type-directed 3.4x slowdown | Paper 2 | Separate Lean (type-directed, correctness) from Z3 (syntax-directed, speed) |
| L8 | Conatural guardedness checker limitations | Paper 3 | Use Nat with bounds for practical specs; Conat for theoretical depth |
| L9 | Gradual metaprogramming no mutual recursion | Paper 4 | Our pipeline stages are sequential, not mutually recursive |
| L10 | Opaque definitions no mutual recursion | Paper 9 | TypeSpecs are independent; no mutual recursion needed |
| L11 | TyDD adoption gap (usability vs usefulness) | S1 | Phase A-3 auto-generated tests lower the usability barrier |

### Second-Order Citations (I1-I7)

| Tag | Paper | Mechanism | Pipeline Application |
|-----|-------|-----------|---------------------|
| I1 | Flanagan 2006 (Hybrid TC) | Static -> runtime cast fallback | 3-layer: Lean kernel -> Z3 -> pytest |
| I2 | Lehmann-Tanter 2017 (Gradual Refinement) | `?` unknown refinement + gradual guarantee | DSL `?` placeholder, incremental spec |
| I3 | Vazou et al. 2018 (Liquid Inference) | Qualifier-based refinement inference | Auto-suggest DSL predicates from qualifier set |
| I4 | Atkey 2018 (QTT Semantics) | Quantitative CwF | Formal semantics for compression levels |
| I5 | Mundler et al. 2025 (PLDI, Constrained Decoding) | Prefix automaton for LLM | DSL grammar automaton for refine_loop |
| I6 | Clune et al. 2024 (Duper) | Superposition calculus for Lean 4 | sorry elimination for first-order FuncSpec goals |
| I7 | Maclaurin 2022 (Foil) | Phantom-type scope safety | Scope-indexed AST for well-scoped FuncSpec |

### Phase A-3 Implementation Order

From H11 (S1 x S4 synthesis) and J1 (S1 methodology transfer): code 18 FuncDecls and derive implementation order.

Recommended order: Validators(6) -> Estimators(5) -> Producers(4) -> Core(1).

From S4 Principle 4 (incremental adoption): start with functions having best power-to-weight ratio. From S4 (canonical hard problem progression): Simple -> Hybrid -> Full for Phase A-3.

### Methodology Transfer (J1-J7)

| Tag | Method | Source | Application |
|-----|--------|--------|-------------|
| J1 | Descriptive coding of specs | S1 | Code 18 FuncDecls -> derive implementation order |
| J2 | VBS tactic benchmarking | S2 | `first \| omega \| simp \| auto \| sorry` + measure auto-prove rate |
| J3 | Two-layer reimplementation | S3 | Lean 4 reimplementation of lean_gen.py for verification |
| J4 | Canonical hard problem progression | S4 | Simple -> Hybrid -> Full for Phase A-3 |
| J5 | Self-hosting recursion | S5 | Spec the codegen itself: pipeline tests pipeline |
| J6 | Pearl-structured presentation | S6 | 3 executable pearls for paper chapters |
| J7 | Work within constraints | S7 | No DSL extensions; encode via naming conventions |

---

## Appendix: Tag Index

| Tag | Name | Part | Section |
|-----|------|------|---------|
| B1 | TrSpec correspondence predicate | III | Design Patterns |
| B2 | Bidirectional Codec | III | Design Patterns |
| B3 | Call-site obligation generation | III | Design Patterns |
| B4 | Hoare-style 4-arg post | III | Design Patterns |
| B5 | PipelineMethods record | III | Design Patterns |
| B6 | Schedule combinators + Fuel | III | Design Patterns |
| C1 | FuncSpec = Prompt Program | III | LLM x Type Integration |
| C2 | Constrained decoding | III | LLM x Type Integration |
| C3 | Unification modulo isomorphisms | III | LLM x Type Integration |
| D1-D5 | Participant quotes (Types = Compression) | II | Types = Compression Thesis |
| E1-E5 | Lean-Auto practical integration | IV | Lean-Auto Integration |
| F1-F8 | Mathematical structures | II | Mathematical Structures |
| G1-G6 | Anti-patterns and warnings | IV | Anti-Patterns and Warnings |
| H1-H11 | Cross-paper synthesis | III | Cross-Paper Synthesis |
| I1-I7 | Second-order citations | V | Second-Order Citations |
| J1-J7 | Methodology transfer | V | Methodology Transfer |
| L1-L11 | Limitations to opportunities | V | Limitations to Opportunities |
| M1-M7 | Information-theoretic structures | II | Types = Compression Thesis |
| N1-N4 | TyDe 2025 paper deep dives | I | S6 (integrated) |
| S1-S8 | Source summaries | I | Source Summaries |
