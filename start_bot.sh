#!/usr/bin/env bash
# Start the pipecat voice bot manually (systemd-equivalent for manual runs)
#
# Usage: bash start_bot.sh
#        VLLM_TTS_BASE_URL=http://localhost:8003 bash start_bot.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOT_DIR="${BOT_DIR:-/home/ubuntu/local-bot}"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/config/client.env}"

# Load client env if present
if [[ -f "$ENV_FILE" ]]; then
    set -o allexport
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +o allexport
fi

PYTHON="$BOT_DIR/.venv/bin/python"
[[ -x "$PYTHON" ]] || { echo "[ERROR] venv not found at $BOT_DIR/.venv — run setup.sh first"; exit 1; }

echo "[INFO] Starting pipecat bot at http://0.0.0.0:5000"
cd "$BOT_DIR"
exec "$PYTHON" -m uvicorn main:app --host 0.0.0.0 --port 5000 --log-level info
