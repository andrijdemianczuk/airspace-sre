#!/usr/bin/env bash
# Host preparation for the Beelink SER3 (Ryzen 3 3200U, 2C/4T, 16GB, Ubuntu).
# Idempotent: safe to re-run. Run as a sudo-capable user, not as root.
set -euo pipefail

echo "==> Base packages"
sudo apt-get update -y
sudo apt-get install -y curl git jq unzip ca-certificates gnupg

echo "==> Kernel limits for log/trace collectors (Loki, Alloy, Tempo watch many files)"
sudo tee /etc/sysctl.d/90-observability.conf >/dev/null <<'EOF'
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches   = 1048576
vm.max_map_count              = 262144
EOF
sudo sysctl --system >/dev/null

echo "==> Flux CLI"
if ! command -v flux >/dev/null; then
  curl -s https://fluxcd.io/install.sh | sudo bash
fi

echo "==> age + SOPS (secrets encrypted in Git)"
sudo apt-get install -y age
if ! command -v sops >/dev/null; then
  SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name)
  curl -fsSLo /tmp/sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"
  sudo install -m 0755 /tmp/sops /usr/local/bin/sops
fi

echo "==> Helm (for local chart inspection; Flux does the real installs)"
if ! command -v helm >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "==> Tailscale (reach the box from anywhere; lives outside the cluster on purpose)"
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
echo "    Run 'sudo tailscale up' once to authenticate this node."

echo "==> Done. Versions:"
flux --version; sops --version | head -1; age --version; helm version --short
