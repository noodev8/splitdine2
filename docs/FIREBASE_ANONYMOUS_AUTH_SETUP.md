# Firebase Anonymous Authentication Setup

## Issue
The "Continue as Guest" button shows this error:
```
[firebase_auth/admin-restricted-operation] This operation is restricted to administrators only.
```

## Solution
Anonymous authentication needs to be enabled in the Firebase console.

## Steps to Enable Anonymous Authentication

### 1. Open Firebase Console
- Go to [Firebase Console](https://console.firebase.google.com/)
- Select your `splitdine` project

### 2. Navigate to Authentication
- In the left sidebar, click on **Authentication**
- Click on the **Sign-in method** tab

### 3. Enable Anonymous Authentication
- Scroll down to find **Anonymous** in the list of providers
- Click on **Anonymous**
- Toggle the **Enable** switch to ON
- Click **Save**

### 4. Verify Setup
- The Anonymous provider should now show as "Enabled" in the list
- Test the "Continue as Guest" button in your app

## Alternative: Disable Guest Mode (Temporary)
If you prefer to disable guest mode for now, you can hide the button by modifying the auth screen:

```dart
// In auth_screen.dart, comment out or remove this section:
/*
SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    onPressed: _isLoading ? null : _signInAnonymously,
    child: const Text('Continue as Guest'),
  ),
),
*/
```

## Security Considerations
- Anonymous users have limited access based on Firestore security rules
- Anonymous accounts can be converted to permanent accounts later
- Consider implementing session timeouts for anonymous users

## Testing
After enabling anonymous authentication:
1. Tap "Continue as Guest" in the app
2. You should see "Welcome, Guest!" on the home screen
3. You should be able to create and join sessions as a guest user
