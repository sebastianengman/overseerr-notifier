#!/bin/bash

SERVICE_NAME="overseerr-notifier"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SCRIPT_DIR="/opt/${SERVICE_NAME}"
SCRIPT_FILE="${SCRIPT_DIR}/notifier.sh"
LOG_FILE="/var/log/${SERVICE_NAME}.log"

echo
echo "🔧 Welcome to the Overseerr Notifier Installer"
echo

# Step 1 – Ask for input interactively
read -rp "👉 Enter your Overseerr URL (e.g. http://192.168.1.10:5055): " OVERSEERR_URL
read -rp "🔑 Enter your Overseerr API key: " OVERSEERR_API_KEY
read -rp "🌐 Enter your Discord Webhook URL: " DISCORD_WEBHOOK_URL
read -rp "⏱️ Check interval in seconds (default 3600): " CHECK_INTERVAL

# Set default if empty
CHECK_INTERVAL=${CHECK_INTERVAL:-3600}

# Step 2 – Install dependencies
echo "[1/5] Installing required packages..."
apt update && apt install -y curl jq dateutils

# Step 3 – Create script directory and script
echo "[2/5] Creating script in $SCRIPT_DIR..."
mkdir -p "$SCRIPT_DIR"

cat > "$SCRIPT_FILE" <<EOF
#!/bin/bash

OVERSEERR_URL="$OVERSEERR_URL"
OVERSEERR_API_KEY="$OVERSEERR_API_KEY"
DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
CHECK_INTERVAL=$CHECK_INTERVAL

get_title() {
    local type="\$1"
    local tmdbId="\$2"

    if [ "\$tmdbId" == "null" ] || [ -z "\$tmdbId" ]; then
        echo "Unknown Title"
        return
    fi

    if [ "\$type" == "tv" ]; then
        curl -s -H "X-Api-Key: \$OVERSEERR_API_KEY" "\$OVERSEERR_URL/api/v1/tv/\$tmdbId" | jq -r '.name // "Unknown Title"'
    else
        curl -s -H "X-Api-Key: \$OVERSEERR_API_KEY" "\$OVERSEERR_URL/api/v1/movie/\$tmdbId" | jq -r '.title // "Unknown Title"'
    fi
}

while true; do
    echo "[INFO] Checking Overseerr for pending requests..."

    RESPONSE=\$(curl -s -H "Accept: application/json" \\
        -H "X-Api-Key: \$OVERSEERR_API_KEY" \\
        "\$OVERSEERR_URL/api/v1/request?take=50&filter=pending")

    PENDING_COUNT=\$(echo "\$RESPONSE" | jq '.results | length')

    if [ "\$PENDING_COUNT" -gt 0 ]; then
        MESSAGE=":warning: **\$PENDING_COUNT pending requests in Overseerr!**\\n\\n"

        IDS=\$(echo "\$RESPONSE" | jq -r '.results[].id')

        i=1
        for ID in \$IDS; do
            ENTRY=\$(echo "\$RESPONSE" | jq -r --argjson id \$ID '.results[] | select(.id == \$id)')
            TYPE=\$(echo "\$ENTRY" | jq -r '.type')
            CREATED=\$(echo "\$ENTRY" | jq -r '.createdAt')
            USERNAME=\$(echo "\$ENTRY" | jq -r '.requestedBy.displayName // "Unknown User"')
            TMDBID=\$(echo "\$ENTRY" | jq -r '.media.tmdbId // empty')
            TITLE=\$(get_title "\$TYPE" "\$TMDBID")

            TIME_AGO=\$(dateutils.ddiff "\$CREATED" now -f '%dd %Hh' 2>/dev/null || echo "?")
            ICON="🎬"
            [ "\$TYPE" == "tv" ] && ICON="📺"

            MESSAGE+="\$i. \$ICON \$TITLE (requested by \$USERNAME – \$TIME_AGO ago)\\n"
            ((i++))
        done

        curl -H "Content-Type: application/json" \\
             -X POST \\
             -d "{\\\"content\\\": \\\"\$MESSAGE\\\"}" \\
             "\$DISCORD_WEBHOOK_URL"
    else
        echo "[INFO] No pending requests found."
    fi

    sleep "\$CHECK_INTERVAL"
done
EOF

chmod +x "$SCRIPT_FILE"

# Step 4 – Create systemd service
echo "[3/5] Creating systemd service..."

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Overseerr Discord Notifier
After=network.target

[Service]
ExecStart=$SCRIPT_FILE >> $LOG_FILE 2>&1
User=root
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Step 5 – Enable and start service
echo "[4/5] Reloading systemd..."
systemctl daemon-reload

echo "[5/5] Enabling and starting service..."
systemctl enable overseerr-notifier
systemctl start overseerr-notifier

echo ""
echo "✅ Installation complete!"
echo "Use: journalctl -u overseerr-notifier -f to view logs"
