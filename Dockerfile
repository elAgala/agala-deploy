FROM alpine:3.19 AS builder

# Install Go
RUN apk add --no-cache go

# Set up Go workspace
WORKDIR /build
COPY go.mod ./
COPY main.go ./

# Build the Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o entrypoint .

FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache python3 py3-pip openssh-client jq curl tar git && \
  pip3 install ansible --break-system-packages

# Install sops
RUN curl -fsSL -o /usr/local/bin/sops \
  https://github.com/getsops/sops/releases/download/v3.9.4/sops-v3.9.4.linux.amd64 && \
  chmod +x /usr/local/bin/sops

# Install age
RUN curl -fsSL -o /tmp/age.tar.gz \
  https://github.com/FiloSottile/age/releases/download/v1.2.1/age-v1.2.1-linux-amd64.tar.gz && \
  tar -xzf /tmp/age.tar.gz -C /tmp && \
  mv /tmp/age/age /usr/local/bin/age && \
  mv /tmp/age/age-keygen /usr/local/bin/age-keygen && \
  rm -rf /tmp/age /tmp/age.tar.gz

# Install ansible collections
RUN ansible-galaxy collection install community.docker:4.6.1 community.sops

# Copy the Go binary from builder
COPY --from=builder /build/entrypoint /entrypoint
RUN chmod +x /entrypoint

# Set working directory
WORKDIR /app

# Default command
ENTRYPOINT ["/entrypoint"]
