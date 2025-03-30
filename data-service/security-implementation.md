# Security Implementation

## Overview

The Data Service implements comprehensive security measures to protect sensitive customer data. This document describes the security implementation, focusing on field-level encryption, key management, and other security features.

## Field-Level Encryption

### AES-256-GCM Encryption

The system uses AES-256-GCM (Galois/Counter Mode) for field-level encryption of sensitive data:

```javascript
// Encryption service
class EncryptionService {
  constructor(keyProvider) {
    this.keyProvider = keyProvider;
    this.algorithm = 'aes-256-gcm';
  }
  
  // Encrypt data
  async encrypt(data, keyId = null) {
    // Get encryption key
    const key = await this.keyProvider.getEncryptionKey(keyId);
    
    // Generate random IV (16 bytes)
    const iv = crypto.randomBytes(16);
    
    // Create cipher
    const cipher = crypto.createCipheriv(this.algorithm, key.material, iv);
    
    // Get associated data
    const aad = Buffer.from(key.id);
    cipher.setAAD(aad);
    
    // Encrypt data
    let encrypted = cipher.update(typeof data === 'string' ? data : JSON.stringify(data), 'utf8', 'base64');
    encrypted += cipher.final('base64');
    
    // Get auth tag
    const authTag = cipher.getAuthTag();
    
    // Return encrypted data with metadata
    return {
      data: encrypted,
      iv: iv.toString('base64'),
      tag: authTag.toString('base64'),
      keyId: key.id,
      algorithm: this.algorithm
    };
  }
  
  // Decrypt data
  async decrypt(encryptedData) {
    // Validate encrypted data
    if (!encryptedData || !encryptedData.data || !encryptedData.iv || !encryptedData.tag || !encryptedData.keyId) {
      throw new Error('Invalid encrypted data');
    }
    
    // Get decryption key
    const key = await this.keyProvider.getEncryptionKey(encryptedData.keyId);
    
    // Create decipher
    const iv = Buffer.from(encryptedData.iv, 'base64');
    const decipher = crypto.createDecipheriv(this.algorithm, key.material, iv);
    
    // Set auth tag
    decipher.setAuthTag(Buffer.from(encryptedData.tag, 'base64'));
    
    // Get associated data
    const aad = Buffer.from(key.id);
    decipher.setAAD(aad);
    
    // Decrypt data
    let decrypted = decipher.update(encryptedData.data, 'base64', 'utf8');
    decrypted += decipher.final('utf8');
    
    try {
      // Try to parse JSON
      return JSON.parse(decrypted);
    } catch (e) {
      // Return as string if not JSON
      return decrypted;
    }
  }
}
```

### Integration with Prisma

The encryption is integrated with Prisma via middleware:

```javascript
// Prisma middleware for field encryption
prisma.$use(async (params, next) => {
  // Get encryption fields configuration for model
  const encryptionFields = getEncryptionFieldsForModel(params.model);
  
  // If no fields to encrypt, pass through
  if (!encryptionFields || encryptionFields.length === 0) {
    return next(params);
  }
  
  // Handle create/update operations
  if (['create', 'update', 'upsert'].includes(params.action)) {
    // Encrypt fields
    await encryptFields(params, encryptionFields);
  }
  
  // Execute query
  const result = await next(params);
  
  // Handle read operations
  if (['findUnique', 'findFirst', 'findMany'].includes(params.action)) {
    // Decrypt fields
    await decryptFields(result, encryptionFields);
  }
  
  return result;
});

// Function to encrypt fields
async function encryptFields(params, encryptionFields) {
  // Skip if no data
  if (!params.args.data) {
    return;
  }
  
  // Create a copy of data
  const data = { ...params.args.data };
  
  // Encrypt each field
  for (const field of encryptionFields) {
    if (data[field.name] !== undefined && data[field.name] !== null) {
      // Encrypt field value
      const encrypted = await encryptionService.encrypt(data[field.name], field.keyId);
      
      // Replace with encrypted value
      data[field.name] = JSON.stringify(encrypted);
    }
  }
  
  // Update params with encrypted data
  params.args.data = data;
}

// Function to decrypt fields
async function decryptFields(result, encryptionFields) {
  // Skip if no result
  if (!result) {
    return;
  }
  
  // Handle array of results
  if (Array.isArray(result)) {
    for (const item of result) {
      await decryptFieldsInItem(item, encryptionFields);
    }
    return;
  }
  
  // Handle single result
  await decryptFieldsInItem(result, encryptionFields);
}

// Decrypt fields in a single item
async function decryptFieldsInItem(item, encryptionFields) {
  // Decrypt each field
  for (const field of encryptionFields) {
    if (item[field.name] && typeof item[field.name] === 'string') {
      try {
        // Parse encrypted data
        const encrypted = JSON.parse(item[field.name]);
        
        // Decrypt field value
        const decrypted = await encryptionService.decrypt(encrypted);
        
        // Replace with decrypted value
        item[field.name] = decrypted;
      } catch (error) {
        // Log error but continue with other fields
        logger.error(`Failed to decrypt field ${field.name}:`, error);
      }
    }
  }
}
```

## AWS KMS Integration

The system integrates with AWS Key Management Service (KMS) for secure key management:

```javascript
// AWS KMS key provider
class AwsKmsKeyProvider {
  constructor(kms, config) {
    this.kms = kms;
    this.config = config;
    this.keyCache = new Map();
    this.cacheTTL = 3600000; // 1 hour
  }
  
  // Get encryption key by ID
  async getEncryptionKey(keyId = null) {
    // Use current key if no specific key ID provided
    const targetKeyId = keyId || this.config.currentKeyId;
    
    // Check cache
    const cacheKey = `key_${targetKeyId}`;
    const cachedKey = this.keyCache.get(cacheKey);
    
    if (cachedKey && cachedKey.expires > Date.now()) {
      return cachedKey.key;
    }
    
    try {
      // Generate data key
      const response = await this.kms.generateDataKey({
        KeyId: targetKeyId,
        KeySpec: 'AES_256'
      }).promise();
      
      // Extract key material
      const key = {
        id: targetKeyId,
        material: response.Plaintext,
        encryptedMaterial: response.CiphertextBlob,
        created: Date.now()
      };
      
      // Cache key
      this.keyCache.set(cacheKey, {
        key,
        expires: Date.now() + this.cacheTTL
      });
      
      return key;
    } catch (error) {
      logger.error('Failed to get encryption key:', error);
      throw new Error('Could not retrieve encryption key');
    }
  }
  
  // Decrypt encrypted key
  async decryptKey(encryptedKey) {
    try {
      // Decrypt key using KMS
      const response = await this.kms.decrypt({
        CiphertextBlob: encryptedKey
      }).promise();
      
      return response.Plaintext;
    } catch (error) {
      logger.error('Failed to decrypt key:', error);
      throw new Error('Could not decrypt key');
    }
  }
}
```

## Key Rotation

The system implements seamless key rotation without downtime:

```javascript
// Key rotation service
class KeyRotationService {
  constructor(kms, keyProvider, config) {
    this.kms = kms;
    this.keyProvider = keyProvider;
    this.config = config;
  }
  
  // Rotate keys
  async rotateKeys() {
    try {
      // Create new CMK in AWS KMS
      const createKeyResponse = await this.kms.createKey({
        Description: `Data encryption key ${new Date().toISOString()}`,
        KeyUsage: 'ENCRYPT_DECRYPT',
        Origin: 'AWS_KMS'
      }).promise();
      
      const newKeyId = createKeyResponse.KeyMetadata.KeyId;
      
      // Update key configuration
      await this.updateKeyConfiguration(newKeyId);
      
      // Re-encrypt data using new key
      await this.reEncryptData(newKeyId);
      
      return {
        success: true,
        newKeyId,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Key rotation failed:', error);
      
      throw new Error('Key rotation failed');
    }
  }
  
  // Update key configuration
  async updateKeyConfiguration(newKeyId) {
    // Store previous key ID
    const previousKeyId = this.config.currentKeyId;
    
    // Update configuration
    await this.config.update({
      currentKeyId: newKeyId,
      previousKeyId,
      lastRotation: new Date().toISOString()
    });
    
    logger.info('Key configuration updated:', {
      currentKeyId: newKeyId,
      previousKeyId
    });
  }
  
  // Re-encrypt data using new key
  async reEncryptData(newKeyId) {
    // This should be done as a background job for large datasets
    // Here's a simplified version
    
    // Get models with encrypted fields
    const modelsWithEncryption = getModelsWithEncryption();
    
    for (const model of modelsWithEncryption) {
      // Log start of re-encryption
      logger.info(`Starting re-encryption for model: ${model.name}`);
      
      // Get encryption fields
      const encryptionFields = model.encryptionFields;
      
      // Get batch size from config
      const batchSize = this.config.reEncryptionBatchSize || 100;
      let processedCount = 0;
      
      // Process in batches
      let hasMore = true;
      let lastId = null;
      
      while (hasMore) {
        // Get batch of records
        const records = await prisma[model.name].findMany({
          take: batchSize,
          ...(lastId ? {
            cursor: {
              id: lastId
            },
            skip: 1 // Skip the record we already processed
          } : {})
        });
        
        // Check if we have more records
        hasMore = records.length === batchSize;
        
        if (records.length > 0) {
          // Remember last ID for pagination
          lastId = records[records.length - 1].id;
          
          // Process each record
          for (const record of records) {
            try {
              // Process each encrypted field
              for (const field of encryptionFields) {
                if (record[field.name] && typeof record[field.name] === 'string') {
                  try {
                    // Parse encrypted data
                    const encrypted = JSON.parse(record[field.name]);
                    
                    // Decrypt field value
                    const decrypted = await this.keyProvider.decrypt(encrypted);
                    
                    // Re-encrypt with new key
                    const reEncrypted = await this.keyProvider.encrypt(decrypted, newKeyId);
                    
                    // Update record
                    await prisma[model.name].update({
                      where: { id: record.id },
                      data: {
                        [field.name]: JSON.stringify(reEncrypted)
                      }
                    });
                  } catch (fieldError) {
                    logger.error(`Failed to re-encrypt field ${field.name} for record ${record.id}:`, fieldError);
                  }
                }
              }
              
              processedCount++;
            } catch (recordError) {
              logger.error(`Failed to re-encrypt record ${record.id}:`, recordError);
            }
          }
          
          // Log progress
          logger.info(`Re-encryption progress for ${model.name}: ${processedCount} records processed`);
        }
      }
      
      logger.info(`Completed re-encryption for model: ${model.name}, total records: ${processedCount}`);
    }
  }
}
```

## Audit Logging

The system implements comprehensive audit logging for security events:

```javascript
// Audit logging service
class AuditLogger {
  constructor(prisma) {
    this.prisma = prisma;
  }
  
  // Log authentication event
  async logAuthEvent(data) {
    return this.createAuditLog({
      type: 'AUTH',
      ...data
    });
  }
  
  // Log data access event
  async logDataAccess(data) {
    return this.createAuditLog({
      type: 'DATA_ACCESS',
      ...data
    });
  }
  
  // Log encryption event
  async logEncryptionEvent(data) {
    return this.createAuditLog({
      type: 'ENCRYPTION',
      ...data
    });
  }
  
  // Log admin action
  async logAdminAction(data) {
    return this.createAuditLog({
      type: 'ADMIN',
      ...data
    });
  }
  
  // Create audit log entry
  async createAuditLog(data) {
    // Get current user and tenant
    const userId = getCurrentUserId();
    const tenantId = getCurrentTenantId();
    
    // Create log entry
    return this.prisma.auditLog.create({
      data: {
        type: data.type,
        action: data.action,
        userId,
        tenantId,
        resourceType: data.resourceType,
        resourceId: data.resourceId,
        metadata: data.metadata ? JSON.stringify(data.metadata) : null,
        ipAddress: data.ipAddress,
        userAgent: data.userAgent,
        status: data.status || 'SUCCESS',
        timestamp: new Date()
      }
    });
  }
  
  // Query audit logs
  async queryLogs(filters) {
    // Build query
    const query = {
      where: {}
    };
    
    // Apply filters
    if (filters.type) query.where.type = filters.type;
    if (filters.action) query.where.action = filters.action;
    if (filters.userId) query.where.userId = filters.userId;
    if (filters.resourceType) query.where.resourceType = filters.resourceType;
    if (filters.resourceId) query.where.resourceId = filters.resourceId;
    if (filters.status) query.where.status = filters.status;
    if (filters.startDate && filters.endDate) {
      query.where.timestamp = {
        gte: new Date(filters.startDate),
        lte: new Date(filters.endDate)
      };
    }
    
    // Apply pagination
    if (filters.page && filters.pageSize) {
      query.skip = (filters.page - 1) * filters.pageSize;
      query.take = filters.pageSize;
    }
    
    // Apply sorting
    if (filters.sortBy) {
      query.orderBy = {
        [filters.sortBy]: filters.sortDirection || 'desc'
      };
    } else {
      query.orderBy = {
        timestamp: 'desc'
      };
    }
    
    // Get total count
    const totalCount = await this.prisma.auditLog.count({
      where: query.where
    });
    
    // Get logs
    const logs = await this.prisma.auditLog.findMany(query);
    
    return {
      logs,
      totalCount,
      page: filters.page || 1,
      pageSize: filters.pageSize || logs.length,
      pageCount: filters.pageSize ? Math.ceil(totalCount / filters.pageSize) : 1
    };
  }
}
```

## Additional Security Measures

### 1. Transaction Management

The system implements robust transaction management to ensure data integrity:

```javascript
// Transaction wrapper
const withTransaction = async (callback) => {
  // Start transaction
  return prisma.$transaction(async (tx) => {
    // Get current tenant ID
    const tenantId = getCurrentTenantId();
    
    if (tenantId) {
      // Set tenant context for transaction
      await tx.$executeRaw`SELECT set_config('app.tenant_id', ${tenantId}::text, false);`;
    }
    
    // Execute callback with transaction
    return callback(tx);
  }, {
    timeout: 10000 // 10 seconds
  });
};

// Example usage
const createClient = async (data) => {
  return withTransaction(async (tx) => {
    // Create client
    const client = await tx.client.create({
      data: {
        name: data.name,
        email: data.email,
        tenantId: getCurrentTenantId()
      }
    });
    
    // Create related records
    await tx.clientContact.create({
      data: {
        clientId: client.id,
        phoneNumber: data.phoneNumber,
        address: data.address,
        tenantId: getCurrentTenantId()
      }
    });
    
    // Log audit event
    await tx.auditLog.create({
      data: {
        type: 'DATA_CHANGE',
        action: 'CREATE',
        resourceType: 'CLIENT',
        resourceId: client.id,
        userId: getCurrentUserId(),
        tenantId: getCurrentTenantId(),
        timestamp: new Date()
      }
    });
    
    return client;
  });
};
```

### 2. Idempotent Operations

The system implements idempotent operations to prevent duplicate processing:

```javascript
// Idempotency service
class IdempotencyService {
  constructor(prisma) {
    this.prisma = prisma;
    this.keyTTL = 24 * 60 * 60 * 1000; // 24 hours
  }
  
  // Execute idempotent operation
  async execute(idempotencyKey, operation) {
    // Get current tenant ID
    const tenantId = getCurrentTenantId();
    
    // Check for existing key
    const existingKey = await this.prisma.idempotencyKey.findUnique({
      where: {
        key_tenantId: {
          key: idempotencyKey,
          tenantId
        }
      }
    });
    
    if (existingKey) {
      // If completed, return stored result
      if (existingKey.status === 'COMPLETED') {
        return existingKey.result ? JSON.parse(existingKey.result) : null;
      }
      
      // If in progress, throw error
      if (existingKey.status === 'IN_PROGRESS') {
        throw new Error('Operation in progress');
      }
      
      // If failed, allow retry
      if (existingKey.status === 'FAILED') {
        // Update status to in progress
        await this.prisma.idempotencyKey.update({
          where: {
            id: existingKey.id
          },
          data: {
            status: 'IN_PROGRESS',
            updatedAt: new Date()
          }
        });
      }
    } else {
      // Create new key
      await this.prisma.idempotencyKey.create({
        data: {
          key: idempotencyKey,
          tenantId,
          status: 'IN_PROGRESS',
          expiresAt: new Date(Date.now() + this.keyTTL)
        }
      });
    }
    
    try {
      // Execute operation
      const result = await operation();
      
      // Update key with result
      await this.prisma.idempotencyKey.update({
        where: {
          key_tenantId: {
            key: idempotencyKey,
            tenantId
          }
        },
        data: {
          status: 'COMPLETED',
          result: result ? JSON.stringify(result) : null,
          updatedAt: new Date()
        }
      });
      
      return result;
    } catch (error) {
      // Update key with error
      await this.prisma.idempotencyKey.update({
        where: {
          key_tenantId: {
            key: idempotencyKey,
            tenantId
          }
        },
        data: {
          status: 'FAILED',
          error: JSON.stringify({
            message: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
          }),
          updatedAt: new Date()
        }
      });
      
      throw error;
    }
  }
}
```

### 3. Soft Deletes

The system implements soft deletes for data retention:

```javascript
// Prisma middleware for soft deletes
prisma.$use(async (params, next) => {
  // Check if model supports soft delete
  const isSoftDeleteEnabled = modelSupportsSoftDelete(params.model);
  
  if (!isSoftDeleteEnabled) {
    // Pass through for models without soft delete
    return next(params);
  }
  
  // Handle delete operations
  if (params.action === 'delete') {
    // Change action to update
    params.action = 'update';
    params.args.data = {
      deletedAt: new Date(),
      ...params.args.data
    };
  }
  
  if (params.action === 'deleteMany') {
    // Change action to updateMany
    params.action = 'updateMany';
    if (params.args.data !== undefined) {
      params.args.data.deletedAt = new Date();
    } else {
      params.args.data = { deletedAt: new Date() };
    }
  }
  
  // Handle read operations
  if (['findUnique', 'findFirst', 'findMany'].includes(params.action)) {
    // Add filter to exclude soft deleted records
    if (params.args.where) {
      if (params.args.where.deletedAt === undefined) {
        params.args.where.deletedAt = null;
      }
    } else {
      params.args.where = { deletedAt: null };
    }
  }
  
  return next(params);
   });
   ```

### 4. Comprehensive Error Handling

The system implements comprehensive error handling:

```javascript
// Error handler middleware
const errorHandler = (err, req, res, next) => {
  // Log error
  logger.error('API Error:', {
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
    path: req.path,
    method: req.method,
    query: req.query,
    body: req.body,
    userId: req.user?.id,
    tenantId: getCurrentTenantId()
  });
  
  // Handle known error types
  if (err instanceof ValidationError) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: err.message,
      details: err.details,
      requestId: req.id
    });
  }
  
  if (err instanceof AuthorizationError) {
    return res.status(403).json({
      error: 'AUTHORIZATION_ERROR',
      message: err.message,
      requestId: req.id
    });
  }
  
  if (err instanceof NotFoundError) {
    return res.status(404).json({
      error: 'NOT_FOUND',
      message: err.message,
      requestId: req.id
    });
  }
  
  if (err instanceof RateLimitError) {
    return res.status(429).json({
      error: 'RATE_LIMIT_EXCEEDED',
      message: err.message,
      retryAfter: err.retryAfter,
      requestId: req.id
    });
  }
  
  // Generic server error
  res.status(500).json({
    error: 'SERVER_ERROR',
    message: 'An unexpected error occurred',
    requestId: req.id
  });
  
  // Track error metrics
  metrics.increment('api.errors', 1, {
    path: req.path,
    method: req.method,
    errorType: err.constructor.name
  });
};
```

## Best Practices for Developers

### 1. Handling Sensitive Data

Always use the encryption service for sensitive data:

```javascript
// Good: Using encryption service
const storeCard = async (userId, cardData) => {
  // Encrypt sensitive data
  const encryptedCardNumber = await encryptionService.encrypt(cardData.cardNumber);
  const encryptedCvv = await encryptionService.encrypt(cardData.cvv);
  
  // Store with only necessary data in plaintext
  return prisma.paymentMethod.create({
    data: {
      userId,
      tenantId: getCurrentTenantId(),
      type: 'CREDIT_CARD',
      cardBrand: cardData.cardBrand,
      lastFour: cardData.cardNumber.slice(-4),
      expiryMonth: cardData.expiryMonth,
      expiryYear: cardData.expiryYear,
      cardholderName: cardData.cardholderName,
      encryptedCardNumber: JSON.stringify(encryptedCardNumber),
      encryptedCvv: JSON.stringify(encryptedCvv)
    }
  });
};

// Bad: Storing sensitive data without encryption
const storeCardInsecure = async (userId, cardData) => {
  return prisma.paymentMethod.create({
    data: {
      userId,
      tenantId: getCurrentTenantId(),
      type: 'CREDIT_CARD',
      cardBrand: cardData.cardBrand,
      cardNumber: cardData.cardNumber, // BAD: Plaintext sensitive data
      cvv: cardData.cvv, // BAD: Plaintext sensitive data
      expiryMonth: cardData.expiryMonth,
      expiryYear: cardData.expiryYear,
      cardholderName: cardData.cardholderName
    }
  });
};
```

### 2. Proper Transaction Handling

Always use transactions for multi-step operations:

```javascript
// Good: Using transactions
const createMatterWithDocuments = async (matterData, documents) => {
  return withTransaction(async (tx) => {
    // Create matter
    const matter = await tx.matter.create({
      data: {
        title: matterData.title,
        description: matterData.description,
        clientId: matterData.clientId,
        tenantId: getCurrentTenantId()
      }
    });
    
    // Create documents
    for (const doc of documents) {
      await tx.document.create({
        data: {
          name: doc.name,
          fileType: doc.fileType,
          matterId: matter.id,
          tenantId: getCurrentTenantId()
        }
      });
    }
    
    return matter;
  });
};

// Bad: Not using transactions
const createMatterWithDocumentsInsecure = async (matterData, documents) => {
  // Create matter
  const matter = await prisma.matter.create({
    data: {
      title: matterData.title,
      description: matterData.description,
      clientId: matterData.clientId,
      tenantId: getCurrentTenantId()
    }
  });
  
  // If this fails, we'll have a matter without documents
  for (const doc of documents) {
    await prisma.document.create({
      data: {
        name: doc.name,
        fileType: doc.fileType,
        matterId: matter.id,
        tenantId: getCurrentTenantId()
      }
    });
  }
  
  return matter;
};
```

### 3. Audit Logging

Always log sensitive operations:

```javascript
// Good: With audit logging
const updateClientBilling = async (clientId, billingData) => {
  // Update client billing
  const result = await prisma.clientBilling.update({
    where: {
      clientId
    },
    data: billingData
  });
  
  // Log audit event
  await auditLogger.logDataAccess({
    action: 'UPDATE',
    resourceType: 'CLIENT_BILLING',
    resourceId: clientId,
    metadata: {
      fieldsUpdated: Object.keys(billingData)
    },
    ipAddress: getCurrentRequest().ip,
    userAgent: getCurrentRequest().headers['user-agent']
  });
  
  return result;
};

// Bad: Without audit logging
const updateClientBillingInsecure = async (clientId, billingData) => {
  // Update client billing without logging
  return prisma.clientBilling.update({
    where: {
      clientId
    },
    data: billingData
  });
};
```

## References

- [NIST Encryption Standards](https://csrc.nist.gov/publications/detail/sp/800-38d/final)
- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
- [Smarter Firms Security Standards](../security/standards.md) 