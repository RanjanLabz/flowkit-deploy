# FlowKit Orchestrator — Standalone Render Deployment

## Quick Deploy

1. Create a new GitHub repo with this structure:

```
your-orchestrator-repo/
├── render.yaml
├── Dockerfile
├── main.py
├── config/
└── requirements.txt
```

2. Copy files from `flowkit-deploy/orchestrator-only/` into your repo
3. Also copy `main.py`, `config/`, `requirements.txt` from `flowkit-global-orchestrator/`
4. Push to GitHub
5. render.com → New → Blueprint → select your repo
6. Set env vars → Deploy

## Env Vars

| Variable | Required | Description |
|----------|----------|-------------|
| `ORCHESTRATOR_REDIS_URL` | Yes | Redis connection (Upstash free tier) |
| `ORCHESTRATOR_API_KEY` | Yes | Random secret for API auth |
| `WORKER_API_KEY` | Yes | Shared key workers use to connect |
| `MONGODB_URI` | Yes | MongoDB Atlas free tier |
| `MONGODB_DATABASE` | No | Database name (default: flowkit_orchestrator) |

## After Deploy

Your orchestrator URL will be: `https://your-orchestrator.onrender.com`

Test:
- Health: `https://your-orchestrator.onrender.com/health`
- Workers: `https://your-orchestrator.onrender.com/workers`

Register a worker:
```bash
curl -X POST https://your-orchestrator.onrender.com/workers \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: YOUR_API_KEY' \
  -d '{
    "id": "render-worker-1",
    "base_url": "https://your-worker.onrender.com",
    "enabled": true,
    "max_jobs": 10,
    "weight": 100
  }'
```
