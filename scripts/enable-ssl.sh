#!/bin/bash

###############################################################################
# Enable HTTPS/SSL with Let's Encrypt for BriansClaw + OpenMOSS
#
# Usage: sudo bash scripts/enable-ssl.sh yourdomain.com
#
# This script:
# - Creates Nginx config for your domain
# - Generates SSL certificate with certbot
# - Sets up auto-renewal
# - Tests and restarts services
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Check if domain is provided
if [ -z "$1" ]; then
    error "Usage: sudo bash scripts/enable-ssl.sh yourdomain.com"
fi

DOMAIN="$1"
NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

log "Enabling SSL for domain: ${DOMAIN}"

# Check if Nginx config template exists
if [ ! -f "/etc/nginx/sites-available/openmoss-template" ]; then
    error "Nginx template not found. Run deploy.sh first."
fi

###############################################################################
# Create Nginx config for this domain
###############################################################################

log "Creating Nginx configuration for ${DOMAIN}..."

# Copy and customize template
cp /etc/nginx/sites-available/openmoss-template "${NGINX_CONF}"

# Replace domain placeholder
sed -i "s/DOMAIN_NAME/${DOMAIN}/g" "${NGINX_CONF}"

# Comment out SSL lines (certbot will handle them)
sed -i 's/^[[:space:]]*# ssl_certificate/    # ssl_certificate/' "${NGINX_CONF}"

success "Nginx config created at ${NGINX_CONF}"

###############################################################################
# Enable site in Nginx
###############################################################################

log "Enabling Nginx site..."

if [ -L "${NGINX_ENABLED}" ]; then
    rm "${NGINX_ENABLED}"
fi

ln -s "${NGINX_CONF}" "${NGINX_ENABLED}"

# Test Nginx config
if ! nginx -t &>/dev/null; then
    error "Nginx configuration test failed. Check ${NGINX_CONF}"
fi

success "Nginx site enabled and configuration validated"

###############################################################################
# Reload Nginx
###############################################################################

log "Reloading Nginx..."
systemctl reload nginx
success "Nginx reloaded"

###############################################################################
# Generate SSL certificate with Certbot
###############################################################################

log "Generating SSL certificate with Let's Encrypt..."
log "This may take a minute..."

# Run certbot with Nginx plugin
certbot certonly \
    --nginx \
    --non-interactive \
    --agree-tos \
    --no-eff-email \
    -d "${DOMAIN}" \
    -m "admin@${DOMAIN}" || error "Certbot failed. Check your domain setup."

success "SSL certificate generated for ${DOMAIN}"

###############################################################################
# Update Nginx config with SSL paths
###############################################################################

log "Updating Nginx config with SSL certificate paths..."

# Uncomment and update SSL certificate lines
sed -i "s|# ssl_certificate /etc/letsencrypt/live/DOMAIN_NAME/fullchain.pem;|ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;|g" "${NGINX_CONF}"
sed -i "s|# ssl_certificate_key /etc/letsencrypt/live/DOMAIN_NAME/privkey.pem;|ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;|g" "${NGINX_CONF}"

# Test updated config
if ! nginx -t &>/dev/null; then
    error "Updated Nginx configuration test failed"
fi

success "Nginx config updated with SSL paths"

###############################################################################
# Reload Nginx with SSL
###############################################################################

log "Reloading Nginx with SSL enabled..."
systemctl reload nginx
success "Nginx reloaded with SSL"

###############################################################################
# Setup auto-renewal
###############################################################################

log "Setting up certificate auto-renewal..."

# Certbot automatically creates a systemd timer, but we can verify it
if systemctl list-timers | grep -q "certbot"; then
    success "Certbot auto-renewal timer is active"
else
    warn "Certbot auto-renewal timer not found. Setting up manually..."
    systemctl enable certbot.timer
    systemctl start certbot.timer
    success "Certbot auto-renewal timer enabled"
fi

###############################################################################
# Test SSL
###############################################################################

log "Testing SSL configuration..."

# Wait a moment for Nginx to settle
sleep 2

# Test HTTP to HTTPS redirect
if curl -s -I "http://${DOMAIN}" | grep -q "301"; then
    success "HTTP to HTTPS redirect working"
else
    warn "HTTP to HTTPS redirect may not be working. Manual check recommended."
fi

# Test HTTPS
if curl -s -I "https://${DOMAIN}" | grep -q "200\|301"; then
    success "HTTPS is responding"
else
    warn "HTTPS response check failed. Check service status."
fi

###############################################################################
# Summary
###############################################################################

echo ""
echo "=========================================="
echo -e "${GREEN}✓ SSL Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Your domain is now secured with HTTPS!"
echo ""
echo -e "${BLUE}Access your services at:${NC}"
echo "  https://${DOMAIN}          (OpenMOSS WebUI)"
echo "  https://${DOMAIN}/openclaw/ (OpenClaw management)"
echo ""
echo -e "${BLUE}Certificate Information:${NC}"
echo "  Certificate: /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
echo "  Private Key: /etc/letsencrypt/live/${DOMAIN}/privkey.pem"
echo "  Auto-renewal: Enabled (runs automatically)"
echo ""
echo -e "${BLUE}Verify SSL with:${NC}"
echo "  curl https://${DOMAIN}"
echo "  # or open in browser: https://${DOMAIN}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Wait 1-2 minutes for DNS propagation"
echo "2. Visit: https://${DOMAIN}"
echo "3. Complete OpenMOSS setup wizard"
echo "4. Register your first agents!"
echo ""
echo "=========================================="
echo ""
