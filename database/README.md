# SplitDine Database Setup Guide

## Design Philosophy

**Database as Data Storage Only**
- Database used purely for data persistence
- All business logic, validation, and constraints handled at API level
- No database functions, triggers, or complex constraints
- Simple, clean schema focused on performance and flexibility

## Prerequisites

1. **PostgreSQL 13+** installed and running
2. **Database created**: `splitdine_prod`
3. **Database user created**: `splitdine_prod_user` with appropriate permissions

## Database Setup

### 1. Connect to PostgreSQL

```bash
# Connect as postgres superuser
psql -U postgres

# Or connect directly to your database
psql -U splitdine_prod_user -d splitdine_prod
```

### 2. Run Schema Creation

```bash
# From the project root directory
psql -U splitdine_prod_user -d splitdine_prod -f database/schema.sql
```

### 3. Verify Installation

```sql
-- Check that all tables were created
\dt

-- Check table structure
\d app_user
\d sessions
\d session_participants
\d receipt_items
\d item_assignments
\d final_splits
\d session_activity_log

-- Verify indexes
\di
```

## Database Schema Overview

### Core Tables

1. **app_user** - User accounts (registered and anonymous)
2. **sessions** - Bill splitting sessions
3. **session_participants** - Many-to-many relationship between users and sessions
4. **receipt_items** - Individual items from receipts
5. **item_assignments** - Assignment of items to users
6. **final_splits** - Calculated final amounts per user
7. **session_activity_log** - Audit trail of session activities

### Key Features

- **Serial Primary Keys** - Simple integer primary keys for performance
- **No Database Constraints** - All validation handled at API level
- **Performance Indexes** - Strategic indexes on frequently queried columns
- **Simple Schema** - Clean, straightforward table design
- **Flexible Data Storage** - No rigid constraints allow for easy schema evolution
- **API-Controlled Logic** - All business rules enforced in application code

### Data Relationships

**Note**: Relationships are logical only (enforced by API), not database foreign keys

```
app_user (1) ←→ (many) session_participants (many) ←→ (1) sessions
sessions (1) ←→ (many) receipt_items
receipt_items (1) ←→ (many) item_assignments (many) ←→ (1) app_user
sessions (1) ←→ (many) final_splits (many) ←→ (1) app_user
sessions (1) ←→ (many) session_activity_log (many) ←→ (1) app_user
```

## Environment Variables

Create a `.env` file in your backend project with:

```env
# Database Configuration
DATABASE_URL=postgresql://splitdine_prod_user:YOUR_PASSWORD@localhost:5432/splitdine_prod
DB_HOST=localhost
DB_PORT=5432
DB_NAME=splitdine_prod
DB_USER=splitdine_prod_user
DB_PASSWORD=YOUR_PASSWORD

# JWT Configuration
JWT_SECRET=your_jwt_secret_here
JWT_REFRESH_SECRET=your_refresh_secret_here
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Server Configuration
PORT=3000
NODE_ENV=development

# External APIs (for future use)
GOOGLE_VISION_API_KEY=your_google_vision_key
OPENAI_API_KEY=your_openai_key
STRIPE_SECRET_KEY=your_stripe_secret_key
```

## Sample Data (Optional)

To insert test data for development:

```sql
-- Sample users
INSERT INTO app_user (email, display_name, password_hash, is_anonymous) VALUES
('test@splitdine.com', 'Test User', '$2b$10$example_hash', FALSE),
('organizer@splitdine.com', 'Session Organizer', '$2b$10$example_hash', FALSE),
('guest@splitdine.com', 'Guest User', '$2b$10$example_hash', FALSE);

-- Create a test session
INSERT INTO sessions (organizer_id, restaurant_name, total_amount, tax_amount, tip_amount)
VALUES (2, 'Test Restaurant', 85.50, 7.25, 12.83);
```

## Database Maintenance

### Regular Maintenance Tasks

1. **Vacuum and Analyze** (weekly)
```sql
VACUUM ANALYZE;
```

2. **Clean up old sessions** (monthly)
```sql
-- Delete completed sessions older than 30 days
DELETE FROM sessions 
WHERE status = 'completed' 
AND created_at < NOW() - INTERVAL '30 days';
```

3. **Archive activity logs** (monthly)
```sql
-- Delete activity logs older than 90 days
DELETE FROM session_activity_log 
WHERE created_at < NOW() - INTERVAL '90 days';
```

### Performance Monitoring

```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT 
    indexrelname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

## Backup and Recovery

### Backup
```bash
# Full database backup
pg_dump -U splitdine_prod_user -d splitdine_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# Schema only backup
pg_dump -U splitdine_prod_user -d splitdine_prod --schema-only > schema_backup.sql
```

### Restore
```bash
# Restore from backup
psql -U splitdine_prod_user -d splitdine_prod < backup_file.sql
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure user has proper permissions on database
   - Grant necessary privileges: `GRANT ALL PRIVILEGES ON DATABASE splitdine_prod TO splitdine_prod_user;`

2. **Connection Issues**
   - Check PostgreSQL is running: `sudo systemctl status postgresql`
   - Verify connection string in environment variables

3. **Performance Issues**
   - Run `ANALYZE;` to update table statistics
   - Check slow queries with `pg_stat_statements`

4. **Data Integrity**
   - Remember: No database constraints means API must handle all validation
   - Implement proper error handling in API for data consistency

## Next Steps

After database setup is complete:

1. Set up Express.js backend server
2. Configure database connection pool
3. Implement API endpoints
4. Add authentication middleware
5. Test database operations

The database is now ready for the SplitDine backend implementation!
