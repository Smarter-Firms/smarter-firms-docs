# OAuth Security Review

This document provides a security review of the OAuth token handling within the Clio Integration Service, identifying potential security risks and mitigation strategies.

## OAuth Token Storage Security

### Current Implementation

The Clio Integration Service stores OAuth tokens (access tokens and refresh tokens) for each user connection in the PostgreSQL database using the following schema:

```typescript
model ClioConnection {
  id          String    @id @default(uuid())
  userId      String    @unique
  firmId      String
  accessToken String
  refreshToken String
  expiresAt   DateTime
  tokenType   String    @default("Bearer")
  scope       String
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  syncStatus  SyncStatus @relation(fields: [syncStatusId], references: [id])
  syncStatusId String
}
```

### Risks

1. **Sensitive Data Exposure**: OAuth tokens stored in plain text could be exposed if database access is compromised.
2. **Token Theft**: If an attacker gains access to the database, they could use tokens to impersonate users.
3. **No Database Encryption**: Currently, database-level encryption is dependent on the PostgreSQL deployment.
4. **Long-lived Tokens**: Refresh tokens may have long lifetimes, increasing risk if compromised.

### Mitigation Strategies

1. **Implement Column-level Encryption**:
   - Encrypt `accessToken` and `refreshToken` columns using a strong encryption algorithm (AES-256-GCM)
   - Store encryption keys separately from the database (using AWS KMS or similar)

2. **Update Database Schema**:
   ```typescript
   model ClioConnection {
     // ... existing fields
     accessToken String @db.Text // Now stores encrypted token
     refreshToken String @db.Text // Now stores encrypted token
     encryptionIV String // Initialization vector for encryption
     // ... remaining fields
   }
   ```

3. **Token Lifecycle Management**:
   - Implement automatic refresh token rotation when they're used
   - Add support for token revocation when users disconnect the service
   - Store token usage metrics to detect unusual patterns

## OAuth Authorization Flow Security

### Current Implementation

The service implements the OAuth 2.0 Authorization Code flow with Clio's API:

1. Users are redirected to Clio's authorization page
2. After approval, Clio redirects back with an authorization code
3. The service exchanges the code for access and refresh tokens
4. Tokens are stored and used for subsequent API calls

### Risks

1. **Authorization Code Interception**: The code could be intercepted in transit.
2. **Redirect URI Validation**: Insufficient validation may lead to token leaks.
3. **CSRF Attacks**: Without state parameter validation, cross-site request forgery is possible.
4. **Missing PKCE**: No Proof Key for Code Exchange implementation increases security risks.

### Mitigation Strategies

1. **Implement PKCE Extension**:
   - Generate a code verifier and challenge for each authorization request
   - Store the code verifier in the user's session
   - Include the code challenge in the authorization request
   - Verify the code in the token exchange step

2. **Strengthen State Parameter Usage**:
   - Generate cryptographically secure random state parameters
   - Bind the state to the user's session
   - Validate the state parameter upon callback

3. **Secure Callback Handling**:
   - Enforce HTTPS for all OAuth callbacks
   - Implement strict redirect URI validation
   - Add short timeouts for authorization codes

## Token Usage Security

### Current Implementation

Tokens are used to authenticate API requests to Clio:

1. Access tokens are stored and used for API calls
2. When tokens expire, refresh tokens are used to obtain new access tokens
3. API requests include tokens in the Authorization header

### Risks

1. **Token Leakage**: Tokens could be leaked in logs, error messages, or browser history.
2. **No Token Validation**: Access tokens aren't validated before use.
3. **Insufficient Token Scopes**: Using tokens with overly permissive scopes.
4. **Token Transmission**: Tokens could be intercepted if not using HTTPS.

### Mitigation Strategies

1. **Implement Token Masking in Logs**:
   - Create middleware that masks tokens in logs and error messages
   - Use patterns to identify token formats and replace with placeholders

2. **Enhance Token Validation**:
   - Validate token expiry before use
   - Implement token introspection when possible
   - Verify token scopes against the required operation

3. **Implement Least Privilege Principle**:
   - Request only the necessary OAuth scopes
   - Document required scopes for each API endpoint
   - Implement scope-based authorization checks

4. **Secure Transport**:
   - Enforce HTTPS for all API communications
   - Implement HSTS headers
   - Use secure cookies with HttpOnly and Secure flags

## Token Refresh Security

### Current Implementation

The service refreshes access tokens when they expire:

1. When an API call fails with a 401 status, the service attempts token refresh
2. The refresh token is sent to Clio's token endpoint
3. New access and refresh tokens are stored in the database

### Risks

1. **Refresh Token Rotation**: Failure to update refresh tokens when they are used.
2. **Error Handling**: Improper error handling could lead to token leakage.
3. **Race Conditions**: Multiple concurrent requests could cause token refresh conflicts.
4. **Refresh Token Expiry**: No handling for permanently expired refresh tokens.

### Mitigation Strategies

1. **Implement Token Rotation**:
   - Update both access and refresh tokens when refreshing
   - Implement proper cleanup of old tokens

2. **Improve Error Handling**:
   - Add specific error types for authentication failures
   - Implement proper logging without exposing tokens
   - Create a circuit breaker for repeated authentication failures

3. **Add Refresh Token Locking**:
   - Implement a mutex or distributed lock when refreshing tokens
   - Queue API requests during token refresh
   - Reuse refreshed tokens for queued requests

4. **Add Refresh Token Expiry Handling**:
   - Detect permanently expired refresh tokens
   - Notify users when re-authentication is needed
   - Provide clear user flows for re-connecting Clio

## Implementation Checklist

- [ ] Implement column-level encryption for tokens
- [ ] Add PKCE support to the OAuth flow
- [ ] Strengthen state parameter validation
- [ ] Implement token masking in logs
- [ ] Add scope-based authorization checks
- [ ] Implement token rotation tracking
- [ ] Add mutex for token refresh operations
- [ ] Create re-authentication flows for expired tokens
- [ ] Add monitoring for unusual token usage patterns
- [ ] Perform regular security audits of token handling

## Conclusion

OAuth token handling requires careful implementation to maintain security. The recommendations in this document should be implemented in priority order, with encryption of stored tokens being the highest priority. Regular security assessments should be performed to ensure continued protection of OAuth credentials. 