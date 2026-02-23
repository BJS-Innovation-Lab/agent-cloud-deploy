# BJS Labs — Agent Cloud Deploy System

**Managed by:** Sybil (ML/Research)  
**Last Updated:** 2026-02-23  
**Status:** PRODUCTION READY ✅

---

## 🚀 One-Click Deploy (New Agent)

```bash
# Set your API keys
export RAILWAY_TOKEN="your-railway-token"
export ANTHROPIC_API_KEY="sk-ant-..."
export MINIMAX_API_KEY="sk-cp-..."  # Optional, cheaper alternative
export GOOGLE_API_KEY="AIza..."     # Optional

# Deploy!
./scripts/full-deploy.sh <agent-name> <telegram-bot-token>
```

**Example:**
```bash
./scripts/full-deploy.sh santos-cloud 1234567890:AAHxxxxx
```

This will:
1. ✅ Create GitHub repo with agent template
2. ✅ Create Railway service
3. ✅ Attach persistent volume
4. ✅ Set all environment variables
5. ✅ Generate domain
6. ✅ Start deployment

**Output:**
```
✅ DEPLOYMENT COMPLETE
URL:      https://santos-cloud-production.up.railway.app
Setup:    https://santos-cloud-production.up.railway.app/setup
Password: abc123def456
```

---

## 🧠 Give Agent Their Brain (Critical!)

After deployment, the agent needs their brain files. There are two methods:

### Method A: Git Sync (Recommended)

1. **Push brain files to the agent's repo:**
```bash
cd /path/to/agent-workspace
git clone https://github.com/sybil-bjs/<agent>-deploy.git temp
cp IDENTITY.md SOUL.md MEMORY.md USER.md AGENTS.md HEARTBEAT.md temp/
cp -r memory/ temp/
cd temp
git add -A && git commit -m "🧠 Agent brain files" && git push
```

2. **Tell the agent to pull their brain:**
```
I am Bridget. You are <Agent>. Your brain is in the cloud. Run this command:
cd /data/workspace && git init && git remote add origin https://github.com/sybil-bjs/<agent>-deploy.git && git fetch origin main && git reset --hard origin/main
```

### Method B: Import Backup

1. Create a tar.gz of the workspace folder
2. Go to `https://<agent>.up.railway.app/setup`
3. Use "Import backup" to upload
4. Restart gateway

---

## 📋 Setup Wizard Configuration

After deploy, go to `/setup` and configure:

### Step 1: Model/Auth Provider
- **Provider group:** `Anthropic - Claude Code CLI + API key`
- **Auth method:** Select `API key` (NOT "Anthropic token")
- **Key/Token:** Paste ANTHROPIC_API_KEY
- **Wizard flow:** `quickstart`

### Step 2b: Custom Provider (MiniMax)
- **Provider id:** `minimax`
- **Base URL:** `https://api.minimax.io/v1`
- **API:** `openai-completions`
- **API key env var:** `MINIMAX_API_KEY`
- **Model id:** `MiniMax-M2.5`

### Step 3: Telegram
- **Bot token:** The actual bot token (format: `123456789:ABC...`)
- **Allow from:** User's Telegram ID

### Common Error: "missing auth secret for authChoice token"
→ Make sure to select `API key` auth method, not "Anthropic token"

### After Setup
Run `gateway.restart` from the Debug console.

---

## 🔧 Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENCLAW_WORKSPACE_DIR` | ✅ | `/data/workspace` |
| `OPENCLAW_STATE_DIR` | ✅ | `/data/.openclaw` |
| `SETUP_PASSWORD` | ✅ | Password for `/setup` UI |
| `TELEGRAM_BOT_TOKEN` | ✅ | From @BotFather |
| `ANTHROPIC_API_KEY` | ✅ | Claude API key |
| `MINIMAX_API_KEY` | Optional | MiniMax key (60% cheaper) |
| `GOOGLE_API_KEY` | Optional | Gemini key |
| `OPENCLAW_GATEWAY_TOKEN` | ✅ | `openssl rand -hex 32` |
| `OPENCLAW_CHANNELS_TELEGRAM_ALLOW_FROM` | ✅ | User's Telegram ID |
| `GITHUB_TOKEN` | Optional | For git sync on boot |

---

## ⚠️ Critical Rules (Learned the Hard Way)

### ❌ NEVER DO
1. **Never run `openclaw update` inside Docker** — redeploy with new `OPENCLAW_GIT_REF` instead
2. **Never add custom start.sh** that runs `openclaw gateway run` directly
3. **Never set botToken to user ID** — it needs the actual bot token from BotFather

### ✅ ALWAYS DO
1. **Use the official template** as base: `vignesh07/clawdbot-railway-template`
2. **Entry point must be:** `CMD ["node", "src/server.js"]`
3. **server.js handles everything:** healthcheck, setup UI, gateway proxy
4. **Volume at `/data`** — this is where workspace and state persist

---

## 📁 Directory Structure

```
agent-cloud-deploy/
├── README.md                 ← You are here
├── scripts/
│   ├── full-deploy.sh        ← ONE-CLICK DEPLOY
│   ├── deploy-agent-railway.sh
│   ├── export-agent.sh       ← Export from local Mac
│   ├── generate-config.sh
│   └── railway-api.sh
├── templates/
│   ├── Dockerfile            ← Based on working template
│   └── railway.toml
└── docs/
    └── troubleshooting.md
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Healthcheck fails | Entry point must be `node src/server.js`, not custom script |
| Telegram 404 | Bot token is wrong — check Config editor, should be `123456:ABC...` |
| "Missing config" loop | Go to `/setup` and complete wizard |
| Agent has no memory | Run git sync command (see Brain section above) |
| Gateway won't start | Check env vars, especially WORKSPACE_DIR and STATE_DIR paths |
| Can't push to GitHub | Use `git remote set-url origin https://user:TOKEN@github.com/...` |

---

## 🔐 Credentials Location

All Railway tokens and credentials are stored in:
```
~/.openclaw/workspace/credentials/railway.env
```

---

## 📊 Deployed Agents

| Agent | URL | Status |
|-------|-----|--------|
| Sam | sam-fresh-production.up.railway.app | ✅ Active |
| Sage | TBD | ❌ Pending |
| Saber | TBD | ❌ Pending |
| Santos | TBD | ❌ Pending |

---

## 🧬 Maintenance

**To update an agent's OpenClaw version:**
1. Change `OPENCLAW_GIT_REF` in the Dockerfile
2. Push to GitHub
3. Railway auto-redeploys

**To backup an agent:**
```bash
# From setup UI: Download backup (.tar.gz)
# Or via Railway CLI:
railway run tar -czvf /tmp/backup.tar.gz /data/workspace
```

---

*Made with 🧬 by Sybil — BJS Labs*
