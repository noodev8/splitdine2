# SplitDine Configuration Guide

This guide explains how to configure the SplitDine Flutter app for different environments and network setups.

## Quick Setup

### Change Base URL

Edit `lib/config/app_config.dart` and update the `baseUrl` constant:

```dart
// Change this line to your current server URL
static const String baseUrl = 'http://192.168.1.88:3000/api';

// Other common options:
// static const String baseUrl = 'http://10.0.2.2:3000/api';        // Android emulator
// static const String baseUrl = 'http://127.0.0.1:3000/api';       // Local testing
// static const String baseUrl = 'https://api.splitdine.com/api';   // Production
```

## Configuration Options

### App Settings
- **App Name**: "Split Dine"
- **Debug Banner**: Disabled (always)
- **Logging**: Enabled
- **API Timeout**: 30 seconds

## Common Network Scenarios

### Home Network
```dart
static const String baseUrl = 'http://192.168.1.88:3000/api';
```

### Office Network
```dart
static const String baseUrl = 'http://192.168.0.100:3000/api';
```

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

### Local Testing
```dart
static const String baseUrl = 'http://127.0.0.1:3000/api';
```

### Production
```dart
static const String baseUrl = 'https://api.splitdine.com/api';
```

## How to Find Your IP Address

### Windows
```cmd
ipconfig
```
Look for "IPv4 Address" under your active network adapter.

### macOS/Linux
```bash
ifconfig
```
Look for "inet" under your active network interface.

### Quick Method
The app will print the current configuration when it starts. Check the Flutter console logs to see:
```
=== App Configuration ===
Base URL: http://192.168.1.88:3000/api
App Name: Split Dine
Debug Mode: false
API Timeout: 30s
========================
```

## Server Configuration

Make sure your backend server is configured to accept connections from all interfaces:

In `splitdine2_server/server.js`:
```javascript
app.listen(PORT, '0.0.0.0', () => {
  // Server will accept connections from any IP
});
```

## Troubleshooting

### "Network Error" in App
1. Check that your base URL is correct in `app_config.dart`
2. Ensure the backend server is running
3. Verify the server is accessible: `http://[YOUR_IP]:3000/health`
4. Check firewall settings on your development machine

### Can't Connect from Physical Device
1. Make sure you're using your actual IP address, not `localhost` or `127.0.0.1`
2. Ensure both your development machine and device are on the same network
3. Check that the server is binding to `0.0.0.0`, not just `localhost`

### "Access token is required" Error
1. Make sure you're logged in before accessing the lobby
2. Check that the authentication flow completed successfully
3. Verify the token is being stored correctly

### Production Deployment
1. Update the `baseUrl` to your production server URL
2. Test thoroughly before deployment

## File Locations

- **Main Config**: `lib/config/app_config.dart`
- **Auth Service**: `lib/services/auth_service.dart`
- **Session Service**: `lib/services/session_service.dart`
- **App Entry**: `lib/main.dart`

All services automatically use the configuration from `app_config.dart` - no need to update multiple files!
