#!/usr/bin/env bash
# ============================================================================
# FlowKit Worker — One-Click Installer
# Works on: Ubuntu 22.04+, Debian 12+, Oracle Linux 9+, Amazon Linux 2023
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/RanjanLabz/flowkit-vps-worker/main/install.sh | bash
#
# With orchestrator registration:
#   ORCHESTRATOR_URL="https://your-orchestrator.onrender.com" \
#   ORCHESTRATOR_API_KEY="your-key" \
#   curl -fsSL https://raw.githubusercontent.com/RanjanLabz/flowkit-vps-worker/main/install.sh | bash
# ============================================================================

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
APP_DIR="${APP_DIR:-/opt/flow-worker}"
REPO_URL="${REPO_URL:-https://github.com/RanjanLabz/flowkit-vps-worker.git}"
BRANCH="${BRANCH:-main}"
WORKER_ID="${WORKER_ID:-$(hostname)-worker}"
WORKER_PUBLIC_URL="${WORKER_PUBLIC_URL:-}"
ORCHESTRATOR_URL="${ORCHESTRATOR_URL:-}"
ORCHESTRATOR_API_KEY="${ORCHESTRATOR_API_KEY:-}"
REDIS_URL="${REDIS_URL:-}"
VNC_PASSWORD="${VNC_PASSWORD:-}"
WORKER_API_KEY="${WORKER_API_KEY:-$(openssl rand -hex 16 2>/dev/null || head -c 32 /dev/urandom | base64)}"
FLOWKIT_REPO="${FLOWKIT_REPO:-https://github.com/crisng95/flowkit.git}"

log()  { printf "\033[1;32m[flowkit]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[flowkit]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[flowkit]\033[0m %s\n" "$*" >&2; exit 1; }

# ── Detect OS ───────────────────────────────────────────────────────────────
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID}"
    OS_VERSION="${VERSION_ID}"
  else
    err "Cannot detect OS. Requires Ubuntu, Debian, or Oracle Linux."
  fi

  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64)   CHROME_PKG="google-chrome-stable"; DOCKER_ARCH="amd64" ;;
    aarch64|arm64)  CHROME_PKG="chromium";              DOCKER_ARCH="arm64" ;;
    *)              err "Unsupported architecture: $ARCH" ;;
  esac

  log "Detected: $OS_ID $OS_VERSION ($ARCH)"
}

# ── Install Docker ─────────────────────────────────────────────────────────
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
    return
  fi

  log "Installing Docker..."
  export DEBIAN_FRONTEND=noninteractive

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg git >/dev/null
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  elif command -v yum >/dev/null 2>&1; then
    yum install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  systemctl enable --now docker
  log "Docker installed: $(docker --version)"
}

# ── Clone / Update Repo ────────────────────────────────────────────────────
sync_repo() {
  log "Syncing worker repo..."
  mkdir -p "$APP_DIR"
  if [ -d "$APP_DIR/.git" ]; then
    git -C "$APP_DIR" fetch origin "$BRANCH"
    git -C "$APP_DIR" checkout "$BRANCH"
    git -C "$APP_DIR" pull --ff-only origin "$BRANCH"
  else
    git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
  fi
}

# ── ARM Chromium Patch ─────────────────────────────────────────────────────
patch_arm() {
  if [ "$ARCH" = "x86_64" ]; then
    return
  fi

  warn "ARM detected — switching to Chromium (no Google Chrome for ARM)"
  sed -i 's/chrome_binary: "google-chrome"/chrome_binary: "chromium"/' "$APP_DIR/config/worker.yaml"

  cat > "$APP_DIR/docker/Dockerfile" <<'DOCKERFILE'
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git gnupg \
    xvfb fluxbox x11vnc \
    fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 \
    libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 \
    libnspr4 libnss3 libxcomposite1 libxdamage1 libxfixes3 \
    libxkbcommon0 libxrandr2 xdg-utils chromium \
    && ln -sf /usr/bin/chromium /usr/bin/google-chrome \
    && pip install --no-cache-dir websockify \
    && git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY worker /app/worker
COPY config /worker/config

RUN mkdir -p /worker/accounts /worker/logs /chrome-profiles /extension

EXPOSE 8080 5901-5999 9222-9722 12000-12500

CMD ["uvicorn", "worker.api.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
DOCKERFILE
}

# ── Install FlowKit Extension ───────────────────────────────────────────────
install_flowkit_ext() {
  log "Setting up FlowKit extension..."
  mkdir -p "$APP_DIR/worker/accounts" "$APP_DIR/worker/logs" "$APP_DIR/chrome-profiles" "$APP_DIR/extension" "$APP_DIR/config"

  if [ ! -f "$APP_DIR/extension/manifest.json" ] || ! grep -q "Flow Kit" "$APP_DIR/extension/manifest.json" 2>/dev/null; then
    tmp_dir="$(mktemp -d)"
    git clone --depth 1 "$FLOWKIT_REPO" "$tmp_dir" 2>/dev/null || true
    if [ -d "$tmp_dir/extension" ]; then
      rm -rf "$APP_DIR/extension"
      mkdir -p "$APP_DIR/extension"
      cp -a "$tmp_dir/extension/." "$APP_DIR/extension/"
    fi
    rm -rf "$tmp_dir"
  fi
}

# ── Generate docker-compose.yml ─────────────────────────────────────────────
write_compose() {
  cat > "$APP_DIR/docker-compose.yml" <<'COMPOSE'
services:
  worker:
    build:
      context: .
      dockerfile: docker/Dockerfile
    restart: unless-stopped
    network_mode: host
    environment:
      WORKER_CONFIG: /worker/config/worker.yaml
      REDIS_URL: ${REDIS_URL:?REDIS_URL required}
      WORKER_API_KEY: ${WORKER_API_KEY:-}
      WORKER_ALLOW_PUBLIC_HEALTH: "true"
      WORKER_ALLOW_PUBLIC_DOCS: "false"
      VNC_PASSWORD: ${VNC_PASSWORD:-}
    shm_size: "1gb"
    volumes:
      - ./config:/worker/config
      - ./worker/accounts:/worker/accounts
      - ./worker/logs:/worker/logs
      - ./chrome-profiles:/chrome-profiles
      - ./extension:/extension
COMPOSE
}

# ── Write .env ──────────────────────────────────────────────────────────────
write_env() {
  log "Writing .env..."
  cat > "$APP_DIR/.env" <<EOF
REDIS_URL=${REDIS_URL}
WORKER_API_KEY=${WORKER_API_KEY}
VNC_PASSWORD=${VNC_PASSWORD}
WORKER_ID=${WORKER_ID}
EOF
}

# ── Auto-register with Orchestrator ─────────────────────────────────────────
register_with_orchestrator() {
  if [ -z "$ORCHESTRATOR_URL" ]; then
    return
  fi

  log "Registering with orchestrator at $ORCHESTRATOR_URL..."

  # Detect public IP
  local public_ip
  public_ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || \
              curl -s --max-time 5 https://ifconfig.me 2>/dev/null || \
              hostname -I | awk '{print $1}')

  local worker_url="${WORKER_PUBLIC_URL:-http://${public_ip}:8080}"
  local api_key_header=""
  if [ -n "$ORCHESTRATOR_API_KEY" ]; then
    api_key_header="-H 'x-api-key: ${ORCHESTRATOR_API_KEY}'"
  fi

  eval curl -s -X POST "${ORCHESTRATOR_URL}/workers" \
    -H "'Content-Type: application/json'" \
    $api_key_header \
    -d "'{\"id\":\"${WORKER_ID}\",\"base_url\":\"${worker_url}\",\"enabled\":true,\"max_jobs\":10,\"weight\":100}'"

  log "Registered with orchestrator: $worker_url"
}

# ── Build & Start ───────────────────────────────────────────────────────────
start_worker() {
  cd "$APP_DIR"

  log "Building Docker image..."
  docker compose build

  log "Starting worker..."
  docker compose up -d

  # Firewall rules
  if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=6080-6579/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=5901-5999/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=9222-9722/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
  fi

  # Systemd auto-restart
  cat > /etc/systemd/system/flow-worker.service <<EOF
[Unit]
Description=FlowKit Worker
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable flow-worker.service 2>/dev/null || true
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  log "=========================================="
  log "  FlowKit Worker — One-Click Installer"
  log "=========================================="

  detect_os
  install_docker
  sync_repo
  patch_arm
  install_flowkit_ext
  write_compose
  write_env
  start_worker
  register_with_orchestrator

  local public_ip
  public_ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

  echo ""
  log "=========================================="
  log "  Installation Complete!"
  log "=========================================="
  log ""
  log "  Worker API:    http://${public_ip}:8080"
  log "  Health Check:  http://${public_ip}:8080/health"
  log "  API Docs:      http://${public_ip}:8080/docs"
  log "  VNC (debug):   http://${public_ip}:6080+"
  log ""
  log "  Worker ID:     ${WORKER_ID}"
  log "  App Dir:       ${APP_DIR}"
  log ""
  log "  To update: cd ${APP_DIR} && bash ./scripts/update.sh"
  log "=========================================="
}

main "$@"
