#!/usr/bin/env bash
# Bootstrap Flux against this repo and load the SOPS age key into the cluster.
# Requires: GITHUB_TOKEN (fine-grained PAT: this repo, Contents + Administration RW)
#           GITHUB_USER
set -euo pipefail
: "${GITHUB_TOKEN:?export GITHUB_TOKEN first}"
: "${GITHUB_USER:?export GITHUB_USER first}"

REPO="${REPO:-airspace-sre}"
AGE_KEY="${AGE_KEY:-$HOME/.config/sops/age/keys.txt}"

# The age private key is the ONE thing that cannot live in Git.
# First run: generate it and back it up off-box (password manager).
# Rebuild runs: restore it to $AGE_KEY before running this script.
if [[ ! -f "$AGE_KEY" ]]; then
  mkdir -p "$(dirname "$AGE_KEY")"
  age-keygen -o "$AGE_KEY"
  echo
  echo "!! New age key generated at $AGE_KEY"
  echo "!! Back it up NOW. Public key (put this in .sops.yaml):"
  grep '^# public key' "$AGE_KEY"
  echo
fi

flux check --pre

flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository="$REPO" \
  --branch=main \
  --path=clusters/beelink \
  --personal

kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$AGE_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

flux reconcile kustomization flux-system --with-source
flux get kustomizations
