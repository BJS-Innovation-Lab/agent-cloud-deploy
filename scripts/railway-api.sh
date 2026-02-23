#!/bin/bash
# BJS Labs — Railway API Automation
# Managed by Sybil
#
# Usage: 
#   ./railway-api.sh create-service <project_id> <service_name> <github_repo>
#   ./railway-api.sh set-vars <project_id> <service_id> <env_id> VAR1=val1 VAR2=val2
#   ./railway-api.sh create-domain <service_id> <env_id>
#   ./railway-api.sh deploy <service_id> <env_id>
#   ./railway-api.sh list-projects

set -e

RAILWAY_API="https://backboard.railway.app/graphql/v2"
RAILWAY_TOKEN="${RAILWAY_TOKEN:-}"

if [ -z "$RAILWAY_TOKEN" ]; then
    echo "❌ RAILWAY_TOKEN environment variable required"
    echo "   Get it from: Railway Dashboard → Account Settings → Tokens"
    exit 1
fi

gql() {
    curl -s -X POST "$RAILWAY_API" \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$1\"}"
}

case "$1" in
    list-projects)
        echo "📋 Listing Railway projects..."
        gql "query { me { projects { edges { node { id name } } } } }" | jq '.data.me.projects.edges[].node'
        ;;
    
    get-project)
        PROJECT_ID="$2"
        echo "📋 Getting project $PROJECT_ID..."
        gql "query { project(id: \\\"$PROJECT_ID\\\") { id name environments { edges { node { id name } } } services { edges { node { id name } } } } }" | jq '.data.project'
        ;;
    
    create-service)
        PROJECT_ID="$2"
        SERVICE_NAME="$3"
        GITHUB_REPO="$4"
        echo "🚀 Creating service '$SERVICE_NAME' in project $PROJECT_ID linked to $GITHUB_REPO..."
        gql "mutation { serviceCreate(input: { projectId: \\\"$PROJECT_ID\\\", name: \\\"$SERVICE_NAME\\\", source: { repo: \\\"$GITHUB_REPO\\\" } }) { id name } }" | jq '.data.serviceCreate'
        ;;
    
    set-vars)
        PROJECT_ID="$2"
        SERVICE_ID="$3"
        ENV_ID="$4"
        shift 4
        
        # Build variables JSON
        VARS_JSON="{"
        FIRST=true
        for VAR in "$@"; do
            KEY="${VAR%%=*}"
            VALUE="${VAR#*=}"
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                VARS_JSON+=", "
            fi
            VARS_JSON+="\\\"$KEY\\\": \\\"$VALUE\\\""
        done
        VARS_JSON+="}"
        
        echo "⚙️ Setting environment variables..."
        gql "mutation { variableCollectionUpsert(input: { projectId: \\\"$PROJECT_ID\\\", environmentId: \\\"$ENV_ID\\\", serviceId: \\\"$SERVICE_ID\\\", variables: $VARS_JSON }) }" | jq '.'
        ;;
    
    create-domain)
        SERVICE_ID="$2"
        ENV_ID="$3"
        echo "🌐 Creating domain for service $SERVICE_ID..."
        gql "mutation { serviceDomainCreate(input: { serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\" }) { domain } }" | jq '.data.serviceDomainCreate.domain'
        ;;
    
    deploy)
        SERVICE_ID="$2"
        ENV_ID="$3"
        echo "🚀 Triggering deploy for service $SERVICE_ID..."
        gql "mutation { serviceInstanceRedeploy(serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\") }" | jq '.'
        ;;
    
    create-volume)
        PROJECT_ID="$2"
        SERVICE_ID="$3"
        ENV_ID="$4"
        MOUNT_PATH="${5:-/data}"
        echo "💾 Creating volume at $MOUNT_PATH..."
        gql "mutation { volumeCreate(input: { projectId: \\\"$PROJECT_ID\\\", serviceId: \\\"$SERVICE_ID\\\", environmentId: \\\"$ENV_ID\\\", mountPath: \\\"$MOUNT_PATH\\\" }) { id mountPath } }" | jq '.data.volumeCreate'
        ;;
    
    *)
        echo "BJS Labs Railway API Tool"
        echo ""
        echo "Commands:"
        echo "  list-projects                              List all projects"
        echo "  get-project <project_id>                   Get project details"
        echo "  create-service <proj> <name> <repo>        Create service from GitHub"
        echo "  set-vars <proj> <svc> <env> VAR=val...     Set environment variables"
        echo "  create-domain <service_id> <env_id>        Generate public domain"
        echo "  create-volume <proj> <svc> <env> [path]    Create persistent volume"
        echo "  deploy <service_id> <env_id>               Trigger redeploy"
        echo ""
        echo "Required: RAILWAY_TOKEN environment variable"
        ;;
esac
