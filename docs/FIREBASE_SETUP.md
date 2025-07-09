# Firebase Setup Guide for SplitDine

## Required Configuration Files

When setting up SplitDine on a new development machine, you'll need to add the Firebase configuration files that are excluded from git for security reasons.

### Files Needed

1. **Android Configuration**
   - File: `google-services.json`
   - Location: `splitdine2_flutter/android/app/google-services.json`
   - Source: Firebase Console → Project Settings → Your apps → Android app

2. **iOS Configuration**
   - File: `GoogleService-Info.plist`
   - Location: `splitdine2_flutter/ios/Runner/GoogleService-Info.plist`
   - Source: Firebase Console → Project Settings → Your apps → iOS app

### How to Get These Files

#### From Firebase Console:
1. Go to https://console.firebase.google.com/project/splitdine
2. Click the gear icon → Project settings
3. Scroll down to "Your apps" section
4. For Android app: Click the `google-services.json` download button
5. For iOS app: Click the `GoogleService-Info.plist` download button

#### From Another Development Machine:
If you already have these files on another machine, simply copy them:

**Windows/Linux:**
```bash
# Copy from your main development machine
scp user@main-machine:/path/to/splitdine2/splitdine2_flutter/android/app/google-services.json ./android/app/
scp user@main-machine:/path/to/splitdine2/splitdine2_flutter/ios/Runner/GoogleService-Info.plist ./ios/Runner/
```

**Manual Copy:**
1. Copy `google-services.json` from your main machine
2. Place it in `splitdine2_flutter/android/app/`
3. Copy `GoogleService-Info.plist` from your main machine  
4. Place it in `splitdine2_flutter/ios/Runner/`

### Verification

After placing the files, verify they're in the correct locations:

```
splitdine2_flutter/
├── android/
│   └── app/
│       └── google-services.json ✓
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist ✓
└── lib/
    └── firebase_options.dart ✓ (already in git)
```

### Security Notes

- These files contain your Firebase project configuration
- They're excluded from git via `.gitignore` for security
- Never commit them to public repositories
- Each developer should get their own copy from Firebase Console or securely from team lead

### Troubleshooting

**If you get Firebase connection errors:**
1. Verify files are in correct locations (see above)
2. Check file names are exact (case-sensitive)
3. Ensure files aren't corrupted during transfer
4. Try re-downloading from Firebase Console

**If builds fail:**
1. Run `flutter clean`
2. Run `flutter pub get`
3. Rebuild the app

### Environment-Specific Setup (Future)

When you have multiple environments (dev/staging/prod):
1. Create separate Firebase projects for each environment
2. Download separate config files for each
3. Use build flavors or environment variables to switch between them

This approach keeps your configurations secure while maintaining development flexibility.
