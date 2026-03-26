import Manifest.EpistemicLayer

/-!
# 認識論的層モデルの仮定（Assumptions）

このファイルは、認識論的層モデルのインスタンシエーションにおいて
人間の設計判断 (C) と LLM の推論 (H) から構成される仮定を蓄積する。

## 認識論的出自 (Epistemic Source)

全ての仮定に出自ラベルを付与する:
- **C (Human Decision)**: Phase 1 の対話で人間が判断したもの。T6 の権威に基づく。
  覆すには人間に再質問が必要。
- **H (LLM Inference)**: LLM が C + 外部情報 + 推論から導出したもの。
  LLM が自律的に修正可能。反証条件を明記する。

## S=(A,C,H,D) との対応

- A: EpistemicLayerClass（import 先。Read-only）
- C: このファイルの `[C]` ラベル付き仮定
- H: このファイルの `[H]` ラベル付き仮定
- D: ConditionalAxiomSystem.lean（このファイルから導出）
-/

namespace Manifest.Models.Assumptions

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 認識論的出自の型定義
-- ============================================================

/-- 仮定の認識論的出自。C（人間判断）と H（LLM推論）を型レベルで区別する。 -/
inductive EpistemicSource where
  /-- 人間の設計判断。Phase 1 の対話で引き出されたもの。
      T6（人間の最終決定権）の権威に基づく。 -/
  | humanDecision
      (phase : Nat)        -- 対話の Phase 番号
      (question : String)  -- 対応する質問の識別子
      (date : String)      -- 判断日 (YYYY-MM-DD)
  /-- LLM の推論。C + 外部情報 + LLM の知識から導出。 -/
  | llmInference
      (basis : List String)    -- 根拠とした C/H の識別子リスト
      (refutation : String)    -- 反証条件（何があればこの推論は覆るか）
  deriving Repr

/-- 仮定の記録。出自 + 内容 + 確信度。 -/
structure Assumption where
  /-- 一意な識別子（例: "C1", "H3"） -/
  id : String
  /-- 認識論的出自 -/
  source : EpistemicSource
  /-- 自然言語での記述 -/
  content : String
  deriving Repr

-- ============================================================
-- 仮定の蓄積（プロジェクト固有）
-- ============================================================

-- ============================================================
-- 層定義の仕様型（Phase 2 の出力）
-- ============================================================

/-- 層の仕様。Phase 2 で LLM が C∪H から導出する。
    ConditionalAxiomSystem の生成入力になる。 -/
structure LayerSpec where
  /-- 層の名前（Lean の識別子として有効な文字列） -/
  name : String
  /-- 層の自然言語での定義 -/
  definition : String
  /-- 認識論的順序値（大きいほど強い） -/
  ordValue : Nat
  /-- この層を導出した根拠となる仮定の ID リスト -/
  derivedFrom : List String
  deriving Repr

/-- 命題の層割り当て仕様。 -/
structure AssignmentSpec where
  /-- 割り当て対象の自然言語での記述 -/
  proposition : String
  /-- 割り当て先の層名（LayerSpec.name に対応） -/
  layerName : String
  /-- この割り当ての根拠となる仮定の ID リスト -/
  justification : List String
  deriving Repr

/-- モデル仕様全体。Phase 2 の最終出力であり、G4 (Lean コード生成) の入力。 -/
structure ModelSpec where
  /-- 層の仕様リスト（ordValue の降順） -/
  layers : List LayerSpec
  /-- 命題の割り当て仕様リスト -/
  assignments : List AssignmentSpec
  /-- 根拠となった仮定リスト -/
  assumptions : List Assumption
  deriving Repr

-- ============================================================
-- 仮定の蓄積（プロジェクト固有）
-- ============================================================

-- 以下は model-questioner エージェントの Phase 1-3 の対話結果から生成される。
-- 初期状態では空。対話を経るごとに git commit で蓄積される。

end Manifest.Models.Assumptions
