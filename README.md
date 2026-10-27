# airspace-sre

A small, real service run the way an SRE team would run it: live ADS-B aircraft data over Calgary, ingested on a single mini PC, with OpenTelemetry instrumentation, SLOs with burn-rate alerting, an error-budget deploy gate, chaos experiments, and blameless postmortems.

Everything is open source and reconciled from this repository by Flux.

## Hardware
Beelink SER3: Ryzen 3 3200U (2C/4T), 16 GB RAM, 500 GB SSD, Ubuntu. One node, no HA, and the docs say so wherever it matters.

## Status
| Phase | Scope | State |
|---|---|---|
| 1 | k3s, Flux, SOPS/age, Tailscale, rebuild drill | in progress |
| 2 | ADS-B ingest service + Postgres, OTel-instrumented | |
| 3 | OTel Collector → Prometheus 3 / Loki / Tempo → Grafana | |
| 4 | SLOs (Sloth), burn-rate alerts, error-budget deploy gate | |
| 5 | Chaos game days + postmortems | |

## Layout
```
bootstrap/        host prep, k3s install, Flux bootstrap
clusters/beelink/ Flux entry point (infrastructure → apps)
infrastructure/   platform: namespaces, observability, chaos tooling
apps/             the ADS-B service and its database
docs/adr/         architecture decisions
docs/runbooks/    operational procedures
docs/postmortems/ incident write-ups
```

## Quick start
```bash
./bootstrap/00-host-prep.sh
./bootstrap/01-install-k3s.sh
export GITHUB_TOKEN=... GITHUB_USER=...
./bootstrap/02-flux-bootstrap.sh
```

## How this was built
Design decisions, trade-offs and operations are mine and are recorded in `docs/adr/` and `docs/build-log.md`. I used Claude (chat and Claude Code) as a pair programmer for drafting manifests, code and docs, and reviewed everything that landed.

## Data
Aircraft data from [adsb.lol](https://adsb.lol), licensed under the Open Database License (ODbL).
