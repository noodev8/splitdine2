# SplitDine Technical Specifications

## Database Schema (PostgreSQL)

### Design Philosophy
- **Database as Data Storage Only** - No business logic in database
- **API-Level Validation** - All constraints and validation handled in application code
- **Simple Schema** - Clean, straightforward table design without complex constraints
- **Performance Focus** - Strategic indexes for query optimization
- **Flexibility** - Schema can evolve easily without rigid database constraints

### Table Structure

#### `app_user` Table
```sql
CREATE TABLE app_user (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255),
  phone VARCHAR(20),
  display_name VARCHAR(100),
  password_hash VARCHAR(255),
  is_anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  default_tip_percentage DECIMAL(5,2) DEFAULT 15.00,
  notifications_enabled BOOLEAN DEFAULT TRUE
);

-- Indexes for app_user table
CREATE INDEX idx_app_user_email ON app_user(email);
CREATE INDEX idx_app_user_last_active ON app_user(last_active_at);
```

#### `sessions` Table
```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  join_code VARCHAR(6) UNIQUE NOT NULL,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  restaurant_name VARCHAR(255),
  receipt_image_url TEXT,
  receipt_ocr_text TEXT,
  receipt_processed BOOLEAN DEFAULT FALSE,
  total_amount DECIMAL(10,2) DEFAULT 0.00,
  tax_amount DECIMAL(10,2) DEFAULT 0.00,
  tip_amount DECIMAL(10,2) DEFAULT 0.00,
  service_charge DECIMAL(10,2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT sessions_amounts_check CHECK (
    total_amount >= 0 AND
    tax_amount >= 0 AND
    tip_amount >= 0 AND
    service_charge >= 0
  )
);

-- Indexes for sessions table
CREATE UNIQUE INDEX idx_sessions_join_code ON sessions(join_code);
CREATE INDEX idx_sessions_organizer ON sessions(organizer_id);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_created_at ON sessions(created_at);

-- Function to generate unique join codes
CREATE OR REPLACE FUNCTION generate_join_code() RETURNS VARCHAR(6) AS $$
DECLARE
  code VARCHAR(6);
  exists_check INTEGER;
BEGIN
  LOOP
    code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    SELECT COUNT(*) INTO exists_check FROM sessions WHERE join_code = code AND status = 'active';
    EXIT WHEN exists_check = 0;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;
```

#### `session_participants` Table
```sql
CREATE TABLE session_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'participant' CHECK (role IN ('organizer', 'participant')),
  confirmed BOOLEAN DEFAULT FALSE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  left_at TIMESTAMP WITH TIME ZONE,

  UNIQUE(session_id, user_id)
);

-- Indexes for session_participants table
CREATE INDEX idx_session_participants_session ON session_participants(session_id);
CREATE INDEX idx_session_participants_user ON session_participants(user_id);
CREATE INDEX idx_session_participants_role ON session_participants(session_id, role);
```

#### `receipt_items` Table
```sql
CREATE TABLE receipt_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  quantity INTEGER DEFAULT 1,
  category VARCHAR(20) DEFAULT 'food' CHECK (category IN ('food', 'drink', 'service', 'other')),
  description TEXT,
  parsed_confidence DECIMAL(3,2) DEFAULT 0.00,
  manually_edited BOOLEAN DEFAULT FALSE,
  is_shared BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT receipt_items_price_check CHECK (price >= 0),
  CONSTRAINT receipt_items_quantity_check CHECK (quantity > 0),
  CONSTRAINT receipt_items_confidence_check CHECK (parsed_confidence >= 0 AND parsed_confidence <= 1)
);

-- Indexes for receipt_items table
CREATE INDEX idx_receipt_items_session ON receipt_items(session_id);
CREATE INDEX idx_receipt_items_category ON receipt_items(category);
CREATE INDEX idx_receipt_items_shared ON receipt_items(is_shared);
```

#### `item_assignments` Table
```sql
CREATE TABLE item_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES receipt_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  split_type VARCHAR(20) DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom', 'percentage')),
  custom_amount DECIMAL(10,2),
  percentage_share DECIMAL(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(item_id, user_id),

  -- Constraints
  CONSTRAINT item_assignments_custom_amount_check CHECK (
    (split_type = 'custom' AND custom_amount IS NOT NULL AND custom_amount >= 0) OR
    (split_type != 'custom' AND custom_amount IS NULL)
  ),
  CONSTRAINT item_assignments_percentage_check CHECK (
    (split_type = 'percentage' AND percentage_share IS NOT NULL AND percentage_share >= 0 AND percentage_share <= 100) OR
    (split_type != 'percentage' AND percentage_share IS NULL)
  )
);

-- Indexes for item_assignments table
CREATE INDEX idx_item_assignments_session ON item_assignments(session_id);
CREATE INDEX idx_item_assignments_item ON item_assignments(item_id);
CREATE INDEX idx_item_assignments_user ON item_assignments(user_id);
CREATE INDEX idx_item_assignments_split_type ON item_assignments(split_type);
```

#### `final_splits` Table
```sql
CREATE TABLE final_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subtotal_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  tax_share DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  tip_share DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  service_charge_share DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  confirmed BOOLEAN DEFAULT FALSE,
  paid BOOLEAN DEFAULT FALSE,
  payment_method VARCHAR(50),
  payment_reference VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(session_id, user_id),

  -- Constraints
  CONSTRAINT final_splits_amounts_check CHECK (
    subtotal_amount >= 0 AND
    tax_share >= 0 AND
    tip_share >= 0 AND
    service_charge_share >= 0 AND
    total_amount >= 0
  )
);

-- Indexes for final_splits table
CREATE INDEX idx_final_splits_session ON final_splits(session_id);
CREATE INDEX idx_final_splits_user ON final_splits(user_id);
CREATE INDEX idx_final_splits_confirmed ON final_splits(confirmed);
CREATE INDEX idx_final_splits_paid ON final_splits(paid);
```

#### Additional Tables for Enhanced Functionality

#### `session_activity_log` Table
```sql
CREATE TABLE session_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action_type VARCHAR(50) NOT NULL,
  action_details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for session_activity_log table
CREATE INDEX idx_session_activity_session ON session_activity_log(session_id);
CREATE INDEX idx_session_activity_user ON session_activity_log(user_id);
CREATE INDEX idx_session_activity_type ON session_activity_log(action_type);
CREATE INDEX idx_session_activity_created ON session_activity_log(created_at);
```

## API Endpoints (Express/Node.js)

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh` - Refresh JWT token
- `GET /api/auth/me` - Get current user info

### Session Management
- `POST /api/sessions` - Create new session
- `GET /api/sessions/:id` - Get session details
- `POST /api/sessions/join` - Join session by code
- `PUT /api/sessions/:id` - Update session
- `DELETE /api/sessions/:id/leave` - Leave session
- `GET /api/sessions/user/:userId` - Get user's sessions

### Receipt Processing
- `POST /api/receipts/upload` - Upload receipt image
- `POST /api/receipts/process` - OCR and AI parsing
- `PUT /api/receipts/items/:id` - Update receipt item
- `DELETE /api/receipts/items/:id` - Delete receipt item

### Item Assignments
- `POST /api/assignments` - Assign item to users
- `PUT /api/assignments/:id` - Update assignment
- `DELETE /api/assignments/:id` - Remove assignment
- `GET /api/sessions/:id/assignments` - Get session assignments

### Payment Processing
- `POST /api/payments/intent` - Create Stripe payment intent
- `POST /api/payments/process` - Process payment
- `GET /api/payments/status/:id` - Check payment status

## Real-time Data Flow

### WebSocket Connections
1. Client connects to WebSocket server on session join
2. Server maintains session rooms for participants
3. User actions trigger database updates and WebSocket broadcasts
4. All participants receive real-time updates via WebSocket
5. Client-side optimistic updates with server reconciliation

### Session Update Flow
1. User performs action (assign item, update split, etc.)
2. Client sends optimistic update to UI
3. Client sends API request to server
4. Server validates and updates PostgreSQL database
5. Server broadcasts update to all session participants via WebSocket
6. Clients receive update and reconcile with local state

### Conflict Resolution
- Server-side validation prevents invalid states
- Last-write-wins for simple fields with timestamps
- Optimistic locking for critical operations
- User notification for conflicts requiring manual resolution

## Security & Authentication

### JWT Authentication
- JWT tokens for API authentication
- Refresh token rotation for security
- Role-based access control (organizer vs participant)
- Session-based permissions

### API Security
- Input validation and sanitization
- Rate limiting on all endpoints
- CORS configuration for web clients
- SQL injection prevention with parameterized queries

### Database Security
- Row-level security policies
- User can only access their own data
- Session participants can only access their session data
- Organizers have additional permissions for their sessions

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
