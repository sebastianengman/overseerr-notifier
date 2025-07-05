#!/bin/bash

SERVICE_NAME="overseerr-notifier"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SCRIPT_DIR="/opt/${SERVICE_NAME}"
SCRIPT_FILE="${SCRIPT_DIR}/notifier.sh"
LOG_FILE="/var/log/${SERVICE_NAME}.log"

echo "[1/6] Updating system and installing dependencies..."
apt update && apt install -y curl jq dateutils

echo "[2/6] Creating script directory..."
mkdir -p "$SCRIPT_DIR"

echo "[3/6] Copying notifier script..."
cp "$(dirname "$0")/notifier.sh" "$SCRIPT_FILE"
chmod +x "$SCRIPT_FILE"

echo "[4/6] Creating systemd service..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Overseerr Discord Notifier
After=network.target

[Service]
ExecStart=/bin/bash $SCRIPT_FILE >> $LOG_FILE 2>&1
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "[5/6] Reloading systemd and enabling service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo "[6/6] Starting service..."
systemctl start "$SERVICE_NAME"

echo ""
echo "✅ Overseerr Notifier is installed and running!"
echo "View logs with: journalctl -u $SERVICE_NAME -f"
