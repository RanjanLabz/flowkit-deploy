FROM python:3.11-slim

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg2 curl unzip nginx git \
    xvfb x11vnc fluxbox \
    fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 \
    libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 \
    libnss3 libxcomposite1 libxdamage1 libxrandr2 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC + websockify
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify

# Install Python deps
COPY worker-only/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy nginx config
COPY worker-only/nginx-render.conf /etc/nginx/nginx.conf

# Copy extension + worker + config
COPY worker-only/extension/ /extension/
COPY worker-only/worker/ /worker/
COPY worker-only/config/ /worker/config/

# Create dirs
RUN mkdir -p /chrome-profiles /worker/accounts /worker/logs

# Start script
COPY worker-only/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
