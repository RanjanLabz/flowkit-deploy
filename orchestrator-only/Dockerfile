FROM python:3.11-slim

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy orchestrator code
COPY main.py .
COPY config/ /app/config/

# Create logs dir
RUN mkdir -p /tmp/orchestrator/logs

EXPOSE 8090

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8090"]
