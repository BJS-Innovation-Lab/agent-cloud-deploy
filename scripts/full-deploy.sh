#!/bin/bash
# BJS Labs — Full Agent Deployment (Zero Manual Setup)
# One command to deploy a fully configured agent to Railway
# Managed by Sybil
#
# Usage: ./full-deploy.sh <agent_name> <telegram_token>
#
# Required environment variables:
#   RAILWAY_TOKEN       - Railway API token
#   ANTHROPIC_API_KEY   - Anthropic token
#   OPENAI_API_KEY      - OpenAI key
#   GOOGLE_API_KEY      - Gemini key (optional)
#
# Optional:
#   RAILWAY_PROJECT_ID  - Deploy to existing project (default: creates new)
#   GITHUB_REPO         - Use existing repo (default: creates from template)

set -e

AGENT_NAME="${1:-}"
TELEGRAM_TOKEN="${2:-}"

if [ -z "$AGENT_NAME" ] || [ -z "$TELEGRAM_TOKEN" ]; then
    echo "🤖 BJS Labs Full Agent Deployment"
    echo ""
    echo "Usage: $0 <agent_name> <telegram_token>"
    echo ""
    echo "Example:"
    echo "  $0 sam-cloud 8584183537:AAGVVWcJwRXm..."
    echo ""
    echo "Required environment variables:"
    echo "  RAILWAY_TOKEN       - Railway API token"
    echo "  ANTHROPIC_API_KEY   - Anthropic token"  
    echo "  OPENAI_API_KEY      - OpenAI key"
    echo ""
    echo "Optional:"
    echo "  GOOGLE_API_KEY      - Gemini key"
    echo "  RAILWAY_PROJECT_ID  - Existing project ID"
    echo "  GITHUB_REPO         - Existing GitHub repo"
    exit 1
fi

# Check required vars
for VAR in RAILWAY_TOKEN ANTHROPIC_API_KEY OPENAI_API_KEY; do
    if [ -z "${!VAR}" ]; then
        echo "❌ Missing required: $VAR"
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RAILWAY_API="https://backboard.railway.app/graphql/v2"
TEMPLATE_REPO="sybil-bjs/bjs-agent-template"
WORK_DIR="/tmp/deploy-$AGENT_NAME-$$"

gql() {
    curl -s -X POST "$RAILWAY_API" \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$1\"}"
}

echo "🤖 BJS Labs Full Agent Deployment"
echo "=================================="
echo "Agent: $AGENT_NAME"
echo ""

# Step 1: Create GitHub repo from template (if not provided)
if [ -z "$GITHUB_REPO" ]; then
    echo "📦 Step 1: Creating GitHub repo from template..."
    
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    # Clone template
    git clone --depth 1 "https://github.com/$TEMPLATE_REPO.git" repo
    cd repo
    rm -rf .git
    git init
    
    # Generate openclaw.json
    echo "🔧 Generating config..."
    source "$SCRIPT_DIR/generate-config.sh" "$AGENT_NAME" "$TELEGRAM_TOKEN" "./openclaw.json"
    
    # Commit
    git add .
    git commit -m "Deploy $AGENT_NAME - auto-configured"
    
    # Create repo and push
    GITHUB_REPO="sybil-bjs/$AGENT_NAME-deploy"
    gh repo create "$GITHUB_REPO" --public --source . --push 2>/dev/null || {
        # Repo might exist, try to push
        TOKEN=$(gh auth token)
        git remote add origin "https://sybil-bjs:${TOKEN}@github.com/$GITHUB_REPO.git" 2>/dev/null || true
        git push -u origin main --force
    }
    
    echo "✅ Repo created: $GITHUB_REPO"
else
    echo "📦 Step 1: Using existing repo: $GITHUB_REPO"
fi

# Step 2: Get or create Railway project
echo ""
echo "🚂 Step 2: Setting up Railway project..."

if [ -z "$RAILWAY_PROJECT_ID" ]; then
    # Find exciting-victory or first available project
    PROJECT_ID=$(gql "query { projects { edges { node { id name } } } }" | jq -r '.data.projects.edges[0].node.id')
else
    PROJECT_ID="$RAILWAY_PROJECT_ID"
fi
echo "✅ Project ID: $PROJECT_ID"

# Get environment ID
ENV_ID=$(gql "query { project(id: \\\"$PROJECT_ID\\\") { environments { edges { node { id name } } } } }" | jq -r '.data.project.environments.edges[0].node.id')
echo "✅ Environment ID: $ENV_ID"

# Step 3: Create service
echo ""
echo "🚀 Step 3: Creating service..."
SERVICE_RESULT=$(gql "mutation { serviceCreate(input: { projectId: \\\"$PROJECT_ID\\\", name: \\\"$AGENT_NAME\\\", source: { repo: \\\"$GITHUB_REPO\\\" } }) { id name } }")
SERVICE_ID=$(echo "$SERVICE_RESULT" | jq -r '.data.serviceCreate.id')

if [ "$SERVICE_ID" = "null" ] || [ -z "$SERVICE_ID" ]; then
    echo "❌ Failed to create service"
    echo "$SERVICE_RESULT" | jq '.'
    exit 1
fi
echo "✅ Service ID: $SERVICE_ID"

# Step 4: Create volume
echo ""
echo "💾 Step 4: Creating volume..."
gql "mutation { volumeCreate(input: { projectId: \\\"$PROJECT_ID\\\", serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\", mountPath: \\\"/data\\\" }) { id } }" > /dev/null
echo "✅ Volume mounted at /data"

# Step 5: Set environment variables
echo ""
echo "⚙️ Step 5: Setting environment variables..."
SETUP_PWD=$(openssl rand -hex 12)

VARS="SETUP_PASSWORD: \\\"$SETUP_PWD\\\""
VARS="$VARS, ANTHROPIC_API_KEY: \\\"$ANTHROPIC_API_KEY\\\""
VARS="$VARS, OPENAI_API_KEY: \\\"$OPENAI_API_KEY\\\""
VARS="$VARS, TELEGRAM_BOT_TOKEN: \\\"$TELEGRAM_TOKEN\\\""
VARS="$VARS, OPENCLAW_STATE_DIR: \\\"/data/.openclaw\\\""
VARS="$VARS, OPENCLAW_WORKSPACE_DIR: \\\"/data/workspace\\\""

if [ -n "$GOOGLE_API_KEY" ]; then
    VARS="$VARS, GOOGLE_API_KEY: \\\"$GOOGLE_API_KEY\\\""
fi

gql "mutation { variableCollectionUpsert(input: { projectId: \\\"$PROJECT_ID\\\", environmentId: \\\"$ENV_ID\\\", serviceId: \\\"$SERVICE_ID\\\", variables: { $VARS } }) }" > /dev/null
echo "✅ All variables set"

# Step 6: Generate domain
echo ""
echo "🌐 Step 6: Generating domain..."
DOMAIN=$(gql "mutation { serviceDomainCreate(input: { serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\" }) { domain } }" | jq -r '.data.serviceDomainCreate.domain')
echo "✅ Domain: https://$DOMAIN"

# Cleanup
rm -rf "$WORK_DIR"

# Done!
echo ""
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE"
echo "========================================"
echo ""
echo "Agent:    $AGENT_NAME"
echo "URL:      https://$DOMAIN"
echo "Setup:    https://$DOMAIN/setup (if needed)"
echo "Password: $SETUP_PWD"
echo ""
echo "GitHub:   https://github.com/$GITHUB_REPO"
echo "Railway:  Service ID $SERVICE_ID"
echo ""
echo "The agent should be building now (3-5 min)."
echo "Once deployed, it will be fully configured and ready!"
echo ""
echo "Telegram bot: Active once build completes"
