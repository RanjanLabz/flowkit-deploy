#!/usr/bin/env bash
# FlowKit Worker — Update Script
# Run: cd /opt/flow-worker && sudo bash ./scripts/update.sh
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
log() { printf "\033[1;32m[flowkit]\033[0m %s\n" "$*"; }

log "Updating FlowKit Worker..."
cd "$APP_DIR"

git fetch origin
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git pull --ff-only origin "$BRANCH"

log "Rebuilding Docker image..."
docker compose build --no-cache

log "Restarting worker..."
docker compose up -d

log "Health check..."
sleep 5
curl -sf http://localhost:8080/health | python3 -m json.tool || warn "Health check failed"

log "Update complete!"
