# Database Migration Plan for Authentication Extensions

## Overview

This document outlines the migration plan for implementing the authentication-related database schema extensions in the Smarter Firms platform. These extensions support consultant user types, firm-consultant associations, and comprehensive authentication logging.

## Migration Phases

### Phase 1: Schema Extension (Week 1)

1. **Add New Enum Types**
   - Create `UserType` enum (`LAW_FIRM_USER`, `CONSULTANT`)
   - Create `AuthMethod` enum (`CLIO_SSO`, `LOCAL`)
   - Create `AccessLevel` enum (`FULL_ACCESS`, `LIMITED_ACCESS`, `READ_ONLY`)
   - Create `AssociationStatus` enum (`ACTIVE`, `PENDING`, `REVOKED`)
   - Create `AuthEventType` enum for logging purposes

2. **Extend User Model**
   - Add `type` field (UserType enum)
   - Add `authMethod` field (AuthMethod enum)
   - Add `hasClioConnection` boolean field
   - Add `organization` and `bio` nullable text fields
   - Add appropriate indexes for performance

3. **Create Initial Migration**
   ```bash
   npx prisma migrate dev --name add_auth_enums_and_user_extensions
   ```

### Phase 2: Relationship Tables (Week 2)

1. **Create ConsultantProfile Model**
   - Implement ConsultantProfile table with foreign key to User
   - Add unique referral code field
   - Add specialty and profile fields
   - Add appropriate indexes

2. **Create Firm-Consultant Association Table**
   - Implement FirmConsultantAssociation table
   - Add composite unique constraint on firmId/consultantId
   - Add indexes for common query patterns
   - Set up cascading deletion rules

3. **Create Permission Model**
   - Implement ConsultantPermission table
   - Set up granular permission structure
   - Add composite unique constraint on associationId/resource/action

4. **Run Migration**
   ```bash
   npx prisma migrate dev --name add_consultant_and_association_tables
   ```

### Phase 3: Logging Infrastructure (Week 3)

1. **Create Auth Log Table**
   - Implement AuthLog table for security auditing
   - Add appropriate indexes for efficient querying
   - Set up foreign key relationships

2. **Run Migration**
   ```bash
   npx prisma migrate dev --name add_auth_logging
   ```

3. **Generate Prisma Client**
   ```bash
   npx prisma generate
   ```

## Testing Strategy

1. **Database Seeding**
   - Create seed script with test data for all models
   - Include different user types and permission scenarios
   - Simulate various association states

2. **Integration Testing**
   - Verify foreign key constraints and cascading deletes
   - Test multi-tenant data isolation
   - Validate permission enforcement

3. **Performance Testing**
   - Benchmark queries with significant data volume
   - Test common query patterns with timing measurements
   - Verify index efficiency

## Rollout Plan

1. **Staging Deployment**
   - Deploy schema changes to staging environment
   - Verify migration success
   - Run automated tests

2. **Performance Verification**
   - Conduct load testing in staging
   - Verify query performance meets requirements
   - Optimize indexes as needed

3. **Production Deployment**
   - Schedule maintenance window for production migration
   - Create backup before migration
   - Deploy with feature flags to control rollout
   - Monitor database performance after deployment

4. **Monitoring**
   - Set up alerting for slow queries
   - Monitor index usage
   - Track database size growth

## Rollback Strategy

1. **Automatic Rollback Triggers**
   - Define specific error conditions that trigger rollback
   - Establish performance thresholds for rollback decision

2. **Rollback Process**
   - Create down migrations for each phase
   - Test rollback process in staging
   - Document manual rollback steps if needed

## Security Considerations

1. **Data Encryption**
   - Implement field-level encryption for sensitive notes
   - Store encryption keys in AWS KMS
   - Use authenticated encryption (AES-GCM)

2. **Multi-Tenant Isolation**
   - Enforce firm-level isolation in all queries
   - Implement row-level security patterns
   - Add firmId parameter to repository methods

3. **Audit Logging**
   - Ensure comprehensive event capture
   - Implement non-repudiation mechanisms
   - Set up log retention policies

## Post-Deployment Tasks

1. **Schema Documentation**
   - Update data dictionary with new models
   - Document relationships and constraints
   - Create entity-relationship diagrams

2. **Performance Monitoring**
   - Schedule regular query performance reviews
   - Set up alerts for slow-running queries
   - Monitor index usage and optimize as needed

3. **Security Audit**
   - Conduct post-deployment security review
   - Verify encryption implementation
   - Test data isolation effectiveness 