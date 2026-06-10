# FlowKit Worker — Standalone Render Deployment

## Quick Deploy

1. Create a new GitHub repo with this structure:

```
your-worker-repo/
├── render.yaml
├── Dockerfile
├── nginx-render.conf
├── worker/
├── config/
├── extension/
└── requirements.txt
```

2. Copy files from `flowkit-deploy/worker-only/` into your repo
3. Also copy `worker/`, `config/`, `extension/`, `requirements.txt` from `flowkit-vps-worker/`
4. Push to GitHub
5. render.com → New → Blueprint → select your repo
6. Set env vars → Deploy

## Env Vars

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_URL` | Yes | Redis connection (Upstash free tier works) |
| `WORKER_API_KEY` | Yes | Shared key with orchestrator |
| `ORCHESTRATOR_URL` | No | Auto-register on startup |
| `ORCHESTRATOR_API_KEY` | No | For auto-registration |
| `WORKER_ID` | No | Worker identifier (default: render-worker-1) |
| `VNC_PASSWORD` | No | VNC viewer password |

## After Deploy

Your worker URL will be: `https://your-worker.onrender.com`

Test:
- Health: `https://your-worker.onrender.com/health`
- VNC: `https://your-worker.onrender.com/vnc/`
- API docs: `https://your-worker.onrender.com/docs`
