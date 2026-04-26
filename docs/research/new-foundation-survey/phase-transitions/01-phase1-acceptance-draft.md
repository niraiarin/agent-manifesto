# Phase 1 Acceptance Criteria (Day 156 draft、PI-7 audit follow-up)

## 背景

PI-7 (Day 148 plan) で Phase 0 終了 chronological gate を Day 155 に設定したが、
Phase 1 の acceptance criteria が未定義のまま。independent reviewer (Day 155 dispatch)
が指摘した通り、Phase 1 = "usable form" の操作可能定義が存在しない。本 draft は
user 確認のための叩き台。

## Phase 1 提案 acceptance criteria (5 項目、draft)

| # | criterion | 操作的定義 | 現状 |
|---|---|---|---|
| 1 | **Manifest 公理体系の型表現が完備** | source 57 axiom の name-distinct 全件が port に存在 | **達成 (100% by name)** |
| 2 | **Public API surface の文書化** | `agent-spec-lib/AgentSpec.lean` 経由で import される top-level def/class/theorem 数 + README に列挙 | 未着手 |
| 3 | **Examples** | `Examples/` ディレクトリで end-user 用 sample (3-5 件)、各 import + 1 theorem use | 未着手 |
| 4 | **Versioning** | `lakefile.toml` に semantic version (例 0.1.0)、CHANGELOG.md 整備 | 未着手 |
| 5 | **CI gate** | GitHub Actions で lake build PASS + 主要 axiom dependency audit (`#print axioms`) を再現可能化 | 部分的 (lake build 手元のみ) |

## Phase 1 NOT goals (defer 候補)

- Theorem 100% port (現状 20%、残 80% は research artifact として lean-formalization/ に残置)
- DesignFoundation 完全 port (1952 LOC、Phase 2+ で再検討)
- Tooling 層の semantic 保証強化 (PI-12/13 は Phase 1 入りの hard requirement に含めない、parallel 進行で OK)

## 移行判断基準

- **Phase 1 移行可** (5 / 5 OK)
- **Phase 1 部分移行** (1, 2, 5 OK + 3, 4 部分): semi-stable release
- **継続** (1 のみ OK): Manifest sprint 続行、Phase 0 延長

## user 確認 needed

- 上記 5 criteria が適切か
- "100% by name" を 1 として認めるか (実態は file location 違い + 22 axiom が port 側で追加 = port 拡張済)
- DesignFoundation 完全 port を Phase 1 の hard requirement にするか defer 容認か
