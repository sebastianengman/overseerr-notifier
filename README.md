# Overseerr Notifier

⏰ A Bash script + systemd service that sends hourly Discord notifications for any pending requests in your Overseerr server.

## 📦 Features

- Polls the Overseerr API every hour (by default)
- Checks for pending (unreviewed) requests
- Sends a detailed message to a Discord webhook
- Includes title, requesting user, and how long the request has been pending

## 🧰 Requirements

- Debian or Ubuntu (or compatible)
- Required packages: curl, jq, dateutils (installed automatically)

## 🚀 Quick Install (recommended)

Run this command on your server:

```bash
bash <(curl -s https://raw.githubusercontent.com/sebastianengman/overseerr-notifier/main/install.sh)
