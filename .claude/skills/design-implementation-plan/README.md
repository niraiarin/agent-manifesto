# design-implementation-plan

マニフェスト準拠の設計実装計画書を任意のプラットフォーム向けに生成するスキル。

D1-D9 設計原則をプロバイダプリミティブ（Claude Code, GitHub Actions, CI/CD 等）に
マッピングし、フェーズ別ロードマップ、テストケース、V1-V7 計測設計を含む計画書を出力する。

## 起動トリガー

`/design-implementation-plan` または「実装計画」「設計計画」「ロードマップ」「design plan」「implementation plan」「何から実装すべき」

## 入力

- 対象プロバイダ（Claude Code, GitHub Actions, etc.）
- プロジェクト要件

## 出力

- D1-D9 のプロバイダマッピング
- フェーズ別ロードマップ
- テストケース設計
- V1-V7 計測設計

## 参照ファイル

- `docs/design-development-foundation.md` — D1-D9 設計開発基礎論
- `lean-formalization/Manifest/DesignFoundation.lean` — Lean 形式検証
- `lean-formalization/Manifest/Ontology.lean` — 境界条件 L1-L6
- `lean-formalization/Manifest/Observable.lean` — 変数 V1-V7
