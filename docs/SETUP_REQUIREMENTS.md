# SplitDine Setup Requirements

## Required Software Downloads

### Development Environment
- [x] **Flutter SDK** (Latest stable version)
  - Download: https://flutter.dev/docs/get-started/install
  - Includes Dart SDK
  - Platform: Windows/macOS/Linux

- [x] **Android Studio** (Recommended IDE)
  - Download: https://developer.android.com/studio
  - Includes Android SDK and emulator
  - Alternative: VS Code with Flutter extension

- [x] **Xcode** (macOS only - for iOS development)
  - Download: Mac App Store
  - Required for iOS builds and simulator

- [x] **Git** (Version control)
  - Download: https://git-scm.com/downloads
  - For code versioning and collaboration

### Backend Development Tools
- [ ] **Node.js** (v18+ LTS)
  - Download: https://nodejs.org/
  - Required for Express.js backend server
  - Includes npm package manager

- [ ] **PostgreSQL** (v14+)
  - Download: https://www.postgresql.org/download/
  - Alternative: Docker PostgreSQL container
  - Required for database storage

- [ ] **Docker** (Optional but recommended)
  - Download: https://www.docker.com/products/docker-desktop
  - For containerized development environment
  - Simplifies PostgreSQL setup

### Mobile Development Tools
- [x] **Android SDK** (via Android Studio)
  - API Level 21+ (Android 5.0+)
  - Build tools and platform tools

- [x] **iOS SDK** (via Xcode - macOS only)
  - iOS 11.0+ support
  - Simulator and device tools

### Code Editor (Alternative to Android Studio)
- [x] **Visual Studio Code**
  - Download: https://code.visualstudio.com/
  - Extensions needed:
    - Flutter
    - Dart
    - PostgreSQL
    - REST Client
    - GitLens

## Required Service Registrations

### External API Services
- [ ] **Google Cloud Platform Account**
  - URL: https://console.cloud.google.com/
  - Services needed:
    - Vision API (for OCR)
    - Enable billing for API usage
    - Generate API credentials

- [ ] **OpenAI Account**
  - URL: https://platform.openai.com/
  - Required for GPT-powered receipt parsing
  - Generate API key for backend integration
    - Cloud Storage
    - Hosting (optional)
  - Pricing: Free tier available, pay-as-you-go

### AI/ML Services
- [ ] **Google Cloud Platform Account**
  - URL: https://cloud.google.com/
  - For Google Vision API (OCR)
  - Free tier: $300 credit for new users
  - Enable Vision API in console

- [ ] **OpenAI Account**
  - URL: https://platform.openai.com/
  - For GPT API (receipt parsing)
  - Pricing: Pay-per-use (starts ~$0.002/1K tokens)
  - Get API key from dashboard

### Payment Processing
- [ ] **Stripe Account**
  - URL: https://stripe.com/
  - For payment processing
  - Stripe Connect for marketplace payments
  - Free to set up, transaction fees apply

### Development Tools (Optional but Recommended)
- [x] **GitHub Account** (if not using existing repo)
  - URL: https://github.com/
  - For code hosting and collaboration
  - Free for public/private repos

## API Keys and Configuration

### Required API Keys
1. **Firebase Configuration**
   - Web API key
   - Project ID
   - App ID (Android/iOS)
   - Messaging Sender ID

2. **Google Vision API Key**
   - Enable Vision API in Google Cloud Console
   - Create service account or API key
   - Download service account JSON (recommended)

3. **OpenAI API Key**
   - Generate from OpenAI dashboard
   - Set usage limits for cost control

4. **Stripe Keys**
   - Publishable key (client-side)
   - Secret key (server-side)
   - Webhook endpoint secret

### Environment Configuration Files Needed
```
.env (for development)
├── FIREBASE_API_KEY=your_key
├── GOOGLE_VISION_API_KEY=your_key
├── OPENAI_API_KEY=your_key
├── STRIPE_PUBLISHABLE_KEY=your_key
└── STRIPE_SECRET_KEY=your_key
```

## Hardware Requirements

### Development Machine
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB+ free space
- **OS**: Windows 10+, macOS 10.14+, or Linux
- **Internet**: Stable broadband connection

### Testing Devices
- **Android Device** (API 21+) or emulator
- **iOS Device** (iOS 11+) or simulator (macOS only)
- **Multiple screen sizes** for responsive testing

## Development Dependencies (Installed via Package Managers)

### Flutter Packages (pubspec.yaml)
```yaml
dependencies:
  google_ml_vision: ^latest
  http: ^latest
  provider: ^latest
  qr_flutter: ^latest
  qr_code_scanner: ^latest
  image_picker: ^latest
  stripe_payment: ^latest
```

### Node.js (for Firebase Functions)
- [ ] **Node.js** (LTS version)
  - Download: https://nodejs.org/
  - Required for Firebase Cloud Functions
  - npm package manager included

- [ ] **Firebase CLI**
  - Install: `npm install -g firebase-tools`
  - For deploying functions and hosting

## Setup Cost Estimates

### Free Tier Services
- Google Cloud ($300 credit for new users)
- GitHub (unlimited public/private repos)
- Android development (free)

### Paid Services (Development Phase)
- OpenAI API: ~$10-50/month (depending on usage)
- iOS Developer Program: $99/year (for App Store)
- Stripe: Free setup, 2.9% + 30¢ per transaction

### Total Estimated Setup Cost
- **Development Only**: $0-20/month
- **With iOS Publishing**: $99/year additional
- **Production Ready**: $50-200/month (depending on scale)

## Installation Order Recommendation

### Phase 1: Core Development Setup
1. Install Flutter SDK
2. Install Android Studio or VS Code
3. Set up Android emulator
4. Install Git

### Phase 2: External Services
1. Set up Google Cloud Platform
2. Enable Vision API
3. Create OpenAI account
4. Set up Stripe account
5. Generate all API keys

### Phase 3: Advanced Setup
2. Set up CI/CD (GitHub Actions)
3. Configure testing devices
4. Set up monitoring and analytics

## Verification Checklist

### Development Environment Ready
- [ ] `flutter doctor` shows no issues
- [ ] Android emulator launches successfully
- [ ] Can create and run new Flutter project
- [ ] Git is configured with your credentials

### Services Connected
- [ ] Firebase project created and configured
- [ ] All API keys generated and secured
- [ ] Test API calls work (Vision, OpenAI, Stripe)
- [ ] Firebase CLI authenticated

### Security Setup
- [ ] API keys stored securely (not in code)
- [ ] Environment variables configured
- [ ] .gitignore includes sensitive files
- [ ] Service account permissions configured

## Troubleshooting Resources

### Common Issues
- **Flutter Doctor Issues**: https://flutter.dev/docs/get-started/install
- **Android Setup**: https://developer.android.com/studio/troubleshoot
- **API Integration**: Check respective service documentation

### Support Channels
- Flutter: https://flutter.dev/community
- Stack Overflow for specific technical issues

## Next Steps After Setup

1. **Verify Installation**: Run through verification checklist
2. **Create Test Project**: Build simple "Hello World" with Firebase
3. **Test API Integrations**: Verify all external services work
4. **Begin Phase 1**: Start with project initialization tasks

This setup will provide everything needed for the complete SplitDine development process.
