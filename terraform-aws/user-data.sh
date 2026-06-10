#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

APP_DIR="${app_dir}"
REPO_URL="${repo_url}"
BRANCH="${repo_branch}"
WORKER_ID="${worker_id}"
ORCHESTRATOR_URL="${orchestrator_url}"
ORCHESTRATOR_API_KEY="${orchestrator_api_key}"
REDIS_URL="${redis_url}"
VNC_PASSWORD="${vnc_password}"
WORKER_API_KEY="$(openssl rand -hex 16)"
FLOWKIT_REPO="https://github.com/crisng95/flowkit.git"

log() { echo "[flowkit] $*"; }

# Install Docker
log "Installing Docker..."
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg git >/dev/null
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
systemctl enable --now docker

# Clone repo
log "Cloning worker repo..."
mkdir -p "$APP_DIR"
git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
mkdir -p "$APP_DIR/worker/accounts" "$APP_DIR/worker/logs" "$APP_DIR/chrome-profiles" "$APP_DIR/extension"

# Install FlowKit extension
log "Installing FlowKit extension..."
tmp="$(mktemp -d)"
git clone --depth 1 "$FLOWKIT_REPO" "$tmp" 2>/dev/null || true
if [ -d "$tmp/extension" ]; then
  rm -rf "$APP_DIR/extension"
  mkdir -p "$APP_DIR/extension"
  cp -a "$tmp/extension/." "$APP_DIR/extension/"
fi
rm -rf "$tmp"

# Write env
cat > "$APP_DIR/.env" <<EOF
REDIS_URL=$REDIS_URL
WORKER_API_KEY=$WORKER_API_KEY
VNC_PASSWORD=$VNC_PASSWORD
WORKER_ID=$WORKER_ID
EOF

# Build and start
cd "$APP_DIR"
docker compose build
docker compose up -d

# Systemd
cat > /etc/systemd/system/flow-worker.service <<EOF
[Unit]
Description=FlowKit Worker
Requires=docker.service
After=docker.service
[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable flow-worker.service

# Register with orchestrator
if [ -n "$ORCHESTRATOR_URL" ]; then
  PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || hostname -I | awk '{print $1}')
  curl -s -X POST "$ORCHESTRATOR_URL/workers" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ORCHESTRATOR_API_KEY" \
    -d "{\"id\":\"$WORKER_ID\",\"base_url\":\"http://$PUBLIC_IP:8080\",\"enabled\":true,\"max_jobs\":10,\"weight\":100}" || true
fi

log "Done! Worker running on port 8080"
