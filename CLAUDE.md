# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Flutter Frontend (splitdine2_flutter/)
```bash
# Install dependencies
flutter pub get

# Run development
flutter run

# Build for production
flutter build apk    # Android
flutter build ios    # iOS

# Run static analysis (linting)
flutter analyze

# Run tests
flutter test

# Clean build artifacts
flutter clean
```

### Node.js Backend (splitdine2_server/)
```bash
# Install dependencies
npm install

# Run development with auto-reload
npm run dev

# Run production
npm start

# Note: No lint or test scripts configured yet
```

## High-Level Architecture

SplitDine is a bill-splitting mobile application with:
- **Frontend**: Flutter cross-platform mobile app
- **Backend**: Express.js REST API
- **Database**: PostgreSQL
- **External Services**: Google Vision API (OCR), OpenAI API, Stripe (planned)

### Core Application Flow
1. **Authentication**: Users login/register or join as guests → JWT tokens
2. **Session Lobby**: Central hub showing all dining sessions
3. **Session Creation**: Host creates session with location/date → 6-digit join code
4. **Receipt Processing**: Scan receipt → OCR → parse items → manual editing
5. **Item Assignment**: Assign items to participants (individual or shared)
6. **Payment Summary**: Calculate totals per person with tax/tip distribution

### Frontend Architecture
- **State Management**: Provider pattern with 5 main providers (Auth, Session, Receipt, Assignment, SplitItem)
- **Service Layer**: Dedicated services for API calls (ApiService base class + feature-specific services)
- **Screen Organization**: One screen per file in `lib/screens/`
- **Standardized API**: All POST requests with `return_code` response format

### Backend Architecture
- **Route Structure**: Modular routes under `/api/*` (auth, sessions, receipts, etc.)
- **Middleware Stack**: JWT auth, rate limiting, error handling, security (Helmet)
- **Database Philosophy**: Simple schema, all business logic in API layer
- **Response Format**: Consistent JSON with `return_code`, `message`, `data`, `timestamp`

### Database Schema
Key tables:
- `app_user`: Users (supports anonymous)
- `session`: Dining sessions with metadata
- `session_guest`: Participants in sessions
- `session_receipt`: Receipt items
- `guest_choice`: Item-to-user assignments
- `split_items`: Items marked for sharing

### Key Implementation Details
- **Session Codes**: 6-digit random codes for easy joining
- **Anonymous Users**: Full functionality without registration
- **Split Logic**: Individual items = full price, shared items = price/assignees
- **Real-time Updates**: WebSocket support planned but not implemented
- **Security**: JWT auth, bcrypt passwords, parameterized queries
- **Error Handling**: Comprehensive with user-friendly messages

## Development Guidelines

### Code Standards
- **File Naming**: Always lowercase with underscores (e.g., `user_profile.dart`)
- **API Routes**: Must include complete specification header comments
- **Flutter Screens**: Brief description comment at top of each screen file
- **Response Format**: Never change existing JSON fields (backward compatibility)

### Common Patterns
- **Flutter Navigation**: Use `Navigator.pushNamed()` with route names
- **API Calls**: Always handle loading states and errors
- **Form Validation**: Client-side validation before API calls
- **State Updates**: Use Provider's `notifyListeners()` for UI updates

### Testing Requirements
- Minimum 80% code coverage goal
- Widget tests for UI components
- Integration tests for critical flows
- Unit tests for business logic

### Security Practices
- Never log sensitive data (passwords, tokens)
- Always use parameterized queries
- Validate all user inputs
- Rate limit authentication endpoints