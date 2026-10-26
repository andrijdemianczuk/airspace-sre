# Runbook: rebuild the cluster from a clean slate

**Goal:** prove the whole platform is recoverable from Git plus one secret. Record time-to-recovery every run; it is this system's measured RTO.

## Prerequisites (off-box)
- age private key from the password manager
- GitHub fine-grained PAT for this repo

## Drill
```bash
# 0. Start the clock
date -u +%FT%TZ | tee /tmp/drill-start

# 1. Destroy
/usr/local/bin/k3s-uninstall.sh

# 2. Restore the age key
mkdir -p ~/.config/sops/age && $EDITOR ~/.config/sops/age/keys.txt

# 3. Rebuild
./bootstrap/01-install-k3s.sh
export GITHUB_TOKEN=... GITHUB_USER=...
./bootstrap/02-flux-bootstrap.sh

# 4. Wait for everything to converge, then stop the clock
flux get kustomizations --watch     # until all Ready=True
date -u +%FT%TZ
```

## What "recovered" means
All Flux Kustomizations Ready, all pods Running, and (once SLOs exist) the ingest freshness SLI back inside target.

## Known data loss
Postgres and observability data live on local PVCs and are destroyed by this drill. That is acceptable for this project and is stated explicitly; backups are a later chapter.

## Drill log
| Date | Time to recover | Notes |
|---|---|---|
| | | |
