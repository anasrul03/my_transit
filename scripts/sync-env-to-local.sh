#!/bin/bash

# Script to sync Mapbox SDK token from .env to android/local.properties

ENV_FILE=".env"
LOCAL_PROPERTIES="android/local.properties"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Extract MAPBOX_SDK_REGISTRY_TOKEN from .env
MAPBOX_TOKEN=$(grep "MAPBOX_SDK_REGISTRY_TOKEN" "$ENV_FILE" | cut -d '=' -f2 | tr -d ' ' | tr -d '"')

if [ -z "$MAPBOX_TOKEN" ]; then
    echo "Error: MAPBOX_SDK_REGISTRY_TOKEN not found in .env file"
    exit 1
fi

# Update local.properties
if [ -f "$LOCAL_PROPERTIES" ]; then
    # Check if MAPBOX_SDK_REGISTRY_TOKEN already exists
    if grep -q "MAPBOX_SDK_REGISTRY_TOKEN" "$LOCAL_PROPERTIES"; then
        # Replace existing token
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|MAPBOX_SDK_REGISTRY_TOKEN=.*|MAPBOX_SDK_REGISTRY_TOKEN=$MAPBOX_TOKEN|" "$LOCAL_PROPERTIES"
        else
            # Linux
            sed -i "s|MAPBOX_SDK_REGISTRY_TOKEN=.*|MAPBOX_SDK_REGISTRY_TOKEN=$MAPBOX_TOKEN|" "$LOCAL_PROPERTIES"
        fi
        echo "✓ Updated MAPBOX_SDK_REGISTRY_TOKEN in $LOCAL_PROPERTIES"
    else
        # Append token
        echo "" >> "$LOCAL_PROPERTIES"
        echo "MAPBOX_SDK_REGISTRY_TOKEN=$MAPBOX_TOKEN" >> "$LOCAL_PROPERTIES"
        echo "✓ Added MAPBOX_SDK_REGISTRY_TOKEN to $LOCAL_PROPERTIES"
    fi
else
    echo "Error: $LOCAL_PROPERTIES not found"
    exit 1
fi

echo "Done! You can now build the app."

