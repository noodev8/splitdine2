# SplitDine API Server

Express.js backend server for the SplitDine mobile application with PostgreSQL database integration.

## Features

- **JWT Authentication** - Secure user authentication with JSON Web Tokens
- **PostgreSQL Integration** - Robust database operations with connection pooling
- **RESTful API** - Clean API design following POST-only methodology
- **Rate Limiting** - Protection against abuse and DoS attacks
- **Security Headers** - Comprehensive security with Helmet.js
- **Error Handling** - Centralized error handling with detailed logging
- **Input Validation** - Thorough validation of all API inputs
- **CORS Support** - Configurable cross-origin resource sharing

## Project Structure

```
splitdine2_server/
├── config/
│   ├── config.js          # Application configuration
│   └── database.js        # Database connection and utilities
├── controllers/           # Business logic controllers (future)
├── middleware/
│   ├── auth.js           # JWT authentication middleware
│   ├── errorHandler.js   # Error handling middleware
│   └── rateLimiter.js    # Rate limiting middleware
├── routes/
│   ├── auth.js           # Authentication routes
│   ├── sessions.js       # Session management routes
│   └── receipts.js       # Receipt management routes
├── utils/
│   ├── database.js       # Database query utilities
│   └── password.js       # Password hashing utilities
├── server.js             # Main application entry point
├── package.json          # Dependencies and scripts
├── .env.example          # Environment variables template
└── README.md             # This file
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/anonymous` - Create anonymous user
- `POST /api/auth/validate` - Validate JWT token

### Session Management
- `POST /api/sessions/create` - Create new session
- `POST /api/sessions/join` - Join session by code
- `POST /api/sessions/details` - Get session details
- `POST /api/sessions/end` - End session (host only)
- `POST /api/sessions/my-sessions` - Get user's sessions

### Receipt Management
- `POST /api/receipts/add-item` - Add receipt item
- `POST /api/receipts/get-items` - Get session receipt items
- `POST /api/receipts/update-item` - Update receipt item
- `POST /api/receipts/delete-item` - Delete receipt item

## Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- PostgreSQL database
- npm or yarn package manager

### Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your configuration:
   ```env
   PORT=3000
   NODE_ENV=development
   DATABASE_URL=postgresql://splitdine_prod_user:your_password@localhost:5432/splitdine_prod
   JWT_SECRET=your_super_secret_jwt_key_here_at_least_32_characters
   JWT_EXPIRES_IN=24h
   CORS_ORIGIN=http://localhost:3000
   BCRYPT_ROUNDS=12
   ```

3. **Set up PostgreSQL database:**
   - Ensure PostgreSQL is running
   - Create database and user as specified in DATABASE_URL
   - Run the schema from `../database/schema.sql`

### Running the Server

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on the configured port (default: 3000) and test the database connection.

## API Response Format

All API endpoints follow a consistent response format:

```json
{
  "return_code": "SUCCESS",
  "message": "Operation completed successfully",
  "data": {},
  "timestamp": "2025-07-11T09:30:00.000Z"
}
```

### Return Codes
- `SUCCESS` - Operation completed successfully
- `MISSING_FIELDS` - Required fields are missing
- `INVALID_CREDENTIALS` - Authentication failed
- `UNAUTHORIZED` - Access denied
- `NOT_FOUND` - Resource not found
- `SERVER_ERROR` - Internal server error
- `RATE_LIMIT_EXCEEDED` - Too many requests

## Security Features

- **JWT Authentication** - Stateless authentication with configurable expiration
- **Password Hashing** - bcrypt with configurable salt rounds
- **Rate Limiting** - Multiple rate limiters for different endpoint types
- **CORS Protection** - Configurable cross-origin resource sharing
- **Security Headers** - Comprehensive security headers via Helmet.js
- **Input Validation** - Thorough validation of all API inputs
- **SQL Injection Protection** - Parameterized queries throughout

## Development

### Code Style
- Use consistent indentation (2 spaces)
- Follow async/await patterns
- Include comprehensive error handling
- Add JSDoc comments for functions
- Use descriptive variable names

### Testing
```bash
npm test
```

### Debugging
Set `NODE_ENV=development` for detailed error messages and stack traces.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `JWT_SECRET` | JWT signing secret (min 32 chars) | Required |
| `JWT_EXPIRES_IN` | JWT expiration time | 24h |
| `CORS_ORIGIN` | Allowed CORS origins | * |
| `BCRYPT_ROUNDS` | Password hashing rounds | 12 |

## License

This project is part of the SplitDine application suite.
