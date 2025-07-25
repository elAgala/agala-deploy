FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache python3 py3-pip openssh-client jq curl tar && \
  pip3 install ansible --break-system-packages

# Install 1Password CLI
RUN echo https://downloads.1password.com/linux/alpinelinux/stable/ >> /etc/apk/repositories && \
  wget https://downloads.1password.com/linux/keys/alpinelinux/support@1password.com-61ddfc31.rsa.pub -P /etc/apk/keys && \
  apk update && apk add 1password-cli

# Install ansible community.docker collection
RUN ansible-galaxy collection install community.docker:4.6.1

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /app

# Default command
ENTRYPOINT ["/entrypoint.sh"]
