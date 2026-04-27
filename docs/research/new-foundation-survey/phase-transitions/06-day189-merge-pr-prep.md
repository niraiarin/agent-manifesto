# Day 189 main merge PR prep

Phase 5 α step 2/3。`research/new-foundation` を `main` へ merge する PR の事前準備。

## 規模

- merge-base: `54631cceb46356bfb9cff0a5b48798a226e418c7`
- research/new-foundation 側 commits: **391** (Day 1-188)
- diff: 228 files changed, 59,404 insertions(+), 3,919 deletions(-)

## potential conflict files (3 件)

merge-base 以降、main + research/new-foundation **両方**で変更された file:

| file | conflict 性質 | 対応 |
|---|---|---|
| `.claude/hooks/p2-verify-on-commit.sh` | research 側で governance 強化、main 側で別 hook 改修可能性 | manual diff review |
| `.claude/settings.json` | 両方で hook 追加可能性 | merge tool で 3-way |
| `CLAUDE.md` | research 側で Scope discipline rule 追加 (Day 123)、main 側で別ルール追加可能性 | manual diff review |

## merge strategy 候補

### (1) Squash merge (推奨)

- 391 commits を 1 commit に統合
- commit message に Phase 0+1+2+3+4 全成果を要約
- main 側 commit log を単純化、Phase 単位で見やすい
- 但し研究プロセスの granular history が失われる (個別 PI commits 等)

### (2) Merge commit (rebase なし)

- 391 commits を main に追加 (full history 保持)
- research/new-foundation の Day cycle history が main で観察可能
- main log が大幅に長く、router research 等他 work の commit と interleave

### (3) Cherry-pick selective

- 重要 commit (Phase milestone、PI 完了) のみ pick
- granular control 可能、但し選定工数大

**推奨: (1) Squash merge** — 規模が大きく、main 側に granular history が必要なら research worktree 別途参照可能。

## squash commit message draft

```
release: agent-spec-lib v0.1.0 + agent-manifesto Phase 0-4 完了 (#xxx)

Day 1-188 累積成果:

## agent-spec-lib v0.1.0 (Lean 4 形式系)

- Manifest 公理体系 100% by name port: 47 top + Framework 9/9 + Foundation 6/6
- Tooling 9 module: AgentVerify / SkillRegistry / SkillVCG / IsVerifyToken / TrustDelegation /
  VerifyTokenLoader / VerifyTokenMacro / CriticalPatterns / MeasurableSemantic / OpaqueOrigin
- Spine + Process + Provenance + Proofs layer (Phase 0 Week 2-3 完成)
- examples 10 件 + lake build 2056 PASS / sorry 0 / native_decide 0
- API_SURFACE.md (53 stable + 10 provisional) + CHANGELOG + CONTRIBUTING

## governance toolkit (.claude/ + governance/)

- 26 cycle-check (Check 1-26)、3 例 install acceptance
- p2-verify hook + l1-file-guard + l1-safety-check
- governance/install.sh で別 project に deploy 可能

## Process Improvement (PI 16/16 = 100% done)

- PI-1〜PI-16 全完成、自己評価バイアス削減 + cycle 構造修正 + Lean 形式系 semantic 補強

## 互換性

- 本 PR 自体は existing main から見て conservative_extension (Lean 形式系 + governance toolkit の純粋追加)
- API_SURFACE.md stable 53 module は v0.1.0 freeze、major version bump (v0.2.0+) で変更

Closes: research/new-foundation work、Phase 5+ は別 branch / 別 work で。

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## 実施手順 (Day 190 予定、user 確認下)

1. main 最新を fetch + research/new-foundation に rebase 試行 (conflict 解消 dry-run)
2. conflict 3 件を 3-way merge tool で解決
3. squash commit を作成
4. `gh pr create` で PR 起こす
5. user 確認 → PR merge

## risk + mitigation

| risk | mitigation |
|---|---|
| 391 commit squash で history 失う | research/new-foundation worktree 維持 (defer) で granular history 参照可能 |
| `.claude/hooks/p2-verify-on-commit.sh` conflict | research 側 governance 強化が main の hook を覆う可能性、manual review |
| Mathlib heavy build (Probability 1965 jobs) で main CI 遅延 | agent-spec-lib build job は path filter で other work に影響なし |
| `agent-spec-lib/` 巨大 directory 追加 | main repo size 増加、許容範囲 (Lean lib ~50K LOC) |
| breaking change なし validation 必要 | API_SURFACE.md 確認 + lake build 後の axiom dependency audit (`#print axioms`) |

## checklist (Day 190 実施前)

- [ ] main 最新 fetch
- [ ] rebase dry-run、conflict 3 件確認
- [ ] CHANGELOG [0.1.0] 確定 (Day 188 完了)
- [ ] lakefile version v!"0.1.0" 確定 (Day 188 完了)
- [ ] cycle-check 全 PASS (Day 188 確認済)
- [ ] examples + governance install acceptance 全 PASS (Day 178/186 確認済)
- [ ] user に PR 作成 + merge を確認

Day 190 で実施 (user 同意済前提)。
