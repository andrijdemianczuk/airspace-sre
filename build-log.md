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
