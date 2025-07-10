# SplitDine Project Rules & Standards

## API Development Rules

### Routes Coding Rules
1. **All routes use POST method** - Consistent HTTP method for all endpoints
2. **Always use/return simplified JSON** - Keep response structures simple and consistent
3. **All routes return "return_code"** - Every response must include a machine-readable "return_code" field that is either "SUCCESS" or an error type
4. **Additional parameters allowed** - Routes can return any other parameters but must always include "return_code"
5. **Never change existing JSON fields** - If changes are needed to existing fields, create new variations to ensure backward compatibility with client app

### Authentication Rules
1. **Use JWT Authentication** - JSON Web Tokens for secure authentication
2. **Middleware location** - Use authentication middleware from "C:\noovos\noovos_server\middleware\auth.js"
3. **Token validation** - All protected routes must validate JWT tokens
4. **Secure token storage** - Store tokens securely on client side

### File Naming Rules
1. **Always use lowercase** - All new files must use lowercase filenames
2. **Use underscores** - Separate words with underscores (e.g., user_profile.js)
3. **Descriptive names** - File names should clearly indicate their purpose

## Documentation Standards

### Screen Documentation Rules
1. **Brief description required** - All screens must display a brief description at the top explaining what the screen does
2. **Purpose clarity** - Description should clearly state the screen's main function
3. **User context** - Explain what the user can accomplish on this screen

### API Route Documentation Rules
1. **Header format required** - All API route files must include a standardized header
2. **Complete specification** - Include method, purpose, request payload, success response, and return codes
3. **Standard format** - Use the following template:

```
=======================================================================================================================================
API Route: [route_name]
=======================================================================================================================================
Method: POST
Purpose: [Clear description of what this route does]
=======================================================================================================================================
Request Payload:
{
  "field1": "value1",                  // type, required/optional
  "field2": "value2"                   // type, required/optional
}

Success Response:
{
  "return_code": "SUCCESS",
  "field1": "value1",                  // type, description
  "field2": "value2"                   // type, description
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"ERROR_TYPE_1"
"ERROR_TYPE_2"
"SERVER_ERROR"
=======================================================================================================================================
*/
```

## Code Quality Rules

### General Coding Standards
1. **Meaningful names** - Use descriptive variable and function names
2. **Error handling** - Implement comprehensive error handling for all operations
3. **Comments** - Add comments for complex logic and business rules
4. **Consistent formatting** - Follow established code formatting standards
5. **No hardcoded values** - Use configuration files or environment variables

### Database Rules
1. **Use parameterized queries** - Prevent SQL injection attacks
2. **Connection pooling** - Use connection pools for database connections
3. **Transaction management** - Use transactions for multi-step operations
4. **Index optimization** - Create appropriate indexes for query performance
5. **Data validation** - Validate all input data before database operations

### Security Rules
1. **Input validation** - Validate and sanitize all user inputs
2. **Rate limiting** - Implement rate limiting on all API endpoints
3. **CORS configuration** - Properly configure Cross-Origin Resource Sharing
4. **Password security** - Use bcrypt for password hashing
5. **Token expiration** - Implement appropriate token expiration times

## Testing Rules

### Backend Testing
1. **Unit tests required** - Write unit tests for all business logic
2. **Integration tests** - Test API endpoints with database operations
3. **Error scenario testing** - Test all error conditions and edge cases
4. **Performance testing** - Test response times and database query performance
5. **Security testing** - Test authentication and authorization

### Frontend Testing
1. **Widget tests** - Test individual UI components
2. **Integration tests** - Test complete user flows
3. **API integration tests** - Test API communication
4. **Error handling tests** - Test error states and user feedback
5. **Performance tests** - Test app performance on different devices

## Git Workflow Rules

### Branch Management
1. **Feature branches** - Create separate branches for each feature
2. **Descriptive names** - Use descriptive branch names (e.g., feature/user-authentication)
3. **Regular commits** - Make frequent, small commits with clear messages
4. **Pull requests** - Use pull requests for code review before merging
5. **Clean history** - Squash commits when appropriate for clean history

### Commit Message Rules
1. **Clear descriptions** - Write clear, descriptive commit messages
2. **Present tense** - Use present tense ("Add feature" not "Added feature")
3. **Reference issues** - Reference issue numbers when applicable
4. **Scope indication** - Indicate scope (frontend, backend, docs, etc.)

## Deployment Rules

### Environment Management
1. **Environment separation** - Maintain separate dev, staging, and production environments
2. **Configuration management** - Use environment variables for configuration
3. **Secret management** - Never commit secrets or API keys to version control
4. **Database migrations** - Use migration scripts for database schema changes
5. **Backup procedures** - Implement regular backup procedures for production data

### Release Management
1. **Version tagging** - Tag releases with semantic versioning
2. **Release notes** - Maintain detailed release notes
3. **Rollback procedures** - Have rollback procedures for failed deployments
4. **Testing before release** - Thoroughly test in staging before production release
5. **Monitoring** - Monitor application performance and errors after deployment

## Communication Rules

### Documentation Updates
1. **Keep docs current** - Update documentation with code changes
2. **API documentation** - Update Postman documentation for API changes
3. **User guides** - Update user guides for UI changes
4. **Technical specs** - Update technical specifications for architecture changes

### Code Review Rules
1. **Review all changes** - All code changes must be reviewed before merging
2. **Constructive feedback** - Provide constructive, helpful feedback
3. **Test verification** - Verify that tests pass before approving
4. **Documentation check** - Ensure documentation is updated if needed
5. **Security review** - Review for security implications

## Performance Rules

### Database Performance
1. **Query optimization** - Optimize database queries for performance
2. **Index usage** - Use appropriate indexes for frequently queried fields
3. **Connection limits** - Monitor and manage database connection usage
4. **Query monitoring** - Monitor slow queries and optimize them
5. **Data archiving** - Implement data archiving for old records

### API Performance
1. **Response times** - Maintain fast API response times (< 500ms for most endpoints)
2. **Caching** - Implement caching for frequently accessed data
3. **Pagination** - Use pagination for large data sets
4. **Compression** - Use response compression for large payloads
5. **Rate limiting** - Implement rate limiting to prevent abuse

## Maintenance Rules

### Regular Maintenance
1. **Dependency updates** - Regularly update dependencies for security
2. **Log monitoring** - Monitor application logs for errors and issues
3. **Performance monitoring** - Monitor application performance metrics
4. **Security audits** - Conduct regular security audits
5. **Backup verification** - Regularly verify backup integrity

### Issue Management
1. **Bug tracking** - Use issue tracking system for bugs and features
2. **Priority classification** - Classify issues by priority and severity
3. **Response times** - Establish response time expectations for different issue types
4. **Root cause analysis** - Perform root cause analysis for critical issues
5. **Prevention measures** - Implement measures to prevent recurring issues

These rules ensure consistent, secure, and maintainable development practices across the SplitDine project.
