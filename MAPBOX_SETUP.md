# Mapbox Setup Guide

Based on the [official Mapbox Flutter documentation](https://docs.mapbox.com/flutter/maps/guides/install/).

## Quick Setup

### 1. Get Your Mapbox Public Access Token

1. Go to https://account.mapbox.com/access-tokens/
2. Sign up/login if needed
3. Click "Create a token" or use your default public token
4. Copy the token (starts with `pk.`)

### 2. Run the App with Token

**Option A: Using environment variable**
```bash
export ACCESS_TOKEN=pk.your_token_here
make run-dev
```

**Option B: Using --dart-define directly**
```bash
flutter run --dart-define ACCESS_TOKEN=pk.your_token_here
```

**Option C: Using .env file (recommended)**
Create a `.env` file in the project root:
```bash
echo "ACCESS_TOKEN=pk.your_token_here" > .env
```

The Makefile will automatically load it:
```bash
make run-dev
```

### 3. For Android Builds

You also need the **SDK Registry Token** (starts with `sk.`) in `android/local.properties`:

1. Get SDK token from https://account.mapbox.com/access-tokens/
2. Create a token with **"DOWNLOADS:READ"** scope
3. Add to `android/local.properties`:
   ```
   MAPBOX_SDK_REGISTRY_TOKEN=sk.your_sdk_token_here
   ```

**✅ This is already configured in your project!**

## ⚠️ Important: Two Tokens Needed

Mapbox requires **TWO different tokens**:

| Token Type | Starts With | Purpose | Location | Status |
|------------|-------------|---------|----------|--------|
| **Public Token** | `pk.` | Display maps at runtime | Pass via `--dart-define` | ❌ **YOU NEED THIS** |
| **SDK Token** | `sk.` | Download SDK during build | `android/local.properties` | ✅ Already configured |

**Common Mistake**: Don't use the `sk.` token for displaying maps! It won't work.
You MUST get a separate `pk.` token for the app to display maps.

## VS Code Setup

If using VS Code, add to `.vscode/launch.json`:

```json
{
    "configurations": [
        {
            "name": "Flutter",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": [
                "--dart-define",
                "ACCESS_TOKEN=pk.your_token_here"
            ]
        }
    ]
}
```

## Testing

After setup, the app should:
1. Initialize Mapbox without errors
2. Display maps when Mapbox widgets are added
3. Work on both iOS and Android

## Troubleshooting

- **"ACCESS_TOKEN not provided"** → Make sure you're passing the token via `--dart-define`
- **"SDK Registry token is null"** → Add SDK token to `android/gradle.properties`
- **Map not showing** → Check that token is valid and has correct scopes

