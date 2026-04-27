# Governance Toolkit Usage (Day 177 Phase 3 Theme C5)

別 project に install 後の runtime workflow walkthrough。

## Daily workflow

### 1. Edit / Write 操作時

`l1-file-guard.sh` が PreToolUse hook として発火、以下を block:
- `.env` / `.pem` / credentials への書き込み → 即 block
- test path 内の `skip` / `xit` などの test disable パターン → block

block された場合、AI が原因を user に報告して指示を仰ぐ。bypass 不可。

### 2. Bash 実行時

`l1-safety-check.sh` + `p2-verify-on-commit.sh` が発火:
- destructive command (`rm -rf`, `git push --force`) は user 確認要求
- `git commit` 時、staged file が CRITICAL_PATTERNS にマッチ + token 不在 → block

token 取得方法:
1. `/verify` skill (本 toolkit には未含む、Claude Code skill 側) で independent verifier 起動
2. 結果を `.claude/metrics/p2-verified.jsonl` に append
3. 再度 commit 試行 → token を hook が読んで PASS 判定

### 3. Commit 後の cycle-check

```bash
bash scripts/cycle-check.sh
```

Check 1-24 を全実行。出力例:
```
[1] OK  breakdown 整合
[20] OK  前回 run log 整合性
[21] OK  同一 scope marker N 連敗 なし
[22] OK  decision_deadline 超過 なし
[23] OK  weekly_retro 直近
[24] OK  Hook ↔ Lean criticalPatterns sync
```

NG / FAIL 出たら commit 前に対処。

### 4. Pre-commit 自動化 (optional)

```bash
cp scripts/cycle-check.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

これで `git commit` 前に自動的に cycle-check が走る。

## Day cycle 運用 (PI-1〜PI-13 規律)

### Day cycle entry の生成

各 Day の作業終了時、以下を `artifact-manifest.json` の `verifier_history` に append:

```json
{
  "round": "Day N <scope>",
  "date": "YYYY-MM-DD",
  "result": "PASS",
  "evaluator": "<1-3 文の作業要約>",
  "scope": "<scope marker>",
  "change_category": "<enum>",
  "subagent_dispatch": true,
  "cycle_check_log_hash": "<sha256 of cycle-check log>",
  "pass_layers": {
    "cycle_hygiene": "pass",
    "implementation": "pass" / "fail" / "not_attempted" / "n_a",
    "evaluation": "pass" / "fail" / "n_a"
  }
}
```

- **PI-1**: pass_layers 3 軸必須
- **PI-2**: implementation=fail のとき failed_attempt {marker, files, reason} 必須
- **PI-8**: change_category は subagent dispatch で決定 (Worker 不可)

### 週次 retrospective (PI-6)

7 Day ごとに `weekly_retro` array に entry 追加:
- commit_count / process_only_count / impl pass-fail-n_a count
- theorem_delta / axiom_delta / loc_delta
- highlights (1-3 文)

### 長期 deferred 項目の取扱 (PI-3)

`pending_items` の各 entry に `decision_deadline: <Day#>` を設定。
deadline 超過時、Check 22 が ERROR で blocking。3 択:
- promote (実行 Day に組む)
- retire (catalog 削除、理由記録)
- escalate (user 判断委譲)

## Troubleshooting

### Q. cycle-check Check 5b schema NG が出る

A. `pending_items` schema に新規 field を追加した場合、schema 側も更新が必要。
`docs/research/<your-survey>/11-pending-tasks.schema.json` 等を編集。

### Q. p2-verify-on-commit.sh で「token not found」と block される

A. `.claude/metrics/p2-verified.jsonl` に該当 file の token がない。
`/verify` skill (Claude Code 側) で verifier subagent 起動 → token append → 再 commit。

### Q. Hook が発火しない

A. `.claude/settings.json` の hooks セクション設定を確認。
`bash install.sh` で生成した `.claude/settings.governance.sample.json` を merge する。

### Q. Test pattern false positive (CONTRIBUTING.md 等で skip 記述が block される)

A. `l1-file-guard.sh` の test path 検出は `(test|spec|_test\.|\.test\.)` regex。
`agent-spec-lib` のような path は `spec` を含むため、CONTRIBUTING.md などでも発火する場合あり。
代替案: 文書側で `skip` 等の word を回避するか、hook 側 regex を refine。

## 関連文書

- `README.md`: governance toolkit 設計根拠 + use case 価値順位
- `install.sh`: installer
- 本体 agent-manifesto:
  - `docs/research/new-foundation-survey/usecases/01-current-usecases.md`
  - `docs/research/new-foundation-survey/phase-transitions/03-phase3-acceptance-draft.md`
