# FlowKit Worker — Standalone Render Deployment

## Quick Deploy

All files are already in this folder. Just:

1. Create a new GitHub repo
2. Copy everything from `flowkit-deploy/worker-only/` into it
3. Push to GitHub
4. render.com → New → Blueprint → select your repo
5. Set env vars → Deploy

## Env Vars

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_URL` | Yes | Redis connection (Upstash free tier works) |
| `WORKER_API_KEY` | Yes | Shared key with orchestrator |
| `ORCHESTRATOR_URL` | No | Your orchestrator URL (auto-registers) |
| `ORCHESTRATOR_API_KEY` | No | For auto-registration |
| `WORKER_ID` | No | Worker identifier (default: render-worker-1) |
| `VNC_PASSWORD` | No | VNC viewer password |

## After Deploy

Your worker URL will be: `https://your-worker.onrender.com`

Test:
- Health: `https://your-worker.onrender.com/health`
- VNC: `https://your-worker.onrender.com/vnc/`
- API docs: `https://your-worker.onrender.com/docs`
