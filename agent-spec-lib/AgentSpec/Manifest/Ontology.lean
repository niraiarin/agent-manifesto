/-! # AgentSpec.Manifest.Ontology (Week 3 Day 74、Manifest 移植 PoC)

新基盤 Manifest 移植 Phase 1 (T1 stand-alone reproduction)。
GA-I7 (b) 再定義方針: lean-formalization/Manifest/Ontology.lean を
AgentSpec.Manifest namespace で再定義 (Lake cross-project require は避ける)。

## Day 74 PoC scope

T1 (session_bounded) に必要な最小 dependency のみ:
- `AgentId` / `SessionId` opaque
- `SessionStatus` inductive
- `Time` abbrev
- `Session` structure
- `World` structure (sessions + time のみ)

## 後続 Day で additive 拡張予定

- Day 75-76: T1 残 axiom (no_cross_session_memory + session_no_shared_state) →
  `AuditEntry` / `Action` / `canTransition` opaque 追加
- Day 77+: T2 (structure_persists / structure_accumulates) →
  `Structure` / `StructureKind` / `Epoch` 追加
- Week 3-4: T3-T8 + P1-P6 順次

## 設計根拠

`docs/research/new-foundation-survey/00-synthesis.md` §4.1 + 制約 C1
(T₀ 無矛盾性継承)、`10-gap-analysis.md` GA-I7 (b) 再定義方針。
既存 Manifest 55 axioms を 7 週で移植、本 Day 74 PoC は path 確立。
-/

namespace AgentSpec.Manifest

/-- Agent identifier (opaque per T1: agent identity is irrelevant to type-level
    reasoning about session boundedness). -/
opaque AgentId : Type

instance : Repr AgentId := ⟨fun _ _ => "«AgentId»"⟩

/-- Session identifier (opaque per T1). -/
opaque SessionId : Type

instance : Repr SessionId := ⟨fun _ _ => "«SessionId»"⟩

/-- Logical clock for state ordering (Lamport-style monotonic). -/
abbrev Time : Type := Nat

/-- Session status. By T1, sessions must reach `terminated` in finite time. -/
inductive SessionStatus where
  | active
  | terminated
  deriving BEq, Repr

/-- Session: ephemeral instance with finite lifetime (T1 grounding).

    Identical to lean-formalization/Manifest/Ontology.lean Session structure,
    re-defined here per GA-I7 (b). -/
structure Session where
  id     : SessionId
  agent  : AgentId
  start  : Time
  status : SessionStatus
  deriving Repr

/-- World skeleton (Day 74 PoC、minimum for T1 session_bounded only).

    既存 Manifest の World は 7 fields (structures / sessions / allocations /
    feedbacks / auditLog / epoch / time) だが、Day 74 PoC では sessions + time
    のみで session_bounded axiom 表現に十分。Day 75+ で additive 拡張予定. -/
structure World where
  sessions : List Session
  time     : Time
  deriving Repr

instance : Inhabited World := ⟨⟨[], 0⟩⟩

end AgentSpec.Manifest
