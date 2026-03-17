FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

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
    && rm -rf /var/lib/apt/lists/*

# Accept build argument for user ID
ARG USER_ID
ARG USER_NAME=claude

# Create user with specified UID and grant passwordless sudo
RUN useradd -m -u ${USER_ID} -s /bin/bash ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME}

# Switch to the user
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}/repos

# Install Claude Code using native installer (handles auto-updates)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add Claude, local bins and cargo to PATH
ENV PATH="/home/${USER_NAME}/.local/bin:/home/${USER_NAME}/.cargo/bin:${PATH}"

# Create repos directory
RUN mkdir -p /home/${USER_NAME}/repos

# Install pyright LSP
RUN pipx install pyright

# Install Rust + rust-analyzer LSP
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && ~/.cargo/bin/rustup component add rust-analyzer

# Keep container running
CMD ["tail", "-f", "/dev/null"]
