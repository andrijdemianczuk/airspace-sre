#!/usr/bin/env bash
# Install single-node k3s with control-plane metrics exposed for Prometheus.
set -euo pipefail

# The API server cert must name the hosts kubectl dials from the Mac.
# Read the MagicDNS name at runtime so the tailnet name never lands in Git.
TS_FQDN=$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' | sed 's/\.$//')
if [[ -z "$TS_FQDN" ]]; then
  echo "Tailscale is not up. Run 'sudo tailscale up' first (see 00-host-prep.sh)." >&2
  exit 1
fi

sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF
# Single node, default SQLite (kine) datastore. See docs/adr/0001.
write-kubeconfig-mode: "0644"
node-name: beelink

# Extra SANs on the API server cert so kubectl from the Mac works over Tailscale.
tls-san:
  - "beelink"
  - "${TS_FQDN}"

# Expose control-plane metrics so Prometheus can scrape them.
# Safe here: the node is only reachable on the LAN and the tailnet.
kube-controller-manager-arg:
  - "bind-address=0.0.0.0"
kube-scheduler-arg:
  - "bind-address=0.0.0.0"
kube-proxy-arg:
  - "metrics-bind-address=0.0.0.0"

# Leave headroom for the OS on a 2-core box.
kubelet-arg:
  - "system-reserved=cpu=300m,memory=512Mi"
  - "kube-reserved=cpu=200m,memory=512Mi"
  - "eviction-hard=memory.available<500Mi,nodefs.available<10%"
EOF

curl -sfL https://get.k3s.io | sh -

mkdir -p "$HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

echo "==> Waiting for node Ready"
kubectl wait --for=condition=Ready node/beelink --timeout=180s
kubectl get nodes -o wide
