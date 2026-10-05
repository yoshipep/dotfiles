FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Madrid timezone (tzdata is absent from the base image)
ENV TZ=Europe/Madrid

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    ca-certificates \
    sudo \
    poppler-utils \
    clangd \
    python3 \
    python3-pip \
    pipx \
    tzdata \
    vim \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node.js from the official tarball (Ubuntu 24.04 ships Node 18, Playwright needs 20+)
ARG NODE_VERSION=24.11.0
RUN arch=$(dpkg --print-architecture | sed 's/amd64/x64/') \
    && curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.gz \
    | tar -xz -C /usr/local --strip-components=1 --exclude='*.md' --exclude=LICENSE

# Accept build argument for user ID
ARG USER_ID
ARG USER_NAME=claude

# Create user with specified UID and grant passwordless sudo
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u ${USER_ID} -s /bin/bash ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME}

# Switch to the user
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}/repos

# Install Claude Code using native installer (handles auto-updates)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add Claude, local bins and cargo to PATH
ENV PATH="/home/${USER_NAME}/.local/bin:/home/${USER_NAME}/.cargo/bin:${PATH}"

# Create repos directory (.claude created so its persistence volume seeds with claude ownership)
RUN mkdir -p /home/${USER_NAME}/repos \
    && mkdir -p /home/${USER_NAME}/.config && chmod 700 /home/${USER_NAME}/.config \
    && mkdir -p /home/${USER_NAME}/.claude

# Install pyright LSP
RUN pipx install pyright

# Install Playwright + its MCP server + Chromium (npm globals go to ~/.local, browser in ~/.cache/ms-playwright)
RUN npm config set prefix /home/${USER_NAME}/.local \
    && npm install -g playwright @playwright/mcp \
    && sudo apt-get update \
    && sudo /home/${USER_NAME}/.local/bin/playwright install-deps chromium \
    && sudo rm -rf /var/lib/apt/lists/* \
    && /home/${USER_NAME}/.local/bin/playwright install chromium

# Install Rust + rust-analyzer LSP
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && ~/.cargo/bin/rustup component add rust-analyzer

# Keep container running
CMD ["tail", "-f", "/dev/null"]
