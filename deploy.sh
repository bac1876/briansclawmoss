#!/bin/bash

###############################################################################
# BriansClaw + OpenMOSS Automated Deployment Script
# 
# Usage: bash deploy.sh
# or: curl -fsSL https://raw.github.com/yourrepo/deploy.sh | bash
#
# This script will:
# - Install system dependencies (Node.js, Python, etc.)
# - Clone OpenClaw and OpenMOSS
# - Configure both systems
# - Set up systemd services
# - Configure firewall
# - Initialize databases
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

###############################################################################
# PHASE 1: Pre-flight checks
###############################################################################

log "Starting BriansClaw + OpenMOSS deployment..."
log "Checking prerequisites..."

# Check if running as root (recommended)
if [[ $EUID -ne 0 ]]; then
   warn "This script should ideally be run as root for system-wide installations"
   warn "Some commands may require sudo. Continuing..."
fi

# Check OS
if ! grep -q "Ubuntu\|Debian" /etc/os-release; then
    error "This script requires Ubuntu or Debian. Other Linux distributions may need adjustments."
fi

# Check internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    error "No internet connectivity. Please ensure you're connected to the internet."
fi

success "Pre-flight checks passed"

###############################################################################
# PHASE 2: System updates and base dependencies
###############################################################################

log "Updating system packages..."
apt-get update
apt-get upgrade -y

log "Installing base dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    ufw \
    fail2ban \
    htop \
    tmux \
    vim \
    nano

success "Base dependencies installed"

###############################################################################
# PHASE 3: Node.js & npm setup
###############################################################################

log "Verifying Node.js and npm..."
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
success "Node.js $NODE_VERSION installed"
success "npm $NPM_VERSION installed"

# Install npm globally useful packages
npm install -g pm2 yarn pnpm

###############################################################################
# PHASE 4: Python environment setup
###############################################################################

log "Setting up Python environment..."
python3 -m venv /opt/python-env
source /opt/python-env/bin/activate
pip install --upgrade pip setuptools wheel
success "Python virtual environment created at /opt/python-env"

###############################################################################
# PHASE 5: Clone OpenClaw
###############################################################################

log "Setting up OpenClaw..."

if [ -d "/opt/openclaw" ]; then
    warn "OpenClaw directory already exists. Pulling latest changes..."
    cd /opt/openclaw
    git pull
else
    log "Cloning OpenClaw repository..."
    git clone https://github.com/openclaw/openclaw.git /opt/openclaw
    cd /opt/openclaw
fi

# Install OpenClaw dependencies
log "Installing OpenClaw dependencies..."
npm install

success "OpenClaw installed at /opt/openclaw"

###############################################################################
# PHASE 6: Clone OpenMOSS
###############################################################################

log "Setting up OpenMOSS..."

if [ -d "/opt/openmoss" ]; then
    warn "OpenMOSS directory already exists. Pulling latest changes..."
    cd /opt/openmoss
    git pull
else
    log "Cloning OpenMOSS repository..."
    git clone https://github.com/uluckyXH/OpenMOSS.git /opt/openmoss
    cd /opt/openmoss
fi

# Install OpenMOSS dependencies
log "Installing OpenMOSS dependencies..."
source /opt/python-env/bin/activate
pip install -r requirements.txt

# Create necessary directories
mkdir -p /opt/openmoss/data
mkdir -p /opt/openmoss/logs
mkdir -p /opt/openmoss-workspace

success "OpenMOSS installed at /opt/openmoss"

###############################################################################
# PHASE 7: Configure OpenMOSS
###############################################################################

log "Configuring OpenMOSS..."

# Generate a random admin password and registration token
ADMIN_PASSWORD=$(openssl rand -base64 12)
REGISTRATION_TOKEN="openclaw-$(openssl rand -hex 16)"

# Copy config template
if [ ! -f "/opt/openmoss/config.yaml" ]; then
    cp /opt/openmoss/config.example.yaml /opt/openmoss/config.yaml
    
    # Update config with generated values
    sed -i "s/admin123/${ADMIN_PASSWORD}/" /opt/openmoss/config.yaml
    sed -i "s/openclaw-register-2024/${REGISTRATION_TOKEN}/" /opt/openmoss/config.yaml
    sed -i "s|/home/your-user/TaskWork|/opt/openmoss-workspace|" /opt/openmoss/config.yaml
    
    log "OpenMOSS config generated with:"
    log "  Admin password: ${ADMIN_PASSWORD}"
    log "  Registration token: ${REGISTRATION_TOKEN}"
else
    warn "OpenMOSS config already exists. Skipping template generation."
fi

success "OpenMOSS configured"

###############################################################################
# PHASE 8: Build OpenMOSS frontend (if needed)
###############################################################################

log "Checking OpenMOSS frontend..."

if [ ! -d "/opt/openmoss/static" ]; then
    log "Building OpenMOSS frontend..."
    cd /opt/openmoss/webui
    npm install
    npm run build
    
    mkdir -p /opt/openmoss/static
    cp -r /opt/openmoss/webui/dist/* /opt/openmoss/static/
    
    success "OpenMOSS frontend built"
else
    success "OpenMOSS frontend already exists"
fi

###############################################################################
# PHASE 9: Create systemd services
###############################################################################

log "Creating systemd service files..."

# OpenClaw service
cat > /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openclaw
Environment="NODE_ENV=production"
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# OpenMOSS service
cat > /etc/systemd/system/openmoss.service << 'EOF'
[Unit]
Description=OpenMOSS Backend
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openmoss
Environment="PYTHONUNBUFFERED=1"
ExecStart=/opt/python-env/bin/python3 -m uvicorn app.main:app --host 0.0.0.0 --port 6565 --access-log
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable openclaw.service
systemctl enable openmoss.service

success "Systemd services created and enabled"

###############################################################################
# PHASE 10: Configure Firewall
###############################################################################

log "Configuring firewall..."

# Enable UFW
ufw --force enable

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (critical!)
ufw allow 22/tcp

# Allow web traffic
ufw allow 80/tcp
ufw allow 443/tcp

# Allow internal services (for testing, restrict later)
ufw allow 8080/tcp  # OpenClaw
ufw allow 6565/tcp  # OpenMOSS

success "Firewall configured"

###############################################################################
# PHASE 11: Install Nginx (reverse proxy)
###############################################################################

log "Installing Nginx..."
apt-get install -y nginx certbot python3-certbot-nginx

# Create Nginx config template
cat > /etc/nginx/sites-available/openmoss-template << 'EOF'
# Replace DOMAIN_NAME with your actual domain

upstream openclaw {
    server 127.0.0.1:8080;
}

upstream openmoss {
    server 127.0.0.1:6565;
}

server {
    listen 80;
    server_name DOMAIN_NAME;

    # Redirect to HTTPS (after SSL is enabled)
    return 301 https://$server_name$request_uri;

    access_log /var/log/nginx/openmoss_access.log;
    error_log /var/log/nginx/openmoss_error.log;
}

server {
    listen 443 ssl http2;
    server_name DOMAIN_NAME;

    # SSL certificates (will be populated by certbot)
    # ssl_certificate /etc/letsencrypt/live/DOMAIN_NAME/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/DOMAIN_NAME/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;

    access_log /var/log/nginx/openmoss_access.log;
    error_log /var/log/nginx/openmoss_error.log;

    # OpenMOSS proxy
    location / {
        proxy_pass http://openmoss;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # OpenClaw proxy (optional, for agent management)
    location /openclaw/ {
        proxy_pass http://openclaw/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

success "Nginx installed and configured"

###############################################################################
# PHASE 12: Start services
###############################################################################

log "Starting services..."

systemctl start openclaw
systemctl start openmoss
systemctl restart nginx

# Wait a moment for services to start
sleep 3

# Check service status
if systemctl is-active --quiet openclaw; then
    success "OpenClaw is running (port 8080)"
else
    warn "OpenClaw failed to start. Check logs: journalctl -u openclaw -n 50"
fi

if systemctl is-active --quiet openmoss; then
    success "OpenMOSS is running (port 6565)"
else
    warn "OpenMOSS failed to start. Check logs: journalctl -u openmoss -n 50"
fi

###############################################################################
# PHASE 13: Fail2ban setup
###############################################################################

log "Configuring Fail2ban..."

systemctl enable fail2ban
systemctl restart fail2ban

success "Fail2ban enabled"

###############################################################################
# PHASE 14: Final summary
###############################################################################

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Your BriansClaw + OpenMOSS system is ready!"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Register your domain and point it to: 143.110.233.145"
echo "2. Run SSL setup: sudo bash scripts/enable-ssl.sh your-domain.com"
echo "3. Access OpenMOSS WebUI at: http://143.110.233.145 (or your domain)"
echo ""
echo -e "${BLUE}Service Information:${NC}"
echo "  OpenClaw Gateway:  http://127.0.0.1:8080 (internal)"
echo "  OpenMOSS Backend:  http://127.0.0.1:6565 (internal)"
echo "  Nginx Proxy:       http://143.110.233.145 (public)"
echo ""
echo -e "${BLUE}Admin Credentials (saved to ~/openmoss-credentials.txt):${NC}"
echo "  Admin Password: ${ADMIN_PASSWORD}"
echo "  Registration Token: ${REGISTRATION_TOKEN}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View OpenMOSS logs:  sudo journalctl -u openmoss -f"
echo "  View OpenClaw logs:  sudo journalctl -u openclaw -f"
echo "  Check service status: sudo systemctl status openmoss"
echo "  Restart services:    sudo systemctl restart openmoss openclaw nginx"
echo ""
echo -e "${YELLOW}IMPORTANT: Save your credentials!${NC}"
echo "  Credentials saved to: /root/openmoss-credentials.txt"
echo ""

# Save credentials to file
cat > /root/openmoss-credentials.txt << EOF
BriansClaw + OpenMOSS Credentials
Generated: $(date)

Admin Password: ${ADMIN_PASSWORD}
Registration Token: ${REGISTRATION_TOKEN}

OpenMOSS Config Location: /opt/openmoss/config.yaml
OpenMOSS Workspace: /opt/openmoss-workspace
OpenMOSS Database: /opt/openmoss/data/tasks.db

Keep this file secure and never share these credentials!
EOF

chmod 600 /root/openmoss-credentials.txt

echo "✓ Credentials saved to /root/openmoss-credentials.txt"
echo ""
echo "=========================================="
echo ""
