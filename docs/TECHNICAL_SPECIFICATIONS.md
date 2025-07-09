# SplitDine Technical Specifications

## Database Schema (Firestore)

### Collections Structure

#### `/sessions/{sessionId}`
```json
{
  "id": "string",
  "organizerId": "string",
  "joinCode": "string (6-digit)",
  "status": "active|completed|cancelled",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "restaurantName": "string?",
  "receiptData": {
    "imageUrl": "string?",
    "ocrText": "string?",
    "parsedItems": "array",
    "totalAmount": "number",
    "tax": "number",
    "tip": "number",
    "serviceCharge": "number"
  },
  "participants": {
    "userId": {
      "name": "string",
      "joinedAt": "timestamp",
      "role": "organizer|participant",
      "confirmed": "boolean"
    }
  },
  "assignments": {
    "itemId": {
      "assignedTo": "array<userId>",
      "splitType": "equal|custom",
      "customSplits": "object?"
    }
  },
  "finalSplit": {
    "userId": {
      "amount": "number",
      "items": "array<itemId>",
      "confirmed": "boolean",
      "paid": "boolean"
    }
  }
}
```

#### `/users/{userId}`
```json
{
  "id": "string",
  "email": "string?",
  "phone": "string?",
  "displayName": "string",
  "isAnonymous": "boolean",
  "createdAt": "timestamp",
  "lastActiveAt": "timestamp",
  "paymentMethods": "array?",
  "preferences": {
    "defaultTipPercentage": "number",
    "notifications": "boolean"
  }
}
```

#### `/receiptItems/{itemId}`
```json
{
  "id": "string",
  "sessionId": "string",
  "name": "string",
  "price": "number",
  "quantity": "number",
  "category": "food|drink|service|other",
  "description": "string?",
  "parsedConfidence": "number",
  "manuallyEdited": "boolean"
}
```

## API Endpoints (Firebase Functions)

### Receipt Processing
- `POST /processReceipt` - OCR and AI parsing
- `POST /validateReceipt` - Validate parsed data
- `PUT /updateReceiptItem` - Manual item editing

### Session Management
- `POST /createSession` - Create new session
- `POST /joinSession` - Join existing session
- `PUT /updateSession` - Update session data
- `DELETE /leaveSession` - Leave session

### Payment Processing
- `POST /createPaymentIntent` - Stripe payment setup
- `POST /processPayment` - Handle payment
- `GET /paymentStatus` - Check payment status

## Real-time Data Flow

### Session Updates
1. User action triggers Firestore write
2. Firestore listeners notify all participants
3. UI updates optimistically with conflict resolution
4. Server-side validation ensures data consistency

### Conflict Resolution
- Last-write-wins for simple fields
- Merge strategies for complex objects
- User notification for conflicts requiring manual resolution

## Security Rules (Firestore)

### Sessions
```javascript
// Users can read sessions they're participants in
// Only organizers can write to session data
// Participants can write to their own assignments
```

### Users
```javascript
// Users can only read/write their own user document
// Public fields available for session participants
```

## External API Integration

### Google Vision API
- Image preprocessing and optimization
- OCR text extraction with confidence scores
- Error handling and retry logic

### OpenAI GPT API
- Structured prompt for receipt parsing
- JSON response validation
- Fallback to manual parsing on failure

### Stripe Connect
- Account creation and verification
- Payment processing with fees
- Webhook handling for payment events

## Performance Considerations

### Image Handling
- Client-side compression before upload
- Progressive image loading
- Automatic cleanup of old images

### Real-time Sync
- Efficient query patterns
- Connection state management
- Offline capability with sync on reconnect

### Cost Optimization
- Session data archival after completion
- Image storage lifecycle management
- API usage monitoring and limits

## Error Handling

### Network Errors
- Retry logic with exponential backoff
- Offline mode with local storage
- User-friendly error messages

### API Failures
- Graceful degradation for OCR/AI failures
- Manual input fallbacks
- Payment failure recovery flows

### Data Validation
- Client and server-side validation
- Input sanitization
- Type safety with proper models

## Testing Strategy

### Unit Tests
- Business logic and calculations
- Data model validation
- Utility functions

### Integration Tests
- Firebase operations
- API integrations
- Real-time synchronization

### End-to-End Tests
- Complete user flows
- Cross-platform compatibility
- Performance benchmarks

## Deployment Configuration

### Environment Variables
- API keys and secrets
- Firebase configuration
- Feature flags

### Build Configuration
- Release vs debug builds
- Code obfuscation
- Asset optimization

### Monitoring
- Crash reporting
- Performance monitoring
- User analytics
