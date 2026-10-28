# ADR 0003: Build once — decouple the development platform from the deployment platform

**Status:** Accepted, 2026-10-27

## Context
Development happens on a MacBook Pro M1 Pro (ARM64). The deployment target is the Beelink SER3 (x86_64). Container images built on the Mac would be `linux/arm64` by default; the cluster needs `linux/amd64`. Building natively on the Beelink is possible but spends its only two cores on compilation instead of the workloads it's there to run, and ties image provenance to whichever machine happened to run the build.

## Options
- **Cross-compile locally with `docker buildx --platform linux/amd64`, push from the Mac.** Works, but makes "what got deployed" a function of the author's laptop state (local Docker version, logged-in registry session, uncommitted Dockerfile edits). No audit trail beyond shell history.
- **Build on the Beelink itself.** Wastes CPU on the one box that's supposed to be running the service, and still ties builds to a single machine's availability.
- **Build once in CI (GitHub Actions), push to a registry, tag by git SHA.** The build is reproducible from any clean checkout, runs on infrastructure not shared with the service, and produces an immutable artifact Flux can reference by digest/tag.

## Decision
GitHub Actions builds `linux/amd64` images on every push to `main` that touches `apps/`, pushes to GHCR, and tags with the git SHA. No image is ever built on the Mac or the Beelink. No manifest ever references `:latest`.

## Consequences
- Development (ARM, interactive, fast iteration) is fully decoupled from deployment (amd64, declarative, Flux-reconciled). The Mac never needs Docker configured for the target architecture.
- Every running image traces back to exactly one commit via its SHA tag — required for the error-budget deploy gate (ADR 0004) to mean anything: the gate approves or blocks a specific, reproducible artifact, not "whatever's in the registry right now."
- Flux's image reflector/automation controllers (bootstrapped in `02-flux-bootstrap.sh`) watch GHCR for new SHA tags and commit the update back to Git — so "build once" extends to "deploy via the same Git history," not a separate `kubectl set image`.
- CI becomes a dependency for shipping any change to `apps/`. Acceptable: a single-node homelab cluster with an offline build pipeline is a worse failure mode than a slower one.
- Build attestations/provenance (SLSA-style) are deferred — noted as a follow-up once the pipeline exists, not a blocker to standing it up.
