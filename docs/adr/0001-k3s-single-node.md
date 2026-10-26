# ADR 0001: Single-node k3s on the SER3, managed by Flux

**Status:** Accepted, 2026-10-26

## Context
Hardware is a Beelink SER3: Ryzen 3 3200U (2 cores / 4 threads), 16 GB RAM, 500 GB SSD, Ubuntu. The project has to show SRE practice (SLOs, alerting, chaos, postmortems) within roughly two weeks. CPU, not RAM, is the binding constraint.

## Options
- **Talos Linux.** Immutable, API-only, no SSH. The strongest security and reproducibility story, but the learning curve would consume time better spent on reliability work, and it replaces the existing Ubuntu install.
- **k3s on Ubuntu.** Single binary, control plane in one process, sits on the OS already installed. Default SQLite datastore.
- **MicroK8s.** Familiar from earlier work, but snap-based and less common in current homelab/GitOps practice.

## Decision
k3s on Ubuntu, with every workload reconciled by Flux from this repository and secrets encrypted with SOPS/age.

## Consequences
- Reproducibility comes from GitOps rather than the OS: rebuild = reinstall k3s + run Flux bootstrap + restore one age key. Measured in `docs/runbooks/rebuild.md`.
- **No high availability.** One node means upgrades and host failures take everything down. SLO targets are set with this in mind and the error budget will reflect it honestly.
- SQLite is acceptable for one node; moving to embedded etcd would only matter with more control-plane nodes.
- Host-level drift (packages, sysctls) is managed by `bootstrap/00-host-prep.sh`, not Git reconciliation. Talos would close that gap and remains a candidate follow-up.
- Every workload gets explicit CPU requests and limits; the observability stack runs in monolithic/single-binary modes with modest retention.
