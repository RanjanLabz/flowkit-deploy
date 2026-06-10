#!/bin/bash
set -e

# Clean up old lock files
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Start Xvfb (virtual display)
Xvfb :99 -screen 0 1920x1080x24 -ac &
export DISPLAY=:99

# Wait for display
sleep 2

# Start x11vnc (no auth needed in Docker)
x11vnc -display :99 -forever -nopw -rfbport 5900 -noxdamage -shared &

# Wait for VNC
sleep 2

# Render sets $PORT (default 10000)
PORT=${PORT:-10000}

# Start nginx on Render's port
sed -i "s/listen 80;/listen $PORT;/" /etc/nginx/nginx.conf
nginx &

# Start noVNC (websockify)
cd /opt/noVNC
./utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Start worker with global VNC mode (skip per-account Xvfb/x11vnc/noVNC)
export PYTHONPATH=/worker
export VNC_GLOBAL=1
cd /
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000
