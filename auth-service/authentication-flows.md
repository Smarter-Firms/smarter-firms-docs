# Authentication Flows

This document details the authentication flows implemented in the Smarter Firms platform.

## Clio SSO Flow with PKCE

The primary authentication method for law firm users is Single Sign-On (SSO) with Clio, implemented using the OAuth 2.0 Authorization Code flow with PKCE (Proof Key for Code Exchange) for enhanced security.

```mermaid
sequenceDiagram
    participant User as User Browser
    participant Client as Smarter Firms UI
    participant Auth as Auth Service
    participant Clio as Clio Identity
    participant ClioAPI as Clio API

    User->>Client: Click "Sign in with Clio"
    Client->>Client: Generate code_verifier (random string)
    Client->>Client: Calculate code_challenge = SHA256(code_verifier)
    Client->>Auth: POST /clio/authorize {code_challenge, redirect_uri}
    Auth->>Auth: Store code_challenge with state
    Auth->>Client: Return authorization URL + state
    Client->>User: Redirect to Clio authorization URL
    User->>Clio: Authenticate with Clio credentials
    Clio->>User: Present authorization consent
    User->>Clio: Approve authorization
    Clio->>Client: Redirect with authorization code + state
    Client->>Auth: POST /clio/callback {code, state, code_verifier}
    Auth->>Auth: Verify state matches
    Auth->>Auth: Verify code_challenge = SHA256(code_verifier)
    Auth->>Clio: Exchange code for tokens
    Clio->>Auth: Return access and refresh tokens
    Auth->>ClioAPI: Get user profile info
    ClioAPI->>Auth: Return user data
    Auth->>Auth: Create/update user account
    Auth->>Auth: Generate JWT and refresh token
    Auth->>Client: Return tokens + user profile
    Client->>User: Redirect to dashboard
```

### Security Measures

- PKCE implementation requires S256 method only (no plain code challenge)
- Code verifier: 43-128 characters, cryptographically secure random generation
- State parameter for CSRF protection
- HTTP-only cookies for refresh tokens
- Multiple redirect URI validation

## Email/Password Authentication

Traditional email/password authentication serves as a fallback method and for consultant users.

```mermaid
sequenceDiagram
    participant User as User Browser
    participant Client as Smarter Firms UI
    participant Auth as Auth Service
    participant DB as Database

    User->>Client: Enter email/password
    Client->>Client: Collect browser fingerprint
    Client->>Auth: POST /login {email, password, fingerprint}
    Auth->>Auth: Rate limiting check
    Auth->>DB: Query user by email
    DB->>Auth: Return user (if exists)
    Auth->>Auth: Verify password with Argon2id
    Auth->>Auth: Check email verification status
    Auth->>Auth: Generate JWT and refresh token
    Auth->>Auth: Associate fingerprint with session
    Auth->>Auth: Log authentication event
    Auth->>Client: Return tokens + Set-Cookie with refresh token
    Client->>User: Redirect to dashboard or 2FA
```

### Security Measures

- Argon2id password hashing with proper parameters
- Rate limiting by IP and username
- Browser fingerprinting for suspicious login detection
- Account lockout after multiple failures
- Comprehensive security event logging

## Two-Factor Authentication Flow

Mandatory for consultant accounts, optional for law firm users.

```mermaid
sequenceDiagram
    participant User as User Browser
    participant Client as Smarter Firms UI
    participant Auth as Auth Service
    participant DB as Database

    Note over User,Auth: After successful primary authentication

    Auth->>DB: Check if 2FA is enabled/required
    DB->>Auth: Return 2FA status
    
    alt 2FA Required
        Auth->>Client: Return requires_2fa=true
        Client->>User: Show 2FA input screen
        User->>Client: Enter 2FA code
        Client->>Auth: POST /2fa/verify {code}
        Auth->>Auth: Verify TOTP code
        
        alt 2FA Valid
            Auth->>Auth: Generate full access tokens
            Auth->>Client: Return tokens + user profile
            Client->>User: Complete login, redirect to dashboard
        else 2FA Invalid
            Auth->>Client: Return error
            Client->>User: Show error, prompt retry
        end
    else 2FA Not Required
        Auth->>Client: Return full tokens + user profile
        Client->>User: Complete login, redirect to dashboard
    end
```

## Token Refresh Strategy

Includes IP-binding and token family tracking for enhanced security.

```mermaid
sequenceDiagram
    participant Client as Smarter Firms UI
    participant Auth as Auth Service
    participant Redis as Token Store
    
    Client->>Auth: POST /token {grant_type: "refresh_token", fingerprint}
    Auth->>Auth: Extract refresh token from cookie
    Auth->>Auth: Validate token signature and expiration
    Auth->>Redis: Verify token is not blacklisted
    Auth->>Auth: Check IP subnet against original IP
    
    alt IP Changed Subnet
        Auth->>Client: Return error or require additional verification
    else IP Valid
        Auth->>Auth: Generate new access and refresh token
        Auth->>Redis: Invalidate old refresh token
        Auth->>Redis: Store new refresh token in same family
        Auth->>Client: Return new tokens + updated cookie
    end
```

### Security Measures

- Token family tracking to detect theft
- IP subnet binding with tiered verification
- Automated blacklisting of suspicious token families
- Refresh token rotation on every use

## Account Linking Process

For connecting existing accounts to Clio.

```mermaid
sequenceDiagram
    participant User as User Browser
    participant Client as Smarter Firms UI
    participant Auth as Auth Service
    participant Clio as Clio Identity
    participant DB as Database

    User->>Client: Initiate Clio account linking
    Client->>Auth: GET /me (get current user profile)
    Auth->>Client: Return user profile
    Client->>Client: Generate code_verifier
    Client->>Client: Calculate code_challenge
    Client->>Auth: POST /clio/authorize {code_challenge, redirect_uri}
    Auth->>Client: Return authorization URL + state
    Client->>User: Redirect to Clio authorization
    User->>Clio: Authenticate with Clio
    Clio->>Client: Redirect with authorization code
    Client->>Auth: POST /account/link-clio {code, state, code_verifier}
    Auth->>Clio: Exchange code for tokens
    Clio->>Auth: Return Clio tokens
    Auth->>DB: Update user with Clio connection
    Auth->>Client: Return updated user profile
    Client->>User: Show success, update UI
```

## Password Reset Flow

Secure flow for password recovery.

```mermaid
sequenceDiagram
    participant User as User Browser
    participant Client as Smarter Firms UI
    participant Auth as Auth Service
    participant Email as Email Service
    participant DB as Database

    User->>Client: Request password reset
    Client->>Auth: POST /password-reset/request {email}
    Auth->>Auth: Rate limiting check
    Auth->>DB: Check if user exists
    Auth->>Auth: Generate secure reset token
    Auth->>DB: Store hashed token with expiration
    Auth->>Email: Send reset email with token
    Auth->>Client: Return success (regardless of user existence)
    Client->>User: Show instructions
    
    User->>Client: Click reset link in email
    Client->>User: Show password reset form
    User->>Client: Enter new password
    Client->>Auth: POST /password-reset/confirm {token, new_password}
    Auth->>DB: Verify token is valid and not expired
    Auth->>Auth: Hash new password with Argon2id
    Auth->>DB: Update password, invalidate token
    Auth->>Auth: Invalidate all existing refresh tokens
    Auth->>Client: Return success
    Client->>User: Show success, redirect to login
```

## Error Handling

All authentication flows include standardized error handling:

- Specific error codes for different failure scenarios
- Rate limiting information in headers
- Graceful degradation when subsystems are unavailable
- Security-focused logging that avoids sensitive data 