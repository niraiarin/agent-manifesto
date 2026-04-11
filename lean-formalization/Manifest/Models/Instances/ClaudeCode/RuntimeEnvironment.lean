import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions

/-!
# Claude Code Conditional Axiom System - Runtime Environment and Dependencies

macOS/POSIX 互換性、外部ツール前提条件を条件付き公理として構造化する。

## 反証トリガー

OS 変更（macOS → Linux CI 移行等）、外部ツールのバージョン変更時に
このファイル全体が再検証対象となる。

## 設計方針

- 手書き
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- 外部ツール依存の型定義
-- ============================================================

/-- 外部ツールの依存分類。 -/
inductive ToolDependency where
  | required      -- 不在時にツール/スクリプトが機能しない
  | optional      -- 不在時にフォールバックあり
  | undocumented  -- 必要だが CLAUDE.md 未記載
  deriving BEq, Repr

/-- POSIX 互換性のレベル。 -/
inductive PosixCompat where
  | posixStandard  -- POSIX 標準、全 OS で同一
  | bsdExtension   -- macOS BSD 固有（-i '', tail -r 等）
  | gnuExtension   -- Linux GNU 固有（sed -i, tac 等）
  deriving BEq, Repr

-- ============================================================
-- RE1: 外部ツール依存の分類
-- ============================================================

/-- 外部ツールと依存分類のマッピング。CC-H31, CC-H32 に基づく。 -/
inductive ExternalTool where
  | jq       -- JSON 処理。全 hook が依存
  | elan     -- Lean ツールチェーン管理
  | gh       -- GitHub CLI
  | python3  -- h5-doc-lint.sh が依存
  | yq       -- YAML 処理。command -v チェックあり
  | bc       -- 数値計算。sync-counts.sh が依存
  deriving BEq, Repr

/-- ツールの依存分類。 -/
def toolDependencyClass : ExternalTool → ToolDependency
  | .jq      => .required      -- 15/18 hook が使用、ガードなし
  | .elan    => .required      -- Lean ビルドに必須
  | .gh      => .required      -- GitHub 操作に必須
  | .python3 => .undocumented  -- hook が使用するが CLAUDE.md 未記載
  | .yq      => .optional      -- command -v チェックあり
  | .bc      => .required      -- sync-counts.sh 圧縮比計算

/-- ツールが不在時に silent failure を起こすか。 -/
def causesSilentFailure : ExternalTool → Bool
  | .jq      => true   -- hook が exit 非0 で終了するが exit 2 ではない
  | .python3 => true   -- h5-doc-lint.sh が失敗するが非ブロック
  | .elan    => false   -- lake build が明示的に失敗
  | .gh      => false   -- gh コマンドが明示的に失敗
  | .yq      => false   -- command -v チェックで事前検出
  | .bc      => false   -- shell エラーで明示的に失敗

/-- [Derivation Card]
    Derives from: D1 (enforcement layering), CC-H31, CC-H32
    Proposition: RE1
    Content: jq and python3 cause silent failure when absent.
      This undermines D1 structural enforcement: hooks fail without blocking.
      The fix is to add command -v guards (like yq already has).
    Proof strategy: constructor with rfl -/
theorem re1_silent_failure_tools :
  causesSilentFailure .jq = true ∧
  causesSilentFailure .python3 = true ∧
  causesSilentFailure .yq = false := by
  exact ⟨rfl, rfl, rfl⟩

-- ============================================================
-- RE2: POSIX 互換性パターン
-- ============================================================

/-- macOS で代替が必要なコマンドパターン。CC-H30 に基づく。 -/
inductive MacOSWorkaround where
  | sedInPlace    -- sed -i '' (BSD) vs sed -i (GNU)
  | tacReverse    -- tail -r (macOS) vs tac (GNU)
  | wcTrim        -- wc -l | tr -d ' ' (macOS 前置スペース)
  | grepNoPerl    -- grep -oP 不可、POSIX 代替必要
  deriving BEq, Repr

/-- 全ての macOS workaround は POSIX 代替で解決可能か。 -/
def hasPosixAlternative : MacOSWorkaround → Bool
  | .sedInPlace => true   -- sed -i '' は POSIX 非標準だが両 OS で動く回避策あり
  | .tacReverse => true   -- tac || tail -r パターン
  | .wcTrim     => true   -- tr -d ' ' で正規化
  | .grepNoPerl => true   -- POSIX ERE で代替

/-- [Derivation Card]
    Derives from: CC-H30
    Proposition: RE2
    Content: All macOS-specific workarounds have POSIX alternatives.
      This means CI/CD (Linux) migration is feasible without rewriting.
    Proof strategy: intro + cases -/
theorem re2_all_have_alternatives :
  ∀ (w : MacOSWorkaround), hasPosixAlternative w = true := by
  intro w; cases w <;> rfl

end Manifest.Models.Instances.ClaudeCode
