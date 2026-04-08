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

## 時間的有効性 (Temporal Validity)

条件付き公理系の仮定 (C/H) は外部ソースに由来する。外部ソースは時間とともに
変化するため、C/H には時間的有効性があり、それを管理する義務がある。

- **ソース追跡**: 再 fetch 可能な外部ソース参照を保持する
- **鮮度管理**: 最終検証日と見直し間隔を追跡する
- **陳腐化検知**: 見直し期限の到来を検知し、D13 の影響波及を発動する

これは特定のインスタンスの問題ではなく、全ての条件付き公理系に適用される
根源的性質である（#225）。

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

-- ============================================================
-- 時間的有効性（#225: 条件付き公理系の根源的性質）
-- ============================================================

/-- 仮定の時間的有効性。
    外部ソースに由来する仮定 (C/H) が時間とともに陳腐化しうることを
    型レベルで表現する。

    根拠:
    - D9（分類自体のメンテナンス）: 根拠が失われた導出は再検討対象
    - D13（前提否定の影響波及）: 仮定の失効は依存する導出に波及する
    - P3（学習の統治 — 退役）: 陳腐化した仮定は退役候補
    - T5（フィードバックなしに改善なし）: 外部ソースの変化を検知しなければ改善不可 -/
structure TemporalValidity where
  /-- 再 fetch 可能な外部ソース参照（URL, doc path, repo ref 等）。
      仮定の根拠を再検証するために必要。 -/
  sourceRef : String
  /-- 最終検証日 (YYYY-MM-DD)。
      この日時点で仮定が有効であることが確認された。 -/
  lastVerified : String
  /-- 見直し間隔（日数）。None = 定期見直しなし（明示的トリガーのみ）。
      Some n = n 日ごとに見直しが必要。 -/
  reviewInterval : Option Nat := none
  deriving Repr

/-- 仮定の記録。出自 + 内容 + 時間的有効性。 -/
structure Assumption where
  /-- 一意な識別子（例: "C1", "H3"） -/
  id : String
  /-- 認識論的出自 -/
  source : EpistemicSource
  /-- 自然言語での記述 -/
  content : String
  /-- 時間的有効性。None = 時間的制約なし（恒久的仮定）。
      条件付き公理系の仮定は外部ソースに由来するため、
      通常は Some で有効期限・ソース参照を明示すべきである。 -/
  validity : Option TemporalValidity := none
  deriving Repr

-- ============================================================
-- 時間的有効性の運用支援関数
-- ============================================================

/-- 仮定に見直し情報が設定されているかを判定する。 -/
def Assumption.hasReviewInfo (a : Assumption) : Bool :=
  a.validity.isSome

/-- 仮定に定期見直しが設定されているかを判定する。 -/
def Assumption.hasPeriodicReview (a : Assumption) : Bool :=
  match a.validity with
  | some tv => tv.reviewInterval.isSome
  | none => false

-- ============================================================
-- 仮定の失効と影響波及（D13 接続）
-- ============================================================

/-- 仮定の失効イベント。
    D13（前提否定の影響波及）を仮定レベルに拡張する。
    仮定が失効した場合、この仮定に依存する全ての導出が再検証対象となる。

    affectedDerivations は PropositionId のリストであり、
    DesignFoundation.lean の `assumptionImpact` / `affected` と
    同じ型を使用する（型的接続の保証）。 -/
structure AssumptionExpiration where
  /-- 失効した仮定の識別子 -/
  assumptionId : String
  /-- 失効の理由（外部ソースの変更内容、期限到来等） -/
  reason : String
  /-- この仮定に依存する導出の PropositionId リスト。
      DesignFoundation.lean の affected / assumptionImpact と型が一致する。 -/
  affectedDerivations : List PropositionId
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
