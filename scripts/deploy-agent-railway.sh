#!/bin/bash
# BJS Labs — Deploy Agent to Railway (Automated)
# Managed by Sybil
#
# Usage: ./deploy-agent-railway.sh <agent_name> <github_repo> [telegram_bot_token]
#
# Prerequisites:
#   - RAILWAY_TOKEN environment variable
#   - RAILWAY_PROJECT_ID environment variable (or uses default BJS project)
#   - ANTHROPIC_API_KEY environment variable
#   - OPENAI_API_KEY environment variable

set -e

AGENT_NAME="${1:-}"
GITHUB_REPO="${2:-}"
TELEGRAM_BOT_TOKEN="${3:-}"

if [ -z "$AGENT_NAME" ] || [ -z "$GITHUB_REPO" ]; then
    echo "Usage: $0 <agent_name> <github_repo> [telegram_bot_token]"
    echo ""
    echo "Example:"
    echo "  $0 sam-cloud sybil-bjs/sam-cloud-deploy-1771857056 123456:ABC..."
    exit 1
fi

# Check required env vars
for VAR in RAILWAY_TOKEN ANTHROPIC_API_KEY OPENAI_API_KEY; do
    if [ -z "${!VAR}" ]; then
        echo "❌ Required: $VAR environment variable"
        exit 1
    fi
done

RAILWAY_API="https://backboard.railway.app/graphql/v2"
SCRIPT_DIR="$(dirname "$0")"

# Use existing BJS project or create new
PROJECT_ID="${RAILWAY_PROJECT_ID:-}"

gql() {
    curl -s -X POST "$RAILWAY_API" \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$1\"}"
}

echo "🤖 BJS Labs Agent Deployment"
echo "============================"
echo "Agent: $AGENT_NAME"
echo "Repo:  $GITHUB_REPO"
echo ""

# Step 1: Get or validate project
if [ -z "$PROJECT_ID" ]; then
    echo "📋 Finding BJS project..."
    PROJECT_ID=$(gql "query { me { projects { edges { node { id name } } } } }" | jq -r '.data.me.projects.edges[0].node.id')
    if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
        echo "❌ No projects found. Set RAILWAY_PROJECT_ID manually."
        exit 1
    fi
fi
echo "✅ Project ID: $PROJECT_ID"

# Step 2: Get environment ID
echo "📋 Getting environment..."
ENV_ID=$(gql "query { project(id: \\\"$PROJECT_ID\\\") { environments { edges { node { id name } } } } }" | jq -r '.data.project.environments.edges[0].node.id')
echo "✅ Environment ID: $ENV_ID"

# Step 3: Create service
echo "🚀 Creating service '$AGENT_NAME'..."
SERVICE_RESULT=$(gql "mutation { serviceCreate(input: { projectId: \\\"$PROJECT_ID\\\", name: \\\"$AGENT_NAME\\\", source: { repo: \\\"$GITHUB_REPO\\\" } }) { id name } }")
SERVICE_ID=$(echo "$SERVICE_RESULT" | jq -r '.data.serviceCreate.id')

if [ "$SERVICE_ID" = "null" ] || [ -z "$SERVICE_ID" ]; then
    echo "❌ Failed to create service:"
    echo "$SERVICE_RESULT" | jq '.'
    exit 1
fi
echo "✅ Service ID: $SERVICE_ID"

# Step 4: Create volume
echo "💾 Creating persistent volume at /data..."
VOLUME_RESULT=$(gql "mutation { volumeCreate(input: { projectId: \\\"$PROJECT_ID\\\", serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\", mountPath: \\\"/data\\\" }) { id mountPath } }")
echo "✅ Volume created"

# Step 5: Set environment variables
echo "⚙️ Setting environment variables..."
SETUP_PASSWORD=$(openssl rand -hex 16)

VARS_JSON="{\\\"ANTHROPIC_API_KEY\\\": \\\"$ANTHROPIC_API_KEY\\\", \\\"OPENAI_API_KEY\\\": \\\"$OPENAI_API_KEY\\\", \\\"SETUP_PASSWORD\\\": \\\"$SETUP_PASSWORD\\\", \\\"OPENCLAW_STATE_DIR\\\": \\\"/data/.openclaw\\\", \\\"OPENCLAW_WORKSPACE_DIR\\\": \\\"/data/workspace\\\"}"

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    VARS_JSON="{\\\"ANTHROPIC_API_KEY\\\": \\\"$ANTHROPIC_API_KEY\\\", \\\"OPENAI_API_KEY\\\": \\\"$OPENAI_API_KEY\\\", \\\"TELEGRAM_BOT_TOKEN\\\": \\\"$TELEGRAM_BOT_TOKEN\\\", \\\"SETUP_PASSWORD\\\": \\\"$SETUP_PASSWORD\\\", \\\"OPENCLAW_STATE_DIR\\\": \\\"/data/.openclaw\\\", \\\"OPENCLAW_WORKSPACE_DIR\\\": \\\"/data/workspace\\\"}"
fi

gql "mutation { variableCollectionUpsert(input: { projectId: \\\"$PROJECT_ID\\\", environmentId: \\\"$ENV_ID\\\", serviceId: \\\"$SERVICE_ID\\\", variables: $VARS_JSON }) }" > /dev/null
echo "✅ Variables set"

# Step 6: Create domain
echo "🌐 Generating public domain..."
DOMAIN_RESULT=$(gql "mutation { serviceDomainCreate(input: { serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\" }) { domain } }")
DOMAIN=$(echo "$DOMAIN_RESULT" | jq -r '.data.serviceDomainCreate.domain')
echo "✅ Domain: https://$DOMAIN"

# Done!
echo ""
echo "========================================"
echo "✅ DEPLOYMENT INITIATED"
echo "========================================"
echo ""
echo "Agent:    $AGENT_NAME"
echo "URL:      https://$DOMAIN"
echo "Setup:    https://$DOMAIN/setup"
echo "Password: $SETUP_PASSWORD"
echo ""
echo "Service ID:     $SERVICE_ID"
echo "Environment ID: $ENV_ID"
echo ""
echo "Next steps:"
echo "  1. Wait for build to complete (~2-5 min)"
echo "  2. Visit https://$DOMAIN/setup"
echo "  3. Complete Telegram/channel setup if not pre-configured"
echo ""
echo "Monitor: railway.app → $AGENT_NAME → Logs"
