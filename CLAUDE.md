# CLAUDE.md — airspace-sre

Context for Claude Code sessions in this repo. Read this first; it carries decisions made before Claude Code was involved.

## What this project is
A small, real service (live ADS-B aircraft data around Calgary/YYC) run the way an SRE team would run it, as a public portfolio piece. The point is demonstrated SRE judgment — SLOs, burn-rate alerting, an error-budget deploy gate, chaos game days, blameless postmortems — not a homelab showcase.

## Environment
- **Workstation:** MacBook Pro M1 Pro (ARM), PyCharm. All code and manifests are authored here.
- **Server:** Beelink SER3, Ryzen 3 3200U (2C/4T, x86_64), 16 GB, Ubuntu, mostly headless. Reached over SSH and Tailscale (`beelink`). Automatic suspend is disabled so it stays reachable.
- **CPU is the binding constraint**, not RAM. Every workload gets explicit CPU requests/limits. Observability components run in monolithic/single-binary modes with modest retention.
- **Resuming from the Mac:** Git/GitHub access needs nothing extra. For the cluster: join the Mac to the same tailnet, then `scp andrij@beelink:~/.kube/config ~/.kube/config` and edit its `server:` field from `https://127.0.0.1:6443` to the Tailscale name — that's why `01-install-k3s.sh` puts the Tailscale FQDN in the k3s cert's `tls-san`. SSH to `beelink` over Tailscale works as-is for anything needing a real terminal (the `sudo`-gated bootstrap steps).

## Non-negotiable conventions
- **GitOps only.** Flux reconciles `clusters/beelink` → `infrastructure` → `apps`. Nothing is applied to the cluster by hand except bootstrap. kubectl from the Mac is for inspection and debugging.
- **Build once, decouple dev from deploy.** Container images are never built on the Mac. GitHub Actions builds `linux/amd64` images to GHCR, tagged by git SHA. No `latest` tags in manifests.
- **Secrets** are SOPS-encrypted with age (`.sops.yaml`). Never commit plaintext secrets, tokens, or kubeconfigs. The age private key lives only off-box (password manager) and in-cluster as `flux-system/sops-age`.
- **Idempotent scripts.** Bootstrap scripts must be safe to re-run.
- **Every significant decision gets an ADR** in `docs/adr/`, numbered sequentially.
- **Single node is stated honestly** wherever it matters: no HA, upgrades cause downtime, SLO targets reflect that.

## Data source
adsb.lol OpenAPI, `/v2/point/51.13/-114.01/250`, polled every 5 s. Polled REST, not a stream. Keyless today; rate limits/API key may arrive. The client must handle 429 with exponential backoff + jitter and expose backoff state as a metric. Provider-agnostic (airplanes.live shares the schema). See ADR 0002. ODbL attribution in README.

## SLO design (finalized in [ADR 0004](docs/adr/0004-slo-targets.md))
- Freshness (time-based): minutes where newest stored snapshot < 30 s old. Target 99% / 30 d.
- Ingest success: polls fetched+parsed+stored / polls excluding upstream 429/5xx. 99%.
- Query latency: API reads < 250 ms / all reads. 99%. Use native histograms.
- adsb.lol dependency SLI: measured and dashboarded, **not** budgeted against us.
- Burn-rate alerts via Sloth (14.4×/1h page, 6×/6h page, 1×/3d ticket), Alertmanager → ntfy.
- Error-budget deploy gate sits between "image published" and "manifest updated" (Flux image automation).

## Roadmap
1. Foundation: k3s, Flux, SOPS/age, Tailscale, rebuild drill (measured RTO in `docs/runbooks/rebuild.md`).
2. Ingest service: Python, OTel SDK from the first commit, Postgres, small query API.
3. Telemetry: OTel Collector hub → Prometheus 3 (OTLP receiver, native histograms), Loki, Tempo, Grafana with dashboards as code. Author has prior OTel collector experience — keep this phase brief; consider a Collector processor that drops noisy telemetry with a before/after cost number.
4. SLOs, burn-rate alerts, error-budget deploy gate.
5. Chaos Mesh game days (pod kill, DB failure, latency injection) + blameless postmortems in `docs/postmortems/`.

## Out of scope for this repo
An AI incident-response agent is planned as a **separate, independent repo**. This platform must not know it exists: the agent integrates only through standard interfaces (Alertmanager webhook, Prometheus/Loki/Tempo APIs, Git). Do not add agent code, hooks, or coupling here. Game-day incidents should be captured in a form the agent repo can later replay as fixtures.

## Working style
- Explain the reasoning behind non-obvious choices; the author will be asked about them in interviews.
- Prefer small, reviewable commits with clear messages.
- Update `docs/build-log.md` at the end of each working session (author's voice, short, dated, link ADRs).
