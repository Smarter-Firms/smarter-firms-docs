# Consultant Experience

This document outlines the design and technical specifications for the consultant experience within the Smarter Firms platform.

## Overview

Consultant accounts allow third-party advisors to access and analyze multiple law firms' data through the Smarter Firms platform. These accounts have special requirements and interfaces to manage multiple firm relationships.

## User Journey

### Registration & Onboarding

1. **Registration**:
   - Consultant selects "Consultant Registration" from login page
   - Completes form with personal/organization details
   - Verifies email
   - Sets up required 2FA
   - Creates profile including organization, specialty, bio

2. **Firm Association**:
   - Can be invited by a firm (receive email invitation)
   - Can enter referral code during registration
   - Can request access to a firm (requires firm approval)

3. **Orientation**:
   - Receives tutorial on navigating between firms
   - Introduced to consultant-specific features
   - Completes profile visible to associated firms

## Interface Design

### 1. Firm Selector Dashboard

```
┌──────────────────────────────────────────────────────────────────────┐
│ SMARTER FIRMS                                         [User Menu ▼]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CONSULTANT DASHBOARD                                                │
│                                                                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐         │
│  │ RECENT FIRMS   │  │ FIRM DIRECTORY │  │ METRICS        │         │
│  │                │  │                │  │                │         │
│  │ * Smith Law    │  │ SEARCH:  [   ] │  │ Total Firms: 12│         │
│  │ * Johnson LLC  │  │                │  │ Active: 10     │         │
│  │ * Davis Group  │  │ • Abbott Law   │  │ New This Month:│         │
│  │                │  │ • Baker & Co   │  │ 2              │         │
│  │ VIEW ALL       │  │ • Carter Legal │  │                │         │
│  └────────────────┘  └────────────────┘  └────────────────┘         │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ FIRM ACTIVITY FEED                                              │ │
│  │                                                                 │ │
│  │ • Smith Law - New matter created (23 min ago)                   │ │
│  │ • Johnson LLC - Monthly report ready (2 hours ago)              │ │
│  │ • Davis Group - Revenue goal achieved (1 day ago)               │ │
│  │                                                                 │ │
│  │                                       VIEW ALL NOTIFICATIONS    │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 2. Firm View Switcher

```
┌──────────────────────────────────────────────────────────────────────┐
│ SMARTER FIRMS                                         [User Menu ▼]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  VIEWING: SMITH LAW FIRM                   [CHANGE FIRM ▼]           │
│                                                                      │
│  [Overview] [Performance] [Clients] [Matters] [Financial] [Reports]  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │               [FIRM-SPECIFIC DASHBOARD CONTENT]                │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│               [CONSULTANT'S NOTES ABOUT THIS FIRM]                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Private notes visible only to consultant                        │  │
│  │ Last review date: March 15, 2023                               │  │
│  │                                                                │  │
│  │ Goals:                                                         │  │
│  │ - Increase matter efficiency                                   │  │
│  │ - Improve client intake process                                │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 3. Multi-Firm Analytics View

```
┌──────────────────────────────────────────────────────────────────────┐
│ SMARTER FIRMS                                         [User Menu ▼]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  MULTI-FIRM ANALYTICS                           [Export] [Share]     │
│                                                                      │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ PERFORMANCE COMPARISON  │  │ REVENUE BENCHMARKING    │           │
│  │                         │  │                         │           │
│  │ [Bar chart comparing    │  │ [Line chart showing     │           │
│  │  key metrics across     │  │  revenue trends across  │           │
│  │  selected firms]        │  │  all firms over time]   │           │
│  │                         │  │                         │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                      │
│  FIRM SELECTION                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ ☑ Smith Law   ☑ Johnson LLC   ☑ Davis Group                    │  │
│  │ ☐ Abbott Law  ☐ Baker & Co    ☐ Carter Legal                   │  │
│  │                                                                │  │
│  │                              [APPLY FILTERS] [SAVE SELECTION]  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ KEY INSIGHTS                                                   │  │
│  │                                                                │  │
│  │ • Smith Law has 25% higher revenue per attorney                │  │
│  │ • Davis Group's matter efficiency is 15% below average         │  │
│  │ • Johnson LLC shows consistent month-over-month growth         │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 4. Firm Management Interface

```
┌──────────────────────────────────────────────────────────────────────┐
│ SMARTER FIRMS                                         [User Menu ▼]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  MANAGE FIRM RELATIONSHIPS                    [+ ADD NEW FIRM]       │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ FIRM                ACCESS LEVEL         STATUS      ACTIONS   │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │ Smith Law          Full Access          Active      [⚙ Edit]   │  │
│  │ Johnson LLC        Limited Access       Active      [⚙ Edit]   │  │
│  │ Davis Group        Read Only            Active      [⚙ Edit]   │  │
│  │ Abbott Law         Full Access          Pending     [Cancel]   │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ FIRM INVITATIONS                                               │  │
│  │                                                                │  │
│  │ You have sent 2 pending invitations:                           │  │
│  │ • Baker & Co (sent 2 days ago)                    [RESEND]     │  │
│  │ • Carter Legal (sent 1 week ago)                  [RESEND]     │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ REFERRAL CODES                                                 │  │
│  │                                                                │  │
│  │ Your personal referral code: HTM2023                           │  │
│  │ Firms using this code: 5                                       │  │
│  │                                                                │  │
│  │ [GENERATE NEW CODE] [COPY CODE] [VIEW USAGE STATS]             │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Technical Specifications

### 1. Data Model Extensions

```
User {
  id: UUID
  email: String
  name: String
  type: Enum [LAW_FIRM_USER, CONSULTANT]
  organization: String (optional)
  bio: String (optional)
  authMethod: Enum [CLIO_SSO, LOCAL]
  hasClioConnection: Boolean
  consultantProfile: ConsultantProfile (if type = CONSULTANT)
}

ConsultantProfile {
  id: UUID
  userId: UUID (foreign key)
  specialty: String
  referralCode: String
  profileImage: String (URL)
  publicProfile: Boolean
}

FirmConsultantAssociation {
  id: UUID
  firmId: UUID (foreign key)
  consultantId: UUID (foreign key)
  accessLevel: Enum [FULL_ACCESS, LIMITED_ACCESS, READ_ONLY]
  status: Enum [ACTIVE, PENDING, REVOKED]
  createdAt: DateTime
  invitedBy: UUID (foreign key to User)
  referralCode: String (optional)
  lastAccessed: DateTime
  notes: String (private notes visible only to consultant)
}

ConsultantPermission {
  id: UUID
  associationId: UUID (foreign key to FirmConsultantAssociation)
  resource: String (e.g., "matters", "clients", "financial")
  action: String (e.g., "view", "export")
  allowed: Boolean
}
```

### 2. API Endpoints

**Consultant Management**
```
POST   /api/consultants                // Register as consultant
GET    /api/consultants/profile        // Get consultant profile
PUT    /api/consultants/profile        // Update consultant profile
GET    /api/consultants/firms          // List associated firms
POST   /api/consultants/referral-codes // Generate new referral code
GET    /api/consultants/referral-codes // Get referral code stats
```

**Firm Relationships**
```
POST   /api/consultant-firms           // Create association (send invitation)
GET    /api/consultant-firms/:firmId   // Get specific firm association
PUT    /api/consultant-firms/:firmId   // Update firm relationship
DELETE /api/consultant-firms/:firmId   // Remove firm association
GET    /api/consultant-firms/:firmId/permissions // Get permissions
PUT    /api/consultant-firms/:firmId/permissions // Update permissions
```

**Multi-Firm Analytics**
```
GET    /api/analytics/multi-firm       // Get analytics across firms
POST   /api/analytics/multi-firm/export // Export multi-firm report
GET    /api/analytics/benchmarks       // Get benchmark data
```

### 3. Security Considerations

1. **Data Isolation**:
   - Each firm's data must be strictly isolated
   - Consultant access should be clearly logged and auditable
   - Firms should be able to revoke consultant access at any time

2. **Permission Granularity**:
   - Granular permissions for consultants (view, export, etc.)
   - Ability to limit access to specific data categories
   - Time-limited access options

3. **Transparency**:
   - Firms should be notified when consultants access their data
   - Detailed access logs available to firm administrators
   - Clear opt-in process for sharing data with consultants

### 4. Implementation Requirements

1. **Auth Service**:
   - Add consultant-specific authentication flow
   - Implement firm relationship management
   - Create permission verification middleware

2. **Data Service**:
   - Implement multi-firm query capabilities
   - Create data aggregation endpoints
   - Build benchmarking functionality

3. **UI Service**:
   - Create consultant-specific components
   - Implement firm selector and switcher
   - Build multi-firm analytics visualizations

4. **API Gateway**:
   - Extend routing for consultant-specific endpoints
   - Implement additional rate limiting for consultant accounts
   - Add consultant-specific authentication middleware 