# adjust-action-space

L4 行動空間の調整（拡張・縮小）を提案するスキル。

V4/V5 の実績データに基づき、permissions の変更を人間に提案する。
D8（均衡探索）に従い、拡張と縮小の両方向を扱う。

## 起動トリガー

`/adjust-action-space` または「行動空間」「権限」「permissions」「拡張」「縮小」「auto-merge」

## 原則

- **最適 ≠ 最大**: 行動空間の最大化は目的ではない (D8)
- **拡張と防護はセット**: 拡張提案には必ず対応する防護設計を含める (D7/P1)
- **人間が最終決定者**: 提案のみ。実行は人間の承認後 (T6)

## Lean 形式化との対応

| 概念 | Lean ファイル | 定理/定義 |
|------|-------------|----------|
| D8: 過剰拡大は価値を毀損 | DesignFoundation.lean | `d8_overexpansion_risk` |
| D8: 能力-リスク共成長 | DesignFoundation.lean | `d8_capability_risk` |
| D7: 蓄積は bounded | DesignFoundation.lean | `d7_accumulation_bounded` |
| D7: 毀損は unbounded | DesignFoundation.lean | `d7_damage_unbounded` |
| T₀ 縮小禁止 | Procedure.lean | `t0_contraction_forbidden` |
