#!/usr/bin/env bash
# Health check for all voicebot application services

PASS=0
FAIL=0

check_http() {
    local name="$1" url="$2"
    if curl -sf --max-time 3 "$url" &>/dev/null; then
        echo "[OK  ] $name — $url"
        ((PASS++)) || true
    else
        echo "[FAIL] $name — $url"
        ((FAIL++)) || true
    fi
}

check_svc() {
    local name="$1"
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        echo "[OK  ] $name (systemd: $(systemctl is-active "$name"))"
        ((PASS++)) || true
    else
        echo "[FAIL] $name (systemd: $(systemctl is-active "$name" 2>/dev/null || echo 'not found'))"
        ((FAIL++)) || true
    fi
}

echo "========================================"
echo "  Voicebot Application — Health Check"
echo "========================================"
echo ""
echo "--- HTTP Endpoints ---"
check_http "Next.js  (3000)" "http://localhost:3000"
check_http "Bot API  (5000)" "http://localhost:5000/bot/dial?to=%2B1&lang=en"
check_http "STT vLLM (8000)" "http://localhost:8000/health"
check_http "LLM vLLM (8001)" "http://localhost:8001/health"
check_http "TTS      (8005)" "http://localhost:8005/health"
echo ""
echo "--- Systemd Services ---"
check_svc "voicebot-nextjs"
check_svc "voicebot-bot"
check_svc "voicebot-stt"
check_svc "voicebot-tts"
echo ""

TOTAL=$((PASS + FAIL))
echo "Result: $PASS/$TOTAL checks passed"
[[ $FAIL -eq 0 ]] && echo "All checks passed." || echo "$FAIL check(s) failed."
exit $FAIL
