# Authentication System API Contracts

This document defines the API contracts for the authentication system in the Smarter Firms platform. It includes detailed specifications for all authentication endpoints, request/response formats, and security requirements.

## Table of Contents

1. [Common Standards](#common-standards)
2. [Authentication Endpoints](#authentication-endpoints)
3. [JWT Token Structure](#jwt-token-structure)
4. [Security Requirements](#security-requirements)
5. [Error Handling](#error-handling)

## Common Standards

All authentication API endpoints adhere to the following standards:

- **Base URL**: `/api/v1/auth`
- **Content Type**: `application/json`
- **Authentication**: Bearer token in the `Authorization` header when required
- **Rate Limiting**: Applied to sensitive endpoints with specific thresholds
- **CSRF Protection**: For state-changing operations

### Common Response Format

All responses follow a standard structure:

**Success Response**:
```json
{
  "status": "success",
  "data": {} // Response data specific to the endpoint
}
```

**Error Response**:
```json
{
  "status": "error",
  "code": "ERROR_CODE",
  "message": "Human-readable error message",
  "details": {} // Optional additional error details
}
```

## Authentication Endpoints

### Registration and Login

#### POST /register
- **Description**: Register a new user
- **Rate Limit**: 10 requests per IP per hour
- **Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "firstName": "John",
  "lastName": "Doe",
  "userType": "LAW_FIRM_USER|CONSULTANT",
  "organization": "Law Firm Inc.",
  "referralCode": "ABC123" // Optional
}
```
- **Response (201 Created)**:
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "user_uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "userType": "LAW_FIRM_USER",
      "isEmailVerified": false,
      "twoFactorEnabled": false,
      "hasClioConnection": false
    },
    "tokens": {
      "accessToken": "jwt_access_token",
      "refreshToken": "jwt_refresh_token",
      "expiresIn": 3600
    }
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid input data
  - `409 Conflict`: Email already exists
  - `429 Too Many Requests`: Rate limit exceeded
  
#### POST /login
- **Description**: Authenticate with email/password
- **Rate Limit**: 5 requests per account per minute, 20 per IP per hour
- **Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "user_uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "userType": "LAW_FIRM_USER",
      "organization": "Law Firm Inc.",
      "isEmailVerified": true,
      "twoFactorEnabled": false,
      "hasClioConnection": true
    },
    "tokens": {
      "accessToken": "jwt_access_token",
      "refreshToken": "jwt_refresh_token",
      "expiresIn": 3600
    }
  }
}
```
- **Response for 2FA-enabled accounts**:
```json
{
  "status": "success",
  "data": {
    "sessionToken": "temporary_session_token",
    "requires2FA": true
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid credentials format
  - `401 Unauthorized`: Invalid credentials
  - `403 Forbidden`: Account locked or requires verification
  - `429 Too Many Requests`: Rate limit exceeded

#### POST /refresh
- **Description**: Refresh access token
- **Rate Limit**: 10 requests per user per minute
- **Request Body**:
```json
{
  "refreshToken": "jwt_refresh_token"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "accessToken": "new_jwt_access_token",
    "refreshToken": "new_jwt_refresh_token",
    "expiresIn": 3600
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid token format
  - `401 Unauthorized`: Invalid or expired token
  - `429 Too Many Requests`: Rate limit exceeded

#### POST /logout
- **Description**: Invalidate tokens
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "refreshToken": "jwt_refresh_token" // Optional, if not provided all sessions will be terminated
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Successfully logged out"
  }
}
```

### Email Verification

#### POST /verify-email
- **Description**: Verify user email address
- **Rate Limit**: 5 requests per token
- **Request Body**:
```json
{
  "token": "verification_token"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Email verified successfully"
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid token
  - `410 Gone`: Token expired

#### POST /resend-verification
- **Description**: Resend email verification
- **Authentication Required**: Yes
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Verification email sent successfully"
  }
}
```

### Password Management

#### POST /forgot-password
- **Description**: Request password reset
- **Rate Limit**: 3 requests per email per hour
- **Request Body**:
```json
{
  "email": "user@example.com"
}
```
- **Response (200 OK)**: Always return success to prevent email enumeration
```json
{
  "status": "success",
  "data": {
    "message": "If your email exists in our system, you will receive reset instructions"
  }
}
```

#### POST /reset-password
- **Description**: Reset password with token
- **Rate Limit**: 5 requests per token
- **Request Body**:
```json
{
  "token": "reset_token",
  "newPassword": "NewSecurePassword123!"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Password reset successfully"
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid token or password
  - `410 Gone`: Token expired

#### POST /change-password
- **Description**: Change password when authenticated
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "currentPassword": "CurrentPassword123!",
  "newPassword": "NewSecurePassword123!"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Password changed successfully"
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid current password or new password doesn't meet requirements
  - `401 Unauthorized`: Current password incorrect

### Two-Factor Authentication

#### POST /2fa/setup
- **Description**: Initialize 2FA setup
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "method": "APP" // APP, SMS
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "secret": "OTP_SECRET",
    "qrCode": "data:image/png;base64,..." // Only for app method
  }
}
```

#### POST /2fa/verify
- **Description**: Verify and activate 2FA
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "code": "123456",
  "method": "APP" // APP, SMS
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "enabled": true,
    "recoveryCodes": ["code1", "code2", "code3", ...]
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid verification code

#### POST /2fa/challenge
- **Description**: Complete 2FA challenge during login
- **Request Body**:
```json
{
  "sessionToken": "temporary_session_token",
  "code": "123456"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "user_uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "userType": "LAW_FIRM_USER",
      "organization": "Law Firm Inc.",
      "isEmailVerified": true,
      "twoFactorEnabled": true,
      "hasClioConnection": false
    },
    "tokens": {
      "accessToken": "jwt_access_token",
      "refreshToken": "jwt_refresh_token",
      "expiresIn": 3600
    }
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid code or session
  - `401 Unauthorized`: Invalid session token

#### DELETE /2fa
- **Description**: Disable 2FA
- **Authentication Required**: Yes
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Two-factor authentication disabled successfully"
  }
}
```

### Clio Integration

#### GET /clio/url
- **Description**: Get Clio OAuth authorization URL
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "authUrl": "https://account.clio.com/oauth2/auth?response_type=code&client_id={client_id}&redirect_uri={callback_uri}&scope=openid&state={csrf_token}"
  }
}
```

#### GET /clio/callback
- **Description**: Handle Clio OAuth callback
- **Query Parameters**:
  - `code`: Authorization code from Clio
  - `state`: CSRF token to validate
- **Response**: Redirects to frontend with tokens in URL fragment

#### POST /link-account
- **Description**: Link external auth provider to existing account
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "provider": "CLIO",
  "authCode": "authorization_code"
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "message": "Account linked successfully",
    "authMethods": ["LOCAL", "CLIO"]
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: Invalid code
  - `409 Conflict`: Provider account already linked to another user

### Consultant Profile Management

#### POST /consultant-profile
- **Description**: Create consultant profile
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "specialty": "Legal Technology",
  "bio": "Expert in legal tech solutions",
  "publicProfile": true
}
```
- **Response (201 Created)**:
```json
{
  "status": "success",
  "data": {
    "profile": {
      "id": "profile_uuid",
      "userId": "user_uuid",
      "specialty": "Legal Technology",
      "bio": "Expert in legal tech solutions",
      "publicProfile": true,
      "profileImage": null,
      "createdAt": "2023-06-01T00:00:00Z"
    }
  }
}
```
- **Error Responses**:
  - `400 Bad Request`: User is not a consultant

#### PUT /consultant-profile
- **Description**: Update consultant profile
- **Authentication Required**: Yes
- **Request Body**:
```json
{
  "specialty": "Legal Technology",
  "bio": "Updated bio information",
  "publicProfile": true
}
```
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "profile": {
      "id": "profile_uuid",
      "userId": "user_uuid",
      "specialty": "Legal Technology",
      "bio": "Updated bio information",
      "publicProfile": true,
      "profileImage": null,
      "updatedAt": "2023-06-01T00:00:00Z"
    }
  }
}
```

### Token Management

#### GET /validate-token
- **Description**: Validate access token
- **Authentication Required**: Yes
- **Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "valid": true,
    "payload": {
      "sub": "user_uuid",
      "email": "user@example.com",
      "userType": "LAW_FIRM_USER",
      "roles": ["user"],
      "permissions": ["read:matters", "write:documents"]
    }
  }
}
```

#### GET /.well-known/jwks.json
- **Description**: Get JSON Web Key Set (JWKS) for token verification
- **Response (200 OK)**:
```json
{
  "keys": [
    {
      "kty": "RSA",
      "use": "sig",
      "kid": "key-id-1",
      "alg": "RS256",
      "n": "key-modulus",
      "e": "AQAB"
    }
  ]
}
```

## JWT Token Structure

### Access Token

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-id-1"
  },
  "payload": {
    "iss": "auth.smarterfirms.com",
    "sub": "user_uuid",
    "aud": "api.smarterfirms.com",
    "iat": 1625097600,
    "exp": 1625101200,
    "jti": "unique-jwt-id",
    "type": "access",
    "name": "John Doe",
    "email": "user@example.com",
    "userType": "LAW_FIRM_USER|CONSULTANT",
    "firmId": "firm_uuid", // For firm users
    "roles": ["user", "admin"],
    "permissions": ["read:matters", "write:documents"],
    "authMethod": "CLIO|LOCAL",
    "verified": true,
    "securityLevel": 2
  }
}
```

### Refresh Token

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-id-1"
  },
  "payload": {
    "iss": "auth.smarterfirms.com",
    "sub": "user_uuid",
    "aud": "auth.smarterfirms.com",
    "iat": 1625097600,
    "exp": 1625184000,
    "jti": "unique-jwt-id",
    "type": "refresh",
    "family": "token-family-id",
    "version": 1
  }
}
```

## Security Requirements

### Password Policy

- **Minimum Length**: 12 characters
- **Required Complexity**:
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one number
  - At least one special character
- **Password History**: 10 previous passwords
- **Maximum Age**: 90 days
- **Hashing**: Bcrypt with work factor 12+

### Rate Limiting Thresholds

- **Login**: 5 attempts per account per minute, 20 per IP per hour
- **Registration**: 10 attempts per IP per hour
- **Password Reset**: 3 attempts per email per hour
- **API**: 100 requests per minute per user
- **Failed Login Lockout**: 10 minutes after 5 consecutive failures

### CSRF Protection

- **CSRF Tokens**: Required for all state-changing operations
- **Double-Submit Cookie Pattern**: Implemented
- **Header Validation**: Origin and Referer headers checked

### Cookie Security

- **HTTP-Only Flag**: Enabled for all authentication cookies
- **Secure Flag**: Enabled (HTTPS only)
- **SameSite**: Lax for standard operation
- **Domain Binding**: Strict
- **Signed Cookies**: To prevent tampering

## Error Handling

All error responses follow this format:

```json
{
  "status": "error",
  "code": "ERROR_CODE",
  "message": "Human readable error message",
  "details": {} // Optional additional error details
}
```

### Common Error Codes

- `INTERNAL_SERVER_ERROR`: Unhandled server error
- `VALIDATION_ERROR`: Invalid request data
- `UNAUTHORIZED`: Authentication required
- `FORBIDDEN`: Not permitted to access the resource
- `NOT_FOUND`: Resource not found
- `CONFLICT`: Resource already exists
- `TOKEN_EXPIRED`: Authentication token has expired
- `INVALID_TOKEN`: Invalid authentication token
- `INVALID_CREDENTIALS`: Invalid login credentials
- `EMAIL_ALREADY_EXISTS`: Email already registered
- `ACCOUNT_INACTIVE`: Account is not active
- `EMAIL_NOT_VERIFIED`: Email address not verified
- `ACCOUNT_LOCKED`: Account temporarily locked
- `TOO_MANY_REQUESTS`: Rate limit exceeded
- `TWO_FACTOR_REQUIRED`: Two-factor authentication required
- `INVALID_TWO_FACTOR_CODE`: Invalid two-factor code 