# Router Observability Runbook

## Setup

Install the weekly launchd job manually from the project template:

```bash
cd /Users/nirarin/work/agent-manifesto-research-672
mkdir -p "$HOME/Library/LaunchAgents"
sed "s#__MANIFESTO_ROOT__#$(pwd)#g" \
  docs/research/routellm-phase3/classifier/launchd/com.nirarin.router-drift.plist.template \
  > "$HOME/Library/LaunchAgents/com.nirarin.router-drift.plist"
plutil -lint "$HOME/Library/LaunchAgents/com.nirarin.router-drift.plist"
launchctl load "$HOME/Library/LaunchAgents/com.nirarin.router-drift.plist"
```

The job runs `scripts/router-drift-check.sh` every Monday at 09:00. The script writes drift reports to `docs/research/routellm-phase3/analysis/` and logs to `docs/research/routellm-phase3/logs/`.

## Verify

```bash
launchctl list | grep router-drift
bash scripts/router-drift-check.sh
tail -50 docs/research/routellm-phase3/logs/drift-check-$(date +%Y%m%d).log
```

Expected exit codes:

- `0`: drift check completed and no alert was required.
- `2`: drift was detected and the alert dispatcher ran.
- `1`: setup, drift generation, or alert dispatch failed.

For a dry-run alert body, use a generated report with `drift.alert == true`:

```bash
cd docs/research/routellm-phase3/classifier
uv run python3 alert_dispatcher.py --report ../analysis/drift-report-YYYYMMDD.json --dry-run
```

## Drift Response

1. Open the generated GitHub issue and inspect the linked drift report.
2. Triage likely causes: label distribution shift, lower confidence, fallback increase, or data quality changes in `logs/predictions*.jsonl`.
3. Decide whether retraining is justified. Do not retrain without human approval.
4. After approval, run `uv run python3 retrain_cli.py --base-train ... --base-eval ... --corrections ... --model-dir ...`.
5. Validate the new model against GT hold-out accuracy and leak metrics.
6. Roll back to the model backup if GT hold-out accuracy regresses or leak becomes non-zero.
7. Record the decision and result in the drift issue.

## Teardown

```bash
launchctl unload "$HOME/Library/LaunchAgents/com.nirarin.router-drift.plist"
```

Remove the copied plist only after unloading it. Keep the project template under version control.

## Troubleshooting

- `gh` auth expired: run `gh auth status`, then re-authenticate before the next drift check.
- `uv not found`: ensure `uv` is on launchd `PATH`, or install it at `$HOME/.local/bin/uv`.
- MPS OOM during retrain: retry on CPU or reduce concurrent workloads before retraining.
- Missing drift report: inspect the daily `drift-check-YYYYMMDD.log` file first.
- Log rotation is not implemented; prune old files under `docs/research/routellm-phase3/logs/` manually when needed.

## Metrics/Prometheus

`serve_encoder.py` exposes Prometheus text metrics at `/metrics`:

```bash
curl -s localhost:9001/metrics | head -20
```

The endpoint reports prediction totals by label, recent confidence mean, total fallback count, and recent p95 latency. Prometheus or Grafana deployment is out of scope for this issue.
