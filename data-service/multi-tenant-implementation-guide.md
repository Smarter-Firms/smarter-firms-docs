# Multi-Tenant Implementation Guide

## Overview

The Data Service implements a robust multi-tenant architecture that ensures strong data isolation between different law firms. This document describes the implementation details, security measures, and best practices for working with the multi-tenant architecture.

## Multi-Tenant Architecture

The Data Service implements a multi-layered approach to multi-tenancy:

### 1. PostgreSQL Row-Level Security (RLS)

At the database level, the system uses PostgreSQL's Row-Level Security feature to enforce tenant isolation:

```sql
-- Enable RLS on a table
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Create a policy that restricts access based on tenant_id
CREATE POLICY tenant_isolation_policy ON clients
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Similar policies for all tenant-specific tables
```

### 2. Session Context for Tenant Identification

The system sets a session-level context variable that RLS policies use:

```sql
-- Set the tenant context for the current session
SELECT set_config('app.tenant_id', $1, false);
```

### 3. AsyncLocalStorage for Context Propagation

In Node.js, the system uses AsyncLocalStorage to propagate tenant context across async operations:

```javascript
const { AsyncLocalStorage } = require('async_hooks');

// Create tenant context storage
const tenantContextStorage = new AsyncLocalStorage();

// Middleware to set tenant context
const setTenantContext = (req, res, next) => {
  const tenantId = extractTenantId(req);
  
  // Validate tenant ID
  if (!isValidTenantId(tenantId)) {
    return res.status(403).json({
      error: 'Invalid tenant ID'
    });
  }
  
  // Set tenant context for the current request lifecycle
  tenantContextStorage.run({ tenantId }, () => {
    next();
  });
};

// Function to get current tenant ID
const getCurrentTenantId = () => {
  const context = tenantContextStorage.getStore();
  return context?.tenantId;
};

// Function to execute code in a specific tenant context
const withTenantId = async (tenantId, callback) => {
  return tenantContextStorage.run({ tenantId }, callback);
};
```

### 4. Repository Pattern with Tenant Isolation

The system implements the repository pattern to enforce tenant isolation at the application level:

```javascript
// Base repository class with tenant isolation
class BaseRepository {
  constructor(prisma) {
    this.prisma = prisma;
  }
  
  // Get current tenant ID from context
  getCurrentTenantId() {
    const tenantId = getCurrentTenantId();
    if (!tenantId) {
      throw new Error('No tenant context found');
    }
    return tenantId;
  }
  
  // Set tenant filter for queries
  withTenantFilter(query) {
    const tenantId = this.getCurrentTenantId();
    return {
      ...query,
      where: {
        ...query.where,
        tenantId
      }
    };
  }
  
  // Generic find many with tenant isolation
  async findMany(query = {}) {
    const filteredQuery = this.withTenantFilter(query);
    return this.prisma.model.findMany(filteredQuery);
  }
  
  // Generic find unique with tenant isolation
  async findUnique(query) {
    // For findUnique, we need to check tenant ID after query
    const result = await this.prisma.model.findUnique(query);
    
    if (result && result.tenantId !== this.getCurrentTenantId()) {
      return null; // Return null for records from other tenants
    }
    
    return result;
  }
  
  // Create with automatic tenant ID
  async create(data) {
    const tenantId = this.getCurrentTenantId();
    return this.prisma.model.create({
      data: {
        ...data,
        tenantId
      }
    });
  }
  
  // Update with tenant check
  async update(id, data) {
    const tenantId = this.getCurrentTenantId();
    return this.prisma.model.updateMany({
      where: {
        id,
        tenantId
      },
      data
    });
  }
  
  // Delete with tenant check
  async delete(id) {
    const tenantId = this.getCurrentTenantId();
    return this.prisma.model.deleteMany({
      where: {
        id,
        tenantId
      }
    });
  }
}

// Example client repository
class ClientRepository extends BaseRepository {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.client;
  }
  
  // Client-specific methods
  async findByEmail(email) {
    return this.model.findFirst({
      where: {
        email,
        tenantId: this.getCurrentTenantId()
      }
    });
  }
  
  // More client-specific methods...
}
```

### 5. Middleware for Automatic Tenant Context Management

The system includes middleware for automatically managing tenant context:

```javascript
// Tenant middleware factory
const createTenantMiddleware = (options) => {
  const {
    tenantIdSource = 'header', // header, token, url
    headerName = 'X-Tenant-ID',
    tokenField = 'tenantId',
    urlParam = 'tenantId',
    tokenExtractor = null
  } = options;
  
  return (req, res, next) => {
    let tenantId;
    
    // Extract tenant ID based on source
    switch (tenantIdSource) {
      case 'header':
        tenantId = req.headers[headerName.toLowerCase()];
        break;
        
      case 'token':
        if (req.user && req.user[tokenField]) {
          tenantId = req.user[tokenField];
        } else if (tokenExtractor) {
          tenantId = tokenExtractor(req);
        }
        break;
        
      case 'url':
        tenantId = req.params[urlParam];
        break;
        
      default:
        return next(new Error(`Invalid tenant ID source: ${tenantIdSource}`));
    }
    
    if (!tenantId) {
      return res.status(400).json({
        error: 'Tenant ID is required'
      });
    }
    
    // Validate and normalize tenant ID
    try {
      const normalizedTenantId = normalizeTenantId(tenantId);
      
      // Verify tenant access
      verifyTenantAccess(normalizedTenantId, req.user)
        .then(() => {
          // Set tenant context for the current request lifecycle
          tenantContextStorage.run({ tenantId: normalizedTenantId }, () => {
            next();
          });
        })
        .catch(error => {
          res.status(403).json({
            error: 'Tenant access denied'
          });
        });
    } catch (error) {
      res.status(400).json({
        error: 'Invalid tenant ID format'
      });
    }
  };
};

// Apply middleware to routes
app.use('/api/v1/clients', createTenantMiddleware({
  tenantIdSource: 'token'
}), clientRoutes);
```

## Integration with Prisma

The system integrates with Prisma ORM for data access, with added tenant isolation:

```javascript
// Prisma middleware for tenant isolation
prisma.$use(async (params, next) => {
  // Skip tenant filtering for non-tenant models
  if (!isTenantModel(params.model)) {
    return next(params);
  }
  
  // Get current tenant ID
  const tenantId = getCurrentTenantId();
  
  // Skip tenant filtering if no tenant context
  if (!tenantId) {
    // For operations that always require tenant context
    if (['findMany', 'create', 'update', 'delete'].includes(params.action)) {
      throw new Error(`Operation ${params.action} requires tenant context`);
    }
    return next(params);
  }
  
  // Add tenant filter for relevant operations
  if (['findMany', 'findFirst', 'update', 'delete'].includes(params.action)) {
    if (!params.args) {
      params.args = {};
    }
    
    if (!params.args.where) {
      params.args.where = {};
    }
    
    params.args.where.tenantId = tenantId;
  }
  
  // Add tenant ID for create operations
  if (params.action === 'create') {
    if (!params.args) {
      params.args = {};
    }
    
    if (!params.args.data) {
      params.args.data = {};
    }
    
    params.args.data.tenantId = tenantId;
  }
  
  // For createMany, add tenant ID to all records
  if (params.action === 'createMany') {
    if (!params.args) {
      params.args = {};
    }
    
    if (!params.args.data) {
      params.args.data = [];
    }
    
    params.args.data = params.args.data.map(item => ({
      ...item,
      tenantId
    }));
  }
  
  return next(params);
});
```

## Database Connection Management

The system implements efficient database connection management:

```javascript
// Database connection manager
class DatabaseConnectionManager {
  constructor() {
    // Map to store Prisma clients by tenant ID
    this.tenantPrismaClients = new Map();
    
    // Default Prisma client for operations not requiring tenant isolation
    this.defaultPrismaClient = new PrismaClient();
  }
  
  // Get Prisma client for specific tenant
  getPrismaClientForTenant(tenantId) {
    // If no tenant ID, return default client
    if (!tenantId) {
      return this.defaultPrismaClient;
    }
    
    // If client exists for tenant, return it
    if (this.tenantPrismaClients.has(tenantId)) {
      return this.tenantPrismaClients.get(tenantId);
    }
    
    // Create new client for tenant
    const prismaClient = new PrismaClient({
      datasources: {
        db: {
          url: process.env.DATABASE_URL
        }
      }
    });
    
    // Add middleware to set tenant context
    prismaClient.$use(async (params, next) => {
      // Set PostgreSQL session variable for tenant context
      await prismaClient.$executeRaw`SELECT set_config('app.tenant_id', ${tenantId}::text, false);`;
      return next(params);
    });
    
    // Store client for reuse
    this.tenantPrismaClients.set(tenantId, prismaClient);
    
    return prismaClient;
  }
  
  // Get client based on current tenant context
  getPrismaClient() {
    const tenantId = getCurrentTenantId();
    return this.getPrismaClientForTenant(tenantId);
  }
  
  // Clean up resources
  async disconnect() {
    await this.defaultPrismaClient.$disconnect();
    
    for (const client of this.tenantPrismaClients.values()) {
      await client.$disconnect();
    }
    
    this.tenantPrismaClients.clear();
  }
}
```

## Cross-Tenant Operations

Some operations require accessing data across multiple tenants. The system provides careful controls for such operations:

```javascript
// Cross-tenant operation handler
class CrossTenantOperationHandler {
  constructor(dbManager) {
    this.dbManager = dbManager;
  }
  
  // Execute operation across multiple tenants
  async executeAcrossTenants(tenantIds, operation) {
    // Verify permission for cross-tenant operation
    this.verifyPermission();
    
    const results = {};
    const errors = {};
    
    // Execute operation for each tenant
    for (const tenantId of tenantIds) {
      try {
        // Get client for tenant
        const prisma = this.dbManager.getPrismaClientForTenant(tenantId);
        
        // Execute operation in tenant context
        const result = await withTenantId(tenantId, () => operation(prisma));
        
        results[tenantId] = result;
      } catch (error) {
        errors[tenantId] = {
          message: error.message,
          stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        };
      }
    }
    
    return {
      results,
      errors,
      successful: Object.keys(results).length,
      failed: Object.keys(errors).length,
      total: tenantIds.length
    };
  }
  
  // Verify permission for cross-tenant operation
  verifyPermission() {
    const user = getCurrentUser();
    
    if (!user) {
      throw new Error('User not authenticated');
    }
    
    if (!user.permissions.includes('CROSS_TENANT_ACCESS')) {
      throw new Error('User does not have permission for cross-tenant operations');
    }
  }
}
```

## Security Considerations

### Tenant Data Leakage Prevention

The system implements multiple layers of protection against tenant data leakage:

1. **Row-Level Security**: PostgreSQL RLS provides a strong database-level isolation.
2. **Application-Level Filtering**: The repository pattern adds another layer of tenant filtering.
3. **Context Verification**: Context is verified at multiple points in the request lifecycle.
4. **Audit Logging**: All cross-tenant operations are logged for security monitoring.

### Tenant Validation

The system implements robust tenant validation:

```javascript
// Tenant validation service
class TenantValidator {
  constructor(tenantRepository) {
    this.tenantRepository = tenantRepository;
  }
  
  // Validate tenant ID format
  validateTenantIdFormat(tenantId) {
    // UUID validation
    const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidPattern.test(tenantId);
  }
  
  // Verify tenant exists
  async verifyTenantExists(tenantId) {
    const tenant = await this.tenantRepository.findById(tenantId);
    
    if (!tenant) {
      throw new Error(`Tenant with ID ${tenantId} does not exist`);
    }
    
    if (!tenant.active) {
      throw new Error(`Tenant with ID ${tenantId} is inactive`);
    }
    
    return tenant;
  }
  
  // Verify user has access to tenant
  async verifyUserTenantAccess(userId, tenantId) {
    const userTenant = await this.tenantRepository.findUserTenant(userId, tenantId);
    
    if (!userTenant) {
      throw new Error(`User does not have access to tenant ${tenantId}`);
    }
    
    return userTenant;
  }
}
```

## Performance Considerations

### Database Indexing

Tables are indexed to optimize multi-tenant queries:

```sql
-- Index for tenant ID on all tenant-specific tables
CREATE INDEX idx_clients_tenant_id ON clients(tenant_id);
CREATE INDEX idx_matters_tenant_id ON matters(tenant_id);
CREATE INDEX idx_documents_tenant_id ON documents(tenant_id);

-- Composite indexes for common queries
CREATE INDEX idx_clients_tenant_id_email ON clients(tenant_id, email);
CREATE INDEX idx_matters_tenant_id_status ON matters(tenant_id, status);
```

### Connection Pooling

The system implements efficient connection pooling:

```javascript
// Connection pool configuration
const connectionPool = {
  min: 2,
  max: 10,
  idle: 10000,
  acquire: 30000,
  evict: 30000
};

// Apply configuration to Prisma
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  },
  log: ['query', 'info', 'warn', 'error'],
  // Connection pool settings
  connectionLimit: connectionPool.max,
  poolConfig: {
    min: connectionPool.min,
    max: connectionPool.max,
    idleTimeoutMillis: connectionPool.idle,
    acquireTimeoutMillis: connectionPool.acquire,
    reapIntervalMillis: connectionPool.evict
  }
});
```

## Best Practices for Developers

### 1. Always Use Repository Methods

Always use repository methods rather than direct Prisma queries to ensure tenant isolation:

```javascript
// Good: Using repository method
const clients = await clientRepository.findMany({
  where: {
    status: 'active'
  }
});

// Bad: Direct Prisma query might bypass tenant isolation
const clients = await prisma.client.findMany({
  where: {
    status: 'active'
    // Missing tenant filter!
  }
});
```

### 2. Test Tenant Isolation

Comprehensive tests for tenant isolation should be implemented:

```javascript
// Example tenant isolation test
describe('Tenant Isolation', () => {
  it('should not allow access to data from another tenant', async () => {
    // Create test tenants
    const tenant1 = await createTestTenant();
    const tenant2 = await createTestTenant();
    
    // Create test data in tenant 1
    await withTenantId(tenant1.id, async () => {
      await clientRepository.create({
        name: 'Test Client',
        email: 'test@example.com'
      });
    });
    
    // Try to access from tenant 2
    const clients = await withTenantId(tenant2.id, () => {
      return clientRepository.findMany();
    });
    
    // Should not find data from tenant 1
    expect(clients.length).toBe(0);
  });
});
```

### 3. Handle Cross-Tenant Operations Carefully

Cross-tenant operations should be carefully controlled:

```javascript
// Example cross-tenant report generation
async function generateCrossTenantReport(tenantIds) {
  // Verify permission
  if (!currentUser.hasPermission('GENERATE_CROSS_TENANT_REPORT')) {
    throw new Error('Permission denied');
  }
  
  // Log cross-tenant operation
  await auditLogger.log({
    action: 'CROSS_TENANT_REPORT',
    user: currentUser.id,
    tenantIds,
    timestamp: new Date()
  });
  
  // Execute across tenants
  return crossTenantHandler.executeAcrossTenants(tenantIds, async (prisma) => {
    // Perform tenant-specific report generation
    const clientCount = await prisma.client.count();
    const matterCount = await prisma.matter.count();
    const activeMatters = await prisma.matter.count({
      where: {
        status: 'active'
      }
    });
    
    return {
      clientCount,
      matterCount,
      activeMatters
    };
  });
}
```

## References

- [PostgreSQL Row-Level Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Node.js AsyncLocalStorage](https://nodejs.org/api/async_hooks.html#async_hooks_class_asynclocalstorage)
- [Prisma Multi-Tenancy Guide](https://www.prisma.io/docs/guides/other/multi-tenancy)
- [Smarter Firms Security Standards](../security/standards.md) 