# Encryption Key Rotation Strategy

## Overview

This document outlines the key rotation strategy implemented in the Data Service for securely rotating encryption keys without service disruption. Key rotation is a critical security practice that minimizes the impact of potential key compromises while ensuring continuous data availability.

## Key Benefits

1. **Enhanced Security**: Regular key rotation limits the exposure window of any single key
2. **Zero Downtime**: Keys are rotated without service interruption
3. **Audit Trail**: Complete history of key rotations is maintained
4. **Gradual Migration**: Data is re-encrypted in batches to maintain system performance

## Key Management Architecture

### Key Hierarchy

The system uses a hierarchical key management approach with AWS KMS:

```
                 ┌───────────────────┐
                 │   AWS KMS Master  │
                 │   Key (CMK)       │
                 └─────────┬─────────┘
                           │
                           ▼
             ┌─────────────────────────┐
             │  Data Encryption Keys   │
             │  (DEKs)                 │
             └─────────────┬───────────┘
                           │
                           ▼
             ┌─────────────────────────┐
             │  Encrypted Application  │
             │  Data                   │
             └───────────────────────┬─┘
```

1. **Customer Master Key (CMK)**: Managed by AWS KMS, never leaves AWS
2. **Data Encryption Keys (DEKs)**: Generated, encrypted, and stored in our database
3. **Application Data**: Encrypted with DEKs using AES-256-GCM

## Key Rotation Implementation

### KeyRotationService Class

```typescript
// src/services/keyRotationService.ts
import { PrismaClient } from '@prisma/client';
import { KMS } from 'aws-sdk';
import { EncryptionService } from './encryptionService';
import { Logger } from '../utils/logger';

export class KeyRotationService {
  private prisma: PrismaClient;
  private kms: KMS;
  private encryption: EncryptionService;
  private logger: Logger;
  
  constructor() {
    this.prisma = new PrismaClient();
    this.kms = new KMS({
      region: process.env.AWS_REGION || 'us-east-1'
    });
    this.encryption = new EncryptionService();
    this.logger = new Logger('KeyRotationService');
  }
  
  /**
   * Initiate key rotation process
   * @param keyId ID of the key to rotate
   * @param batchSize Number of records to process in each batch
   */
  async rotateKey(keyId: string, batchSize: number = 100): Promise<void> {
    this.logger.info(`Starting key rotation for key ${keyId}`);
    
    // Step 1: Verify old key exists and is active
    const oldKey = await this.prisma.encryptionKey.findUnique({
      where: { id: keyId }
    });
    
    if (!oldKey || oldKey.status !== 'ACTIVE') {
      throw new Error(`Key ${keyId} not found or not active`);
    }
    
    // Step 2: Generate new key
    const { id: newKeyId, key: newKey } = await this.generateNewKey(oldKey.tenantId);
    
    // Step 3: Update database records using both keys
    await this.updateApplicationStatus('KEY_ROTATION_IN_PROGRESS');
    
    try {
      await this.reEncryptData(oldKey.id, newKeyId, batchSize);
      
      // Step 4: After all data is re-encrypted, mark old key as deprecated
      await this.prisma.encryptionKey.update({
        where: { id: oldKey.id },
        data: { status: 'DEPRECATED' }
      });
      
      // Step 5: Log successful rotation
      await this.logKeyRotation(oldKey.id, newKeyId);
      
      this.logger.info(`Key rotation completed successfully from ${oldKey.id} to ${newKeyId}`);
    } catch (error) {
      this.logger.error(`Key rotation failed: ${error.message}`);
      await this.updateApplicationStatus('KEY_ROTATION_FAILED');
      throw error;
    } finally {
      await this.updateApplicationStatus('NORMAL');
    }
  }
  
  /**
   * Generate a new encryption key
   */
  private async generateNewKey(tenantId: string): Promise<{ id: string, key: string }> {
    // Request new key from AWS KMS
    const { CiphertextBlob, Plaintext } = await this.kms.generateDataKey({
      KeyId: process.env.AWS_KMS_KEY_ID,
      KeySpec: 'AES_256'
    }).promise();
    
    // Store encrypted key in database
    const newKey = await this.prisma.encryptionKey.create({
      data: {
        encryptedKey: CiphertextBlob.toString('base64'),
        status: 'ACTIVE',
        createdAt: new Date(),
        version: 1,
        tenantId,
        algorithm: 'AES-256-GCM'
      }
    });
    
    // Return the new key details
    return {
      id: newKey.id,
      key: Plaintext.toString('base64')
    };
  }
  
  /**
   * Re-encrypt data with new key in batches
   */
  private async reEncryptData(oldKeyId: string, newKeyId: string, batchSize: number): Promise<void> {
    let processedCount = 0;
    let hasMoreData = true;
    
    // Get tables with encrypted fields
    const tables = await this.getTablesWithEncryptedFields();
    
    for (const table of tables) {
      const { tableName, encryptedFields } = table;
      
      while (hasMoreData) {
        // Get batch of entities that use the old key
        const entities = await this.prisma[tableName].findMany({
          where: { keyId: oldKeyId },
          take: batchSize,
          skip: processedCount
        });
        
        if (entities.length === 0) {
          hasMoreData = false;
          break;
        }
        
        // Process each entity in batch
        for (const entity of entities) {
          // Decrypt data with old key
          const decryptedData = this.encryption.decryptFields(
            entity, 
            encryptedFields,
            oldKeyId
          );
          
          // Re-encrypt data with new key
          const encryptedData = this.encryption.encryptFields(
            decryptedData,
            encryptedFields,
            newKeyId
          );
          
          // Update entity with re-encrypted data
          await this.prisma[tableName].update({
            where: { id: entity.id },
            data: {
              ...encryptedData,
              keyId: newKeyId,
              updatedAt: new Date()
            }
          });
        }
        
        processedCount += entities.length;
        this.logger.info(`Re-encrypted ${processedCount} records in ${tableName}`);
      }
      
      // Reset for next table
      processedCount = 0;
      hasMoreData = true;
    }
  }
  
  /**
   * Get all tables with encrypted fields
   */
  private async getTablesWithEncryptedFields(): Promise<Array<{ tableName: string, encryptedFields: string[] }>> {
    // This would be configured in the application, but for example:
    return [
      { 
        tableName: 'user', 
        encryptedFields: ['ssn', 'taxId'] 
      },
      { 
        tableName: 'firmConsultantAssociation', 
        encryptedFields: ['contractDetails', 'billingInfo'] 
      },
      // Other tables with encrypted fields
    ];
  }
  
  /**
   * Log key rotation event
   */
  private async logKeyRotation(oldKeyId: string, newKeyId: string): Promise<void> {
    await this.prisma.keyRotationLog.create({
      data: {
        oldKeyId,
        newKeyId,
        rotationDate: new Date(),
        status: 'COMPLETED'
      }
    });
  }
  
  /**
   * Update application status during rotation
   */
  private async updateApplicationStatus(status: string): Promise<void> {
    await this.prisma.systemStatus.update({
      where: { name: 'KEY_ROTATION' },
      data: { status, updatedAt: new Date() }
    });
  }
  
  /**
   * Schedule deletion of old keys (after retention period)
   */
  async scheduleKeyDeletion(keyId: string, retentionDays: number = 90): Promise<void> {
    const deletionDate = new Date();
    deletionDate.setDate(deletionDate.getDate() + retentionDays);
    
    await this.prisma.encryptionKey.update({
      where: { id: keyId },
      data: {
        status: 'SCHEDULED_DELETION',
        scheduledDeletionDate: deletionDate
      }
    });
    
    this.logger.info(`Key ${keyId} scheduled for deletion on ${deletionDate.toISOString()}`);
  }
}
```

## Database Schema

### Encryption Key Management Tables

```sql
-- Encryption Keys Table
CREATE TABLE "EncryptionKey" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "encryptedKey" TEXT NOT NULL,
  "status" TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DEPRECATED', 'SCHEDULED_DELETION', 'DELETED')),
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP,
  "version" INTEGER NOT NULL,
  "tenantId" UUID NOT NULL REFERENCES "Tenant"("id"),
  "algorithm" TEXT NOT NULL DEFAULT 'AES-256-GCM',
  "scheduledDeletionDate" TIMESTAMP,
  "metadata" JSONB
);

-- Key Rotation Logs
CREATE TABLE "KeyRotationLog" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "oldKeyId" UUID NOT NULL REFERENCES "EncryptionKey"("id"),
  "newKeyId" UUID NOT NULL REFERENCES "EncryptionKey"("id"),
  "rotationDate" TIMESTAMP NOT NULL,
  "status" TEXT NOT NULL CHECK (status IN ('STARTED', 'COMPLETED', 'FAILED')),
  "completedAt" TIMESTAMP,
  "error" TEXT
);
```

## Key Rotation Process

### Step-by-Step Rotation Workflow

1. **Initiate Rotation**:
   - Admin calls `rotateKey` with the ID of the current active key
   - System verifies key exists and is active

2. **Generate New Key**:
   - System requests new data encryption key from AWS KMS
   - Encrypted version of key is stored in database with 'ACTIVE' status

3. **Re-encrypt Data**:
   - System processes each table with encrypted fields in batches
   - For each record:
     - Decrypt with old key
     - Re-encrypt with new key
     - Update record with new encrypted data and key reference

4. **Update Key Status**:
   - After all data is re-encrypted, old key is marked as 'DEPRECATED'
   - System logs successful rotation

5. **Schedule Key Deletion**:
   - After retention period (default 90 days), old key is scheduled for deletion
   - Key status changes to 'SCHEDULED_DELETION'

### Automatic Rotation Schedule

Keys are rotated on the following schedule:

1. **Regular Rotation**: Every 90 days for all tenant keys
2. **Emergency Rotation**: Immediately if key compromise is suspected
3. **Tenant Offboarding**: When a tenant is removed from the system

## API Interface

### Key Rotation API

The key rotation service is exposed through a secure admin API:

```typescript
// src/controllers/keyManagementController.ts

/**
 * Initiate key rotation for a tenant
 */
async rotateKeyForTenant(req: Request, res: Response): Promise<void> {
  try {
    const { tenantId } = req.params;
    const { batchSize } = req.body;
    
    // Find current active key
    const currentKey = await this.prisma.encryptionKey.findFirst({
      where: {
        tenantId,
        status: 'ACTIVE'
      },
      orderBy: {
        createdAt: 'desc'
      }
    });
    
    if (!currentKey) {
      res.status(404).json({ error: 'No active key found for tenant' });
      return;
    }
    
    // Start rotation in background
    this.keyRotationService.rotateKey(currentKey.id, batchSize)
      .catch(error => {
        this.logger.error(`Background key rotation failed: ${error.message}`);
      });
    
    res.status(202).json({ 
      message: 'Key rotation initiated',
      rotationId: uuidv4(),
      oldKeyId: currentKey.id
    });
  } catch (error) {
    this.logger.error(`Key rotation API error: ${error.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
}

/**
 * Get key rotation status
 */
async getKeyRotationStatus(req: Request, res: Response): Promise<void> {
  try {
    const status = await this.prisma.systemStatus.findUnique({
      where: { name: 'KEY_ROTATION' }
    });
    
    res.status(200).json({
      status: status?.status || 'NORMAL',
      updatedAt: status?.updatedAt
    });
  } catch (error) {
    this.logger.error(`Get rotation status error: ${error.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
}
```

## Error Handling and Recovery

### Handling Rotation Failures

If rotation fails:

1. System status is set to `KEY_ROTATION_FAILED`
2. Both keys remain active
3. Error is logged to `KeyRotationLog` table
4. Notification is sent to administrators
5. Manual remediation may be required

### Recovery Process

To recover from a failed rotation:

1. Fix the underlying issue (e.g., AWS connectivity)
2. Resume rotation from the last successful batch
3. Monitor progress closely
4. Verify all data is correctly re-encrypted

## Monitoring and Alerts

### Key Rotation Metrics

The following metrics are recorded during rotation:

1. **Rotation Duration**: Total time taken for rotation
2. **Records Processed**: Number of records re-encrypted
3. **Batch Processing Time**: Time taken per batch
4. **Error Rate**: Percentage of records that failed re-encryption

### Alerts Configuration

Alerts are triggered for:

1. **Rotation Start/Complete**: Notification when rotation begins and completes
2. **Rotation Failure**: Immediate alert if rotation fails
3. **Long-Running Rotation**: Alert if rotation exceeds expected duration
4. **Key Expiration**: Warning when keys approach scheduled deletion

## Best Practices

1. **Regular Rotation Schedule**:
   - Establish a regular key rotation schedule (e.g., quarterly)
   - Document the rotation schedule and procedures

2. **Testing and Validation**:
   - Test key rotation in lower environments before production
   - Validate data integrity after rotation

3. **Performance Considerations**:
   - Schedule rotations during off-peak hours
   - Adjust batch size based on database performance
   - Monitor system performance during rotation

4. **Audit and Compliance**:
   - Maintain detailed logs of all key operations
   - Ensure rotation schedule meets compliance requirements
   - Regularly review key access patterns

5. **Emergency Procedures**:
   - Document emergency rotation procedures
   - Train team members on emergency rotation
   - Regularly test emergency rotation scenarios 