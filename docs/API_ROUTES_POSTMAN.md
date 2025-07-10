# SplitDine API Routes - Postman Documentation

## Base URL
```
Development: http://localhost:3000/api
Production: https://api.splitdine.com/api
```

## Authentication
All protected routes require JWT token in header:
```
Authorization: Bearer <jwt_token>
```

---

## Authentication Routes

### 1. Register User
**POST** `/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "display_name": "John Doe"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 123,
    "display_name": "John Doe",
    "email": "user@example.com",
    "is_anonymous": false
  }
}
```

**Return Codes:** `SUCCESS`, `MISSING_FIELDS`, `EMAIL_EXISTS`, `WEAK_PASSWORD`, `SERVER_ERROR`

---

### 2. Login User
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 123,
    "display_name": "John Doe",
    "email": "user@example.com",
    "is_anonymous": false
  }
}
```

**Return Codes:** `SUCCESS`, `MISSING_FIELDS`, `INVALID_CREDENTIALS`, `SERVER_ERROR`

---

### 3. Refresh Token
**POST** `/auth/refresh`

**Request Body:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "token": "new_jwt_token_here",
  "refresh_token": "new_refresh_token_here"
}
```

**Return Codes:** `SUCCESS`, `INVALID_TOKEN`, `TOKEN_EXPIRED`, `SERVER_ERROR`

---

### 4. Get Current User
**POST** `/auth/me`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "user": {
    "id": 123,
    "display_name": "John Doe",
    "email": "user@example.com",
    "is_anonymous": false,
    "created_at": "2024-01-15T10:30:00Z",
    "default_tip_percentage": 15.00
  }
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `USER_NOT_FOUND`, `SERVER_ERROR`

---

## Session Management Routes

### 5. Create Session
**POST** `/sessions/create`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "restaurant_name": "Pizza Palace"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "session": {
    "id": "uuid-here",
    "join_code": "123456",
    "organizer_id": 123,
    "restaurant_name": "Pizza Palace",
    "status": "active",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `MISSING_FIELDS`, `SERVER_ERROR`

---

### 6. Join Session
**POST** `/sessions/join`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "join_code": "123456"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "session": {
    "id": "uuid-here",
    "join_code": "123456",
    "organizer_id": 456,
    "restaurant_name": "Pizza Palace",
    "status": "active",
    "participants": [
      {
        "user_id": 123,
        "display_name": "John Doe",
        "role": "participant",
        "joined_at": "2024-01-15T10:35:00Z"
      }
    ]
  }
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `INVALID_CODE`, `SESSION_NOT_FOUND`, `ALREADY_JOINED`, `SERVER_ERROR`

---

### 7. Get Session Details
**POST** `/sessions/details`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "session_id": "uuid-here"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "session": {
    "id": "uuid-here",
    "join_code": "123456",
    "organizer_id": 456,
    "restaurant_name": "Pizza Palace",
    "status": "active",
    "total_amount": 85.50,
    "tax_amount": 7.25,
    "tip_amount": 12.83,
    "participants": [
      {
        "user_id": 123,
        "display_name": "John Doe",
        "role": "participant",
        "confirmed": true
      }
    ],
    "receipt_items": [
      {
        "id": "item-uuid",
        "name": "Margherita Pizza",
        "price": 18.99,
        "quantity": 1,
        "category": "food"
      }
    ]
  }
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `SESSION_NOT_FOUND`, `ACCESS_DENIED`, `SERVER_ERROR`

---

### 8. Leave Session
**POST** `/sessions/leave`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "session_id": "uuid-here"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "message": "Successfully left session"
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `SESSION_NOT_FOUND`, `NOT_PARTICIPANT`, `ORGANIZER_CANNOT_LEAVE`, `SERVER_ERROR`

---

## Receipt Management Routes

### 9. Upload Receipt Image
**POST** `/receipts/upload`

**Headers:** `Authorization: Bearer <token>`

**Request Body:** (multipart/form-data)
```
session_id: "uuid-here"
receipt_image: [file]
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "image_url": "https://storage.example.com/receipts/image123.jpg",
  "upload_id": "upload-uuid"
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `SESSION_NOT_FOUND`, `INVALID_FILE`, `UPLOAD_FAILED`, `SERVER_ERROR`

---

### 10. Process Receipt (OCR + AI)
**POST** `/receipts/process`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "session_id": "uuid-here",
  "image_url": "https://storage.example.com/receipts/image123.jpg"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "processing_id": "process-uuid",
  "status": "processing",
  "estimated_completion": "2024-01-15T10:35:00Z"
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `SESSION_NOT_FOUND`, `IMAGE_NOT_FOUND`, `PROCESSING_FAILED`, `SERVER_ERROR`

---

## Item Assignment Routes

### 11. Assign Item to Users
**POST** `/assignments/assign`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "session_id": "uuid-here",
  "item_id": "item-uuid",
  "user_ids": [123, 456],
  "split_type": "equal"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "assignment": {
    "id": "assignment-uuid",
    "item_id": "item-uuid",
    "assigned_users": [123, 456],
    "split_type": "equal",
    "amount_per_user": 9.50
  }
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `SESSION_NOT_FOUND`, `ITEM_NOT_FOUND`, `INVALID_USERS`, `SERVER_ERROR`

---

### 12. Calculate Final Splits
**POST** `/sessions/calculate_splits`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "session_id": "uuid-here"
}
```

**Success Response:**
```json
{
  "return_code": "SUCCESS",
  "splits": [
    {
      "user_id": 123,
      "display_name": "John Doe",
      "total_amount": 28.75,
      "items": ["item-uuid-1", "item-uuid-2"],
      "confirmed": false
    }
  ],
  "session_total": 85.50
}
```

**Return Codes:** `SUCCESS`, `UNAUTHORIZED`, `SESSION_NOT_FOUND`, `NO_ASSIGNMENTS`, `CALCULATION_ERROR`, `SERVER_ERROR`

---

## Common Return Codes

### Success
- `SUCCESS` - Operation completed successfully

### Authentication Errors
- `UNAUTHORIZED` - Invalid or missing JWT token
- `TOKEN_EXPIRED` - JWT token has expired
- `INVALID_CREDENTIALS` - Wrong email/password combination

### Validation Errors
- `MISSING_FIELDS` - Required fields are missing from request
- `INVALID_FORMAT` - Field format is incorrect
- `WEAK_PASSWORD` - Password doesn't meet requirements

### Resource Errors
- `NOT_FOUND` - Requested resource doesn't exist
- `ACCESS_DENIED` - User doesn't have permission for this resource
- `ALREADY_EXISTS` - Resource already exists (e.g., email already registered)

### Server Errors
- `SERVER_ERROR` - Internal server error
- `DATABASE_ERROR` - Database operation failed
- `EXTERNAL_API_ERROR` - External service (OCR, AI) failed

---

## Testing Notes

### Environment Variables
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=splitdine_dev
DB_USER=splitdine_user
DB_PASSWORD=your_password
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret
```

### Test Data
- Test user: `test@splitdine.com` / `password123`
- Test session join code: `123456`
- Test restaurant: `Test Restaurant`
