#!/bin/bash
# BJS Labs — Export Agent for Cloud Migration
# Run this on the agent's LOCAL machine (Mac)
# Managed by Sybil

set -e

AGENT_NAME=${1:-"agent"}
EXPORT_DIR="${2:-$HOME/agent-export-$AGENT_NAME}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "🔬 BJS Labs Agent Export Tool"
echo "=============================="
echo "Agent: $AGENT_NAME"
echo "Export to: $EXPORT_DIR"
echo ""

# Safety check - don't run while gateway is active
if pgrep -f "openclaw.*gateway" > /dev/null; then
    echo "⚠️  WARNING: Gateway appears to be running."
    echo "   For safest export, stop it first: openclaw gateway stop"
    read -p "   Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create export directory
mkdir -p "$EXPORT_DIR"
cd "$EXPORT_DIR"

echo "📦 Exporting workspace..."
cp -r ~/.openclaw/workspace ./workspace

echo "📦 Exporting config..."
cp ~/.openclaw/openclaw.json ./openclaw.json.template

echo "🔐 Sanitizing secrets from config..."
# Remove actual tokens, replace with placeholders
# User will need to set these as Railway env vars
cat ./openclaw.json.template | \
    sed 's/"botToken": "[^"]*"/"botToken": "${TELEGRAM_BOT_TOKEN}"/g' | \
    sed 's/"apiKey": "[^"]*"/"apiKey": "${OPENAI_API_KEY}"/g' \
    > ./openclaw.json

echo "📋 Capturing cron jobs..."
openclaw cron list --json > ./cron-jobs-backup.json 2>/dev/null || echo "[]" > ./cron-jobs-backup.json

echo "📋 Capturing current status..."
openclaw gateway status > ./status-snapshot.txt 2>/dev/null || echo "Gateway not running" > ./status-snapshot.txt

echo "🗜️  Creating backup archive..."
cd ..
tar -czf "agent-backup-$AGENT_NAME-$TIMESTAMP.tar.gz" "$(basename $EXPORT_DIR)"

echo ""
echo "✅ Export complete!"
echo ""
echo "Files created:"
echo "  📁 $EXPORT_DIR/"
echo "  📦 agent-backup-$AGENT_NAME-$TIMESTAMP.tar.gz"
echo ""
echo "Next steps:"
echo "  1. Create a new GitHub repo for this agent"
echo "  2. Copy Dockerfile and railway.toml from templates"
echo "  3. Copy the workspace/ folder and openclaw.json"
echo "  4. Set environment variables in Railway dashboard"
echo "  5. Deploy and verify A2A connectivity"
echo ""
echo "Required Railway env vars:"
echo "  ANTHROPIC_API_KEY"
echo "  OPENAI_API_KEY"
echo "  TELEGRAM_BOT_TOKEN"
echo "  A2A_AGENT_ID"
echo "  A2A_AGENT_NAME"
echo "  A2A_RELAY_URL"
