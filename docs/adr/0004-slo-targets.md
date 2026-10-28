# ADR 0004: SLO targets and reasoning

**Status:** Accepted, 2026-10-27

## Context
The project's point is demonstrated SRE judgment, not uptime theater. SLOs need to (a) reflect what a single-node homelab box can honestly promise, (b) separate what this system controls from what adsb.lol controls, and (c) be tight enough that burn-rate alerting is a meaningful exercise rather than something that never fires.

## Options considered for each SLI
- **Freshness.** Could measure as a ratio (snapshots within budget / total) or as time-based (minutes where the newest stored snapshot is stale). Time-based was chosen: it's legible on a dashboard ("down for N minutes") and matches how a single-node outage actually presents — stale data persists for a duration, not for a fraction of discrete events.
- **Ingest success.** Could include upstream 429/5xx in the denominator (penalizes us for adsb.lol's behavior) or exclude them (measures only what the ingest client controls: fetch-parse-store given a response). Excluding upstream errors was chosen, paired with a separate dependency SLI, so an adsb.lol outage is visible without burning this system's error budget.
- **Query latency.** Threshold-based (e.g. "p99 < 250ms") was rejected in favor of a ratio against a fixed latency bucket, measured with native histograms — cheaper to compute accurately at low cardinality/low QPS than client-side percentile estimation, and Prometheus 3's native histograms make this close to free.
- **Targets (99% vs. 99.9% vs. three nines).** 99%/30d was chosen over anything tighter. One node means planned k3s upgrades and host reboots are outages by definition (ADR 0001); a 99.9% target would be violated by routine maintenance and would stop being a useful signal. 99% leaves roughly 7.3 hours/month of budget — enough to cover a handful of planned maintenance windows and still have budget left to practice burning it deliberately in game days.

## Decision
- **Freshness** (time-based): fraction of minutes where the newest stored snapshot is < 30 s old. Target 99% / 30 d.
- **Ingest success:** polls fetched + parsed + stored, divided by polls attempted excluding upstream 429/5xx. Target 99%.
- **Query latency:** fraction of API reads < 250 ms, measured via native histograms. Target 99%.
- **adsb.lol dependency SLI:** measured and dashboarded, but explicitly **not** budgeted against this system's error budget.
- **Burn-rate alerting** via Sloth, multi-window multi-burn-rate:
  - 14.4× burn over 1h → page
  - 6× burn over 6h → page
  - 1× burn over 3d → ticket
- **Error-budget deploy gate:** sits between "image published to GHCR" (ADR 0003) and "Flux image automation updates the manifest." A budget below threshold blocks the automated commit; deploys still happen, just not unattended.

## Consequences
- 99% targets mean the project will visibly burn budget during normal single-node maintenance — that's intentional and should be called out as such in any postmortem, not treated as a surprise.
- The dependency SLI requires adsb.lol-specific instrumentation (response codes, latency) separate from the ingest SLI, adding one more thing the OTel Collector needs to split cleanly (ties into the "noisy telemetry" processor work in phase 3).
- The deploy gate needs the error budget computed and queryable *before* Flux's automation commit lands — i.e., the gate is a check Flux (or a webhook it calls) consults, not a human approval step. Mechanism TBD when phase 4 starts; this ADR fixes the targets and policy, not the implementation.
- Because upstream errors are excluded from ingest success, a silent client-side bug that mislabels real failures as "upstream 429" would hide real problems. Worth a deliberate chaos/game-day test once Chaos Mesh is in place (phase 5).
