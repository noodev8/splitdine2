# SplitDine PostgreSQL Implementation Plan

## Overview
This document outlines the detailed implementation plan for migrating SplitDine from Firebase to a PostgreSQL + Express.js backend architecture.

## Architecture Benefits
- **Predictable Performance** - No Firebase quotas or unexpected costs
- **Full Control** - Complete control over database schema and queries
- **Standard Technology** - Well-established PostgreSQL and Express.js stack
- **Easier Debugging** - Standard SQL tools and logging
- **Cost Effective** - No vendor lock-in, can be self-hosted

## Phase 2: Backend Infrastructure (Revised)

### Task 1: PostgreSQL Database Setup
**Duration**: 1-2 days
**Prerequisites**: None

#### Subtasks:
1. **Install PostgreSQL**
   - Local installation or Docker setup
   - Create `splitdine_dev` database
   - Create database user with appropriate permissions

2. **Database Configuration**
   - Set up connection parameters
   - Configure environment variables
   - Test database connectivity

3. **Migration Framework Setup**
   - Install `node-pg-migrate` or similar tool
   - Create migration directory structure
   - Set up migration scripts

### Task 2: Database Schema Implementation
**Duration**: 2-3 days
**Prerequisites**: Task 1 complete

#### Subtasks:
1. **Core Tables Creation**
   - `users` table with authentication fields
   - `sessions` table with session management
   - `session_participants` table for many-to-many relationships
   - `receipt_items` table for receipt data
   - `item_assignments` table for item splitting
   - `final_splits` table for calculated amounts

2. **Indexes and Constraints**
   - Primary keys and foreign keys
   - Unique constraints (email, join_code)
   - Performance indexes on frequently queried fields

3. **Database Functions**
   - Triggers for `updated_at` timestamps
   - Functions for join code generation
   - Views for complex queries

### Task 3: Express.js API Server Setup
**Duration**: 2-3 days
**Prerequisites**: Task 2 complete

#### Subtasks:
1. **Project Structure**
   - Initialize Node.js project
   - Set up Express.js framework
   - Create directory structure (routes, models, middleware)

2. **Core Dependencies**
   - `express` - Web framework
   - `pg` - PostgreSQL client
   - `jsonwebtoken` - JWT authentication
   - `bcrypt` - Password hashing
   - `cors` - Cross-origin requests
   - `helmet` - Security headers
   - `express-rate-limit` - Rate limiting

3. **Database Connection**
   - Set up PostgreSQL connection pool
   - Create database client wrapper
   - Implement connection error handling

### Task 4: Authentication System
**Duration**: 2-3 days
**Prerequisites**: Task 3 complete

#### Subtasks:
1. **JWT Implementation**
   - JWT token generation and validation
   - Refresh token mechanism
   - Token middleware for protected routes

2. **Authentication Endpoints**
   - `POST /api/auth/register` - User registration
   - `POST /api/auth/login` - User login
   - `POST /api/auth/refresh` - Token refresh
   - `POST /api/auth/logout` - User logout

3. **Password Security**
   - Bcrypt password hashing
   - Password strength validation
   - Secure password reset flow

### Task 5: Core API Endpoints
**Duration**: 3-4 days
**Prerequisites**: Task 4 complete

#### Subtasks:
1. **Session Management**
   - `POST /api/sessions` - Create session
   - `GET /api/sessions/:id` - Get session details
   - `POST /api/sessions/join` - Join session by code
   - `PUT /api/sessions/:id` - Update session
   - `DELETE /api/sessions/:id/leave` - Leave session

2. **Receipt Management**
   - `POST /api/receipts/upload` - Upload receipt image
   - `POST /api/receipts/process` - OCR and parsing
   - `GET /api/receipts/:sessionId/items` - Get receipt items
   - `PUT /api/receipts/items/:id` - Update item
   - `DELETE /api/receipts/items/:id` - Delete item

3. **Assignment Management**
   - `POST /api/assignments` - Assign items to users
   - `PUT /api/assignments/:id` - Update assignment
   - `DELETE /api/assignments/:id` - Remove assignment
   - `GET /api/sessions/:id/splits` - Calculate final splits

### Task 6: WebSocket Integration
**Duration**: 2-3 days
**Prerequisites**: Task 5 complete

#### Subtasks:
1. **Socket.io Setup**
   - Install and configure Socket.io
   - Create WebSocket server
   - Implement connection authentication

2. **Real-time Features**
   - Session rooms for participants
   - Broadcast updates to session participants
   - Handle connection/disconnection events

3. **Event Handlers**
   - Item assignment updates
   - Participant join/leave events
   - Receipt processing status updates

### Task 7: Flutter Backend Integration
**Duration**: 2-3 days
**Prerequisites**: Task 6 complete

#### Subtasks:
1. **HTTP Client Setup**
   - Replace Firebase calls with HTTP requests
   - Implement JWT token management
   - Create API service classes

2. **WebSocket Client**
   - Integrate Socket.io client in Flutter
   - Handle real-time updates
   - Implement reconnection logic

3. **State Management Update**
   - Update state management for API calls
   - Implement offline support
   - Handle loading and error states

### Task 8: Testing and Validation
**Duration**: 2-3 days
**Prerequisites**: Task 7 complete

#### Subtasks:
1. **Backend Testing**
   - Unit tests for API endpoints
   - Integration tests for database operations
   - Authentication flow testing

2. **End-to-End Testing**
   - Complete user registration and login flow
   - Session creation and joining
   - Real-time updates verification

3. **Performance Testing**
   - Database query optimization
   - API response time testing
   - WebSocket connection load testing

## Estimated Timeline
- **Total Duration**: 3-4 weeks
- **Phase 2 Complete**: All backend infrastructure functional
- **Ready for Phase 3**: OCR and receipt processing integration

## Success Criteria
- ✅ PostgreSQL database fully operational
- ✅ Express.js API server handling all core operations
- ✅ JWT authentication system working
- ✅ WebSocket real-time updates functional
- ✅ Flutter app successfully integrated with new backend
- ✅ All tests passing
- ✅ Performance meets requirements

## Risk Mitigation
- **Database Migration**: Start with simple schema, iterate as needed
- **API Design**: Follow RESTful conventions for consistency
- **Real-time Features**: Implement fallback polling if WebSocket fails
- **Testing**: Comprehensive testing at each step to catch issues early

This plan provides a solid foundation for the PostgreSQL-based backend while maintaining the collaborative features that make SplitDine unique.
