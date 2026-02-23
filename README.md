# BJS Labs — Agent Cloud Deploy System

**Managed by:** Sybil (ML/Research)  
**Created:** 2026-02-23  
**Purpose:** Deploy and migrate BJS agents to Railway without external templates

---

## Why Custom Deploy?

External templates can be:
- ❌ Hardcoded to specific models/versions
- ❌ Out of sync with our needs
- ❌ Unmaintained or deprecated
- ❌ Missing our specific requirements (A2A, memory structure)

Our system is:
- ✅ Version-agnostic (specify OpenClaw version at build time)
- ✅ Model-agnostic (API keys as env vars, not hardcoded)
- ✅ Memory-preserving (persistent volumes for workspace)
- ✅ A2A-ready (relay config built in)
- ✅ Maintained by Sybil

---

## Quick Start

### Migrating an Existing Agent (e.g., Sam)

**Step 1: Export from Mac**
```bash
# On Sam's Mac
cd ~/.openclaw/workspace/infrastructure/agent-cloud-deploy
./scripts/export-agent.sh sam ~/sam-export
```

**Step 2: Create GitHub Repo**
```bash
# Create new repo: bjs-labs/sam-cloud
gh repo create bjs-labs/sam-cloud --private
cd ~/sam-export
git init
cp ~/.openclaw/workspace/infrastructure/agent-cloud-deploy/templates/* .
git add .
git commit -m "Sam's cloud migration"
git push -u origin main
```

**Step 3: Deploy to Railway**
```bash
./scripts/deploy-to-railway.sh sam
```

**Step 4: Set Environment Variables in Railway Dashboard**
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY` 
- `TELEGRAM_BOT_TOKEN` (Sam's existing bot token)
- `A2A_AGENT_ID` (Sam's existing ID: `62bb0f39-...`)
- `A2A_AGENT_NAME=Sam`
- `A2A_RELAY_URL=https://a2a-bjs-internal-skill-production-f15e.up.railway.app`

**Step 5: Verify & Cutover**
1. Check Railway logs: `railway logs`
2. Test Telegram: message @sam_ctxt_bot
3. Test A2A: check relay `/agents` endpoint
4. If working: stop local Sam (`openclaw gateway stop`)

---

## Directory Structure

```
agent-cloud-deploy/
├── README.md           ← You are here
├── templates/
│   ├── Dockerfile      ← Universal agent container
│   └── railway.toml    ← Railway config with volumes
├── scripts/
│   ├── export-agent.sh      ← Export from Mac
│   └── deploy-to-railway.sh ← Deploy to Railway
└── docs/
    └── troubleshooting.md
```

---

## Agent Requirements

Each cloud agent needs:

| Component | Source | Notes |
|-----------|--------|-------|
| `workspace/` | Exported from Mac | Agent's memory, identity, skills |
| `openclaw.json` | Exported + sanitized | Config with env var placeholders |
| `Dockerfile` | templates/ | Universal, version-agnostic |
| `railway.toml` | templates/ | Persistent volume config |

---

## Version Control

To deploy a specific OpenClaw version:
```dockerfile
# In Dockerfile, change:
ARG OPENCLAW_VERSION=latest
# To:
ARG OPENCLAW_VERSION=1.2.3
```

Or set at build time:
```bash
railway up --build-arg OPENCLAW_VERSION=1.2.3
```

---

## Troubleshooting

### Agent won't start
- Check Railway logs: `railway logs`
- Verify all env vars are set
- Check `openclaw.json` syntax

### A2A not connecting
- Verify `A2A_AGENT_ID` matches the original
- Check relay status: `curl https://a2a-bjs.../agents`
- Ensure relay URL is correct

### Telegram not responding
- Verify `TELEGRAM_BOT_TOKEN` is correct
- Check only ONE instance is running (stop local first)
- Look for webhook conflicts

### Memory not persisting
- Verify Railway volume is mounted at `/root/.openclaw`
- Check volume name in `railway.toml`

---

## Maintenance

**Sybil's Responsibilities:**
- Keep templates updated with OpenClaw changes
- Test migrations before applying to production agents
- Document any breaking changes
- Monitor deployed agents via A2A relay

**Update Process:**
1. Test changes on a non-critical agent first
2. Update templates in this repo
3. Redeploy affected agents with new templates
4. Verify A2A connectivity after each deploy

---

## Security Notes

- **Never commit real API keys** — use env vars
- **Sanitize exports** — the export script removes tokens
- **Use Railway's secrets** — not plain env vars for sensitive data
- **Restrict repo access** — agent repos contain memory/identity

---

*Last updated: 2026-02-23 by Sybil*
