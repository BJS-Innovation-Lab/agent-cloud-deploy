# BJS Labs — Universal Agent Dockerfile
# Based on working vignesh07/clawdbot-railway-template
# DO NOT MODIFY unless you know what you're doing!

FROM node:22-bookworm AS openclaw-build

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git ca-certificates curl python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable

WORKDIR /openclaw

# Pin to a known-good version. Override with build arg if needed.
ARG OPENCLAW_GIT_REF=v2026.2.17
RUN git clone --depth 1 --branch "${OPENCLAW_GIT_REF}" https://github.com/openclaw/openclaw.git .

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install && pnpm ui:build


# Runtime image
FROM node:22-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates tini python3 python3-venv \
  && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@10.23.0 --activate

# Persist user-installed tools to Railway volume
ENV NPM_CONFIG_PREFIX=/data/npm
ENV NPM_CONFIG_CACHE=/data/npm-cache
ENV PNPM_HOME=/data/pnpm
ENV PNPM_STORE_DIR=/data/pnpm-store
ENV PATH="/data/npm/bin:/data/pnpm:${PATH}"

WORKDIR /app

# Wrapper deps (from vignesh07 template)
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

# Copy built openclaw
COPY --from=openclaw-build /openclaw /openclaw

# Provide openclaw CLI
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

# Copy server wrapper
COPY src ./src

# Agent brain files (optional - seeds fresh deployments)
# COPY workspace/ /app/workspace-seed/

EXPOSE 8080

# CRITICAL: Use tini for proper signal handling
ENTRYPOINT ["tini", "--"]

# CRITICAL: Run server.js, NOT openclaw gateway directly!
# server.js handles: healthcheck, setup UI, gateway lifecycle
CMD ["node", "src/server.js"]
