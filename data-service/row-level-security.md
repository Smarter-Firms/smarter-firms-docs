# Row-Level Security Implementation

This document details how Row-Level Security (RLS) is implemented in PostgreSQL to enforce tenant isolation at the database level for the Smarter Firms platform.

## Overview

PostgreSQL Row-Level Security (RLS) provides a robust mechanism to enforce tenant isolation directly at the database level. Our implementation ensures that each tenant can only access their own data, regardless of how the query is constructed.

## Core Components

### 1. Database Schema Design

Every table that contains tenant-specific data includes a `firm_id` column:

```sql
CREATE TABLE client_matters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL,
    firm_id UUID NOT NULL REFERENCES firms(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX client_matters_firm_id_idx ON client_matters(firm_id);
```

### 2. Row-Level Security Policies

For each tenant-specific table, we create RLS policies that enforce access restrictions:

```sql
-- Enable RLS on the table
ALTER TABLE client_matters ENABLE ROW LEVEL SECURITY;

-- Create a policy that restricts access to rows with matching firm_id
CREATE POLICY tenant_isolation_policy ON client_matters
    USING (firm_id = current_setting('app.current_tenant_id')::UUID);

-- Additional policy for consultant access if necessary
CREATE POLICY consultant_access_policy ON client_matters
    USING (firm_id = ANY(current_setting('app.consultant_accessible_tenants')::UUID[]));

-- Force all users to follow RLS policies
ALTER TABLE client_matters FORCE ROW LEVEL SECURITY;
```

### 3. Current Tenant Context

We set the current tenant context at the beginning of each database session:

```sql
-- Function to set current tenant
CREATE OR REPLACE FUNCTION set_tenant_context(tenant_id UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant_id', tenant_id::TEXT, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set consultant accessible tenants
CREATE OR REPLACE FUNCTION set_consultant_tenants(tenant_ids UUID[])
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.consultant_accessible_tenants', array_to_string(tenant_ids, ','), false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4. Application Integration

In the application code, we set the tenant context at the start of each database transaction:

```typescript
// Set tenant context middleware
export async function setTenantContext(
  req: Request, 
  res: Response, 
  next: NextFunction
) {
  try {
    // Extract tenant ID from JWT
    const tenantId = req.user?.firmId;
    
    // For consultants, extract accessible tenant IDs
    const consultantTenantIds = req.user?.type === 'CONSULTANT' 
      ? req.user.accessibleFirmIds 
      : [];
    
    // Begin transaction with tenant context
    await prisma.$transaction(async (prisma) => {
      // Set current tenant
      if (tenantId) {
        await prisma.$executeRawUnsafe(
          'SELECT set_tenant_context($1)',
          tenantId
        );
      }
      
      // Set consultant accessible tenants if applicable
      if (consultantTenantIds.length > 0) {
        await prisma.$executeRawUnsafe(
          'SELECT set_consultant_tenants($1)',
          consultantTenantIds
        );
      }
      
      // Attach prisma client to request for later use
      req.prisma = prisma;
      
      next();
    }, {
      maxWait: 5000, // 5s maximum wait
      timeout: 10000 // 10s transaction timeout
    });
  } catch (error) {
    next(error);
  }
}
```

## Special Cases

### 1. Shared Tables

Some tables contain data that should be accessible across tenants. For these tables, we skip RLS:

```sql
-- This table has global reference data, no RLS required
CREATE TABLE global_reference_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
```

### 2. Cross-Tenant Reporting

For consultants who need to analyze data across multiple firms, we create specialized functions:

```sql
-- Function to safely retrieve cross-tenant data
CREATE OR REPLACE FUNCTION get_cross_tenant_metrics(
    consultant_id UUID,
    firm_ids UUID[],
    metric_type TEXT
)
RETURNS TABLE (
    firm_id UUID,
    metric_name TEXT,
    metric_value NUMERIC,
    period TEXT
) AS $$
DECLARE
    firm_id UUID;
    has_access BOOLEAN;
BEGIN
    -- Verify consultant has access to all firms
    SELECT EXISTS (
        SELECT 1 FROM consultant_firm_access
        WHERE consultant_id = $1
        AND firm_id = ANY($2)
        GROUP BY consultant_id
        HAVING COUNT(*) = array_length($2, 1)
    ) INTO has_access;
    
    IF NOT has_access THEN
        RAISE EXCEPTION 'Consultant does not have access to all requested firms';
    END IF;
    
    -- Log cross-tenant access
    INSERT INTO access_logs (
        user_id,
        access_type,
        resource_type,
        tenant_ids,
        timestamp
    ) VALUES (
        consultant_id,
        'CROSS_TENANT_READ',
        'metrics',
        firm_ids,
        now()
    );
    
    -- Retrieve data for each firm
    FOREACH firm_id IN ARRAY firm_ids
    LOOP
        -- Temporarily set current tenant ID
        PERFORM set_config('app.current_tenant_id', firm_id::TEXT, false);
        
        -- Return data for this tenant
        RETURN QUERY
            SELECT 
                firm_id,
                m.name,
                m.value,
                m.period
            FROM 
                metrics m
            WHERE 
                m.firm_id = firm_id
                AND m.type = metric_type;
    END LOOP;
    
    -- Reset tenant context
    PERFORM set_config('app.current_tenant_id', '', false);
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Administrative Access

For administrative operations that need to bypass RLS, we create secure procedures:

```sql
-- Function for administrators to access data across tenants
CREATE OR REPLACE FUNCTION admin_audit_tenant_data(
    admin_id UUID,
    target_firm_id UUID,
    action TEXT
)
RETURNS VOID AS $$
DECLARE
    is_admin BOOLEAN;
BEGIN
    -- Verify user is an administrator
    SELECT EXISTS (
        SELECT 1 FROM users
        WHERE id = admin_id AND role = 'ADMIN'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RAISE EXCEPTION 'User is not an administrator';
    END IF;
    
    -- Log administrative access
    INSERT INTO admin_audit_logs (
        admin_id,
        firm_id,
        action,
        timestamp
    ) VALUES (
        admin_id,
        target_firm_id,
        action,
        now()
    );
    
    -- Set bypass RLS for this function only
    SET LOCAL row_security = OFF;
    
    -- Perform the requested action
    -- Action-specific logic here
    
    -- Reset RLS
    SET LOCAL row_security = ON;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Triggers for Tenant ID Enforcement

We use triggers to ensure tenant ID is always properly set:

```sql
-- Trigger function to enforce tenant ID on insert/update
CREATE OR REPLACE FUNCTION enforce_tenant_id()
RETURNS TRIGGER AS $$
DECLARE
    current_tenant_id UUID;
BEGIN
    -- Get current tenant ID
    current_tenant_id := current_setting('app.current_tenant_id', true)::UUID;
    
    -- Ensure tenant ID is set
    IF current_tenant_id IS NULL THEN
        RAISE EXCEPTION 'No tenant context set for this operation';
    END IF;
    
    -- Set firm_id for new/updated records
    NEW.firm_id := current_tenant_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
CREATE TRIGGER enforce_tenant_id_client_matters
BEFORE INSERT OR UPDATE ON client_matters
FOR EACH ROW EXECUTE FUNCTION enforce_tenant_id();
```

## Testing the RLS Implementation

We use the following SQL scripts to verify that RLS is working correctly:

```sql
-- Create test users and tenants
INSERT INTO firms (id, name) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Test Firm A'),
    ('22222222-2222-2222-2222-222222222222', 'Test Firm B');

-- Insert test data for both tenants
SET app.current_tenant_id = '11111111-1111-1111-1111-111111111111';
INSERT INTO client_matters (name, status, firm_id) 
    VALUES ('Matter A1', 'ACTIVE', '11111111-1111-1111-1111-111111111111');

SET app.current_tenant_id = '22222222-2222-2222-2222-222222222222';
INSERT INTO client_matters (name, status, firm_id) 
    VALUES ('Matter B1', 'ACTIVE', '22222222-2222-2222-2222-222222222222');

-- Test tenant isolation
SET app.current_tenant_id = '11111111-1111-1111-1111-111111111111';
SELECT * FROM client_matters; -- Should only see Matter A1

SET app.current_tenant_id = '22222222-2222-2222-2222-222222222222';
SELECT * FROM client_matters; -- Should only see Matter B1
```

## Performance Considerations

To ensure RLS doesn't negatively impact performance:

1. We create indices on all `firm_id` columns
2. We analyze query execution plans to ensure tenant filtering happens efficiently
3. We use prepared statements to allow the query planner to optimize RLS checking
4. We monitor query performance and adjust indices as needed

## Security Audit Procedures

We regularly audit our RLS implementation with the following checks:

1. Verify all tenant-specific tables have RLS enabled
2. Ensure all RLS policies are correctly defined
3. Test cross-tenant access attempts to confirm they are blocked
4. Review logs for any unusual cross-tenant access patterns
5. Perform penetration testing targeting tenant isolation

## Best Practices

1. Always use transactions that set the tenant context
2. Never manually set tenant IDs in application code
3. Don't use superuser connections for regular application operations
4. Regularly verify RLS policies are applied to all tenant tables
5. Log and alert on any errors in tenant context setting 