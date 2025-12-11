FROM alpine:3.19

# Install Node.js, npm, git, and bash
RUN apk add --no-cache \
    nodejs \
    npm \
    git \
    bash \
    shadow

# Accept build argument for user ID
ARG USER_ID
ARG USER_NAME=claude

# Create user with specified UID
RUN adduser -D -u ${USER_ID} -s /bin/bash ${USER_NAME}

# Switch to the user
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Configure npm to use local directory for global packages
RUN mkdir -p /home/${USER_NAME}/.npm-global && \
  npm config set prefix '/home/${USER_NAME}/.npm-global'

# Install Claude Code locally (user can update without sudo)
RUN npm install -g @anthropic-ai/claude-code

# Add npm global bin to PATH
ENV PATH="/home/${USER_NAME}/.npm-global/bin:${PATH}"

# Create repos directory
RUN mkdir -p /home/${USER_NAME}/repos

# Keep container running
CMD ["tail", "-f", "/dev/null"]
