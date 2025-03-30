# Resilience Testing for Multi-Tenant Data Isolation

## Overview

This document outlines the comprehensive resilience testing strategy implemented for the Data Service to ensure tenant data isolation remains robust under extreme edge cases and failure conditions. The testing strategy verifies that the defense-in-depth approach to multi-tenant isolation works reliably under all operating conditions.

## Key Testing Objectives

1. **Verify Tenant Isolation**: Ensure data for one tenant is never accessible by another tenant
2. **Test Edge Cases**: Identify potential vulnerabilities in extreme scenarios
3. **Validate Recovery**: Confirm tenant context is maintained during error conditions
4. **Measure Performance**: Ensure tenant isolation doesn't impact performance at scale
5. **Simulate Attacks**: Test resistance to common attack patterns targeting multi-tenant systems

## Test Coverage Matrix

The testing strategy covers all layers of the multi-tenant architecture:

| Layer | Testing Focus | Test Types |
|-------|---------------|------------|
| API Layer | Request validation, tenant header verification | Unit, Integration |
| Middleware | Tenant context propagation | Unit, Integration |
| Repository | Tenant context enforcement | Unit, Integration |
| Database (RLS) | Row-level security policies | Integration, Stress |
| Caching | Tenant isolation in cache | Unit, Integration |
| Error Handling | Tenant context preservation | Chaos, Unit |
| Transactions | Tenant context in transactions | Integration, Stress |

## Test Implementation

### Repository Layer Tests

```typescript
// src/tests/repository/tenant-isolation.test.ts
import { PrismaClient } from '@prisma/client';
import { FirmConsultantRepository } from '../../repositories/firmConsultantRepository';
import { v4 as uuidv4 } from 'uuid';

describe('Repository Layer Tenant Isolation', () => {
  let prisma: PrismaClient;
  let repository: FirmConsultantRepository;
  let tenantId1: string;
  let tenantId2: string;
  
  beforeAll(async () => {
    prisma = new PrismaClient();
    repository = new FirmConsultantRepository(prisma);
    
    // Set up test tenants
    tenantId1 = uuidv4();
    tenantId2 = uuidv4();
    
    // Create test data
    await prisma.tenant.createMany({
      data: [
        { id: tenantId1, name: 'Test Tenant 1' },
        { id: tenantId2, name: 'Test Tenant 2' }
      ]
    });
    
    // Create test consultants for each tenant
    await prisma.consultant.create({
      data: {
        id: 'consultant1',
        name: 'Consultant 1',
        tenantId: tenantId1
      }
    });
    
    await prisma.consultant.create({
      data: {
        id: 'consultant2',
        name: 'Consultant 2',
        tenantId: tenantId2
      }
    });
  });
  
  afterAll(async () => {
    // Clean up test data
    await prisma.consultant.deleteMany({
      where: {
        id: { in: ['consultant1', 'consultant2'] }
      }
    });
    
    await prisma.tenant.deleteMany({
      where: {
        id: { in: [tenantId1, tenantId2] }
      }
    });
    
    await prisma.$disconnect();
  });
  
  test('findById should only return data for the specified tenant', async () => {
    // Create test firm-consultant associations
    const association1 = await prisma.firmConsultantAssociation.create({
      data: {
        consultantId: 'consultant1',
        firmId: 'firm1',
        tenantId: tenantId1
      }
    });
    
    const association2 = await prisma.firmConsultantAssociation.create({
      data: {
        consultantId: 'consultant2',
        firmId: 'firm2',
        tenantId: tenantId2
      }
    });
    
    // Test correct tenant access
    const result1 = await repository.findById(association1.id, tenantId1);
    expect(result1).not.toBeNull();
    expect(result1?.id).toBe(association1.id);
    
    // Test incorrect tenant access
    const result2 = await repository.findById(association1.id, tenantId2);
    expect(result2).toBeNull();
    
    // Clean up
    await prisma.firmConsultantAssociation.deleteMany({
      where: {
        id: { in: [association1.id, association2.id] }
      }
    });
  });
  
  test('findAll should only return data for the specified tenant', async () => {
    // Create multiple associations for both tenants
    await prisma.firmConsultantAssociation.createMany({
      data: [
        { consultantId: 'consultant1', firmId: 'firm1', tenantId: tenantId1 },
        { consultantId: 'consultant1', firmId: 'firm3', tenantId: tenantId1 },
        { consultantId: 'consultant2', firmId: 'firm2', tenantId: tenantId2 }
      ]
    });
    
    // Test tenant1 access
    const results1 = await repository.findAll(tenantId1);
    expect(results1.length).toBe(2);
    results1.forEach(item => {
      expect(item.tenantId).toBe(tenantId1);
    });
    
    // Test tenant2 access
    const results2 = await repository.findAll(tenantId2);
    expect(results2.length).toBe(1);
    results2.forEach(item => {
      expect(item.tenantId).toBe(tenantId2);
    });
    
    // Clean up
    await prisma.firmConsultantAssociation.deleteMany({
      where: {
        tenantId: { in: [tenantId1, tenantId2] }
      }
    });
  });
  
  test('update should verify tenant before updating', async () => {
    // Create test association
    const association = await prisma.firmConsultantAssociation.create({
      data: {
        consultantId: 'consultant1',
        firmId: 'firm1',
        tenantId: tenantId1
      }
    });
    
    // Test correct tenant update
    const updateData = { status: 'ACTIVE' };
    const updated = await repository.update(association.id, updateData, tenantId1);
    expect(updated).not.toBeNull();
    expect(updated.status).toBe('ACTIVE');
    
    // Test incorrect tenant update - should throw
    await expect(
      repository.update(association.id, updateData, tenantId2)
    ).rejects.toThrow('Entity not found or access denied');
    
    // Clean up
    await prisma.firmConsultantAssociation.delete({
      where: { id: association.id }
    });
  });
});
```

### Row-Level Security Tests

```typescript
// src/tests/database/row-level-security.test.ts
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

describe('PostgreSQL Row-Level Security Tests', () => {
  let prisma: PrismaClient;
  let tenantId1: string;
  let tenantId2: string;
  
  beforeAll(async () => {
    prisma = new PrismaClient();
    
    tenantId1 = uuidv4();
    tenantId2 = uuidv4();
    
    // Create test tenants
    await prisma.tenant.createMany({
      data: [
        { id: tenantId1, name: 'Test Tenant 1' },
        { id: tenantId2, name: 'Test Tenant 2' }
      ]
    });
  });
  
  afterAll(async () => {
    // Clean up
    await prisma.tenant.deleteMany({
      where: {
        id: { in: [tenantId1, tenantId2] }
      }
    });
    
    await prisma.$disconnect();
  });
  
  test('RLS should enforce tenant isolation with raw SQL queries', async () => {
    // Create test data
    await prisma.user.createMany({
      data: [
        { id: 'user1', email: 'user1@test.com', tenantId: tenantId1 },
        { id: 'user2', email: 'user2@test.com', tenantId: tenantId2 }
      ]
    });
    
    // Set tenant context for tenant1
    await prisma.$executeRawUnsafe(`SELECT set_tenant_context('${tenantId1}')`);
    
    // Raw query should only return tenant1 data
    const tenantUsers = await prisma.$queryRawUnsafe(
      `SELECT * FROM "User"`
    );
    
    expect(tenantUsers).toHaveLength(1);
    expect(tenantUsers[0].id).toBe('user1');
    
    // Reset context and clean up
    await prisma.$executeRawUnsafe(`SELECT reset_tenant_context()`);
    
    await prisma.user.deleteMany({
      where: {
        id: { in: ['user1', 'user2'] }
      }
    });
  });
  
  test('RLS should enforce isolation even with direct table access', async () => {
    // Create test data
    await prisma.consultant.createMany({
      data: [
        { id: 'consultant-rls-1', name: 'RLS Test 1', tenantId: tenantId1 },
        { id: 'consultant-rls-2', name: 'RLS Test 2', tenantId: tenantId2 }
      ]
    });
    
    // Simulate direct table access for tenant1
    await prisma.$executeRawUnsafe(`SELECT set_tenant_context('${tenantId1}')`);
    
    const directAccess = await prisma.$queryRawUnsafe(
      `SELECT * FROM "Consultant" WHERE id LIKE 'consultant-rls-%'`
    );
    
    expect(directAccess).toHaveLength(1);
    expect(directAccess[0].tenant_id).toBe(tenantId1);
    
    // Reset context
    await prisma.$executeRawUnsafe(`SELECT reset_tenant_context()`);
    
    // Clean up
    await prisma.consultant.deleteMany({
      where: {
        id: { in: ['consultant-rls-1', 'consultant-rls-2'] }
      }
    });
  });
  
  test('Admin bypass should correctly retrieve all tenant data', async () => {
    // Create test data
    await prisma.firmConsultantAssociation.createMany({
      data: [
        { consultantId: 'c1', firmId: 'f1', tenantId: tenantId1 },
        { consultantId: 'c2', firmId: 'f2', tenantId: tenantId2 }
      ]
    });
    
    // Bypass RLS to get all data (admin operation)
    await prisma.$executeRawUnsafe(`SET ROLE smarter_firms_admin`);
    
    const allData = await prisma.$queryRawUnsafe(
      `SELECT * FROM "FirmConsultantAssociation" WHERE consultant_id IN ('c1', 'c2')`
    );
    
    expect(allData).toHaveLength(2);
    
    // Reset role and clean up
    await prisma.$executeRawUnsafe(`RESET ROLE`);
    
    await prisma.firmConsultantAssociation.deleteMany({
      where: {
        consultantId: { in: ['c1', 'c2'] }
      }
    });
  });
});
```

### Error Handling Tests

```typescript
// src/tests/middleware/tenant-context-preservation.test.ts
import { Request, Response } from 'express';
import { tenantMiddleware } from '../../middleware/tenantMiddleware';
import { TenantContext } from '../../utils/tenantContext';

describe('Tenant Context Preservation in Error Conditions', () => {
  let req: Partial<Request>;
  let res: Partial<Response>;
  let next: jest.Mock;
  
  beforeEach(() => {
    req = {
      headers: { 'x-tenant-id': 'test-tenant-123' },
      path: '/api/consultants'
    };
    
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    
    next = jest.fn();
    
    // Reset tenant context
    TenantContext.clearCurrentTenant();
  });
  
  test('middleware should set tenant context correctly', async () => {
    tenantMiddleware(req as Request, res as Response, next);
    
    expect(TenantContext.getCurrentTenant()).toBe('test-tenant-123');
    expect(next).toHaveBeenCalled();
  });
  
  test('tenant context should be preserved during error scenarios', async () => {
    // Simulate error being thrown in next middleware
    next.mockImplementation(() => {
      throw new Error('Simulated error');
    });
    
    try {
      tenantMiddleware(req as Request, res as Response, next);
    } catch (error) {
      // Error should be thrown
    }
    
    // Tenant context should still be preserved
    expect(TenantContext.getCurrentTenant()).toBe('test-tenant-123');
  });
  
  test('middleware should reject invalid tenant IDs', async () => {
    // Invalid tenant ID format
    req.headers = { 'x-tenant-id': 'invalid-format!' };
    
    tenantMiddleware(req as Request, res as Response, next);
    
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      error: expect.stringContaining('Invalid tenant ID')
    }));
    expect(next).not.toHaveBeenCalled();
  });
  
  test('middleware should reject missing tenant headers for protected routes', async () => {
    // Missing tenant header
    req.headers = {};
    
    tenantMiddleware(req as Request, res as Response, next);
    
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      error: expect.stringContaining('Tenant ID required')
    }));
    expect(next).not.toHaveBeenCalled();
  });
  
  test('middleware should allow public routes without tenant header', async () => {
    // Public route
    req.path = '/api/public/health';
    req.headers = {};
    
    tenantMiddleware(req as Request, res as Response, next);
    
    expect(next).toHaveBeenCalled();
    expect(TenantContext.getCurrentTenant()).toBeNull();
  });
});
```

## Integration Test Strategy

### End-to-End Multi-Tenant Tests

```typescript
// src/tests/integration/multi-tenant-isolation.test.ts
import request from 'supertest';
import { app } from '../../app';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

describe('Multi-Tenant API Isolation Tests', () => {
  let prisma: PrismaClient;
  let tenantId1: string;
  let tenantId2: string;
  let testUser1Id: string;
  let testUser2Id: string;
  
  beforeAll(async () => {
    prisma = new PrismaClient();
    
    // Set up test data
    tenantId1 = uuidv4();
    tenantId2 = uuidv4();
    testUser1Id = uuidv4();
    testUser2Id = uuidv4();
    
    // Create test tenants
    await prisma.tenant.createMany({
      data: [
        { id: tenantId1, name: 'Integration Test Tenant 1' },
        { id: tenantId2, name: 'Integration Test Tenant 2' }
      ]
    });
    
    // Create test users
    await prisma.user.createMany({
      data: [
        { id: testUser1Id, email: 'test1@example.com', tenantId: tenantId1 },
        { id: testUser2Id, email: 'test2@example.com', tenantId: tenantId2 }
      ]
    });
  });
  
  afterAll(async () => {
    // Clean up
    await prisma.user.deleteMany({
      where: {
        id: { in: [testUser1Id, testUser2Id] }
      }
    });
    
    await prisma.tenant.deleteMany({
      where: {
        id: { in: [tenantId1, tenantId2] }
      }
    });
    
    await prisma.$disconnect();
  });
  
  test('GET /api/users/:id should enforce tenant isolation', async () => {
    // Tenant 1 should be able to access their own user
    const response1 = await request(app)
      .get(`/api/users/${testUser1Id}`)
      .set('x-tenant-id', tenantId1)
      .expect(200);
      
    expect(response1.body.id).toBe(testUser1Id);
    
    // Tenant 1 should NOT be able to access Tenant 2's user
    await request(app)
      .get(`/api/users/${testUser2Id}`)
      .set('x-tenant-id', tenantId1)
      .expect(404);
  });
  
  test('POST /api/users should enforce tenant isolation', async () => {
    // Create a user with tenant 1
    const newUser = {
      email: 'newuser@example.com',
      name: 'New User'
    };
    
    const response = await request(app)
      .post('/api/users')
      .set('x-tenant-id', tenantId1)
      .send(newUser)
      .expect(201);
      
    const newUserId = response.body.id;
    
    // Verify the user was created with the correct tenant
    const createdUser = await prisma.user.findUnique({
      where: { id: newUserId }
    });
    
    expect(createdUser).not.toBeNull();
    expect(createdUser?.tenantId).toBe(tenantId1);
    
    // Tenant 2 should NOT be able to access the user
    await request(app)
      .get(`/api/users/${newUserId}`)
      .set('x-tenant-id', tenantId2)
      .expect(404);
      
    // Clean up
    await prisma.user.delete({
      where: { id: newUserId }
    });
  });
  
  test('PUT /api/users/:id should enforce tenant isolation', async () => {
    // Create test users for updating
    const updateUserId1 = uuidv4();
    const updateUserId2 = uuidv4();
    
    await prisma.user.createMany({
      data: [
        { id: updateUserId1, email: 'update1@example.com', tenantId: tenantId1 },
        { id: updateUserId2, email: 'update2@example.com', tenantId: tenantId2 }
      ]
    });
    
    // Tenant 1 should be able to update their own user
    await request(app)
      .put(`/api/users/${updateUserId1}`)
      .set('x-tenant-id', tenantId1)
      .send({ name: 'Updated Name' })
      .expect(200);
      
    // Tenant 1 should NOT be able to update Tenant 2's user
    await request(app)
      .put(`/api/users/${updateUserId2}`)
      .set('x-tenant-id', tenantId1)
      .send({ name: 'Should Not Update' })
      .expect(404);
      
    // Verify Tenant 2's user was not updated
    const user2 = await prisma.user.findUnique({
      where: { id: updateUserId2 }
    });
    
    expect(user2?.name).not.toBe('Should Not Update');
    
    // Clean up
    await prisma.user.deleteMany({
      where: {
        id: { in: [updateUserId1, updateUserId2] }
      }
    });
  });
});
```

## Chaos Testing Strategy

### Tenant Context Resilience

```typescript
// src/tests/chaos/tenant-context-resilience.test.ts
import { PrismaClient } from '@prisma/client';
import { TenantContext } from '../../utils/tenantContext';
import { BaseRepository } from '../../repositories/baseRepository';
import { v4 as uuidv4 } from 'uuid';

// Example entity repository for testing
class TestEntityRepository extends BaseRepository<any, any> {
  constructor(prisma: PrismaClient) {
    super(prisma, 'testEntity');
  }
}

describe('Tenant Context Resilience Under Chaos', () => {
  let prisma: PrismaClient;
  let repository: TestEntityRepository;
  const tenantId = uuidv4();
  
  beforeAll(() => {
    prisma = new PrismaClient();
    repository = new TestEntityRepository(prisma);
  });
  
  afterAll(async () => {
    await prisma.$disconnect();
  });
  
  test('Context is preserved during database connection errors', async () => {
    // Set tenant context
    TenantContext.setCurrentTenant(tenantId);
    
    // Mock a database connection error
    jest.spyOn(prisma, '$connect').mockRejectedValueOnce(new Error('DB connection error'));
    
    try {
      // This operation should fail
      await repository.findAll(tenantId);
    } catch (error) {
      // Error expected
    }
    
    // Tenant context should be preserved
    expect(TenantContext.getCurrentTenant()).toBe(tenantId);
    
    // Restore mock
    jest.restoreAllMocks();
  });
  
  test('Tenant context isolation during concurrent operations', async () => {
    // Simulate 10 concurrent requests with different tenant contexts
    const tenantPromises = Array.from({ length: 10 }, (_, i) => {
      const currentTenantId = `tenant-${i}`;
      
      return new Promise<void>(async (resolve) => {
        // Set tenant context for this "request"
        TenantContext.setCurrentTenant(currentTenantId);
        
        // Simulate random processing time
        await new Promise(r => setTimeout(r, Math.random() * 50));
        
        // Verify tenant context wasn't corrupted by other concurrent "requests"
        expect(TenantContext.getCurrentTenant()).toBe(currentTenantId);
        
        // Clear context when done
        TenantContext.clearCurrentTenant();
        resolve();
      });
    });
    
    // Wait for all concurrent operations to complete
    await Promise.all(tenantPromises);
  });
  
  test('Repository gracefully handles interruption during transaction', async () => {
    // Set tenant context
    TenantContext.setCurrentTenant(tenantId);
    
    // Mock transaction to fail in the middle
    jest.spyOn(prisma, '$transaction').mockImplementationOnce(async (callback) => {
      // Start transaction normally
      const tx = {} as any;
      
      // Simulate partial execution then error
      try {
        await callback(tx);
      } catch (error) {
        // Expected
      }
      
      throw new Error('Transaction interrupted');
    });
    
    try {
      // Attempt an operation that uses transactions
      await repository.create({ name: 'Test Entity' }, tenantId);
    } catch (error) {
      // Error expected
    }
    
    // Tenant context should be preserved
    expect(TenantContext.getCurrentTenant()).toBe(tenantId);
    
    // Clean up
    TenantContext.clearCurrentTenant();
    jest.restoreAllMocks();
  });
});
```

## Performance Testing

### Scale and Load Testing

```typescript
// src/tests/performance/tenant-isolation-performance.test.ts
import { PrismaClient } from '@prisma/client';
import { performance } from 'perf_hooks';
import { v4 as uuidv4 } from 'uuid';
import { FirmConsultantRepository } from '../../repositories/firmConsultantRepository';

describe('Tenant Isolation Performance Tests', () => {
  let prisma: PrismaClient;
  let repository: FirmConsultantRepository;
  let tenantIds: string[] = [];
  const TEST_TENANTS = 10;
  const ENTITIES_PER_TENANT = 100;
  
  beforeAll(async () => {
    prisma = new PrismaClient();
    repository = new FirmConsultantRepository(prisma);
    
    // Create test tenants
    for (let i = 0; i < TEST_TENANTS; i++) {
      tenantIds.push(uuidv4());
    }
    
    // Create tenant records
    await prisma.tenant.createMany({
      data: tenantIds.map(id => ({ id, name: `Performance Test Tenant ${id}` }))
    });
    
    // Create test data for each tenant
    for (const tenantId of tenantIds) {
      const data = Array.from({ length: ENTITIES_PER_TENANT }, (_, i) => ({
        consultantId: `perf-c-${tenantId}-${i}`,
        firmId: `perf-f-${tenantId}-${i}`,
        tenantId
      }));
      
      await prisma.firmConsultantAssociation.createMany({ data });
    }
  });
  
  afterAll(async () => {
    // Clean up test data
    await prisma.firmConsultantAssociation.deleteMany({
      where: {
        tenantId: { in: tenantIds }
      }
    });
    
    await prisma.tenant.deleteMany({
      where: {
        id: { in: tenantIds }
      }
    });
    
    await prisma.$disconnect();
  });
  
  test('Performance of findAll with tenant isolation', async () => {
    const results: { tenantId: string; time: number; count: number }[] = [];
    
    // Test findAll performance for each tenant
    for (const tenantId of tenantIds) {
      const start = performance.now();
      const data = await repository.findAll(tenantId);
      const end = performance.now();
      
      results.push({
        tenantId,
        time: end - start,
        count: data.length
      });
      
      // Verify correct data isolation
      expect(data.length).toBe(ENTITIES_PER_TENANT);
      expect(data.every(item => item.tenantId === tenantId)).toBe(true);
    }
    
    // Calculate statistics
    const times = results.map(r => r.time);
    const average = times.reduce((a, b) => a + b, 0) / times.length;
    const max = Math.max(...times);
    const min = Math.min(...times);
    
    console.log(`Query performance with tenant isolation:
      Average: ${average.toFixed(2)}ms
      Min: ${min.toFixed(2)}ms
      Max: ${max.toFixed(2)}ms`);
    
    // Performance should be consistent across tenants
    const stdDev = Math.sqrt(
      times.map(t => Math.pow(t - average, 2)).reduce((a, b) => a + b, 0) / times.length
    );
    
    console.log(`Standard deviation: ${stdDev.toFixed(2)}ms`);
    
    // Standard deviation should be low (queries should be consistent)
    expect(stdDev / average).toBeLessThan(0.5); // Less than 50% variance
  });
  
  test('Performance of concurrent tenant requests', async () => {
    const CONCURRENT_REQUESTS = 20;
    const start = performance.now();
    
    // Create array of random tenant IDs (with repetition)
    const randomTenantIds = Array.from(
      { length: CONCURRENT_REQUESTS },
      () => tenantIds[Math.floor(Math.random() * tenantIds.length)]
    );
    
    // Execute concurrent requests
    const results = await Promise.all(
      randomTenantIds.map(async tenantId => {
        const requestStart = performance.now();
        const data = await repository.findAll(tenantId);
        const requestEnd = performance.now();
        
        return {
          tenantId,
          time: requestEnd - requestStart,
          count: data.length
        };
      })
    );
    
    const end = performance.now();
    const totalTime = end - start;
    
    console.log(`Concurrent tenant requests (${CONCURRENT_REQUESTS}):
      Total time: ${totalTime.toFixed(2)}ms
      Average per request: ${(totalTime / CONCURRENT_REQUESTS).toFixed(2)}ms`);
    
    // All requests should return correct data
    for (const result of results) {
      expect(result.count).toBe(ENTITIES_PER_TENANT);
    }
  });
});
```

## Attack Simulation

### Common Multi-Tenant Attack Pattern Tests

```typescript
// src/tests/security/tenant-isolation-attacks.test.ts
import request from 'supertest';
import { app } from '../../app';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

describe('Tenant Isolation Attack Resistance Tests', () => {
  let prisma: PrismaClient;
  let tenantId1: string;
  let tenantId2: string;
  let testEntityId: string;
  
  beforeAll(async () => {
    prisma = new PrismaClient();
    
    tenantId1 = uuidv4();
    tenantId2 = uuidv4();
    testEntityId = uuidv4();
    
    // Create test tenants
    await prisma.tenant.createMany({
      data: [
        { id: tenantId1, name: 'Security Test Tenant 1' },
        { id: tenantId2, name: 'Security Test Tenant 2' }
      ]
    });
    
    // Create test entity for tenant1
    await prisma.consultant.create({
      data: {
        id: testEntityId,
        name: 'Security Test Entity',
        tenantId: tenantId1
      }
    });
  });
  
  afterAll(async () => {
    // Clean up
    await prisma.consultant.delete({
      where: { id: testEntityId }
    });
    
    await prisma.tenant.deleteMany({
      where: {
        id: { in: [tenantId1, tenantId2] }
      }
    });
    
    await prisma.$disconnect();
  });
  
  test('Resistance to tenant ID spoofing', async () => {
    // Attempt to access tenant1's data by spoofing tenant header
    await request(app)
      .get(`/api/consultants/${testEntityId}`)
      .set('x-tenant-id', tenantId2)
      .expect(404); // Should not find entity belonging to tenant1
  });
  
  test('Resistance to tenant parameter manipulation', async () => {
    // Attempt to specify a different tenant in URL
    await request(app)
      .get(`/api/consultants/by-tenant/${tenantId1}`)
      .set('x-tenant-id', tenantId2)
      .expect(403); // Should be forbidden
  });
  
  test('Resistance to SQL injection in tenant context', async () => {
    // Attempt SQL injection in tenant header
    await request(app)
      .get('/api/consultants')
      .set('x-tenant-id', "'; DROP TABLE \"User\"; --")
      .expect(400); // Should reject invalid tenant ID format
    
    // Verify table still exists
    const tableCheck = await prisma.$queryRaw`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'User'
      );
    `;
    
    expect(tableCheck[0].exists).toBe(true);
  });
  
  test('Resistance to missing tenant context', async () => {
    // Attempt to access protected endpoint without tenant context
    await request(app)
      .get('/api/consultants')
      .expect(401); // Should require tenant ID
  });
  
  test('Resistance to path traversal in tenant routes', async () => {
    // Attempt path traversal to bypass tenant check
    await request(app)
      .get('/api/consultants/../public/bypass')
      .set('x-tenant-id', tenantId2)
      .expect(404); // Should not be able to traverse paths
  });
});
```

## Continuous Integration

### Automated Testing Pipeline

Tenant isolation tests are automatically run as part of the CI/CD pipeline:

```yaml
# .github/workflows/tenant-isolation-tests.yml
name: Multi-Tenant Isolation Tests

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main, dev ]

jobs:
  test-tenant-isolation:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Initialize test database
        run: |
          npm run prisma:generate
          npm run prisma:migrate:test
          
      - name: Run tenant isolation tests
        run: npm run test:isolation
        
      - name: Run tenant security tests
        run: npm run test:security
        
      - name: Generate test report
        run: npm run test:report
        
      - name: Upload test artifacts
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: reports/
```

## Best Practices

1. **Test Core Isolation Mechanisms**:
   - Test all tenant isolation mechanisms independently
   - Verify each layer enforces isolation correctly
   - Combine layers for defense-in-depth validation

2. **Test Edge Cases**:
   - Missing or invalid tenant context
   - Error conditions with tenant context
   - Concurrent access across tenants
   - System resource constraints

3. **Verify Performance**:
   - Ensure isolation doesn't significantly impact performance
   - Test with realistic tenant data volumes
   - Measure query performance across tenants

4. **Prioritize Security Testing**:
   - Simulate common attack patterns
   - Test boundary conditions
   - Verify logging and monitoring of isolation breaches

5. **Integrate Testing into CI/CD**:
   - Run isolation tests on every code change
   - Block deployments if tests fail
   - Track isolation metrics over time 