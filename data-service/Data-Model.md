# Data Model

This document outlines the core data models for the Smarter Firms application. These models represent the database schema that will be implemented via Prisma.

## Core Entities

### User

Represents a user of the Smarter Firms application.

```prisma
model User {
  id                String    @id @default(uuid())
  email             String    @unique
  password          String?   // Hashed password (null for OAuth-only users)
  firstName         String
  lastName          String
  role              UserRole  @default(USER)
  accessLevel       AccessLevel @default(USER_ONLY)
  isActive          Boolean   @default(true)
  lastLogin         DateTime?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  firm              Firm?     @relation(fields: [firmId], references: [id])
  firmId            String?
  clioConnection    ClioConnection?
  subscription      Subscription?
  accessibleUsers   UserAccess[] @relation("accessGranter")
  accessGrantedBy   UserAccess[] @relation("accessReceiver")
}

enum UserRole {
  SUPER_ADMIN
  ADMIN
  USER
  CONSULTANT
}

enum AccessLevel {
  WHOLE_FIRM
  SPECIFIC_USERS
  USER_ONLY
}

model UserAccess {
  id            String  @id @default(uuid())
  granter       User    @relation("accessGranter", fields: [granterId], references: [id])
  granterId     String
  receiver      User    @relation("accessReceiver", fields: [receiverId], references: [id])
  receiverId    String
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  @@unique([granterId, receiverId])
}
```

### Firm

Represents a law firm in the system.

```prisma
model Firm {
  id              String    @id @default(uuid())
  name            String
  clioFirmId      String?   @unique
  planType        PlanType  @default(INDIVIDUAL)
  isActive        Boolean   @default(true)
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
  users           User[]
  subscription    Subscription?
  practiceAreas   PracticeArea[]
}

enum PlanType {
  INDIVIDUAL
  FIRM
}

model PracticeArea {
  id          String    @id @default(uuid())
  name        String
  firm        Firm      @relation(fields: [firmId], references: [id])
  firmId      String
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  users       User[]
}
```

### Subscription

Manages billing and subscription information.

```prisma
model Subscription {
  id                String    @id @default(uuid())
  stripeCustomerId  String?   @unique
  stripeSubscriptionId String? @unique
  status            SubscriptionStatus @default(ACTIVE)
  planType          PlanType  @default(INDIVIDUAL)
  priceId           String    // Stripe price ID
  currentPeriodStart DateTime
  currentPeriodEnd  DateTime
  cancelAtPeriodEnd Boolean   @default(false)
  quantity          Int       @default(1)
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  user              User?     @relation(fields: [userId], references: [id])
  userId            String?   @unique
  firm              Firm?     @relation(fields: [firmId], references: [id])
  firmId            String?   @unique
  invoices          Invoice[]
}

enum SubscriptionStatus {
  ACTIVE
  PAST_DUE
  UNPAID
  CANCELED
  INCOMPLETE
  INCOMPLETE_EXPIRED
  TRIALING
}

model Invoice {
  id                String    @id @default(uuid())
  stripeInvoiceId   String    @unique
  amount            Int       // Amount in cents
  currency          String    @default("usd")
  status            InvoiceStatus
  invoiceDate       DateTime
  dueDate           DateTime?
  paidDate          DateTime?
  subscription      Subscription @relation(fields: [subscriptionId], references: [id])
  subscriptionId    String
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

enum InvoiceStatus {
  DRAFT
  OPEN
  PAID
  UNCOLLECTIBLE
  VOID
}
```

### Clio Connection

Manages the connection to Clio API.

```prisma
model ClioConnection {
  id                String    @id @default(uuid())
  accessToken       String
  refreshToken      String
  tokenExpiresAt    DateTime
  clioUserId        BigInt    
  clioUserName      String
  lastSyncAt        DateTime?
  isActive          Boolean   @default(true)
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  user              User      @relation(fields: [userId], references: [id])
  userId            String    @unique
  syncStatuses      ClioSyncStatus[]
}

model ClioSyncStatus {
  id                String    @id @default(uuid())
  entityType        ClioEntityType
  lastSyncAt        DateTime?
  status            SyncStatus @default(PENDING)
  recordCount       Int       @default(0)
  errorMessage      String?
  clioConnection    ClioConnection @relation(fields: [clioConnectionId], references: [id])
  clioConnectionId  String
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

enum ClioEntityType {
  WHO_AM_I
  ACTIVITIES
  ACTIVITY_DESCRIPTIONS
  ALLOCATIONS
  BANK_ACCOUNTS
  BANK_TRANSACTIONS
  BILL_LINE_ITEMS
  BILLS
  CONTACTS
  CREDIT_MEMOS
  CURRENCIES
  EXPENSE_CATEGORIES
  GROUPS
  INTEREST_CHARGES
  MATTER_STAGES
  MATTERS
  PAYMENTS
  PRACTICE_AREAS
  TRUST_LINE_ITEMS
  USERS
}

enum SyncStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  FAILED
}
```

### Clio Data Models

These models store the data synced from Clio. All Clio entity IDs must be stored as BigInt.

```prisma
model ClioUser {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  email             String
  enabled           Boolean
  isAccountOwner    Boolean
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  customFields      Json?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  activities        ClioActivity[]
}

model ClioWhoAmI {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  email             String
  firm              String
  firmId            BigInt
  timezone          String
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioMatter {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  displayNumber     String?
  description       String?
  status            String?
  openDate          DateTime?
  closeDate         DateTime?
  pendingDate       DateTime?
  practiceAreaId    BigInt?
  locationId        BigInt?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  customFields      Json?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  activities        ClioActivity[]
  billLineItems     ClioBillLineItem[]
}

model ClioMatterStage {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  description       String?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioActivity {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  type              String
  date              DateTime
  quantity          Float
  price             Float
  total             Float
  note              String?
  isBillable        Boolean
  isContingent      Boolean   @default(false)
  onBill            Boolean
  isBilled          Boolean
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  customFields      Json?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  matter            ClioMatter? @relation(fields: [matterClioId], references: [clioId])
  matterClioId      BigInt?
  user              ClioUser? @relation(fields: [userClioId], references: [clioId])
  userClioId        BigInt?
}

model ClioActivityDescription {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  description       String?
  category          String?
  type              String?
  isActive          Boolean
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioContact {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  type              String
  prefix            String?
  title             String?
  email             String?
  phone             String?
  isClient          Boolean
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  customFields      Json?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioAllocation {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  type              String
  amount            Float
  billId            BigInt?
  lineItemId        BigInt?
  paymentId         BigInt?
  creditId          BigInt?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioBankAccount {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  accountType       String
  accountNumber     String?
  description       String?
  isOperating       Boolean
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  transactions      ClioBankTransaction[]
}

model ClioBankTransaction {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  transactionType   String
  transactionDate   DateTime
  description       String?
  amount            Float
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  bankAccount       ClioBankAccount @relation(fields: [bankAccountClioId], references: [clioId])
  bankAccountClioId BigInt
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioBill {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  number            String?
  subject           String?
  issueDate         DateTime
  dueDate           DateTime?
  sentDate          DateTime?
  status            String
  balance           Float
  clientId          BigInt?
  clientName        String?
  type              String
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  lineItems         ClioBillLineItem[]
}

model ClioBillLineItem {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  type              String
  description       String?
  quantity          Float
  price             Float
  total             Float
  date              DateTime?
  billId            BigInt
  bill              ClioBill  @relation(fields: [billId], references: [clioId])
  matterId          BigInt?
  matter            ClioMatter? @relation(fields: [matterId], references: [clioId])
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioCreditMemo {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  clientId          BigInt?
  clientName        String?
  number            String?
  issueDate         DateTime
  total             Float
  remainingCredit   Float
  status            String
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioCurrency {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  code              String
  name              String
  symbol            String
  isDefault         Boolean
  exchangeRate      Float
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioExpenseCategory {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  description       String?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioGroup {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  description       String?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioInterestCharge {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  billId            BigInt
  amount            Float
  date              DateTime
  description       String?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioPayment {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  clientId          BigInt?
  clientName        String?
  type              String
  method            String?
  reference         String?
  date              DateTime
  amount            Float
  appliedAmount     Float
  status            String
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioPracticeArea {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  name              String
  description       String?
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}

model ClioTrustLineItem {
  id                String    @id @default(uuid())
  clioId            BigInt    @unique
  type              String
  description       String?
  matterId          BigInt?
  contactId         BigInt?
  contactName       String?
  date              DateTime
  amount            Float
  clioCreatedAt     DateTime
  clioUpdatedAt     DateTime
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}
```

### Dashboards and Reports

```prisma
model Dashboard {
  id                String    @id @default(uuid())
  name              String
  description       String?
  isDefault         Boolean   @default(false)
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  owner             User      @relation(fields: [ownerId], references: [id])
  ownerId           String
  widgets           Widget[]
}

model Widget {
  id                String    @id @default(uuid())
  name              String
  type              WidgetType
  config            Json
  position          Json      // {x, y, width, height}
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  dashboard         Dashboard @relation(fields: [dashboardId], references: [id])
  dashboardId       String
}

enum WidgetType {
  BAR_CHART
  LINE_CHART
  PIE_CHART
  TABLE
  KPI
  CUSTOM
}

model SavedFilter {
  id                String    @id @default(uuid())
  name              String
  entityType        String
  conditions        Json
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  owner             User      @relation(fields: [ownerId], references: [id])
  ownerId           String
}
```

## Relationships

### User Relationships
- A User can belong to one Firm (nullable for individual users)
- A User can have one ClioConnection
- A User can have one Subscription (for individual plans)
- Users can grant access to other Users via UserAccess

### Firm Relationships
- A Firm can have many Users
- A Firm can have one Subscription (for firm plans)
- A Firm can have many PracticeAreas

### Clio Data Relationships
- ClioMatter can have many ClioActivities
- ClioMatter can have many ClioTasks
- ClioUser can have many ClioActivities (as creator)
- ClioUser can have many ClioTasks (as assignee)

### Dashboard Relationships
- A User can have many Dashboards
- A Dashboard can have many Widgets
- A User can have many SavedFilters

## Data Flow

1. User authenticates and connects their Clio account
2. Clio API data is fetched and stored in the respective Clio data models
3. User creates and configures dashboards and reports using the stored data
4. Reports and visualizations query the Clio data models for insights

## Indexing Strategy

1. Primary keys: All `id` fields
2. Foreign keys: All fields ending with `Id`
3. Unique constraints: `email`, `clioFirmId`, `stripeCustomerId`, `clioId`
4. Additional indexes:
   - `ClioActivity.date`
   - `ClioTask.dueAt`
   - `ClioMatter.status`
   - Composite indexes for frequently queried combinations 