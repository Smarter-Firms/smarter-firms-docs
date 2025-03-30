# Authentication Strategy

This document outlines the authentication strategy for the Smarter Firms platform, focusing on our primary approach using Clio SSO with fallback options and the consultant experience.

## Authentication Approaches

Smarter Firms will implement a hybrid authentication strategy to support both direct law firm users and consultants:

### 1. Primary Authentication: Clio SSO (OpenID Connect)

For all Clio-connected users, we'll implement "Sign in with Clio" using the OpenID Connect protocol:

- **User Flow**: Users click "Sign in with Clio" → Redirect to Clio Identity → Authenticate → Return with authorization code → Exchange for tokens → Create/update Smarter Firms account
- **Data Retrieved**: User profile (name, email), firm information
- **Security**: Leverages Clio's security including their 2FA if enabled
- **Session Management**: Standard JWT with refresh token pattern, synchronized with Clio token expiration

### 2. Secondary Authentication: Email/Password Registration

For consultants and as a fallback for direct users:

- **User Flow**: Traditional email/password registration → Email verification → Optional 2FA setup
- **Security Requirements**: Strong password requirements, rate limiting, account lockout protection
- **2FA Options**: SMS or authenticator app

## User Types and Authentication Flows

### Law Firm Users (Clio-Connected)

1. **Initial Registration**:
   - User clicks "Sign in with Clio"
   - Redirected to Clio Identity for authentication
   - User authorizes Smarter Firms to access their Clio identity
   - Upon return, create Smarter Firms account using Clio profile data
   - Skip email verification (Clio has already verified)
   - Proceed directly to onboarding flow

2. **Return Login**:
   - User clicks "Sign in with Clio"
   - Authenticates with Clio
   - Upon return, session is established
   - Redirect to dashboard or last visited page

### Consultant Users

1. **Initial Registration**:
   - User selects "Consultant Registration" 
   - Enters email, password, name, organization
   - Verifies email address
   - Sets up 2FA (required for consultants)
   - Completes consultant profile
   - Awaits firm association or enters referral code

2. **Return Login**:
   - User enters email/password
   - Completes 2FA challenge
   - Redirected to firm selector dashboard

### Fallback Registration for Law Firm Users

1. **Initial Registration**:
   - User selects "Create Account" instead of "Sign in with Clio"
   - Enters email, password, name
   - Verifies email address
   - Optional 2FA setup
   - Completes onboarding including manual Clio connection

## Account Linking

Users can link Clio accounts to existing Smarter Firms accounts:

1. For consultants who later become Clio users
2. For users who initially registered with email/password but later want to use SSO

## Technical Implementation

### Clio SSO Implementation Details

```
Authorization Endpoint: https://account.clio.com/oauth2/auth
Token Endpoint: https://account.clio.com/oauth2/token
Required Parameters:
- response_type: "code"
- client_id: [CLIO_IDENTITY_APP_KEY]
- redirect_uri: [CALLBACK_URL]
- scope: "openid"
- state: [GENERATED_NONCE]
```

Implementation Notes:
- Store JWT signing keys from `https://account.clio.com/.well-known/jwks.json`
- Validate token claims including issuer, audience, expiration
- Extract user information from ID token claims

### Auth Service Extensions

The Auth Service will need to be extended to support:
- Multiple authentication providers (Clio SSO and local)
- User account merging/linking
- Consultant-specific roles and permissions
- Firm association mechanism for consultants

## Security Considerations

1. **Token Security**:
   - Store all tokens securely (HTTP-only cookies or server-side storage)
   - Implement proper token validation including signature verification
   - Handle token refresh securely

2. **Data Protection**:
   - Encrypt sensitive data at rest
   - Implement proper access controls for consultant access
   - Maintain comprehensive audit logs

3. **Special Consultant Requirements**:
   - Enforce 2FA for all consultant accounts
   - Implement additional rate limiting for consultant accounts
   - Regular security reviews for consultant access 