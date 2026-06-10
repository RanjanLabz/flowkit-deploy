#!/bin/bash
set -e

# Start nginx
nginx &

# Start noVNC (websockify)
cd /opt/noVNC
./utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Start worker
cd /worker
python -m uvicorn server:app --host 0.0.0.0 --port 8080
