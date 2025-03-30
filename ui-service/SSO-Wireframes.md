# SSO with Fallback Authentication

This document outlines the design and technical specifications for the Single Sign-On (SSO) with fallback authentication flow for the Smarter Firms platform.

## Overview

The authentication system will primarily use Clio SSO for law firm users while providing a traditional email/password authentication fallback for consultants and users without Clio accounts.

## User Journey

### Primary Authentication Flow (Clio SSO)

1. **Initial Landing**:
   - User arrives at login page
   - Selects "Sign in with Clio" (prominent primary option)
   - Redirected to Clio authorization page

2. **Clio Authorization**:
   - User authenticates with Clio credentials
   - Authorizes Smarter Firms to access their Clio data
   - Redirected back to Smarter Firms with authorization code

3. **Account Creation/Login**:
   - For new users: Account automatically created using Clio profile data
   - For returning users: Automatically logged in
   - User directed to appropriate dashboard

### Secondary Authentication Flow (Email/Password)

1. **Traditional Registration**:
   - User selects "Register with Email" option
   - Completes registration form with email, password, name, etc.
   - Verifies email address
   - For consultants: Completes additional consultant profile

2. **Traditional Login**:
   - User enters email and password
   - Optional 2FA if enabled
   - Directed to appropriate dashboard

### Account Linking

1. **Linking Existing Account to Clio**:
   - User with email/password account navigates to account settings
   - Selects "Connect Clio Account"
   - Redirected to Clio authorization
   - Accounts linked upon successful authorization

## Interface Design

### 1. Landing/Login Page

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                          SMARTER FIRMS                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │               [PLATFORM INTRO/VALUE PROPOSITION]               │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │                     [SIGN IN WITH CLIO]                        │  │
│  │                                                                │  │
│  │                         --- OR ---                             │  │
│  │                                                                │  │
│  │              Email: [                              ]           │  │
│  │                                                                │  │
│  │           Password: [                              ]           │  │
│  │                                                                │  │
│  │                        [SIGN IN]                               │  │
│  │                                                                │  │
│  │  Don't have an account?                                        │  │
│  │  [Register with Email]       [Register as Consultant]          │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 2. Email Registration Form

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                          SMARTER FIRMS                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │                   CREATE YOUR ACCOUNT                          │  │
│  │                                                                │  │
│  │              Email: [                              ]           │  │
│  │                                                                │  │
│  │           Password: [                              ]           │  │
│  │                                                                │  │
│  │  Confirm Password: [                              ]           │  │
│  │                                                                │  │
│  │         First Name: [                              ]           │  │
│  │                                                                │  │
│  │          Last Name: [                              ]           │  │
│  │                                                                │  │
│  │               Firm: [                              ]           │  │
│  │                                                                │  │
│  │          Position: [                              ]           │  │
│  │                                                                │  │
│  │                      [CREATE ACCOUNT]                          │  │
│  │                                                                │  │
│  │  Already have an account? [Sign In]                           │  │
│  │                                                                │  │
│  │  Prefer to use Clio? [Sign in with Clio]                      │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 3. Consultant Registration Form

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                          SMARTER FIRMS                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │                CONSULTANT REGISTRATION                         │  │
│  │                                                                │  │
│  │              Email: [                              ]           │  │
│  │                                                                │  │
│  │           Password: [                              ]           │  │
│  │                                                                │  │
│  │  Confirm Password: [                              ]           │  │
│  │                                                                │  │
│  │         First Name: [                              ]           │  │
│  │                                                                │  │
│  │          Last Name: [                              ]           │  │
│  │                                                                │  │
│  │       Organization: [                              ]           │  │
│  │                                                                │  │
│  │         Specialty: [                              ]           │  │
│  │                                                                │  │
│  │      Referral Code: [                              ] (Optional)│  │
│  │                                                                │  │
│  │                [CREATE CONSULTANT ACCOUNT]                     │  │
│  │                                                                │  │
│  │  Already have an account? [Sign In]                           │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 4. Clio Authorization Screen (Clio-hosted)

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                             CLIO                                     │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │                  Authorize Smarter Firms                       │  │
│  │                                                                │  │
│  │  Smarter Firms is requesting access to your Clio account:      │  │
│  │                                                                │  │
│  │  Access includes:                                              │  │
│  │   • Read your user profile                                     │  │
│  │   • Access your matters                                        │  │
│  │   • Access your clients                                        │  │
│  │   • View your billing data                                     │  │
│  │   • View your firm data                                        │  │
│  │                                                                │  │
│  │  By authorizing, you agree to Smarter Firms' Terms of Service  │  │
│  │  and Privacy Policy.                                           │  │
│  │                                                                │  │
│  │         [AUTHORIZE]               [CANCEL]                     │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 5. Account Linking Page

```
┌──────────────────────────────────────────────────────────────────────┐
│ SMARTER FIRMS                                         [User Menu ▼]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ACCOUNT SETTINGS                                                    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ PROFILE                                                        │  │
│  │                                                                │  │
│  │ Email: user@example.com                                        │  │
│  │ Name: John Smith                                               │  │
│  │ Firm: Smith Law                                                │  │
│  │                                                                │  │
│  │ [Edit Profile]                                                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ CONNECTED ACCOUNTS                                             │  │
│  │                                                                │  │
│  │ Clio: Not Connected                                            │  │
│  │                                                                │  │
│  │ [Connect Clio Account]                                         │  │
│  │                                                                │  │
│  │ Connecting your Clio account will allow automatic data         │  │
│  │ synchronization and enhanced features.                         │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ SECURITY                                                       │  │
│  │                                                                │  │
│  │ Password: ********                        [Change Password]    │  │
│  │                                                                │  │
│  │ Two-Factor Authentication: Disabled       [Enable 2FA]         │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Technical Specifications

### 1. Authentication Flow Diagrams

#### Clio SSO Flow

```
┌─────────┐          ┌────────────┐          ┌─────────┐          ┌────────┐
│  User   │          │ Smarter    │          │  Clio   │          │ Clio   │
│ Browser │          │ Firms API  │          │  Auth   │          │  API   │
└────┬────┘          └─────┬──────┘          └────┬────┘          └────┬───┘
     │      Visit          │                      │                    │
     │─────────────────────>                      │                    │
     │                     │                      │                    │
     │  Login Options      │                      │                    │
     <─────────────────────│                      │                    │
     │                     │                      │                    │
     │  Click "Sign in     │                      │                    │
     │  with Clio"         │                      │                    │
     │─────────────────────>                      │                    │
     │                     │                      │                    │
     │                     │  Redirect to Clio    │                    │
     │<─────────────────────────────────────────────>                  │
     │                     │                      │                    │
     │  Authenticate       │                      │                    │
     │  with Clio          │                      │                    │
     │─────────────────────────────────────────────>                  │
     │                     │                      │                    │
     │                     │                      │  User Info         │
     │                     │                      │  Request           │
     │                     │                      │───────────────────>│
     │                     │                      │                    │
     │                     │                      │  User Info         │
     │                     │                      │  Response          │
     │                     │                      <───────────────────│
     │                     │                      │                    │
     │  Redirect with      │                      │                    │
     │  Authorization Code │                      │                    │
     <─────────────────────────────────────────────│                    │
     │                     │                      │                    │
     │  Send Code          │                      │                    │
     │─────────────────────>                      │                    │
     │                     │                      │                    │
     │                     │  Exchange Code       │                    │
     │                     │  for Tokens          │                    │
     │                     │─────────────────────>│                    │
     │                     │                      │                    │
     │                     │  Access & Refresh    │                    │
     │                     │  Tokens              │                    │
     │                     <─────────────────────│                    │
     │                     │                      │                    │
     │  Session Token      │                      │                    │
     <─────────────────────│                      │                    │
     │                     │                      │                    │
```

### 2. Data Model Extensions

```
User {
  id: UUID
  email: String
  name: String
  type: Enum [LAW_FIRM_USER, CONSULTANT]
  authMethod: Enum [CLIO_SSO, LOCAL]
  passwordHash: String (null if CLIO_SSO)
  hasClioConnection: Boolean
  clioUserId: String (optional)
  clioRefreshToken: String (encrypted, optional)
  clioTokenExpiresAt: DateTime (optional)
  emailVerified: Boolean
  createdAt: DateTime
  updatedAt: DateTime
}

AuthenticationLog {
  id: UUID
  userId: UUID (foreign key)
  authMethod: Enum [CLIO_SSO, LOCAL]
  ipAddress: String
  userAgent: String
  success: Boolean
  failureReason: String (optional)
  timestamp: DateTime
}

TwoFactorAuth {
  id: UUID
  userId: UUID (foreign key)
  method: Enum [APP, SMS, EMAIL]
  secret: String (encrypted)
  enabled: Boolean
  backupCodes: String[] (encrypted)
  lastUsed: DateTime
}
```

### 3. API Endpoints

**Authentication**
```
POST   /api/auth/clio/authorize         // Initiate Clio OAuth flow
GET    /api/auth/clio/callback          // Handle Clio OAuth callback
POST   /api/auth/login                  // Traditional email/password login
POST   /api/auth/register               // Traditional registration
POST   /api/auth/logout                 // Logout (all types)
POST   /api/auth/refresh-token          // Refresh JWT token
```

**Account Management**
```
GET    /api/auth/me                     // Get current user profile
PUT    /api/auth/me                     // Update user profile
POST   /api/auth/change-password        // Change password
POST   /api/auth/link-clio              // Link existing account to Clio
DELETE /api/auth/link-clio              // Unlink Clio account
```

**Two-Factor Authentication**
```
POST   /api/auth/2fa/enable             // Enable 2FA
POST   /api/auth/2fa/verify             // Verify 2FA setup
POST   /api/auth/2fa/disable            // Disable 2FA
POST   /api/auth/2fa/backup-codes       // Generate backup codes
```

### 4. Security Considerations

1. **Token Security**:
   - JWT with appropriate expiration (15 minutes)
   - Secure, HTTP-only cookies for refresh tokens
   - CSRF protection for token refresh

2. **Clio Token Storage**:
   - Refresh tokens must be encrypted at rest
   - Access tokens never stored, only used in-memory
   - Regular refresh token rotation

3. **Password Security**:
   - Strong password policies (min length, complexity)
   - Argon2id for password hashing
   - Rate limiting on login attempts
   - Account lockout after multiple failures

4. **Two-Factor Authentication**:
   - TOTP (Time-based One-Time Password) support
   - SMS fallback option
   - Backup codes for account recovery
   - Remember trusted devices option

### 5. Implementation Requirements

1. **Auth Service**:
   - Implement OpenID Connect client for Clio
   - Create JWT token issuance and validation
   - Build user registration and login flows
   - Implement password reset functionality

2. **API Gateway**:
   - Add authentication middleware
   - Implement JWT validation
   - Create role-based access control
   - Handle token refresh logic

3. **UI Service**:
   - Create login and registration components
   - Build account management interface
   - Implement 2FA setup wizard
   - Design password reset flow

4. **Infrastructure**:
   - Set up secure key management
   - Configure HTTPS and proper TLS
   - Implement proper CORS policies
   - Set up IP-based rate limiting