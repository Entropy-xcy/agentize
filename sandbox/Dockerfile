# syntax=docker/dockerfile:1

# =============================================================================
# Agentize Development Sandbox
# =============================================================================
# A comprehensive development environment container for agentize SDK development
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Base
# -----------------------------------------------------------------------------
FROM ubuntu:24.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Install base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    unzip \
    zip \
    tar \
    build-essential \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Stage 2: Node.js
# -----------------------------------------------------------------------------
FROM base AS node

# Install NodeSource Node.js 20.x LTS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Stage 3: Python & uv
# -----------------------------------------------------------------------------
FROM node AS python

# Install uv package manager
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -sf /root/.local/bin/uv /usr/local/bin/uv

# Install Python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Stage 4: SDKMAN
# -----------------------------------------------------------------------------
FROM python AS sdkman

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash \
    && rm -rf /root/.sdkman/bin/sdkman-init.sh

# Configure shell profile for SDKMAN
RUN echo 'source "$HOME/.sdkman/bin/sdkman-init.sh"' >> /root/.bashrc

# -----------------------------------------------------------------------------
# Stage 5: Browser
# -----------------------------------------------------------------------------
FROM sdkman AS browser

# Playwright's bundled Chromium will be installed in tools stage
# No separate browser installation needed here

# -----------------------------------------------------------------------------
# Stage 6: Tools (claude-code-router, playwright-mcp)
# -----------------------------------------------------------------------------
FROM browser AS tools

# Install claude-code-router globally
RUN npm install -g claude-code-router

# Install playwright and playwright MCP with bundled Chromium
RUN npm install -g playwright \
    && npx playwright install --with-deps chromium

# Create symlinks for browser compatibility (playwright's bundled chromium)
RUN ln -sf /root/.cache/ms-playwright/chromium-*/chrome-linux/chrome /usr/bin/google-chrome 2>/dev/null || true && \
    ln -sf /root/.cache/ms-playwright/chromium-*/chrome-linux/chrome /usr/bin/chromium 2>/dev/null || true

# -----------------------------------------------------------------------------
# Stage 7: Claude Code
# -----------------------------------------------------------------------------
FROM tools AS claude

# Copy Claude Code install script
COPY install.sh /tmp/install.sh

# Create required directories
RUN mkdir -p /root/.claude/downloads

# Install Claude Code (silent mode - assumes install.sh works in container)
RUN chmod +x /tmp/install.sh \
    && /tmp/install.sh stable \
    && rm -f /tmp/install.sh

# -----------------------------------------------------------------------------
# Stage 8: Final
# -----------------------------------------------------------------------------
FROM claude AS final

# Create sudoers.d directory for non-root sudo access
RUN mkdir -p /etc/sudoers.d \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/developer \
    && chmod 440 /etc/sudoers.d/developer

# Add non-root user
RUN useradd -m -s /bin/bash developer \
    && mkdir -p /home/developer/.claude/downloads \
    && chown -R developer:developer /home/developer

# Set working directory
WORKDIR /workspace

# Set environment for developer
ENV HOME=/home/developer

# Ensure SDKMAN is available
RUN echo 'source "$HOME/.sdkman/bin/sdkman-init.sh"' >> /home/developer/.bashrc

# Switch to non-root user
USER developer

# Default command
CMD ["/bin/bash"]