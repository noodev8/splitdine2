# SplitDine Development Guidelines

## Code Organization

### Project Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── services/
├── features/
│   ├── auth/
│   ├── session/
│   ├── receipt/
│   ├── payment/
│   └── shared/
└── data/
    ├── models/
    ├── repositories/
    └── datasources/
```

### Feature-Based Architecture
Each feature should contain:
- `presentation/` - UI components and state management
- `domain/` - Business logic and entities
- `data/` - Data sources and repositories

## Coding Standards

### Dart/Flutter Best Practices
- Follow official Dart style guide
- Use meaningful variable and function names
- Implement proper error handling
- Write comprehensive documentation
- Use const constructors where possible

### State Management
- Use Provider or Riverpod for state management
- Separate business logic from UI logic
- Implement proper loading and error states
- Use immutable data models

### Backend API Integration (PostgreSQL + Express.js)
- Use proper error handling for all API operations
- Implement offline support where applicable
- Use JWT tokens for authentication
- Follow RESTful API design principles
- Cache frequently accessed data
- **Use direct SQL queries only** - No ORM or model wrappers for maximum PostgreSQL performance

### Frontend Screen Organization
- **Each screen in separate file** - Keep all UI components in individual screen files
- **No shared UI components initially** - Build functionality first, refactor UI later
- **Basic Material Design components only** - Focus on functionality over styling
- **Screen-specific state management** - Keep state logic close to where it's used

## API Development Standards

### Routes Coding Rules
- **All routes use POST method** - Consistent HTTP method for all endpoints
- **Always use/return simplified JSON** - Keep response structures simple and consistent
- **All routes return "return_code"** - Every response must include a machine-readable "return_code" field that is either "SUCCESS" or an error type
- **Additional parameters allowed** - Routes can return any other parameters but must always include "return_code"
- **Never change existing JSON fields** - If changes are needed to existing fields, create new variations to ensure backward compatibility with client app

### Authentication Standards
- **Use JWT Authentication** - JSON Web Tokens for secure authentication
- **Token-based authentication** - Stateless authentication using JWT tokens
- **Middleware location** - Use authentication middleware from "C:\noovos\noovos_server\middleware\auth.js"
- **Token validation** - All protected routes must validate JWT tokens
- **Secure token storage** - Store tokens securely on client side using secure storage
- **Token expiration** - Implement appropriate token expiration and refresh mechanisms
- **Authorization headers** - Send tokens in Authorization header: "Bearer <token>"

### File Naming Conventions
- **Always use lowercase** - All new files must use lowercase filenames
- **Use underscores** - Separate words with underscores (e.g., user_profile.js)
- **Descriptive names** - File names should clearly indicate their purpose

## Documentation Standards

### Screen Documentation
- **Brief description required** - All screens must display a brief description at the top explaining what the screen does
- **Purpose clarity** - Description should clearly state the screen's main function
- **User context** - Explain what the user can accomplish on this screen

### API Route Documentation
- **Header format required** - All API route files must include a standardized header
- **Complete specification** - Include method, purpose, request payload, success response, and return codes
- **Example format**:
```
=======================================================================================================================================
API Route: login_user
=======================================================================================================================================
Method: POST
Purpose: Authenticates a user using their email and password. Returns a token and basic user details upon success.
=======================================================================================================================================
Request Payload:
{
  "email": "user@example.com",         // string, required
  "password": "securepassword123"      // string, required
}

Success Response:
{
  "return_code": "SUCCESS"
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // string, JWT token for auth
  "user": {
    "id": 123,                         // integer, unique user ID
    "name": "Andreas",                 // string, user's name
    "email": "user@example.com",       // string, user's email
    "account_level": "standard"        // string, e.g. 'standard', 'premium', 'admin'
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CREDENTIALS"
"SERVER_ERROR"
=======================================================================================================================================
*/
```

## Git Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/task-name` - Feature development
- `hotfix/issue-name` - Critical fixes

### Commit Messages
```
type(scope): description

feat(auth): add anonymous user authentication
fix(receipt): resolve OCR parsing edge case
docs(api): update Firebase function documentation
test(session): add unit tests for splitting logic
```

### Pull Request Process
1. Create feature branch from `develop`
2. Implement changes with tests
3. Update documentation if needed
4. Create PR with detailed description
5. Code review and approval required
6. Merge to `develop` after CI passes

## Testing Requirements

### Test Coverage
- Minimum 80% code coverage
- All business logic must have unit tests
- Critical user flows need integration tests
- UI components should have widget tests

### Test Organization
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   └── features/
└── integration/
    └── flows/
```

### Testing Best Practices
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Mock external dependencies
- Test edge cases and error conditions

## Documentation Standards

### Code Documentation
- Document all public APIs
- Include usage examples
- Explain complex algorithms
- Document breaking changes

### README Files
Each feature should have a README explaining:
- Purpose and functionality
- Usage instructions
- Dependencies
- Testing approach

## Performance Guidelines

### Flutter Performance
- Minimize widget rebuilds
- Use const constructors
- Implement proper list virtualization
- Optimize image loading and caching

### Firebase Performance
- Use efficient query patterns
- Implement proper pagination
- Monitor real-time listener usage
- Optimize security rules

### Network Optimization
- Implement request caching
- Use compression for images
- Handle offline scenarios
- Implement retry logic

## Security Practices

### Data Protection
- Validate all user inputs
- Sanitize data before storage
- Use HTTPS for all communications
- Implement proper authentication

### API Security
- Secure API keys and secrets
- Use Firebase security rules
- Implement rate limiting
- Monitor for suspicious activity

### Payment Security
- Follow PCI compliance guidelines
- Never store sensitive payment data
- Use Stripe's secure payment flows
- Implement fraud detection

## Code Review Checklist

### Functionality
- [ ] Code meets requirements
- [ ] Edge cases are handled
- [ ] Error handling is implemented
- [ ] Performance is acceptable

### Code Quality
- [ ] Code follows style guidelines
- [ ] Functions are properly documented
- [ ] No code duplication
- [ ] Proper separation of concerns

### Testing
- [ ] Unit tests are included
- [ ] Tests cover edge cases
- [ ] Integration tests for new features
- [ ] All tests pass

### Security
- [ ] Input validation is implemented
- [ ] No sensitive data in logs
- [ ] Proper authentication checks
- [ ] Security rules are updated

## Deployment Process

### Pre-deployment Checklist
- [ ] All tests pass
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Performance benchmarks met
- [ ] Security review completed

### Release Process
1. Create release branch from `develop`
2. Update version numbers
3. Generate release notes
4. Deploy to staging environment
5. Perform final testing
6. Deploy to production
7. Monitor for issues

## Monitoring and Maintenance

### Key Metrics
- App performance metrics
- User engagement analytics
- Error rates and crash reports
- API usage and costs

### Regular Maintenance
- Update dependencies monthly
- Review and optimize performance
- Monitor security vulnerabilities
- Update documentation

## Communication

### Team Communication
- Daily standups for progress updates
- Weekly technical reviews
- Monthly architecture discussions
- Quarterly retrospectives

### Documentation Updates
- Update docs with code changes
- Maintain API documentation
- Keep deployment guides current
- Document known issues and solutions
