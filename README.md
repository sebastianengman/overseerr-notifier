# Overseerr Notifier

⏰ A lightweight script and systemd service that sends hourly Discord notifications if there are any pending requests in your Overseerr instance.

Perfect for self-hosted users who want to stay on top of user requests without constantly checking the Overseerr web interface.

---

## 📦 Features

- ✅ Polls the Overseerr API for pending requests in regular intervals (default: every hour)
- 📬 Sends notifications to a Discord channel via Webhook
- 💡 Includes detailed info per request:
  - Movie/TV show title 🎬/📺
  - Requested by (user display name)
  - How long ago the request was made

---

## ⚙️ Configuration

Edit the notifier.sh script after cloning or before installing to set:

```bash
OVERSEERR_URL="https://overseerr.example.com"     # your Overseerr domain or IP
OVERSEERR_API_KEY="your_overseerr_api_key"        # Server API key from Overseerr
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."  # Your Discord Webhook URL
CHECK_INTERVAL=3600                               # Polling interval in seconds (default: 1 hour)
