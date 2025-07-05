#!/bin/bash

SERVICE_NAME="overseerr-notifier"
SCRIPT_DIR="/opt/${SERVICE_NAME}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
LOG_FILE="/var/log/${SERVICE_NAME}.log"

echo "[1/4] Stopping service..."
systemctl stop "$SERVICE_NAME"
systemctl disable "$SERVICE_NAME"

echo "[2/4] Removing files..."
rm -rf "$SCRIPT_DIR"
rm -f "$SERVICE_FILE"
rm -f "$LOG_FILE"

echo "[3/4] Reloading systemd..."
systemctl daemon-reload

echo "[✅ DONE] Overseerr Notifier has been uninstalled."
