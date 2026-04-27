import Lean

/-! # CriticalPatterns — Hook ↔ Lean sync (PI-10、Day 153)

`.claude/hooks/p2-verify-on-commit.sh` の CRITICAL_PATTERNS regex と
Lean 側 `criticalPatterns` を二重宣言。cycle-check Check 24 が両者の
文字列一致を byte-check で強制し、hook と Lean spec の drift を構造的に防ぐ。

DesignFoundation.lean の VerificationIndependence / requiredConditions theorem が
realize されているかを構造で保証する meta-meta 層 (PI-10 design rationale)。

## 同期対象 path

`.claude/hooks/p2-verify-on-commit.sh` L57:
```
CRITICAL_PATTERNS='\.claude/hooks/|\.claude/settings\.json|\.claude/settings\.local\.json'
```

Lean 側 `criticalPatterns` (本 file) と完全一致必須。
変更時は hook と Lean を同 commit で更新、cycle-check Check 24 で violation 検出。
-/

namespace AgentSpec.Tooling

/-- Critical file path patterns (regex syntax)。
    `.claude/hooks/p2-verify-on-commit.sh` の CRITICAL_PATTERNS と完全一致必須。
    変更時は hook script と本 def を同 commit で更新する。
    cycle-check.sh Check 24 が両者の byte 一致を verify。 -/
def criticalPatterns : String :=
  "\\.claude/hooks/|\\.claude/settings\\.json|\\.claude/settings\\.local\\.json"

end AgentSpec.Tooling
