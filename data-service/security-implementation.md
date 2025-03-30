# Data Security Implementation Guide

## Overview

This document outlines the security implementation for the Data Service in the Smarter Firms platform, focusing on data isolation, access control, encryption, and audit logging.

## 1. Data Isolation Architecture

### PostgreSQL Row-Level Security

Row-Level Security (RLS) is implemented at the database level to enforce multi-tenant data isolation:

```sql
-- Enable RLS on all tables
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ConsultantProfile" ENABLE ROW LEVEL SECURITY;
-- ...other tables

-- Create tenant isolation policies
CREATE POLICY user_tenant_isolation ON "User"
    USING ("tenantId" = current_setting('app.tenant_id', TRUE)::text);
```

These policies ensure that queries only return rows matching the current tenant context, regardless of where the query is issued from.

### Tenant Context Management

The `TenantPrismaClient` uses middleware to automatically inject tenant filters:

```typescript
middleware: async (params, next) => {
  // Get current tenant ID
  const tenantId = this.getCurrentTenantId();
  
  // Apply tenant filtering to all operations
  if (params.action === 'findUnique' || params.action === 'findFirst') {
    params.args.where = {
      ...params.args.where,
      tenantId,
    };
  }
  // ...other operations
}
```

This ensures that even if tenant filtering is forgotten in application code, it's enforced at the data access layer.

## 2. Field-Level Encryption

Sensitive data is encrypted using authenticated encryption (AES-GCM):

### Encryption Implementation

- Encryption keys are stored in AWS KMS, separate from the database
- Encryption uses AES-256-GCM with authenticated tags
- Each encrypted value includes the IV and auth tag to ensure integrity

Sensitive fields encrypted in our models:

| Model | Encrypted Fields |
|-------|------------------|
| FirmConsultantAssociation | `notes` |
| User | No fields currently encrypted |
| ConsultantProfile | No fields currently encrypted |

### Key Management

- Production keys are stored in AWS KMS
- Key rotation is handled through a separate process
- Each environment (dev, staging, prod) uses different keys

## 3. Access Control Implementation

### Repository-Level Access Control

All repositories include mandatory tenant verification:

```typescript
async findById(id: string, tenantId: string): Promise<Entity | null> {
  // Tenant ID is a required parameter for all operations
  return this.cache.getOrSet(
    {
      prefix: 'entity',
      params: { id },
      tenantId  // Required tenant context
    },
    async () => {
      const result = await this.prisma.entity.findUnique({
        where: { id },
        // ...
      });
      // ...
    }
  );
}
```

### Permission Verification

Granular permissions are checked through the `PermissionRepository`:

```typescript
// Check if a permission exists and is allowed
async isAllowed(associationId: string, resource: string, action: string): Promise<boolean> {
  const permission = await this.findSpecificPermission(associationId, resource, action);
  return !!permission?.allowed;
}
```

## 4. Audit Logging

All authentication and access events are logged in the `AuthLog` table:

```typescript
async logSuccess(userId: string, eventType: AuthEventType, ipAddress: string, userAgent: string, metadata?: Record<string, any>): Promise<AuthLog>
```

### Critical Events Logged

- Authentication attempts (success/failure)
- Permission changes
- Firm access grants/revocations
- Password changes and resets
- API token generation

### Log Retention

- Authentication logs are retained for 90 days in the primary database
- Archived logs are moved to cold storage after 90 days
- Logs are never permanently deleted

## 5. Transaction Management

### Idempotent Operations

Critical operations use idempotent execution to prevent duplicate processing:

```typescript
async executeIdempotent<T>(operationId: string, fn: () => Promise<T>, maxRetries: number = 3): Promise<T>
```

The `OperationLog` table records all critical operations:

```sql
CREATE TABLE "OperationLog" (
  id TEXT PRIMARY KEY,
  status TEXT, -- IN_PROGRESS, COMPLETED, FAILED
  retryCount INTEGER,
  startedAt TIMESTAMP,
  completedAt TIMESTAMP,
  errorMessage TEXT,
  result JSONB
);
```

### Compensating Transactions

For distributed operations, compensating transactions reverse partial changes on failure:

```typescript
async withCompensation<T>(
  mainFn: () => Promise<T>,
  compensatingFn: (error: Error) => Promise<void>
): Promise<T>
```

## 6. Monitoring and Alerting

### Security Monitoring

- Failed login attempts trigger alerts after threshold (5 failures in 30 minutes)
- Unusual access patterns are detected through log analysis
- Tenant context violations are logged and alerted

### Performance Monitoring

- Slow queries (>500ms) are logged and alerted
- Connection pool saturation is monitored
- Cache hit rates are tracked for optimization

## 7. Development Guidelines

### Security Best Practices

1. **Always use tenant context**:
   ```typescript
   withTenant(tenantId, async () => {
     // All operations in this block will be tenant-scoped
   });
   ```

2. **Use transactions for multi-step operations**:
   ```typescript
   transactionManager.withTransaction(async (tx) => {
     // All operations in this block are in a single transaction
   });
   ```

3. **Encrypt sensitive fields**:
   ```typescript
   const encryptedData = encryptionUtil.encryptFields(data, FIELDS_TO_ENCRYPT);
   ```

4. **Verify permissions**:
   ```typescript
   if (!(await permissionRepository.isAllowed(associationId, 'matters', 'view'))) {
     throw new Error('Permission denied');
   }
   ```

5. **Use idempotent operations for distributed processes**:
   ```typescript
   await transactionManager.executeIdempotent(operationId, async () => {
     // Operation will only be executed once, even if called multiple times
   });
   ``` 