#!/bin/bash

# 🔧 Configuration – Replace with your own credentials
OVERSEERR_URL="https://overseerr.example.com"
OVERSEERR_API_KEY="your_overseerr_api_key"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/your_webhook"
CHECK_INTERVAL=3600  # 1 hour in seconds

# 🔄 Function to retrieve title if missing in .media
get_title() {
    local type="$1"
    local tmdbId="$2"

    if [ "$tmdbId" == "null" ] || [ -z "$tmdbId" ]; then
        echo "Unknown Title"
        return
    fi

    if [ "$type" == "tv" ]; then
        curl -s -H "X-Api-Key: $OVERSEERR_API_KEY" "$OVERSEERR_URL/api/v1/tv/$tmdbId" | jq -r '.name // "Unknown Title"'
    else
        curl -s -H "X-Api-Key: $OVERSEERR_API_KEY" "$OVERSEERR_URL/api/v1/movie/$tmdbId" | jq -r '.title // "Unknown Title"'
    fi
}

# 🌀 Loop forever or until manually stopped
while true; do
    echo "[INFO] Checking Overseerr for pending requests..."

    RESPONSE=$(curl -s -H "Accept: application/json" \
        -H "X-Api-Key: $OVERSEERR_API_KEY" \
        "$OVERSEERR_URL/api/v1/request?take=50&filter=pending")

    PENDING_COUNT=$(echo "$RESPONSE" | jq '.results | length')

    if [ "$PENDING_COUNT" -gt 0 ]; then
        MESSAGE=":warning: **$PENDING_COUNT pending requests in Overseerr!**\\n\\n"

        IDS=$(echo "$RESPONSE" | jq -r '.results[].id')

        i=1
        for ID in $IDS; do
            ENTRY=$(echo "$RESPONSE" | jq -r --argjson id $ID '.results[] | select(.id == $id)')
            TYPE=$(echo "$ENTRY" | jq -r '.type')
            CREATED=$(echo "$ENTRY" | jq -r '.createdAt')
            USERNAME=$(echo "$ENTRY" | jq -r '.requestedBy.displayName // "Unknown User"')

            # Get TMDB ID and fallback title from detailed lookup
            TMDBID=$(echo "$ENTRY" | jq -r '.media.tmdbId // empty')
            TITLE=$(get_title "$TYPE" "$TMDBID")

            TIME_AGO=$(dateutils.ddiff "$CREATED" now -f '%dd %Hh' 2>/dev/null || echo "?")

            ICON="🎬"
            [ "$TYPE" == "tv" ] && ICON="📺"

            MESSAGE+="$i. $ICON $TITLE (requested by $USERNAME – $TIME_AGO ago)\\n"
            ((i++))
        done

        echo "[INFO] Sending message to Discord..."
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"$MESSAGE\"}" \
             "$DISCORD_WEBHOOK_URL"
    else
        echo "[INFO] No pending requests found."
    fi

    echo "[INFO] Sleeping for $CHECK_INTERVAL seconds..."
    sleep "$CHECK_INTERVAL"
done
