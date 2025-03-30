# Data Versioning

## Overview

The Data Service implements a comprehensive versioning system to track changes to critical data over time. This document outlines the implementation details of the versioning system, including how changes are tracked, stored, and retrieved.

## Versioning Implementation

### Version Table Structure

Each versioned entity has a corresponding versions table that stores the complete history of changes:

```typescript
// Example Prisma schema for Matter and MatterVersion
model Matter {
  id                String              @id @default(uuid())
  title             String
  description       String?
  status            MatterStatus        @default(ACTIVE)
  clientId          String
  client            Client              @relation(fields: [clientId], references: [id])
  createdAt         DateTime            @default(now())
  updatedAt         DateTime            @updatedAt
  tenantId          String
  currentVersionId  String?
  currentVersion    MatterVersion?      @relation("CurrentVersion", fields: [currentVersionId], references: [id])
  versions          MatterVersion[]     @relation("AllVersions")
  
  @@index([tenantId])
  @@index([clientId])
}

model MatterVersion {
  id                String              @id @default(uuid())
  matterId          String
  matter            Matter              @relation("AllVersions", fields: [matterId], references: [id])
  title             String
  description       String?
  status            MatterStatus
  clientId          String
  versionNumber     Int
  createdAt         DateTime            @default(now())
  createdById       String
  createdBy         User                @relation(fields: [createdById], references: [id])
  changeReason      String?
  tenantId          String
  currentVersionOf  Matter?             @relation("CurrentVersion")
  
  @@unique([matterId, versionNumber])
  @@index([tenantId])
}
```

### Versioning Service

The core versioning functionality is implemented in a `VersioningService`:

```javascript
// Versioning service
class VersioningService {
  constructor(prisma, userContext) {
    this.prisma = prisma;
    this.userContext = userContext;
  }
  
  // Create initial version
  async createInitialVersion(entityName, entityId, data) {
    const userId = this.userContext.getCurrentUserId();
    const tenantId = this.userContext.getCurrentTenantId();
    
    // Validate entity support
    this.validateEntitySupport(entityName);
    
    // Create version record
    const versionData = {
      [`${entityName}Id`]: entityId,
      ...data,
      versionNumber: 1,
      createdById: userId,
      tenantId,
      changeReason: 'Initial creation'
    };
    
    // Create version
    const version = await this.prisma[`${entityName}Version`].create({
      data: versionData
    });
    
    // Update entity with current version
    await this.prisma[entityName].update({
      where: { id: entityId },
      data: { currentVersionId: version.id }
    });
    
    return version;
  }
  
  // Create new version
  async createNewVersion(entityName, entityId, data, changeReason) {
    const userId = this.userContext.getCurrentUserId();
    const tenantId = this.userContext.getCurrentTenantId();
    
    // Validate entity support
    this.validateEntitySupport(entityName);
    
    // Get latest version number
    const latestVersion = await this.prisma[`${entityName}Version`].findFirst({
      where: {
        [`${entityName}Id`]: entityId,
        tenantId
      },
      orderBy: {
        versionNumber: 'desc'
      }
    });
    
    if (!latestVersion) {
      throw new Error(`No existing versions found for ${entityName} with ID ${entityId}`);
    }
    
    // Create version data
    const versionData = {
      [`${entityName}Id`]: entityId,
      ...data,
      versionNumber: latestVersion.versionNumber + 1,
      createdById: userId,
      tenantId,
      changeReason: changeReason || 'Update'
    };
    
    // Create version
    const version = await this.prisma[`${entityName}Version`].create({
      data: versionData
    });
    
    // Update entity with current version
    await this.prisma[entityName].update({
      where: { id: entityId },
      data: { currentVersionId: version.id }
    });
    
    return version;
  }
  
  // Get version history
  async getVersionHistory(entityName, entityId, options = {}) {
    const tenantId = this.userContext.getCurrentTenantId();
    
    // Validate entity support
    this.validateEntitySupport(entityName);
    
    // Build query
    const query = {
      where: {
        [`${entityName}Id`]: entityId,
        tenantId
      },
      orderBy: {
        versionNumber: 'desc'
      },
      include: {
        createdBy: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      }
    };
    
    // Apply pagination
    if (options.page && options.pageSize) {
      query.skip = (options.page - 1) * options.pageSize;
      query.take = options.pageSize;
    }
    
    // Get versions
    const versions = await this.prisma[`${entityName}Version`].findMany(query);
    
    // Get total count
    const totalCount = await this.prisma[`${entityName}Version`].count({
      where: query.where
    });
    
    return {
      versions,
      totalCount,
      page: options.page || 1,
      pageSize: options.pageSize || versions.length,
      pageCount: options.pageSize ? Math.ceil(totalCount / options.pageSize) : 1
    };
  }
  
  // Get specific version
  async getVersion(entityName, entityId, versionNumber) {
    const tenantId = this.userContext.getCurrentTenantId();
    
    // Validate entity support
    this.validateEntitySupport(entityName);
    
    return this.prisma[`${entityName}Version`].findUnique({
      where: {
        [`${entityName}Id_versionNumber`]: {
          [`${entityName}Id`]: entityId,
          versionNumber
        },
        tenantId
      },
      include: {
        createdBy: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      }
    });
  }
  
  // Restore version
  async restoreVersion(entityName, entityId, versionNumber, restorationReason) {
    const userId = this.userContext.getCurrentUserId();
    const tenantId = this.userContext.getCurrentTenantId();
    
    // Validate entity support
    this.validateEntitySupport(entityName);
    
    // Find version to restore
    const versionToRestore = await this.prisma[`${entityName}Version`].findUnique({
      where: {
        [`${entityName}Id_versionNumber`]: {
          [`${entityName}Id`]: entityId,
          versionNumber
        },
        tenantId
      }
    });
    
    if (!versionToRestore) {
      throw new Error(`Version ${versionNumber} not found for ${entityName} with ID ${entityId}`);
    }
    
    // Get latest version number
    const latestVersion = await this.prisma[`${entityName}Version`].findFirst({
      where: {
        [`${entityName}Id`]: entityId,
        tenantId
      },
      orderBy: {
        versionNumber: 'desc'
      }
    });
    
    // Extract data to restore (excluding metadata fields)
    const dataToRestore = { ...versionToRestore };
    
    // Remove metadata fields
    delete dataToRestore.id;
    delete dataToRestore[`${entityName}Id`];
    delete dataToRestore.versionNumber;
    delete dataToRestore.createdAt;
    delete dataToRestore.createdById;
    delete dataToRestore.changeReason;
    delete dataToRestore.tenantId;
    
    // Create restoration version data
    const versionData = {
      [`${entityName}Id`]: entityId,
      ...dataToRestore,
      versionNumber: latestVersion.versionNumber + 1,
      createdById: userId,
      tenantId,
      changeReason: restorationReason || `Restored from version ${versionNumber}`
    };
    
    // Create new version
    const version = await this.prisma[`${entityName}Version`].create({
      data: versionData
    });
    
    // Update entity with current version and restored data
    await this.prisma[entityName].update({
      where: { id: entityId },
      data: {
        ...dataToRestore,
        currentVersionId: version.id
      }
    });
    
    return version;
  }
  
  // Compare versions
  async compareVersions(entityName, entityId, versionNumber1, versionNumber2) {
    const tenantId = this.userContext.getCurrentTenantId();
    
    // Validate entity support
    this.validateEntitySupport(entityName);
    
    // Get version 1
    const version1 = await this.prisma[`${entityName}Version`].findUnique({
      where: {
        [`${entityName}Id_versionNumber`]: {
          [`${entityName}Id`]: entityId,
          versionNumber: versionNumber1
        },
        tenantId
      }
    });
    
    if (!version1) {
      throw new Error(`Version ${versionNumber1} not found for ${entityName} with ID ${entityId}`);
    }
    
    // Get version 2
    const version2 = await this.prisma[`${entityName}Version`].findUnique({
      where: {
        [`${entityName}Id_versionNumber`]: {
          [`${entityName}Id`]: entityId,
          versionNumber: versionNumber2
        },
        tenantId
      }
    });
    
    if (!version2) {
      throw new Error(`Version ${versionNumber2} not found for ${entityName} with ID ${entityId}`);
    }
    
    // Compare versions
    const differences = {};
    const ignoredFields = ['id', 'createdAt', 'createdById', 'versionNumber', 'changeReason', 'tenantId'];
    
    for (const key in version1) {
      if (!ignoredFields.includes(key) && key !== `${entityName}Id`) {
        if (JSON.stringify(version1[key]) !== JSON.stringify(version2[key])) {
          differences[key] = {
            from: version1[key],
            to: version2[key]
          };
        }
      }
    }
    
    return {
      version1: {
        versionNumber: version1.versionNumber,
        createdAt: version1.createdAt,
        changeReason: version1.changeReason
      },
      version2: {
        versionNumber: version2.versionNumber,
        createdAt: version2.createdAt,
        changeReason: version2.changeReason
      },
      differences
    };
  }
  
  // Validate entity support
  validateEntitySupport(entityName) {
    const supportedEntities = this.getSupportedEntities();
    
    if (!supportedEntities.includes(entityName)) {
      throw new Error(`Versioning is not supported for entity type: ${entityName}`);
    }
  }
  
  // Get supported entities
  getSupportedEntities() {
    return [
      'Matter',
      'Client',
      'Document',
      'Contract',
      'Invoice'
    ];
  }
}
```

## Repository Integration

The versioning system is integrated with the repository layer:

```javascript
// Example Matter repository with versioning support
class MatterRepository {
  constructor(prisma, versioningService) {
    this.prisma = prisma;
    this.versioningService = versioningService;
  }
  
  // Create matter with versioning
  async create(data) {
    const tenantId = getCurrentTenantId();
    
    // Start transaction
    return this.prisma.$transaction(async (tx) => {
      // Create matter
      const matter = await tx.matter.create({
        data: {
          title: data.title,
          description: data.description,
          status: data.status || 'ACTIVE',
          clientId: data.clientId,
          tenantId
        }
      });
      
      // Create initial version
      await this.versioningService.createInitialVersion('Matter', matter.id, {
        title: matter.title,
        description: matter.description,
        status: matter.status,
        clientId: matter.clientId
      });
      
      return matter;
    });
  }
  
  // Update matter with versioning
  async update(id, data, changeReason) {
    const tenantId = getCurrentTenantId();
    
    // Start transaction
    return this.prisma.$transaction(async (tx) => {
      // Update matter
      const matter = await tx.matter.update({
        where: { id },
        data: {
          ...data,
          tenantId
        }
      });
      
      // Create new version
      await this.versioningService.createNewVersion('Matter', matter.id, {
        title: matter.title,
        description: matter.description,
        status: matter.status,
        clientId: matter.clientId
      }, changeReason);
      
      return matter;
    });
  }
  
  // Get matter version history
  async getVersionHistory(id, options) {
    return this.versioningService.getVersionHistory('Matter', id, options);
  }
  
  // Get specific matter version
  async getVersion(id, versionNumber) {
    return this.versioningService.getVersion('Matter', id, versionNumber);
  }
  
  // Restore matter version
  async restoreVersion(id, versionNumber, restorationReason) {
    return this.versioningService.restoreVersion('Matter', id, versionNumber, restorationReason);
  }
  
  // Compare matter versions
  async compareVersions(id, versionNumber1, versionNumber2) {
    return this.versioningService.compareVersions('Matter', id, versionNumber1, versionNumber2);
  }
}
```

## API Endpoints

The versioning functionality is exposed through API endpoints:

```javascript
// Example versioning controller
class VersioningController {
  constructor(versioningService) {
    this.versioningService = versioningService;
  }
  
  // Get version history
  async getVersionHistory(req, res) {
    const { entityName, entityId } = req.params;
    const { page, pageSize } = req.query;
    
    try {
      const result = await this.versioningService.getVersionHistory(entityName, entityId, {
        page: page ? parseInt(page) : undefined,
        pageSize: pageSize ? parseInt(pageSize) : undefined
      });
      
      res.json(result);
    } catch (error) {
      res.status(400).json({
        error: 'VERSIONING_ERROR',
        message: error.message
      });
    }
  }
  
  // Get specific version
  async getVersion(req, res) {
    const { entityName, entityId, versionNumber } = req.params;
    
    try {
      const version = await this.versioningService.getVersion(entityName, entityId, parseInt(versionNumber));
      
      if (!version) {
        return res.status(404).json({
          error: 'VERSION_NOT_FOUND',
          message: `Version ${versionNumber} not found for ${entityName} with ID ${entityId}`
        });
      }
      
      res.json(version);
    } catch (error) {
      res.status(400).json({
        error: 'VERSIONING_ERROR',
        message: error.message
      });
    }
  }
  
  // Restore version
  async restoreVersion(req, res) {
    const { entityName, entityId, versionNumber } = req.params;
    const { restorationReason } = req.body;
    
    try {
      const version = await this.versioningService.restoreVersion(
        entityName,
        entityId,
        parseInt(versionNumber),
        restorationReason
      );
      
      res.json({
        success: true,
        message: `Successfully restored ${entityName} to version ${versionNumber}`,
        version
      });
    } catch (error) {
      res.status(400).json({
        error: 'VERSIONING_ERROR',
        message: error.message
      });
    }
  }
  
  // Compare versions
  async compareVersions(req, res) {
    const { entityName, entityId } = req.params;
    const { versionNumber1, versionNumber2 } = req.query;
    
    if (!versionNumber1 || !versionNumber2) {
      return res.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Both versionNumber1 and versionNumber2 are required'
      });
    }
    
    try {
      const comparison = await this.versioningService.compareVersions(
        entityName,
        entityId,
        parseInt(versionNumber1),
        parseInt(versionNumber2)
      );
      
      res.json(comparison);
    } catch (error) {
      res.status(400).json({
        error: 'VERSIONING_ERROR',
        message: error.message
      });
    }
  }
}

// Register routes
app.get('/api/v1/versions/:entityName/:entityId', versioningController.getVersionHistory.bind(versioningController));
app.get('/api/v1/versions/:entityName/:entityId/:versionNumber', versioningController.getVersion.bind(versioningController));
app.post('/api/v1/versions/:entityName/:entityId/:versionNumber/restore', versioningController.restoreVersion.bind(versioningController));
app.get('/api/v1/versions/:entityName/:entityId/compare', versioningController.compareVersions.bind(versioningController));
```

## Versioning UI Components

The system includes UI components for interacting with versions:

```javascript
// React component for version history
const VersionHistory = ({ entityName, entityId }) => {
  const [versions, setVersions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({
    page: 1,
    pageSize: 10,
    totalCount: 0,
    pageCount: 0
  });
  
  useEffect(() => {
    loadVersions();
  }, [entityName, entityId, pagination.page]);
  
  const loadVersions = async () => {
    setLoading(true);
    
    try {
      const response = await api.get(`/api/v1/versions/${entityName}/${entityId}`, {
        params: {
          page: pagination.page,
          pageSize: pagination.pageSize
        }
      });
      
      setVersions(response.data.versions);
      setPagination({
        page: response.data.page,
        pageSize: response.data.pageSize,
        totalCount: response.data.totalCount,
        pageCount: response.data.pageCount
      });
    } catch (error) {
      console.error('Failed to load versions:', error);
      notifications.error('Failed to load version history');
    } finally {
      setLoading(false);
    }
  };
  
  const handlePageChange = (page) => {
    setPagination({
      ...pagination,
      page
    });
  };
  
  const handleRestore = async (versionNumber) => {
    const confirmed = await confirmDialog.show({
      title: 'Restore Version',
      message: `Are you sure you want to restore version ${versionNumber}? This will create a new version based on the selected version's data.`,
      confirmLabel: 'Restore',
      cancelLabel: 'Cancel'
    });
    
    if (!confirmed) {
      return;
    }
    
    try {
      const reason = await promptDialog.show({
        title: 'Restoration Reason',
        message: 'Please provide a reason for restoring this version:',
        defaultValue: `Restored from version ${versionNumber}`
      });
      
      if (!reason) {
        return;
      }
      
      const response = await api.post(`/api/v1/versions/${entityName}/${entityId}/${versionNumber}/restore`, {
        restorationReason: reason
      });
      
      notifications.success('Version restored successfully');
      loadVersions();
    } catch (error) {
      console.error('Failed to restore version:', error);
      notifications.error('Failed to restore version');
    }
  };
  
  const handleCompare = async (versionNumber) => {
    // Implementation for version comparison
  };
  
  return (
    <div className="version-history">
      <h2>Version History</h2>
      
      {loading ? (
        <div className="loading">Loading versions...</div>
      ) : (
        <>
          <table className="version-table">
            <thead>
              <tr>
                <th>Version</th>
                <th>Date</th>
                <th>User</th>
                <th>Reason</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {versions.map((version) => (
                <tr key={version.id}>
                  <td>{version.versionNumber}</td>
                  <td>{formatDate(version.createdAt)}</td>
                  <td>{version.createdBy.name}</td>
                  <td>{version.changeReason}</td>
                  <td>
                    <button onClick={() => handleRestore(version.versionNumber)}>
                      Restore
                    </button>
                    <button onClick={() => handleCompare(version.versionNumber)}>
                      Compare
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          <div className="pagination">
            <button
              disabled={pagination.page === 1}
              onClick={() => handlePageChange(pagination.page - 1)}
            >
              Previous
            </button>
            <span>
              Page {pagination.page} of {pagination.pageCount}
            </span>
            <button
              disabled={pagination.page === pagination.pageCount}
              onClick={() => handlePageChange(pagination.page + 1)}
            >
              Next
            </button>
          </div>
        </>
      )}
    </div>
  );
};
```

## Performance Considerations

### Optimizing Version Storage

For large datasets, consider these optimizations:

1. **Delta Storage**: For large text fields, consider storing only the differences between versions rather than complete copies.

2. **Partitioning**: Use table partitioning for version tables to improve query performance on large datasets.

3. **Compression**: Use database compression for version tables to reduce storage requirements.

4. **Archiving**: Implement an archiving strategy for very old versions to maintain performance.

### Query Optimization

1. **Indexing**: Ensure appropriate indexes on version tables:

```sql
-- Essential indexes for version tables
CREATE INDEX idx_matter_version_matter_id ON "MatterVersion" ("matterId");
CREATE INDEX idx_matter_version_created_at ON "MatterVersion" ("createdAt");
CREATE INDEX idx_matter_version_created_by_id ON "MatterVersion" ("createdById");
```

2. **Pagination**: Always use pagination when querying version history to limit result sets.

3. **Selective Retrieval**: Use projection to retrieve only needed fields when querying versions.

## Best Practices for Developers

### 1. When to Create Versions

Create versions in these scenarios:

```javascript
// 1. After significant content changes
await matterRepository.update(matterId, updatedData, 'Updated matter details');

// 2. After status changes
await matterRepository.update(matterId, { status: 'CLOSED' }, 'Closed matter');

// 3. After ownership changes
await matterRepository.update(matterId, { assignedAttorneyId: newAttorneyId }, 'Reassigned matter');

// 4. After relationship changes
await matterRepository.update(matterId, { clientId: newClientId }, 'Transferred to new client');
```

### 2. Providing Meaningful Change Reasons

Always provide clear, specific change reasons:

```javascript
// Good: Specific reason
await matterRepository.update(matterId, updatedData, 'Updated case strategy after client meeting');

// Bad: Vague reason
await matterRepository.update(matterId, updatedData, 'Updated');
```

### 3. Working with Large Datasets

For entities with many versions:

```javascript
// Good: Use pagination
const versionHistory = await matterRepository.getVersionHistory(matterId, {
  page: 1,
  pageSize: 25
});

// Bad: No pagination
const allVersions = await matterRepository.getVersionHistory(matterId);
```

### 4. Handling Version Restoration

Always confirm before restoring versions:

```javascript
// Good: With confirmation and reason
async function restoreWithConfirmation(matterId, versionNumber) {
  const confirmed = await confirmDialog.show({
    title: 'Restore Version',
    message: `Are you sure you want to restore version ${versionNumber}?`
  });
  
  if (confirmed) {
    const reason = await promptDialog.show({
      title: 'Restoration Reason',
      message: 'Please provide a reason for restoring this version:'
    });
    
    if (reason) {
      await matterRepository.restoreVersion(matterId, versionNumber, reason);
    }
  }
}

// Bad: No confirmation
async function restoreWithoutConfirmation(matterId, versionNumber) {
  await matterRepository.restoreVersion(matterId, versionNumber);
}
```

## References

- [Git Version Control Concepts](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository)
- [Database Temporal Tables](https://docs.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables)
- [Smarter Firms Data Management Guidelines](../data-management/guidelines.md)
``` 