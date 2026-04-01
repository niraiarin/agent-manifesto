# L1 安全境界の変更影響分析

## 1. L1 の現在の定義

L1（倫理・安全境界）は `BoundaryId.ethicsSafety` として定義されており、`BoundaryLayer.fixed`（固定境界）に分類されている。固定境界とは「投資でも努力でも動かない」境界であり、L2（存在論的境界）と共に最も厳格なカテゴリに属する。

### 遵守義務（6項目）

| 境界条件 | 根拠 |
|---------|------|
| テスト改竄の禁止 | 品質保証の基盤 |
| 既存インターフェース破壊の禁止 | 後方互換性 |
| 破壊的操作の事前確認 | 不可逆性リスク |
| 秘密情報のコミット禁止 | セキュリティ |
| 人間の最終決定権 | 説明責任 |
| データプライバシーと知的財産の尊重 | 法的・倫理的義務 |

### 脅威認識（4カテゴリ）

| 脅威カテゴリ | 内容 |
|------------|------|
| 注入指示の実行 | 外部コンテンツに埋め込まれた指示の実行 |
| 信頼境界の違反 | 認証・認可なしの外部システム操作 |
| 意図しない情報漏洩 | 秘密情報の意図しない送信 |
| 不可逆操作の誤実行 | 悪意ある誘導や判断ミスによる不可逆操作 |

## 2. 依存グラフ（半順序構造）

上流（L1 が依存するもの）: P1（自律権と脆弱性の共成長）、T6（人間はリソースの最終決定者）

下流（L1 に依存するもの）: D1（構造的強制）、さらに D11 が D1 に依存

### 推移的閉包で影響を受ける命題: 3件

- **L1** 自身
- **D1**（構造的強制）: `dependencies = [.p5, .l1, .l2, .l3, .l4, .l5, .l6]` — L1 が変わると D1 の前提が変化
- **D11**: `dependencies = [.t3, .d1, .d3]` — D1 経由で間接的に影響

### 重要な構造的関係

- **D1 と L1 の関係**: 「固定境界（L1）は構造的に強制されなければならない」という D1 の核心的主張が L1 の定義に依存している。L1 の定義変更は D1 の正当化根拠に直接影響する。
- **P1 と L1 の関係**: 「L4（行動空間）が拡張されるほど、L1 の保護責任が増大する」— L1 の保護範囲が変われば、P1 との均衡点も移動する。
- **EpistemicLayer**: `TransitivelyDependsOn .d1 .t6` の証明が `L1` を中間ノードとして使用している（`D1 -> L1 -> T6`）。

## 3. 影響を受ける実装成果物

### Lean 形式化（12ファイル）

| ファイル | 影響箇所 | 影響の種類 |
|---------|---------|-----------|
| `Manifest/Ontology.lean` | `BoundaryId.ethicsSafety` 定義、L1 doc comment、`boundaryLayer` 関数、`PropositionId.dependencies .l1` | **定義の変更元** |
| `Manifest/DesignFoundation.lean` | D1 の定理群（`boundaryLayer .ethicsSafety = .fixed`）、`PhaseId.safety`、`RiskLevel.critical` | D1 前提の変化 |
| `Manifest/Observable.lean` | `variablePrimaryBoundary .v3 => .ethicsSafety`、`constraintBoundary .t6 => [.ethicsSafety, .actionSpace]`、カバレッジ定理 | V3-L1 マッピング |
| `Manifest/ObservableDesign.lean` | L1 への参照（信頼損傷の非対称性） | doc comment |
| `Manifest/Traceability.lean` | L1 閉環 PoC 全体（トレースマトリクス、カバレッジ定理、影響分析定理） | トレース |
| `Manifest/EpistemicLayer.lean` | `transitive_dependency_example`（D1->L1->T6 チェーン）、`join_consistency_example` | 証明の中間ノード |
| `Manifest/FormalDerivationSkill.lean` | 間接参照 | 軽微 |
| `Manifest/Models/ConditionalAxiomSystem.lean` | `.l1 => .derived` の分類 | モデル |
| `Manifest/Models/PoC/ThreeLayerGenerated.lean` | `.l1 => .derived` | PoC モデル |
| `Manifest/Models/PoC/CheckMonotone.lean` | `.l1` の strength 値、命題リスト | 単調性検証 |
| `Manifest/Models/PoC/ThreeLayerManual.lean` | `.l1` 分類 | PoC モデル |
| `Manifest/Models/PoC/Scenario1.lean` | `.l1` 分類 | シナリオ |

### Hook（構造的強制の実装）

| ファイル | 役割 |
|---------|------|
| `.claude/hooks/l1-safety-check.sh` | Bash コマンドの安全チェック（破壊的操作、認証情報、プロンプトインジェクション、秘密ファイル） |
| `.claude/hooks/l1-file-guard.sh` | Edit/Write の安全チェック（秘密ファイル書き込み、テスト改竄、Hook 自己保護） |
| `.claude/hooks/p4-drift-detector.sh` | L1 ブロック頻度の監視 |
| `.claude/hooks/p4-gate-logger.sh` | L1 hook 結果の集計 |

### ルール・設定

| ファイル | 影響 |
|---------|------|
| `.claude/rules/l1-safety.md` | L1 の規範的定義（第三層防衛線） |
| `.claude/rules/l1-sandbox-recommendation.md` | L1 補強の推奨設定 |
| `.claude/settings.json` | Hook 登録（3箇所で l1 hook を参照） |
| `CLAUDE.md` | L1 の説明と遵守義務の記載 |

### スキル・エージェント

| ファイル | 参照内容 |
|---------|---------|
| `.claude/skills/verify/SKILL.md` | L1 安全チェック |
| `.claude/skills/evolve/SKILL.md` | L1 行動空間制約 |
| `.claude/skills/formal-derivation/SKILL.md` | L1 参照 |
| `.claude/skills/ground-axiom/SKILL.md` | L1 参照 |
| `.claude/skills/instantiate-model/SKILL.md` | L1 参照 |
| `.claude/agents/hypothesizer/AGENT.md` | L1 行動空間制約の記載 |

### ドキュメント

| ファイル | 影響 |
|---------|------|
| `docs/design-development-foundation.md` | L1 の設計上の根拠 |
| `docs/implementation-boundaries.md` | L1 の実装境界 |
| `research/step0b-prior-art-research.md` | L1 の先行調査 |
| `research/claude-code-technical-spec.md` | L1 の技術仕様 |

## 4. 再実行すべきテスト

### 必須（L1 直接テスト）

**`tests/phase1/test-l1-structural.sh`（10テスト）**

| テスト | 検証内容 |
|-------|---------|
| S1.1 | settings.json に hooks が存在 |
| S1.2 | PreToolUse Bash hook が登録済み |
| S1.3 | PreToolUse Edit hook が登録済み |
| S1.4 | PreToolUse Write hook が登録済み |
| S1.5 | deny list が 10 件以上 |
| S1.6 | l1-safety-check.sh が存在し実行可能 |
| S1.7 | l1-file-guard.sh が存在し実行可能 |
| S1.8 | L1 rules ファイルが存在 |
| S1.9 | PostToolUse hooks が非同期のみ |
| S1.10 | hook コマンドに絶対パスがない |

**`tests/phase1/test-l1-behavioral.sh`（13テスト）**

| テスト | 検証内容 |
|-------|---------|
| B1.1 | 破壊的ファイル削除がブロックされる |
| B1.2 | 強制 push がブロックされる |
| B1.3 | 権限昇格がブロックされる |
| B1.4 | プロンプトインジェクションがブロックされる |
| B1.5 | 認証情報の外部送信がブロックされる |
| B1.6 | 秘密ファイルのステージングがブロックされる |
| B1.7 | 安全な ls コマンドが許可される |
| B1.8 | 安全な git 操作が許可される |
| B2.1 | 秘密ファイルへの書き込みがブロックされる |
| B2.2 | テスト無効化パターンがブロックされる |
| B2.3 | hook 自己変更がブロックされる |
| B2.4 | 通常ファイル編集が許可される |
| B2.5 | 通常テスト編集が許可される |

### 必須（間接影響）

- **`tests/phase5/test-evolve-structural.sh`** — Hypothesizer が L1 行動空間制約を持つことの検証
- **`tests/phase5/test-axiom-quality.sh`** — 公理品質チェック
- **`tests/phase5/test-scripts-structural.sh`** — スクリプト構造チェック

### 推奨（全体回帰テスト）

    bash tests/test-all.sh

### 推奨（Lean ビルド）

    cd lean-formalization && export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest

L1 の定義変更は Lean の型・定理に波及するため、ビルドが通ることの確認は必須。特に以下の定理がコンパイルエラーになる可能性がある:

- `Traceability.lean` の `l1_poc_*` 系定理（`native_decide` による自動証明）
- `DesignFoundation.lean` の `boundaryLayer .ethicsSafety = .fixed` を含む定理
- `EpistemicLayer.lean` の `transitive_dependency_example`

## 5. 変更の互換性分類ガイド

L1 の変更内容によって分類が異なる:

| 変更の種類 | 分類 | 例 |
|-----------|------|-----|
| 遵守義務の追加 | conservative extension | 新しい脅威カテゴリの追加 |
| doc comment の修正 | conservative extension | 説明文の改善 |
| 遵守義務の修正（意味変更なし） | compatible change | 文言の明確化 |
| 遵守義務の削除 | **breaking change** | 既存の保護を緩和 |
| `BoundaryLayer` の変更（fixed から他へ） | **breaking change** | L1 の固定性を解除 |
| Hook の検出パターン変更 | compatible change / breaking change | 検出範囲の拡大/縮小 |

## 6. 変更手順の推奨

1. **変更仕様の明確化**: 何を変えたいか（遵守義務の追加/削除/修正、脅威カテゴリの変更など）を特定
2. **Lean 定義の更新**: `Ontology.lean` の L1 doc comment と必要に応じて型定義を更新
3. **Hook の更新**: `l1-safety-check.sh` / `l1-file-guard.sh` の検出パターンを変更に合わせて更新
4. **ルールの更新**: `.claude/rules/l1-safety.md` を同期
5. **テストの更新**: `test-l1-behavioral.sh` にテストケースを追加/修正
6. **Lean ビルド**: `lake build Manifest` で全定理の整合性を確認
7. **全テスト実行**: `bash tests/test-all.sh` で回帰テスト
8. **CLAUDE.md の同期**: L1 セクションの更新
9. **Traceability の更新**: `l1TraceMatrix` のテスト・成果物マッピングを必要に応じて更新
10. **`manifest-trace impact L1`** で影響が全て捕捉されていることを最終確認

## 7. manifest-trace による確認コマンド

    # 影響分析（変更前後で比較推奨）
    ./manifest-trace impact L1

    # 順方向・逆方向トレース
    ./manifest-trace trace L1

    # カバレッジギャップ（変更後に新しいギャップが生じていないか）
    ./manifest-trace coverage

    # 全体の健全性
    ./manifest-trace health
