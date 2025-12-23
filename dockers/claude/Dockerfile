FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Accept build argument for user ID
ARG USER_ID
ARG USER_NAME=claude

# Create user with specified UID
RUN useradd -m -u ${USER_ID} -s /bin/bash ${USER_NAME}

# Switch to the user
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Install Claude Code using native installer (handles auto-updates)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add Claude to PATH
ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# Create repos directory
RUN mkdir -p /home/${USER_NAME}/repos

# Keep container running
CMD ["tail", "-f", "/dev/null"]
