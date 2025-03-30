# Security Implementation Details

This document provides detailed specifications for the security implementation in the Smarter Firms Authentication Service.

## Table of Contents

1. [JWT Implementation](#jwt-implementation)
2. [PKCE Implementation](#pkce-implementation)
3. [Password Hashing](#password-hashing)
4. [IP Binding Security](#ip-binding-security)
5. [Token Rotation and Revocation](#token-rotation-and-revocation)
6. [Rate Limiting Strategy](#rate-limiting-strategy)
7. [Additional Security Measures](#additional-security-measures)

## JWT Implementation

### Key Generation and Storage

- **Algorithm**: RS256 (RSA Signature with SHA-256)
- **Key Length**: 2048 bits
- **Key Storage**: Private keys stored securely with restricted access
- **Key Format**: PEM format

### JWT Claims

#### Access Token Claims

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "<key-id>"
  },
  "payload": {
    "iss": "auth.smarterfirms.com",
    "sub": "<user-uuid>",
    "aud": "api.smarterfirms.com",
    "iat": 1625097600,
    "exp": 1625101200,
    "jti": "<uuid-v4>",
    "type": "access",
    "name": "John Doe",
    "email": "user@example.com",
    "userType": "LAW_FIRM_USER|CONSULTANT",
    "firmId": "<firm-uuid>",
    "roles": ["user", "admin"],
    "permissions": ["read:matters", "write:documents"],
    "authMethod": "CLIO|LOCAL",
    "verified": true,
    "securityLevel": 2
  }
}
```

#### Refresh Token Claims

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "<key-id>"
  },
  "payload": {
    "iss": "auth.smarterfirms.com",
    "sub": "<user-uuid>",
    "aud": "auth.smarterfirms.com",
    "iat": 1625097600,
    "exp": 1625184000,
    "jti": "<uuid-v4>",
    "type": "refresh",
    "family": "<token-family-id>",
    "version": 1
  }
}
```

### Token Lifetimes

- **Access Token**: 1 hour (3600 seconds)
- **Refresh Token**: 30 days (2,592,000 seconds)
- **Session Token** (for 2FA): 5 minutes (300 seconds)

### Key Rotation

- **Scheduled Rotation**: Every 30 days
- **Emergency Rotation**: Available for immediate rotation in case of suspected compromise
- **Active Keys**: System maintains at least 2 active keys (current and previous) during rotation
- **Key Identifier (KID)**: Generated using SHA-256 hash of public key, truncated to 16 characters

### JWKS Endpoint

- **Endpoint**: `/.well-known/jwks.json`
- **Format**:
  ```json
  {
    "keys": [
      {
        "kty": "RSA",
        "use": "sig",
        "kid": "<key-id>",
        "alg": "RS256",
        "n": "<base64-url-encoded-modulus>",
        "e": "<base64-url-encoded-exponent>"
      }
    ]
  }
  ```

### Token Verification

- **Signature Verification**: Using public key from JWKS
- **Claims Validation**:
  - Issuer (`iss`) must match expected value
  - Audience (`aud`) must match expected value
  - Token type must match expected value
  - Expiration (`exp`) must be in the future
  - Not before (`nbf`) if present must be in the past
  - Issued at (`iat`) if present must be in the past
- **Silent Validation**: Performed on each API request
- **JTI Tracking**: Prevent token reuse in critical operations

## PKCE Implementation

### Code Challenge Methods

- **Supported Methods**: S256 only (plain method not supported for security reasons)
- **Code Verifier Requirements**:
  - Minimum Length: 43 characters
  - Maximum Length: 128 characters
  - Character Set: [A-Z], [a-z], [0-9], "-", ".", "_", "~"
  - Encoding: URL-safe Base64 without padding

### Code Challenge Generation

1. Client generates a cryptographically random code verifier
2. Client computes code challenge as:
   ```
   code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
   ```
3. Client sends `code_challenge` and `code_challenge_method=S256` in authorization request

### Authorization Flow

1. Client requests authorization URL from `/auth/clio/url`
2. Server generates state parameter for CSRF protection
3. Server returns authorization URL including code challenge parameters
4. After authorization, client sends code and code verifier to token endpoint
5. Server verifies code verifier by:
   - Computing the code challenge from the received code verifier
   - Comparing with the originally received code challenge

## Password Hashing

### Algorithm and Parameters

- **Algorithm**: Argon2id (memory-hard function resistant to both side-channel and GPU attacks)
- **Parameters**:
  - Memory Cost: 65536 KiB (64 MB)
  - Time Cost: 3 iterations
  - Parallelism: 4 lanes
  - Salt Length: 16 bytes (128 bits)
  - Hash Length: 32 bytes (256 bits)

### Implementation Details

```javascript
const argon2 = require('argon2');

// Hashing a password
async function hashPassword(password) {
  return await argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 4,
    saltLength: 16,
    hashLength: 32
  });
}

// Verifying a password
async function verifyPassword(hash, password) {
  return await argon2.verify(hash, password);
}
```

### Password Requirements

- **Minimum Length**: 12 characters
- **Character Requirements**:
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one number
  - At least one special character
- **Password History**: Previous 10 passwords cannot be reused
- **Maximum Age**: 90 days before requiring change
- **Regular Expression**: `/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,}$/`

## IP Binding Security

### Binding Type

- **Subnet Binding**: Match the first 24 bits of the IP address (Class C subnet)
- **Storage**: IP subnet is stored with refresh token record

### Verification Levels

1. **Same Subnet**:
   - No additional verification required
   - Example: 192.168.1.x → 192.168.1.y

2. **Different Subnet**:
   - Additional verification required
   - Options: Email verification code or 2FA challenge
   - Example: 192.168.1.x → 192.168.2.y

3. **Different Region/Country**:
   - Full re-authentication required
   - Based on IP geolocation
   - Example: IP from US → IP from Europe

### Implementation Strategy

```javascript
// IP subnet comparison function
function isSameSubnet(ip1, ip2) {
  // Convert IPs to numeric representation
  const ipToLong = (ip) => {
    return ip.split('.')
      .map((octet, index) => parseInt(octet) * Math.pow(256, 3-index))
      .reduce((acc, val) => acc + val);
  };
  
  const ip1Num = ipToLong(ip1);
  const ip2Num = ipToLong(ip2);
  
  // Apply subnet mask (/24)
  const mask = 0xFFFFFF00;
  
  return (ip1Num & mask) === (ip2Num & mask);
}
```

## Token Rotation and Revocation

### Token Family Tracking

- **Family ID**: UUID assigned to each user's refresh token set
- **Version**: Incremental number for each new token in the family
- **Maximum Size**: 5 active tokens per family
- **Pruning Strategy**: Revoke oldest tokens when limit exceeded

### Automatic Token Refresh

- **Threshold**: Refresh when access token reaches 75% of its lifetime
- **Implementation**: Client-side monitoring of token expiration

### Revocation Scenarios

1. **Single Token Revocation**:
   - User logs out from a specific device
   - Token family remains active, only specific token is revoked

2. **Family Revocation**:
   - Password change
   - Security-sensitive account update
   - Suspicious activity detected
   - All tokens in the family are revoked

3. **Version Invalidation**:
   - When a new token is issued, all tokens with lower version numbers are considered invalid
   - Helps detect token theft attempts

### Reuse Detection

- **Detection Method**: If a refresh token with a version lower than the current maximum version is used, it indicates potential token theft
- **Response**: Revoke the entire token family and require re-authentication

## Rate Limiting Strategy

### Rate Limit Definitions

| Endpoint             | Rate Limit                            | Purpose                                 |
|----------------------|---------------------------------------|----------------------------------------|
| `/auth/login`        | 5 per minute per account, 20 per hour per IP | Prevent brute force attacks             |
| `/auth/register`     | 10 per hour per IP                    | Prevent mass account creation           |
| `/auth/forgot-password` | 3 per hour per email               | Prevent email enumeration               |
| `/auth/reset-password` | 5 per token                         | Prevent brute force on reset tokens     |
| `/auth/refresh`      | 10 per hour per user                  | Prevent token grinding attacks          |
| API requests         | 100 per minute per user               | Prevent DoS attacks                    |

### Implementation

- **Storage**: Redis for distributed rate limiting
- **Fallback**: In-memory store if Redis is unavailable
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Timestamp when the limit resets

### Account Lockout

- **Threshold**: 5 failed login attempts
- **Lockout Period**: 10 minutes
- **Progressive Backoff**: Increasing delays between login attempts

## Additional Security Measures

### CSRF Protection

- **Token-based Protection**: State parameter for OAuth flows
- **SameSite Cookies**: Cookies set with SameSite=Lax attribute
- **Double Submit Cookie Pattern**: For state-changing operations
- **Origin Validation**: Check Origin and Referer headers

### Secure Cookie Configuration

- **HttpOnly**: Prevent JavaScript access to sensitive cookies
- **Secure**: HTTPS-only cookies in production
- **SameSite**: Lax for most cookies, Strict for security-critical cookies
- **Expiration**: Aligned with token expiration times
- **Domain**: Strict domain binding

### Request Validation

- **Schema Validation**: Using Zod for all incoming requests
- **Content Type Validation**: Enforce expected content types
- **Header Validation**: Verify required security headers

### Audit Logging

- **Events Logged**:
  - Authentication attempts (success/failure)
  - Token issuance and revocation
  - Security-sensitive actions (password changes, 2FA changes)
  - Account updates
  - Administrative actions
- **Log Data**:
  - Timestamp
  - User ID (if available)
  - IP address
  - User agent
  - Action
  - Result
  - Additional context

### Consultant-Specific Security

- **Mandatory 2FA**: Cannot be disabled for consultant accounts
- **Session Timeout**: 30 minutes of inactivity (versus 2 hours for regular users)
- **IP Tracking**: Log and monitor all login locations
- **Cross-Firm Access Control**: Granular permission system
- **Audit Trail**: Comprehensive logging of all consultant actions

### Data Minimization

- **Token Payload**: Include only necessary claims
- **Storage Period**: Define retention periods for logs and temporary data
- **PII Handling**: Strict access controls for personally identifiable information 