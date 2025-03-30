# Authentication Flows

This document describes the authentication flows for the Smarter Firms platform, including sequence diagrams for each flow.

## Table of Contents

1. [Clio SSO Authentication Flow](#clio-sso-authentication-flow)
2. [Email/Password Authentication Flow](#emailpassword-authentication-flow)
3. [Two-Factor Authentication Flow](#two-factor-authentication-flow)
4. [Token Refresh Flow](#token-refresh-flow)
5. [Account Linking Flow](#account-linking-flow)
6. [Password Reset Flow](#password-reset-flow)

## Clio SSO Authentication Flow

This flow implements OAuth 2.0 with PKCE for secure authentication with Clio.

```mermaid
sequenceDiagram
    participant User
    participant Client
    participant Auth Service
    participant Clio Auth

    User->>Client: Click "Sign in with Clio"
    Client->>Auth Service: GET /auth/clio/url
    Note over Client,Auth Service: Generate code_verifier and code_challenge
    Auth Service-->>Client: Return authorization URL + code_verifier
    Client->>Clio Auth: Redirect to Clio authorization URL with code_challenge
    User->>Clio Auth: Authenticate with Clio
    Clio Auth->>Client: Redirect to callback URL with authorization code
    Client->>Auth Service: GET /auth/clio/callback?code=xyz&state=abc&code_verifier=def
    Auth Service->>Clio Auth: Exchange code + code_verifier for tokens
    Clio Auth-->>Auth Service: Return access, refresh, and ID tokens
    Auth Service->>Auth Service: Verify tokens and extract user info
    Auth Service->>Auth Service: Create/update user account
    Auth Service->>Auth Service: Generate JWT tokens
    Auth Service-->>Client: Redirect with tokens in URL fragment
    Client->>Client: Store tokens
    Client->>Auth Service: Use access token for API requests
```

### Key Security Measures:
- PKCE (Proof Key for Code Exchange) to prevent authorization code interception
- State parameter to prevent CSRF attacks
- Code challenge method: S256 only (plain not supported)
- JWT tokens with RS256 signing for secure API access

## Email/Password Authentication Flow

Traditional email/password authentication with optional two-factor authentication.

```mermaid
sequenceDiagram
    participant User
    participant Client
    participant Auth Service
    participant Email Service

    alt New User Registration
        User->>Client: Fill registration form
        Client->>Auth Service: POST /auth/register
        Auth Service->>Auth Service: Validate input
        Auth Service->>Auth Service: Hash password (Argon2id)
        Auth Service->>Auth Service: Create user account
        Auth Service->>Email Service: Send verification email
        Auth Service-->>Client: Return success with user info
        Client->>User: Show verification required message
        
        User->>Client: Click verification link in email
        Client->>Auth Service: POST /auth/verify-email
        Auth Service->>Auth Service: Verify token
        Auth Service->>Auth Service: Update email verified status
        Auth Service-->>Client: Return success
    end
    
    User->>Client: Enter email and password
    Client->>Auth Service: POST /auth/login
    Auth Service->>Auth Service: Validate credentials
    
    alt 2FA Enabled
        Auth Service-->>Client: Return session token with requires2FA flag
        Client->>User: Show 2FA input screen
        Note right of User: See Two-Factor Authentication Flow
    else 2FA Not Enabled
        Auth Service->>Auth Service: Generate JWT tokens
        Auth Service-->>Client: Return tokens and user info
        Client->>Client: Store tokens
    end
    
    Client->>Auth Service: Use access token for API requests
```

### Key Security Measures:
- Argon2id password hashing with proper parameters
- Rate limiting on login attempts
- Email verification required
- Strong password requirements enforced
- Account lockout after multiple failed attempts

## Two-Factor Authentication Flow

Additional security layer after successful password authentication.

```mermaid
sequenceDiagram
    participant User
    participant Client
    participant Auth Service
    
    alt Setup 2FA
        User->>Client: Request 2FA setup
        Client->>Auth Service: POST /auth/2fa/setup (authenticated)
        Auth Service->>Auth Service: Generate TOTP secret
        Auth Service-->>Client: Return secret and QR code
        Client->>User: Display QR code
        User->>User: Scan QR code with authenticator app
        User->>Client: Enter verification code
        Client->>Auth Service: POST /auth/2fa/verify
        Auth Service->>Auth Service: Verify code
        Auth Service->>Auth Service: Enable 2FA and generate recovery codes
        Auth Service-->>Client: Return recovery codes
        Client->>User: Display and prompt to save recovery codes
    end
    
    alt Login with 2FA
        Note over User,Auth Service: User has already authenticated with password
        Auth Service-->>Client: Return session token with requires2FA flag
        Client->>User: Prompt for 2FA code
        User->>Client: Enter 2FA code
        Client->>Auth Service: POST /auth/2fa/challenge
        Auth Service->>Auth Service: Verify code
        Auth Service->>Auth Service: Generate JWT tokens
        Auth Service-->>Client: Return tokens and user info
        Client->>Client: Store tokens
    end
    
    alt Disable 2FA (non-consultant users only)
        User->>Client: Request disable 2FA
        Client->>Auth Service: DELETE /auth/2fa (authenticated)
        Auth Service->>Auth Service: Verify user is not consultant
        Auth Service->>Auth Service: Disable 2FA
        Auth Service-->>Client: Return success
    end
```

### Key Security Measures:
- TOTP (Time-based One-Time Password) using industry standard algorithm
- Recovery codes for backup access
- Mandatory 2FA for consultant accounts
- Rate limiting on verification attempts

## Token Refresh Flow

Process for obtaining new tokens without requiring re-authentication.

```mermaid
sequenceDiagram
    participant Client
    participant Auth Service
    
    Note over Client: Access token reaches 75% of lifetime
    
    alt Automatic Refresh
        Client->>Auth Service: POST /auth/refresh
        Auth Service->>Auth Service: Validate refresh token
        Auth Service->>Auth Service: Check token family and version
        Auth Service->>Auth Service: Verify IP subnet matches
        Auth Service->>Auth Service: Generate new token pair
        Auth Service->>Auth Service: Update token version
        Auth Service-->>Client: Return new tokens
        Client->>Client: Store new tokens
    end
    
    alt Manual Refresh (access token expired)
        Client->>Auth Service: API request with expired token
        Auth Service-->>Client: 401 Unauthorized
        Client->>Auth Service: POST /auth/refresh
        Auth Service->>Auth Service: Validate refresh token
        Auth Service->>Auth Service: Check token family and version
        Auth Service->>Auth Service: Verify IP subnet matches
        Auth Service->>Auth Service: Generate new token pair
        Auth Service->>Auth Service: Update token version
        Auth Service-->>Client: Return new tokens
        Client->>Client: Store new tokens
        Client->>Auth Service: Retry original API request
    end
    
    alt IP Changed
        Client->>Auth Service: POST /auth/refresh
        Auth Service->>Auth Service: Detect IP subnet change
        alt Different Subnet
            Auth Service-->>Client: Return 403 with additional verification required
            Client->>User: Prompt for additional verification
            User->>Client: Complete additional verification
            Client->>Auth Service: POST /auth/refresh with verification
            Auth Service->>Auth Service: Generate new token pair
            Auth Service-->>Client: Return new tokens
        else Different Region/Country
            Auth Service-->>Client: Return 403 requiring full re-authentication
            Client->>User: Prompt for re-authentication
            Note over Client,Auth Service: Restart authentication flow
        end
    end
```

### Key Security Measures:
- Token family tracking to detect token theft
- Token versioning to invalidate older tokens
- IP subnet binding with tiered security approach
- Rate limiting on refresh requests
- JTI (JWT ID) tracking for token uniqueness

## Account Linking Flow

Process for linking an external authentication provider to an existing account.

```mermaid
sequenceDiagram
    participant User
    participant Client
    participant Auth Service
    participant Clio Auth
    
    User->>Client: Request to link Clio account
    Client->>Auth Service: GET /auth/clio/url (authenticated)
    Auth Service-->>Client: Return authorization URL + code_verifier
    Client->>Clio Auth: Redirect to Clio authorization URL with code_challenge
    User->>Clio Auth: Authenticate with Clio
    Clio Auth->>Client: Redirect to callback URL with authorization code
    Client->>Auth Service: POST /auth/link-account (authenticated)
    Auth Service->>Clio Auth: Exchange code + code_verifier for tokens
    Clio Auth-->>Auth Service: Return access, refresh, and ID tokens
    Auth Service->>Auth Service: Verify tokens and extract user info
    Auth Service->>Auth Service: Check if Clio ID is already linked
    Auth Service->>Auth Service: Link Clio account to user
    Auth Service-->>Client: Return success with available auth methods
    Client->>User: Show success message
```

### Key Security Measures:
- Authentication required for account linking
- PKCE flow for secure OAuth
- Prevention of linking same Clio account to multiple users
- Proper error handling for conflict scenarios

## Password Reset Flow

Secure flow for resetting a forgotten password.

```mermaid
sequenceDiagram
    participant User
    participant Client
    participant Auth Service
    participant Email Service
    
    User->>Client: Request password reset
    Client->>Auth Service: POST /auth/forgot-password
    Auth Service->>Auth Service: Generate reset token
    Auth Service->>Email Service: Send password reset email
    Auth Service-->>Client: Return success (regardless of email existence)
    
    User->>Client: Click reset link in email
    Client->>User: Show password reset form
    User->>Client: Enter new password
    Client->>Auth Service: POST /auth/reset-password
    Auth Service->>Auth Service: Verify token
    Auth Service->>Auth Service: Check token expiration
    Auth Service->>Auth Service: Validate password strength
    Auth Service->>Auth Service: Check password history
    Auth Service->>Auth Service: Hash and update password
    Auth Service->>Auth Service: Invalidate all refresh tokens
    Auth Service-->>Client: Return success
    Client->>User: Show success message and login form
```

### Key Security Measures:
- Time-limited reset tokens (1 hour validity)
- Same response whether email exists or not (prevents enumeration)
- Strong password requirements enforced
- Password history checking to prevent reuse
- All existing sessions invalidated after reset
- Rate limiting on forgot password requests 