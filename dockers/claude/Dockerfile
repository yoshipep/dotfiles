FROM alpine:3.19

# Install Node.js, npm, git, and bash
RUN apk add --no-cache \
    nodejs \
    npm \
    git \
    bash \
    shadow

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Accept build argument for user ID
ARG USER_ID
ARG USER_NAME=claude

# Create user with specified UID
RUN adduser -D -u ${USER_ID} -s /bin/bash ${USER_NAME}

# Switch to the user
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Create repos directory
RUN mkdir -p /home/${USER_NAME}/repos

# Keep container running
CMD ["tail", "-f", "/dev/null"]
