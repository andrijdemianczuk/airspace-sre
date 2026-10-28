# Build log

A dated engineering journal: what I tried, what broke, what I decided. Decisions with lasting consequences live in `docs/adr/`; this log links to them rather than repeating them.

---

## 2026-10-26 — Scoping and foundation

**Goal:** get back into SRE practice after ~7 years in presales, with a public project that shows judgment rather than just a running stack.

**Decided**
- Single-node k3s on the Beelink SER3, reconciled by Flux, secrets via SOPS/age. Talos was the more modern option, but its learning curve would eat time better spent on SLOs and incident practice. → [ADR 0001](adr/0001-k3s-single-node.md)
- adsb.lol as the data source. Free sources are polled REST, not streams, and limits may tighten — so the upstream is modelled as a dependency with its own SLI, separate from what I control. → [ADR 0002](adr/0002-adsb-data-source.md)
- Development on the MacBook (M1, ARM), deployment on the Beelink (x86). Images will be built by GitHub Actions, never locally. ADR to follow.
- The planned AI incident agent will be a separate repo, coupled only through standard interfaces.

**Done**
- Repo scaffold: bootstrap scripts, Flux layout, two ADRs, rebuild runbook. Pushed to GitHub.

**Tripped on**
- `git push` rejected my password. GitHub has required tokens or SSH for Git operations since 2021. Fixed with `gh auth login` + `gh auth setup-git`.

**Next**
- Apply the pending edits listed in `CLAUDE.md`, then run bootstrap on the Beelink and time the first rebuild drill.

---

## 2026-10-26 — Bootstrap fixes, round one

**Done**
- Added `.gitignore` for `.idea/` and untracked the IDE file that slipped into the first commit.
- `01-install-k3s.sh`: `tls-san` for `beelink` and the Tailscale MagicDNS name, so kubectl from the Mac passes cert validation over the tailnet. The FQDN is read from `tailscale status` at install time, which keeps my tailnet name out of a public repo — and means `tailscale up` must happen before k3s.
- `02-flux-bootstrap.sh`: image reflector/automation controllers and a read-write deploy key. Flux will commit new image tags back to Git; that write-back is where the error-budget deploy gate goes.

**Noted**
- `.sops.yaml` still has a placeholder recipient. Fill it in from the public key 02 prints on first run, before encrypting anything.

**Next**
- Image build workflow (amd64 → GHCR, SHA tags), ADR 0003 (build once), ADR 0004 (SLOs). None need the Beelink.
- Then run bootstrap on the box for the first time.

---

## 2026-10-27 — Closed out the planning backlog

**Done**
- [ADR 0003](adr/0003-build-once-decouple.md): build-once / decouple dev (Mac, ARM) from deploy (Beelink, amd64). GitHub Actions is the only place images get built; no `:latest` tags.
- [ADR 0004](adr/0004-slo-targets.md): finalized SLO targets — 99%/30d on freshness, ingest success, and query latency; adsb.lol dependency SLI tracked but not budgeted; Sloth burn-rate windows (14.4×/1h, 6×/6h, 1×/3d); error-budget gate sits between image publish and Flux's manifest commit.
- `.github/workflows/build-image.yml`: builds `linux/amd64`, pushes to GHCR, tags by git SHA. Scoped to trigger on changes under `apps/ingest/` — that path doesn't exist yet (phase 2), so the workflow is dormant until the ingest service lands.
- Cleared the "pending edits" backlog out of `CLAUDE.md` now that all three items are done.

**Next**
- Fill in the real age recipient in `.sops.yaml` (still a placeholder), then run `00`/`01`/`02` on the Beelink for the first time and time the rebuild drill.
- After that: phase 2, the Python ingest service — client against adsb.lol with backoff/jitter on 429, OTel instrumentation from the first commit, Postgres storage.
