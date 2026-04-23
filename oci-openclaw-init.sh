#!/bin/bash
# OCI Instance Initialization Script for Ollama + OpenClaw
# Oracle Linux 9 Compatible
# Run as root during instance bring-up

set -e

# Configuration
OPC_USER="opc"
OPC_HOME="/home/opc"
OLLAMA_PORT=11434
OPENCLAW_PORT=18789

# Generate random API key for OpenClaw
OPENCLAW_API_KEY=$(openssl rand -hex 32)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/openclaw-init.log
}

log "Starting Ollama + OpenClaw installation..."

# Update system
log "Updating system packages..."
dnf update -y

# Install required dependencies
log "Installing dependencies..."
dnf install -y \
    curl \
    wget \
    git \
    tar \
    unzip \
    which \
    ca-certificates \
    gnupg2 \
    openssl \
    openssl-devel \
    python3 \
    python3-pip \
    gcc \
    gcc-c++ \
    make \
    systemd-devel \
    zstd

# Install Node.js 22 (LTS)
log "Installing Node.js 22..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

# Verify Node.js
node --version
npm --version

# Install Ollama
log "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Create Ollama systemd service
log "Setting up Ollama service..."
cat > /etc/systemd/system/ollama.service << 'EOF'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=root
Group=root
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="OLLAMA_HOST=0.0.0.0:11434"

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable ollama.service
systemctl start ollama.service

# Wait for Ollama to be ready
log "Waiting for Ollama to start..."
sleep 5
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        log "Ollama is ready"
        break
    fi
    sleep 2
done

# Pull llama3:latest
log "Pulling llama3:latest..."
ollama pull llama3:latest || log "Warning: Failed to pull llama3:latest, will retry on first use"

# Set up OpenClaw
log "Installing OpenClaw..."

# Create installation directory
mkdir -p /opt/openclaw
cd /opt/openclaw

# Install OpenClaw globally
npm install -g openclaw

# Install optional provider plugins (non-blocking)
log "Installing provider plugins..."
npm install -g @larksuiteoapi/node-sdk 2>/dev/null || log "Note: Lark/Feishu SDK optional, skipping"
npm install -g @openclaw/provider-feishu 2>/dev/null || log "Note: Feishu plugin optional, skipping"
npm install -g @openclaw/provider-slack 2>/dev/null || log "Note: Slack plugin optional, skipping"
npm install -g @openclaw/provider-whatsapp 2>/dev/null || log "Note: WhatsApp plugin optional, skipping"
npm install -g @openclaw/provider-nostr 2>/dev/null || log "Note: Nostr plugin optional, skipping"

# Create OpenClaw workspace directory
mkdir -p ${OPC_HOME}/.openclaw/workspace
cd ${OPC_HOME}/.openclaw/workspace

# Create basic config files
log "Creating OpenClaw configuration..."

# Create MEMORY.md
cat > ${OPC_HOME}/.openclaw/workspace/MEMORY.md << 'EOF'
# Memory

Initial setup complete on OCI instance.
EOF

# Create AGENTS.md
cat > ${OPC_HOME}/.openclaw/workspace/AGENTS.md << 'EOF'
# AGENTS.md

OCI instance with Ollama and OpenClaw.
EOF

# Create OpenClaw config directory
mkdir -p ${OPC_HOME}/.openclaw/config

# Create OpenClaw systemd service
log "Creating OpenClaw service..."
cat > /etc/systemd/system/openclaw.service << EOF
[Unit]
Description=OpenClaw Service
After=network-online.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=${OPC_USER}
Group=${OPC_USER}
WorkingDirectory=${OPC_HOME}/.openclaw/workspace
Environment="HOME=${OPC_HOME}"
Environment="OPENCLAW_API_KEY=${OPENCLAW_API_KEY}"
Environment="OLLAMA_HOST=http://localhost:11434"
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set ownership
chown -R ${OPC_USER}:${OPC_USER} ${OPC_HOME}/.openclaw

# Enable and start OpenClaw
systemctl daemon-reload
systemctl enable openclaw.service
systemctl start openclaw.service

# Create connection info file
log "Creating connection info..."
cat > ${OPC_HOME}/openclaw-connection-info.txt << EOF
========================================
OpenClaw + Ollama Installation Complete
========================================

Instance: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')

--- Ollama ---
Status: $(systemctl is-active ollama)
Port: ${OLLAMA_PORT}
URL: http://localhost:${OLLAMA_PORT}
Models: llama3:latest (pulled)

--- OpenClaw ---
Status: $(systemctl is-active openclaw)
Port: ${OPENCLAW_PORT}
API Key: ${OPENCLAW_API_KEY}

--- SSH Tunnel Setup ---
To access OpenClaw remotely, create an SSH tunnel:

  ssh -L 18789:localhost:18789 -L 11434:localhost:11434 opc@$(hostname -I | awk '{print $1}')

Then access:
- OpenClaw: http://localhost:18789 (with API key above)
- Ollama: http://localhost:11434

--- Pairing ---
To pair with your device, run on the instance:
  openclaw pair

Or configure remote pairing in config.

--- Logs ---
Installation: /var/log/openclaw-init.log
Ollama: journalctl -u ollama -f
OpenClaw: journalctl -u openclaw -f

EOF

chown ${OPC_USER}:${OPC_USER} ${OPC_HOME}/openclaw-connection-info.txt
chmod 600 ${OPC_HOME}/openclaw-connection-info.txt

# Configure firewall (if firewalld is running)
if systemctl is-active firewalld > /dev/null 2>&1; then
    log "Configuring firewall..."
    firewall-cmd --permanent --add-port=${OLLAMA_PORT}/tcp
    firewall-cmd --permanent --add-port=${OPENCLAW_PORT}/tcp
    firewall-cmd --reload
fi

# Ensure services are running
log "Final status check..."
systemctl status ollama --no-pager || true
systemctl status openclaw --no-pager || true

log "Installation complete!"
log "Connection info saved to: ${OPC_HOME}/openclaw-connection-info.txt"
log "API Key: ${OPENCLAW_API_KEY}"
