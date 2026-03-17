# Voicebot Application Deployment

One-command deployment for the full voicebot application stack:
- **Next.js frontend** (port 3000) — chat UI with ASR / LLM / TTS API routes
- **Pipecat bot** (port 5000) — Twilio voice pipeline (STT → LLM → TTS)

## Prerequisites

These services must already be running before you deploy the app:

| Service | Port | Repo |
|---------|------|------|
| `voicebot-stt` | 8000 | [STT_NEC](https://github.com/dcodingx/stt_nec) |
| `voicebot-llm` | 8001 | LLM_NEC |
| `voicebot-tts` | 8005 | [TTS_NEC](https://github.com/dcodingx/TTS_NEC) |

## Architecture

```
Browser  →  Next.js :3000
               ├── /api/asr  →  voicebot-stt  :8000  (Qwen3-ASR vLLM)
               ├── /api/chat →  voicebot-llm  :8001  (shisa-v2 vLLM)
               └── /api/tts  →  voicebot-tts  :8005  (Qwen3-TTS FastAPI)

Twilio call → pipecat bot :5000 → same STT / LLM / TTS services
```

## Quick Deploy

```bash
# 1. Clone this repo on the client server
git clone https://github.com/dcodingx/deploy_app.git

# 2. Copy and edit client.env
cp config/client.env.example config/client.env
nano config/client.env      # set TTS_API_URL, LLM_API_URL, Twilio creds, BASE_URL

# 3. Run setup (requires sudo — installs Node.js, builds Next.js, registers systemd)
sudo bash setup.sh

# 4. Verify
bash healthcheck.sh
```

## Custom Paths

```bash
sudo bash setup.sh \
  --frontend-dir /path/to/llm-tts-chat-app \
  --bot-dir      /path/to/local-bot \
  --user         ubuntu
```

## Configuration

**`config/client.env`** — all runtime settings:

```env
# Service endpoints
ASR_API_URL=http://localhost:8000
LLM_API_URL=http://localhost:8001
TTS_API_URL=http://localhost:8005

# Twilio (for voice bot)
TWILIO_ACCOUNT_SID=ACxxx...
TWILIO_AUTH_TOKEN=xxx...

# Public hostname for Twilio TwiML callbacks
BASE_URL=ai-server-nexs.dcodingx.in
```

## Services After Setup

```bash
# Status
systemctl status voicebot-nextjs
systemctl status voicebot-bot

# Logs
journalctl -u voicebot-nextjs -f
journalctl -u voicebot-bot -f

# Restart
systemctl restart voicebot-nextjs voicebot-bot
```

## Health Check

```bash
bash healthcheck.sh
```

Checks: Next.js (3000), Bot API (5000), STT (8000), LLM (8001), TTS (8005), all systemd services.

## Files

```
deploy_app/
├── setup.sh                        # One-command installer
├── start_bot.sh                    # Manual bot start (no systemd)
├── healthcheck.sh                  # Service health check
└── config/
    ├── client.env.example          # Environment variable template
    ├── voicebot-nextjs.service     # systemd unit — Next.js frontend
    └── voicebot-bot.service        # systemd unit — pipecat voice bot
```
