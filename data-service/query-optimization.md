# Query Optimization Guide

## Overview

This document outlines the query optimization strategies implemented in the Data Service for the Smarter Firms platform, focusing on performance, caching, connection management, and pagination.

## 1. Database Schema Optimization

### Strategic Indexing

Our database schema includes the following optimized indexes:

| Table | Index | Purpose |
|-------|-------|---------|
| User | `email`, `type`, `tenantId` | Fast user lookup and tenant filtering |
| ConsultantProfile | `referralCode`, `tenantId`, `userId_tenantId` | Efficient consultant querying |
| FirmConsultantAssociation | `firmId_status`, `consultantId_status`, `tenantId_firmId`, `tenantId_consultantId` | Optimized firm-consultant relationship queries |
| ConsultantPermission | `associationId`, `tenantId`, `tenantId_resource_action` | Fast permission checking |
| AuthLog | `userId_createdAt`, `eventType_createdAt`, `tenantId_createdAt`, `tenantId_userId_createdAt` | Efficient audit log querying |
| OperationLog | `status_tenantId`, `tenantId_startedAt` | Idempotent operation tracking |

### Composite Indexes

Composite indexes have been carefully designed based on common query patterns:

```sql
-- Fast tenant + firm-specific lookups
CREATE INDEX "idx_association_tenant_firm" ON "FirmConsultantAssociation"("tenantId", "firmId");

-- Efficient permission checking
CREATE INDEX "idx_permission_tenant_resource_action" ON "ConsultantPermission"("tenantId", "resource", "action");

-- Quick user activity logging
CREATE INDEX "idx_authlog_tenant_user_created" ON "AuthLog"("tenantId", "userId", "createdAt");
```

## 2. Caching Strategy

### Multi-level Caching

The `CacheManager` implements a tiered caching strategy:

```typescript
async getOrSet<T>(
  options: CacheKeyOptions,
  fn: () => Promise<T>,
  ttl?: number
): Promise<T>
```

Cache keys are tenant-specific and include serialized parameters:

```
${tenantId}:${prefix}:${serializedParams}
```

### Cache Invalidation Strategies

1. **Targeted Invalidation**: Only invalidate specific cache entries affected by changes
2. **Pattern-Based Invalidation**: Clear cache entries based on prefixes
3. **Tenant-Based Invalidation**: Clear all cache entries for a tenant when necessary

Example implementation:

```typescript
// Delete specific entry
this.cache.delete({
  prefix: 'firm-consultant',
  params: { id },
  tenantId
});

// Invalidate by prefix
this.cache.invalidateByPrefix('firm-consultants', tenantId);

// Invalidate all tenant data
this.cache.invalidateByTenant(tenantId);
```

### Cache TTL Configuration

| Data Type | TTL (seconds) | Rationale |
|-----------|--------------|-----------|
| User data | 300 (5 min) | Relatively static |
| Permissions | 180 (3 min) | May change frequently |
| Associations | 300 (5 min) | Moderate change frequency |
| Reference data | 1800 (30 min) | Rarely changes |

## 3. Pagination Implementation

### Cursor-Based Pagination

For large datasets, cursor-based pagination offers superior performance:

```typescript
static getCursorPagination(params: CursorPaginationParams) {
  const limit = Math.min(params.limit || 10, 100);
  const cursor = params.cursor ? this.decodeCursor(params.cursor) : null;
  
  return {
    take: limit,
    ...(cursor ? { 
      skip: 1, // Skip the cursor item
      cursor: { id: cursor.id }
    } : {}),
    orderBy
  };
}
```

Benefits:
- Consistent performance regardless of offset
- Works with continuously updating data
- Prevents duplicate results when data changes

### Offset-Based Pagination

For simpler use cases, traditional offset-based pagination is available:

```typescript
static getOffsetPagination(params: PaginationParams) {
  const page = Math.max(params.page || 1, 1);
  const limit = Math.min(params.limit || 10, 100);
  const skip = (page - 1) * limit;
  
  return {
    skip,
    take: limit,
    orderBy
  };
}
```

### Pagination Limits

- Maximum page size: 100 items
- Default page size: 10 items
- For larger datasets, cursor-based pagination is enforced

## 4. Connection Pool Management

### Connection Pool Configuration

The database connection pool is optimized for application needs:

```typescript
// Configure connection pool in Prisma
const connectionLimit = parseInt(process.env.DB_CONNECTION_LIMIT || '10', 10);
```

### Connection Pool Monitoring

Database connection metrics are tracked in real-time:

```typescript
async getConnectionMetrics(): Promise<any> {
  const result = await this.prisma.$queryRaw`
    SELECT 
      count(*) as "activeConnections",
      (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as "maxConnections"
    FROM pg_stat_activity 
    WHERE datname = current_database() AND state = 'active'
  `;
  return result;
}
```

### Connection Management Best Practices

1. **Graceful Shutdown**: Connections are properly closed during application shutdown
2. **Transaction Timeouts**: Transactions have configurable timeouts to prevent connection leaks
3. **Connection Reuse**: Connections are reused across requests through the connection pool

## 5. Query Pattern Optimization

### Common Query Anti-patterns to Avoid

1. **N+1 Query Problem**: Always use `include` to fetch related data in a single query

   ```typescript
   // BAD: N+1 problem
   const firms = await prisma.firm.findMany();
   for (const firm of firms) {
     firm.consultants = await prisma.firmConsultantAssociation.findMany({ 
       where: { firmId: firm.id } 
     });
   }
   
   // GOOD: Single query with includes
   const firms = await prisma.firm.findMany({
     include: {
       consultantAssociations: true
     }
   });
   ```

2. **Overfetching**: Use `select` to limit field retrieval

   ```typescript
   // BAD: Fetching all fields
   const users = await prisma.user.findMany();
   
   // GOOD: Select only needed fields
   const users = await prisma.user.findMany({
     select: {
       id: true,
       name: true,
       email: true
     }
   });
   ```

3. **Inefficient Filtering**: Use indexed fields for filtering

   ```typescript
   // BAD: Filtering on non-indexed field
   const users = await prisma.user.findMany({
     where: {
       bio: {
         contains: 'consultant'
       }
     }
   });
   
   // GOOD: Filter on indexed fields
   const users = await prisma.user.findMany({
     where: {
       type: 'CONSULTANT',
       tenantId: currentTenantId
     }
   });
   ```

### Query Optimization Techniques

1. **Compound Where Clauses**: Combine related conditions for better index usage

   ```typescript
   // Less efficient separate conditions
   {
     where: {
       AND: [
         { tenantId },
         { firmId }
       ]
     }
   }
   
   // More efficient combined condition
   {
     where: {
       tenantId_firmId: {
         tenantId,
         firmId
       }
     }
   }
   ```

2. **Batch Operations**: Use `createMany`, `updateMany` for bulk operations

   ```typescript
   // More efficient than individual creates
   await prisma.consultantPermission.createMany({
     data: permissions
   });
   ```

3. **Limiting Result Sets**: Always limit results, especially for large tables

   ```typescript
   // Always use pagination
   const { skip, take } = PaginationUtil.getOffsetPagination(params);
   ```

## 6. Development Guidelines

### Writing Efficient Queries

1. **Use the right pagination strategy**:
   ```typescript
   // For large or frequently changing datasets
   const pagParams = PaginationUtil.getCursorPagination(params);
   
   // For smaller, more stable datasets
   const pagParams = PaginationUtil.getOffsetPagination(params);
   ```

2. **Always leverage caching for expensive queries**:
   ```typescript
   return this.cache.getOrSet(
     {
       prefix: 'expensive-query',
       params: queryParams,
       tenantId
     },
     async () => { /* expensive query */ },
     300 // Cache for 5 minutes
   );
   ```

3. **Use transactions for consistency**:
   ```typescript
   return this.transactions.withTransaction(async (tx) => {
     // Multiple operations in a single transaction
   });
   ```

4. **Monitor query performance**:
   - Add logging for slow queries
   - Use database monitoring tools
   - Review query plans for complex queries 