#!/usr/bin/env bash
# =============================================================================
# Run this on the JUMP SERVER to configure Nginx reverse proxy
# Designed for: AWS ALB in front (SSL terminated at ALB, HTTP only here)
# OS: RHEL / Amazon Linux (yum) or Ubuntu (apt)
#
# Usage:
#   sudo bash setup_jump_server.sh --app-ip 192.168.1.100
# =============================================================================

set -euo pipefail

APP_IP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app-ip) APP_IP="$2"; shift 2 ;;
        *) echo "[WARN] Unknown: $1"; shift ;;
    esac
done

[[ -n "$APP_IP" ]] || { echo "[ERROR] --app-ip required (private IP of app server)"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect package manager ────────────────────────────────────────────────────
echo "[INFO] Installing Nginx..."
if command -v yum &>/dev/null; then
    yum install -y nginx
elif command -v apt-get &>/dev/null; then
    apt-get update -q && apt-get install -y nginx
else
    echo "[ERROR] No supported package manager found (yum/apt)"; exit 1
fi

# ── Write Nginx config ────────────────────────────────────────────────────────
echo "[INFO] Writing Nginx config (app=$APP_IP)..."

# Detect config location (RHEL uses conf.d, Ubuntu uses sites-available)
if [[ -d /etc/nginx/conf.d ]]; then
    NGINX_CONF=/etc/nginx/conf.d/voicebot.conf
else
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    NGINX_CONF=/etc/nginx/sites-available/voicebot
    rm -f /etc/nginx/sites-enabled/default
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/voicebot
fi

sed \
    -e "s|APP_SERVER_PRIVATE_IP|$APP_IP|g" \
    "$SCRIPT_DIR/config/nginx-jump-server.conf" \
    > "$NGINX_CONF"

# ── Remove default server block if present (RHEL) ─────────────────────────────
if [[ -f /etc/nginx/conf.d/default.conf ]]; then
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
    echo "[INFO] Disabled default Nginx config"
fi

nginx -t && systemctl enable nginx && systemctl restart nginx

echo ""
echo "========================================"
echo "  Jump Server Setup Complete"
echo "========================================"
echo "  SSL     : Terminated at AWS ALB (no local certs needed)"
echo "  CPaaS   : https://cps.denaipoc.sproutsandbox.com → $APP_IP:5000"
echo "  Dashboard: https://mgn.denaipoc.sproutsandbox.com → $APP_IP:3000"
echo ""
echo "  ALB Health check: GET /health → 200 ok"
echo ""
echo "  Test (from jump server):"
echo "    curl http://localhost/health"
echo "    curl -H 'Host: cps.denaipoc.sproutsandbox.com' http://localhost/bot/dial?to=%2B1&lang=en"
