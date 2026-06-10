#!/bin/bash
set -e

# Start Xvfb (virtual display)
Xvfb :99 -screen 0 1920x1080x24 -ac &
export DISPLAY=:99

# Wait for display
sleep 2

# Start x11vnc (no auth needed in Docker)
x11vnc -display :99 -forever -nopw -rfbport 5900 -noxdamage -shared &

# Wait for VNC
sleep 2

# Start nginx
nginx &

# Start noVNC (websockify)
cd /opt/noVNC
./utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Start worker
export PYTHONPATH=/worker
cd /
python -m uvicorn api.main:app --host 0.0.0.0 --port 8080
