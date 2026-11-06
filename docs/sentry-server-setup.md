# Sentry server-side setup for Jama'ah (Tier 0 + 1, 2026-11-06)

Client Tier 0 + 1 shipped in code (AGENTS.md exception expanded 2026-11-06):
session tracking, environment/tags, `notification.sync.*` metrics, sampled
`notification.sync` transactions — all behind the existing opt-in toggle.

Server-side state (org `lonelycactus-e0`, project `flutter`, verified live
2026-11-06):

## Done via MCP (read back live)

- **Metric monitor** `Jamaah — notification sync failures` (id 2611553,
  https://lonelycactus-e0.sentry.io/monitors/2611553/): static threshold,
  `failure_rate()` over `transaction:notification.sync` spans, 1d window,
  alert when `> 0`. Connected to Alert 1463733.
  Note: metric monitors cannot query Application Metrics counters directly
  (API supports errors + trace spans only, verified against Sentry docs
  2026-11-06), so this monitors the sync **transaction** failure rate as a
  proxy for `notification.sync.failed`. If app metrics become monitorable,
  migrate the query.
- **Alert** `Jamaah — new high-priority issue` (id 1463733,
  https://lonelycactus-e0.sentry.io/monitors/alerts/1463733/): fires on
  `new_high_priority_issue`, emails issue owners (ActiveMembers fallthrough),
  30-min frequency. Connected to the project issue stream and to monitor
  2611553. Keep the stock "high priority" rule (id 1382030) until this one
  has fired once, then disable the stock one.

## Still manual (no MCP tool exists for these)

- **Inbound filters** (Project → Settings → Filters), ignore:
  - `LocationServiceDisabledException` — location services off
    (FLUTTER-6, 2026-11-01). Expected, not a defect.
  - `abort` from the platform HTTP layer during connectivity loss
    (FLUTTER-5). Re-check after 2 weeks; keep if single-occurrence.
- **Custom dashboard** `Jamaah — health` (Dashboards → Create, 1 of 10 free):
- Errors by release (release health / crash-free %)
- `notification.sync.completed` vs `notification.sync.failed` per day
- `notification.sync.duration` p50/p95 (the sync must stay fast — it runs
  on app start and resume)
- `diagnostics.write_failure` count (should be ~0; nonzero = storage issue)

## Release tracking (wired + tested)

`tool/build_release.ps1` runs `sentry-cli releases new / set-commits
--auto / deploys new / finalize` when `SENTRY_AUTH_TOKEN` is set in `.env`
(non-fatal if missing; tested live 2026-11-06 against release
`dev.jamaah.app@1.0.8+10`: created, 20 commits attached from the local git
tree — no repo integration on the Developer plan — `tester` deploy created,
finalized). To enable: token already in `.env` (from `.env.sentry`); needs
`sentry-cli` on PATH (`npm install -g @sentry/cli`, tested 3.8.2) on the
build machine. Each release build then carries commits + a deploy marker.

## Explicitly not doing

- **Session Replay** — banned by AGENTS.md; 50/mo free quota is token anyway.
- **Profiling / Seer** — paid add-ons ($0.25/hr, $40/contributor).
- **Uptime monitors** — no backend to check.
- **Sending mosque, location, or prayer-time data** — never, per AGENTS.md.
