# Clio Entities

This document provides detailed information about the 20 Clio entities that our system integrates with. All these entities have equal importance for our integration, and their data will be synchronized from Clio to our database.

## Important Implementation Note

**All Clio entity IDs must be stored as BigInt** in our database and handled accordingly in our code. This is critical for proper integration.

## Entity List and Descriptions

### 1. WhoAmI

Provides information about the currently authenticated user and their firm.

**Key Fields:**
- `id` (BigInt): The user's Clio ID
- `email`: The user's email address
- `name`: The user's full name
- `firm`: The name of the firm
- `firmId` (BigInt): The Clio ID for the firm
- `timezone`: The user's timezone

**API Endpoint:** `/api/v4/users/who_am_i`

**Usage:** Identifies the authenticated user and establishes the firm context for other API calls.

### 2. Activities

Represents time entries, expenses, and other billable activities in Clio.

**Key Fields:**
- `id` (BigInt): The activity's Clio ID
- `type`: The type of activity (time, expense, etc.)
- `date`: When the activity occurred
- `quantity`: The amount of time or quantity
- `price`: The price per unit
- `total`: The total amount
- `note`: Additional details about the activity
- `isBillable`: Whether the activity can be billed
- `isBilled`: Whether the activity has been billed

**API Endpoint:** `/api/v4/activities`

**Usage:** Tracks billable time and expenses for reporting and invoicing.

### 3. Activity Descriptions

Provides standardized descriptions for common activities.

**Key Fields:**
- `id` (BigInt): The activity description's Clio ID
- `name`: The name of the activity type
- `description`: Detailed description
- `category`: The category of activity
- `type`: The type of activity description
- `isActive`: Whether this activity description is active

**API Endpoint:** `/api/v4/activity_descriptions`

**Usage:** Used to categorize and standardize activities.

### 4. Allocations

Represents how payments and credits are allocated to bills.

**Key Fields:**
- `id` (BigInt): The allocation's Clio ID
- `type`: The type of allocation
- `amount`: The amount allocated
- `billId` (BigInt): The associated bill ID
- `lineItemId` (BigInt): The associated line item ID
- `paymentId` (BigInt): The associated payment ID
- `creditId` (BigInt): The associated credit ID

**API Endpoint:** `/api/v4/allocations`

**Usage:** Tracks how payments are applied to bills for financial reporting.

### 5. Bank Accounts

Represents firm bank accounts registered in Clio.

**Key Fields:**
- `id` (BigInt): The bank account's Clio ID
- `name`: The name of the account
- `accountType`: The type of account (operating, trust, etc.)
- `accountNumber`: The account number (partial)
- `description`: Additional details
- `isOperating`: Whether this is an operating account

**API Endpoint:** `/api/v4/bank_accounts`

**Usage:** Used for financial reporting and transaction tracking.

### 6. Bank Transactions

Represents transactions in the firm's bank accounts.

**Key Fields:**
- `id` (BigInt): The transaction's Clio ID
- `transactionType`: The type of transaction
- `transactionDate`: When the transaction occurred
- `description`: Description of the transaction
- `amount`: The transaction amount
- `bankAccountId` (BigInt): The associated bank account

**API Endpoint:** `/api/v4/bank_transactions`

**Usage:** Tracking financial transactions for accounting.

### 7. Bill Line Items

Represents individual line items on bills.

**Key Fields:**
- `id` (BigInt): The line item's Clio ID
- `type`: The type of line item
- `description`: Description of the item
- `quantity`: The quantity billed
- `price`: The price per unit
- `total`: The total amount
- `date`: The date of service
- `billId` (BigInt): The associated bill
- `matterId` (BigInt): The associated matter

**API Endpoint:** `/api/v4/bill_line_items`

**Usage:** Detailed bill item tracking for financial analysis.

### 8. Bills

Represents invoices sent to clients.

**Key Fields:**
- `id` (BigInt): The bill's Clio ID
- `number`: The bill number
- `subject`: The subject line
- `issueDate`: When the bill was issued
- `dueDate`: When payment is due
- `sentDate`: When the bill was sent
- `status`: The current status
- `balance`: The remaining balance
- `clientId` (BigInt): The associated client
- `clientName`: The client's name

**API Endpoint:** `/api/v4/bills`

**Usage:** Tracking invoices and billing status.

### 9. Contacts

Represents clients and other contacts in Clio.

**Key Fields:**
- `id` (BigInt): The contact's Clio ID
- `name`: The contact's name
- `type`: The type of contact (person, company, etc.)
- `prefix`: Name prefix (Mr., Ms., etc.)
- `title`: Job title
- `email`: Email address
- `phone`: Phone number
- `isClient`: Whether this contact is a client

**API Endpoint:** `/api/v4/contacts`

**Usage:** Client and contact management for matter association.

### 10. Credit Memos

Represents credits issued to clients.

**Key Fields:**
- `id` (BigInt): The credit memo's Clio ID
- `clientId` (BigInt): The associated client
- `clientName`: The client's name
- `number`: The credit memo number
- `issueDate`: When the credit was issued
- `total`: The total credit amount
- `remainingCredit`: The unused credit amount
- `status`: The current status

**API Endpoint:** `/api/v4/credit_memos`

**Usage:** Tracking credits for financial reporting.

### 11. Currencies

Represents currencies used in the system.

**Key Fields:**
- `id` (BigInt): The currency's Clio ID
- `code`: The currency code (USD, EUR, etc.)
- `name`: The currency name
- `symbol`: The currency symbol
- `isDefault`: Whether this is the default currency
- `exchangeRate`: The exchange rate to the default currency

**API Endpoint:** `/api/v4/currencies`

**Usage:** Multi-currency support for firms with international clients.

### 12. Expense Categories

Represents categories for classifying expenses.

**Key Fields:**
- `id` (BigInt): The category's Clio ID
- `name`: The category name
- `description`: Detailed description

**API Endpoint:** `/api/v4/expense_categories`

**Usage:** Categorizing expenses for financial reporting.

### 13. Groups

Represents groups of users within a firm.

**Key Fields:**
- `id` (BigInt): The group's Clio ID
- `name`: The group name
- `description`: Detailed description

**API Endpoint:** `/api/v4/groups`

**Usage:** User organization and permission management.

### 14. Interest Charges

Represents interest charges applied to overdue bills.

**Key Fields:**
- `id` (BigInt): The interest charge's Clio ID
- `billId` (BigInt): The associated bill
- `amount`: The interest amount
- `date`: When the interest was charged
- `description`: Detailed description

**API Endpoint:** `/api/v4/interest_charges`

**Usage:** Tracking interest for financial reporting.

### 15. Matter Stages

Represents stages in a matter's lifecycle.

**Key Fields:**
- `id` (BigInt): The stage's Clio ID
- `name`: The stage name
- `description`: Detailed description

**API Endpoint:** `/api/v4/matter_stages`

**Usage:** Tracking matter progress and workflow management.

### 16. Matters

Represents legal matters/cases in Clio.

**Key Fields:**
- `id` (BigInt): The matter's Clio ID
- `displayNumber`: The matter number
- `description`: Detailed description
- `status`: The current status
- `openDate`: When the matter was opened
- `closeDate`: When the matter was closed
- `pendingDate`: When the matter became pending
- `practiceAreaId` (BigInt): The associated practice area
- `locationId` (BigInt): The associated location

**API Endpoint:** `/api/v4/matters`

**Usage:** Core entity for case management and reporting.

### 17. Payments

Represents payments received from clients.

**Key Fields:**
- `id` (BigInt): The payment's Clio ID
- `clientId` (BigInt): The associated client
- `clientName`: The client's name
- `type`: The payment type
- `method`: The payment method
- `reference`: Reference number
- `date`: When the payment was received
- `amount`: The payment amount
- `appliedAmount`: The amount applied to bills
- `status`: The current status

**API Endpoint:** `/api/v4/payments`

**Usage:** Payment tracking for financial reporting.

### 18. Practice Areas

Represents legal practice areas within a firm.

**Key Fields:**
- `id` (BigInt): The practice area's Clio ID
- `name`: The practice area name
- `description`: Detailed description

**API Endpoint:** `/api/v4/practice_areas`

**Usage:** Categorizing matters by practice area for reporting.

### 19. Trust Line Items

Represents transactions in client trust accounts.

**Key Fields:**
- `id` (BigInt): The trust line item's Clio ID
- `type`: The type of transaction
- `description`: Detailed description
- `matterId` (BigInt): The associated matter
- `contactId` (BigInt): The associated contact
- `contactName`: The contact's name
- `date`: When the transaction occurred
- `amount`: The transaction amount

**API Endpoint:** `/api/v4/trust_line_items`

**Usage:** Trust accounting and compliance reporting.

### 20. Users

Represents users in the Clio system.

**Key Fields:**
- `id` (BigInt): The user's Clio ID
- `name`: The user's name
- `email`: The user's email address
- `enabled`: Whether the user is active
- `isAccountOwner`: Whether the user is the account owner

**API Endpoint:** `/api/v4/users`

**Usage:** User mapping and activity association.

## Relationship Diagram

The following diagram shows key relationships between Clio entities:

```
                    ┌──────────────┐
                    │              │
                    │   Matters    │
                    │              │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
  ┌────────▼─────┐ ┌───────▼────┐ ┌────────▼─────┐
  │              │ │            │ │              │
  │  Activities  │ │ Bill Line  │ │Trust Line    │
  │              │ │   Items    │ │   Items      │
  └──────────────┘ └────────────┘ └──────────────┘
           │               │               │
           │               │               │
  ┌────────▼─────┐ ┌───────▼────┐ ┌────────▼─────┐
  │              │ │            │ │              │
  │    Users     │ │   Bills    │ │   Contacts   │
  │              │ │            │ │              │
  └──────────────┘ └────────────┘ └──────────────┘
                          │
                          │
                  ┌───────▼────┐
                  │            │
                  │ Allocations│
                  │            │
                  └────────────┘
                          │
                  ┌───────┴────────┐
                  │                │
         ┌────────▼─────┐  ┌───────▼────┐
         │              │  │            │
         │  Payments    │  │  Credit    │
         │              │  │  Memos     │
         └──────────────┘  └────────────┘
```

## Synchronization Strategy

When implementing the Clio Integration service:

1. **Initial Sync**: Fetch all entities in priority order:
   - First: Users, Contacts, Matters
   - Second: Activities, Bills, Payments
   - Third: All other entities

2. **Incremental Sync**: Use `updated_since` parameter to fetch only changed records:
   - Use the most recent `clioUpdatedAt` value as the starting point
   - Process entities in batches to handle large data sets

3. **Webhook Events**: Register for Clio webhooks to get real-time updates:
   - React to create/update/delete events
   - Trigger targeted synchronization jobs for affected entities

4. **ID Handling**: Ensure all Clio IDs are stored as BigInt in the database to prevent overflow issues.

All 20 entities listed in this document must be fully implemented for the integration to function correctly. Each entity is equally important for our application's functionality. 