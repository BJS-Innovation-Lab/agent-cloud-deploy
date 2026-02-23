#!/bin/bash
# BJS Labs — Generate OpenClaw Config
# Creates a complete openclaw.json for zero-setup deployment
# Managed by Sybil
#
# Usage: ./generate-config.sh <agent_name> <telegram_token> [output_path]

set -e

AGENT_NAME="${1:-agent}"
TELEGRAM_TOKEN="${2:-}"
OUTPUT_PATH="${3:-./openclaw.json}"

# These come from environment
ANTHROPIC_TOKEN="${ANTHROPIC_API_KEY:-}"
OPENAI_KEY="${OPENAI_API_KEY:-}"
GEMINI_KEY="${GOOGLE_API_KEY:-}"

if [ -z "$TELEGRAM_TOKEN" ]; then
    echo "Usage: $0 <agent_name> <telegram_token> [output_path]"
    echo ""
    echo "Required environment variables:"
    echo "  ANTHROPIC_API_KEY  - Anthropic token"
    echo "  OPENAI_API_KEY     - OpenAI key"
    echo "  GOOGLE_API_KEY     - Gemini key (optional)"
    exit 1
fi

echo "🔧 Generating openclaw.json for: $AGENT_NAME"

cat > "$OUTPUT_PATH" << EOF
{
  "version": 1,
  "agent": {
    "name": "$AGENT_NAME",
    "model": "anthropic/claude-sonnet-4-20250514"
  },
  "providers": {
    "anthropic": {
      "apiKey": "$ANTHROPIC_TOKEN"
    },
    "openai": {
      "apiKey": "$OPENAI_KEY"
    }${GEMINI_KEY:+,
    "google": {
      "apiKey": "$GEMINI_KEY"
    }}
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_TOKEN"
    }
  },
  "gateway": {
    "auth": {
      "token": "$(openssl rand -hex 32)"
    }
  },
  "workspace": {
    "path": "/data/workspace"
  }
}
EOF

echo "✅ Config written to: $OUTPUT_PATH"
echo ""
echo "Configured:"
echo "  - Agent: $AGENT_NAME"
echo "  - Model: anthropic/claude-sonnet-4-20250514"
echo "  - Telegram: ✅"
echo "  - Anthropic: ${ANTHROPIC_TOKEN:+✅}${ANTHROPIC_TOKEN:-❌ missing}"
echo "  - OpenAI: ${OPENAI_KEY:+✅}${OPENAI_KEY:-❌ missing}"
echo "  - Gemini: ${GEMINI_KEY:+✅}${GEMINI_KEY:-⚠️ not set}"
