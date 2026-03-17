#!/usr/bin/env bash
# =============================================================================
# Run this on the JUMP SERVER to configure Nginx reverse proxy
#
# Usage:
#   sudo bash setup_jump_server.sh --domain ai-server.dcodingx.in \
#                                  --app-ip  192.168.1.100
# =============================================================================

set -euo pipefail

DOMAIN=""
APP_IP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain) DOMAIN="$2"; shift 2 ;;
        --app-ip) APP_IP="$2";  shift 2 ;;
        *) echo "[WARN] Unknown: $1"; shift ;;
    esac
done

[[ -n "$DOMAIN" ]] || { echo "[ERROR] --domain required";  exit 1; }
[[ -n "$APP_IP" ]]  || { echo "[ERROR] --app-ip required"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Installing Nginx..."
apt-get update -q && apt-get install -y nginx certbot python3-certbot-nginx

echo "[INFO] Writing Nginx config (domain=$DOMAIN, app=$APP_IP)..."
sed \
    -e "s|DOMAIN|$DOMAIN|g" \
    -e "s|APP_SERVER_PRIVATE_IP|$APP_IP|g" \
    "$SCRIPT_DIR/config/nginx-jump-server.conf" \
    > /etc/nginx/sites-available/voicebot

# Disable default site if present
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/voicebot /etc/nginx/sites-enabled/voicebot

echo "[INFO] Obtaining SSL certificate via certbot..."
# Temporarily allow HTTP for certbot challenge
sed -i 's/return 301/# return 301/' /etc/nginx/sites-available/voicebot
nginx -t && systemctl reload nginx

certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos \
    --register-unsafely-without-email || {
    echo "[WARN] certbot failed — configure SSL manually or re-run certbot"
}

# Re-enable redirect
sed -i 's/# return 301/return 301/' /etc/nginx/sites-available/voicebot

nginx -t && systemctl reload nginx

echo ""
echo "========================================"
echo "  Jump Server Setup Complete"
echo "========================================"
echo "  Domain : https://$DOMAIN"
echo "  Proxies: / → $APP_IP:3000  (Next.js)"
echo "           /bot/ → $APP_IP:5000  (Bot + Twilio WS)"
echo ""
echo "  Test:"
echo "    curl -I https://$DOMAIN"
echo "    curl https://$DOMAIN/bot/dial?to=%2B1&lang=en"
