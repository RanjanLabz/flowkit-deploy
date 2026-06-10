# FlowKit — Deployment Guide

## Table of Contents

- [Deploy on Render](#deploy-on-render)
  - [Option A: Worker Only](#option-a-worker-only)
  - [Option B: Orchestrator Only](#option-b-orchestrator-only)
  - [Option C: Both Together](#option-c-both-together)
- [Deploy on Any VPS](#deploy-on-any-vps)
- [Deploy via Terraform](#deploy-via-terraform)
- [Usage Guide](#usage-guide)
- [API Reference](#api-reference)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

---

## Deploy on Render

**Quick link:** Use [`flowkit-render-worker`](https://github.com/RanjanLabz/flowkit-render-worker) repo — has everything pre-packed for Render deployment.

### Option A: Worker Only

**Use this if:** You already have an orchestrator running elsewhere and just want to add a Render-based worker.

**Step 1:** Create a new GitHub repo with this structure:

```
your-worker-repo/
├── render.yaml
├── Dockerfile
├── nginx-render.conf
├── start.sh
├── worker/
├── config/
├── extension/
└── requirements.txt
```

Copy `render-free.yaml` or `render-paid.yaml`, `Dockerfile`, `nginx-render.conf`, `start.sh` from `flowkit-deploy/worker-only/`.
Copy `worker/`, `config/`, `extension/`, `requirements.txt` from `flowkit-vps-worker/`.

**Step 2:** Push to GitHub

**Step 3:** render.com → **New** → **Blueprint** → select your repo

**Step 4:** Set **Blueprint Path** based on your plan:

| Plan | Blueprint Path | Cost |
|------|---------------|------|
| Free (spins down after 15 min idle) | `worker-only/render-free.yaml` | $0/month |
| Paid (always on, no spin-down) | `worker-only/render-paid.yaml` | $25/month |

**Step 5:** Set env vars:

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_URL` | Yes | Redis connection (Upstash free tier) |
| `WORKER_API_KEY` | Yes | Shared key with your orchestrator |
| `ORCHESTRATOR_URL` | No | Your orchestrator URL (auto-registers) |
| `ORCHESTRATOR_API_KEY` | No | For auto-registration |
| `WORKER_ID` | No | Worker name (default: render-worker-1) |
| `VNC_PASSWORD` | No | VNC viewer password |

**Step 6:** Deploy

**Step 7:** Register with your orchestrator:

```bash
curl -X POST https://your-orchestrator.onrender.com/workers \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: YOUR_ORCHESTRATOR_API_KEY' \
  -d '{
    "id": "render-worker-1",
    "base_url": "https://your-worker.onrender.com",
    "enabled": true,
    "max_jobs": 10,
    "weight": 100
  }'
```

**Your worker URL:** `https://your-worker.onrender.com`

---

### Option B: Orchestrator Only

**Use this if:** You already have workers running on VPS and just need the orchestrator on Render.

**Step 1:** Create a new GitHub repo with this structure:

```
your-orchestrator-repo/
├── render.yaml
├── Dockerfile
├── main.py
├── config/
└── requirements.txt
```

Copy `render.yaml`, `Dockerfile` from `flowkit-deploy/orchestrator-only/`.
Copy `main.py`, `config/`, `requirements.txt` from `flowkit-global-orchestrator/`.

**Step 2:** Push to GitHub

**Step 3:** render.com → **New** → **Blueprint** → select your repo

**Step 4:** Set env vars:

| Variable | Required | Description |
|----------|----------|-------------|
| `ORCHESTRATOR_REDIS_URL` | Yes | Redis connection (Upstash free tier) |
| `ORCHESTRATOR_API_KEY` | Yes | Random secret for API auth |
| `WORKER_API_KEY` | Yes | Shared key workers use to connect |
| `MONGODB_URI` | Yes | MongoDB Atlas free tier |
| `MONGODB_DATABASE` | No | Database name (default: flowkit_orchestrator) |

**Step 5:** Deploy

**Step 6:** Register your workers:

```bash
curl -X POST https://your-orchestrator.onrender.com/workers \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: YOUR_API_KEY' \
  -d '{
    "id": "vps-worker-1",
    "base_url": "http://YOUR_VPS_IP:8080",
    "enabled": true,
    "max_jobs": 10,
    "weight": 100
  }'
```

**Your orchestrator URL:** `https://your-orchestrator.onrender.com`

---

### Option C: Both Together

**Use this if:** You want orchestrator + worker both on Render, fully managed.

**Step 1:** Create a new GitHub repo with this structure:

```
your-flowkit-repo/
├── render.yaml
├── docker/
│   ├── orchestrator.Dockerfile
│   └── render-worker.Dockerfile
├── nginx-render.conf
├── orchestrator/
├── worker/
├── config/
├── extension/
└── requirements.txt
```

Copy everything from `flowkit-deploy/` except `worker-only/` and `orchestrator-only/`.
Copy `orchestrator/` from `flowkit-global-orchestrator/`.
Copy `worker/`, `config/`, `extension/`, `requirements.txt` from `flowkit-vps-worker/`.

**Step 2:** Push to GitHub

**Step 3:** render.com → **New** → **Blueprint** → select your repo

**Step 4:** Render creates 2 services automatically:

| Service | What it does |
|---------|-------------|
| `flowkit-orchestrator` | Job scheduler, finds healthy workers |
| `flowkit-worker` | Chrome + VNC + FlowKit, runs the jobs |

**Step 5:** Set env vars for BOTH services in Render dashboard

**Step 6:** Deploy — both start together

---

## Deploy on Any VPS

Works on Ubuntu 22.04+, Debian 12+, Oracle Linux 9+.

```bash
# SSH into your VPS, then run:
REDIS_URL="redis://default:password@your-redis:6379" \
ORCHESTRATOR_URL="https://your-orchestrator.onrender.com" \
ORCHESTRATOR_API_KEY="your-key" \
WORKER_ID="my-worker-1" \
curl -fsSL https://raw.githubusercontent.com/RanjanLabz/flowkit-vps-worker/main/install.sh | bash
```

After install:
- **Worker API:** `http://YOUR_IP:8080`
- **VNC viewer:** `http://YOUR_IP:6080`
- **Health:** `http://YOUR_IP:8080/health`

---

## Deploy via Terraform

### AWS

```bash
cd terraform-aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform plan && terraform apply
```

### GCP

```bash
cd terraform-gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform plan && terraform apply
```

### Oracle Cloud

```bash
cd ../flowkit-oci-terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform plan && terraform apply
```

---

## Usage Guide

### Health Check

```bash
curl http://localhost:8080/health
```

### Create Account

```bash
curl -X POST http://localhost:8080/accounts \
  -H 'Content-Type: application/json' \
  -d '{"id": "acc-1", "proxy_enabled": false}'
```

### Start Account

```bash
curl -X POST http://localhost:8080/accounts/acc-1/start
```

### Sign in to Google via VNC

1. Open `http://YOUR_IP:6080` (VPS) or `https://your-worker.onrender.com/vnc/` (Render)
2. You see a Chrome window
3. Navigate to `labs.google`
4. Sign in with your Google account
5. Session persists in Chrome profile

### Submit Generation Jobs

**Text to Image:**
```bash
curl -X POST http://localhost:8090/generate/text-to-image \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: your-api-key' \
  -d '{"prompt": "a sunset over mountains, digital art"}'
```

**Text to Video:**
```bash
curl -X POST http://localhost:8090/generate/text-to-video \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: your-api-key' \
  -d '{"prompt": "cinematic Tokyo rain street", "aspect_ratio": "16:9"}'
```

**Image to Image:**
```bash
curl -X POST http://localhost:8090/generate/image-to-image \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: your-api-key' \
  -d '{
    "prompt": "make it cyberpunk",
    "inputs": {"image_url": "https://example.com/photo.jpg"}
  }'
```

### Check Jobs

```bash
curl http://localhost:8090/jobs?limit=10 \
  -H 'x-api-key: your-api-key'
```

### Manage Accounts

```bash
# List accounts
curl http://localhost:8080/accounts

# Start/stop/restart
curl -X POST http://localhost:8080/accounts/acc-1/start
curl -X POST http://localhost:8080/accounts/acc-1/stop
curl -X POST http://localhost:8080/accounts/acc-1/restart

# Delete
curl -X DELETE http://localhost:8080/accounts/acc-1?remove_profile=true
```

---

## API Reference

### Worker API (port 8080)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Worker health |
| GET | `/accounts` | List accounts |
| POST | `/accounts` | Create account |
| POST | `/accounts/{id}/start` | Start account |
| POST | `/accounts/{id}/stop` | Stop account |
| POST | `/accounts/{id}/restart` | Restart account |
| POST | `/accounts/{id}/recover` | Recover account |
| PATCH | `/accounts/{id}/settings` | Update settings |
| DELETE | `/accounts/{id}` | Delete account |
| GET | `/docs` | Swagger UI |

### Orchestrator API (port 8090)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/workers` | List workers |
| POST | `/workers` | Register worker |
| DELETE | `/workers/{id}` | Remove worker |
| GET | `/jobs` | List jobs |
| POST | `/generate/text-to-image` | Generate image |
| POST | `/generate/text-to-video` | Generate video |
| POST | `/generate/image-to-image` | Edit image |
| POST | `/generate/image-to-video` | Animate image |

---

## Environment Variables

### Worker

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_URL` | Yes | Redis connection string |
| `WORKER_API_KEY` | No | API auth key |
| `VNC_PASSWORD` | No | VNC password |
| `WORKER_ID` | No | Worker identifier |
| `ORCHESTRATOR_URL` | No | Auto-register on startup |
| `ORCHESTRATOR_API_KEY` | No | Orchestrator auth |

### Orchestrator

| Variable | Required | Description |
|----------|----------|-------------|
| `ORCHESTRATOR_REDIS_URL` | Yes | Redis connection |
| `ORCHESTRATOR_API_KEY` | Yes | API auth key |
| `MONGODB_URI` | Yes | MongoDB connection |
| `WORKER_API_KEY` | No | Trusted worker key |

---

## Troubleshooting

**Worker won't start:**
```bash
docker compose logs -f worker
```

**Account stuck BROKEN_SESSION:**
```bash
curl -X POST http://localhost:8080/accounts/acc-1/restart
```

**Jobs stuck QUEUED:**
- Check worker is online: `curl http://localhost:8090/workers`
- Check accounts exist: `curl http://localhost:8080/accounts`
- Worker needs READY accounts with free slots

**VNC black screen:**
- Restart account: `curl -X POST http://localhost:8080/accounts/acc-1/restart`
- Check Chrome: `ps aux | grep chrome`

**Google login required:**
- Open VNC and sign in manually

**Render VNC not working:**
- Make sure you're using `render-worker.Dockerfile` (has nginx)
- Check Render logs for nginx errors
