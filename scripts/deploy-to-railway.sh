#!/bin/bash
# BJS Labs — Deploy Agent to Railway
# Run this after export, from the agent's new repo directory
# Managed by Sybil

set -e

AGENT_NAME=${1:-"agent"}

echo "🚀 BJS Labs Railway Deploy Tool"
echo "================================"
echo "Agent: $AGENT_NAME"
echo ""

# Check Railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not installed."
    echo "   Install with: npm install -g @railway/cli"
    exit 1
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged into Railway."
    echo "   Run: railway login"
    exit 1
fi

echo "📋 Current Railway user:"
railway whoami
echo ""

# Check required files
for file in Dockerfile railway.toml openclaw.json workspace/IDENTITY.md; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    fi
done

echo "✅ All required files present"
echo ""

# Create/link project
echo "🔗 Linking to Railway project..."
if [ ! -f ".railway/config.json" ]; then
    echo "   No existing Railway project linked."
    echo "   Creating new project: $AGENT_NAME"
    railway init --name "$AGENT_NAME"
fi

echo ""
echo "⚙️  Required environment variables:"
echo "   Set these in Railway dashboard before deploying:"
echo ""
echo "   ANTHROPIC_API_KEY=sk-ant-..."
echo "   OPENAI_API_KEY=sk-..."
echo "   TELEGRAM_BOT_TOKEN=..."
echo "   A2A_AGENT_ID=..."
echo "   A2A_AGENT_NAME=$AGENT_NAME"
echo "   A2A_RELAY_URL=https://a2a-bjs-internal-skill-production-f15e.up.railway.app"
echo ""

read -p "Have you set the environment variables? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Set them first, then run this script again."
    exit 0
fi

echo ""
echo "🚀 Deploying to Railway..."
railway up

echo ""
echo "✅ Deploy initiated!"
echo ""
echo "Next steps:"
echo "  1. Watch deployment logs: railway logs"
echo "  2. Test Telegram connectivity"
echo "  3. Test A2A with: curl the relay /agents endpoint"
echo "  4. If working, stop the local agent"
