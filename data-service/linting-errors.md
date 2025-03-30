# Linting Errors Report

This document catalogs the linting errors identified in the codebase and suggests approaches to fix them.

## src/services/exportService.ts

### Import Issues
- `createCsvStringifier` is not exported from 'csv-writer'. Use `createArrayCsvStringifier` instead.
- References to repositories are imported both as individual imports and in constructor parameters.
- Missing constants need to be defined (e.g., `EXPORT_STORAGE_PATH`).
- Missing `errorHandler` utility.

### Type Issues
- `Property 'exportJob' does not exist on type 'PrismaClient'`
  - This likely needs a proper model definition in Prisma schema.
- `Duplicate function implementation` for several methods
  - This indicates duplicate method definitions or conflicts in file structure.
- `Property 'parameters' does not exist on type 'ExportJob'`
  - Update the ExportJob interface to include this property.

### PDFDocument Constructor Error
- `This expression is not constructable. Type has no construct signatures.` (line 582)
  - PDFDocument is not being imported correctly
  - Solution: Import PDFDocument correctly following the package documentation

## src/repositories/clientRepository.ts

### MultiTenant Issues
- `Property 'getCurrentTenantId' does not exist on type 'ClientRepository'`
- `Property 'withTenant' does not exist on type 'ClientRepository'`
  - These should be imported functions, not methods of the repository.
- `Property 'client' does not exist on type 'PrismaClient'`
  - This may indicate an issue with the Prisma client types
  - Solution: Update the PrismaClient type or use a dynamic property access pattern

## src/services/analyticsService.ts

### Type Issues
- `Property 'practiceAreaId' does not exist on type TimeEntryFilters`
  - Need to extend the TimeEntryFilters interface to include this property
  - Solution: Update the TimeEntryFilters interface in its model definition
- Various argument type mismatch errors
  - Need to ensure proper typing for arrays and collections.

## Recommended Approach

### 1. Fix Import and Type Definitions
- Create or update the missing utilities (`errorHandler`)
- Ensure proper import of multiTenant context functions
- Update interfaces to include all required properties
- For the PDFDocument issue, ensure proper import syntax: `import PDFDocument from 'pdfkit'` 
  instead of the current import with asterisk

### 2. Prisma Model Issues
- Ensure all Prisma models referenced in code are actually defined in schema.prisma
- Particularly check for `exportJob` model
- Update schema.prisma to include an exportJob model with necessary fields:
  ```prisma
  model ExportJob {
    id        String   @id @default(uuid())
    tenantId  String
    format    String
    dataSource String
    parameters Json
    status    String
    progress  Int      @default(0)
    filePath  String?
    error     String?
    createdAt DateTime @default(now())
    updatedAt DateTime @updatedAt
    expiresAt DateTime?
    userId    String
    
    tenant    Tenant   @relation(fields: [tenantId], references: [id])
    user      User     @relation(fields: [userId], references: [id])
    
    @@index([tenantId])
  }
  ```

### 3. Model Updates
- Update the ExportJob interface in src/models/export.ts:
  ```typescript
  export interface ExportJob {
    id: string;
    tenantId: string;
    format: ExportFormat;
    dataSource: string;
    filters: Record<string, any>;
    parameters: Record<string, any>; // Add this property
    columns: string[];
    name: string;
    status: ExportStatus;
    createdAt: Date;
    progress: number;
    filePath: string;
    error: string | null;
  }
  ```

### 4. Repository Pattern Consistency
- Ensure BaseRepository provides common functionality correctly
- Make sure inheritance and method overrides are properly implemented
- For clientRepository.ts, implement proper dynamic access to Prisma client models:
  ```typescript
  // Use type assertion or dynamic property access
  const clients = await (this.prisma as any).client.findMany({...});
  
  // Or with a better type system:
  interface ExtendedPrismaClient extends PrismaClient {
    client: any; // Or define proper type
  }
  ```

## Testing Approach
After making changes, test systematically:
1. Run the linter to ensure errors are resolved
2. Run unit tests for the affected components
3. Test integration points manually

## Progress So Far
- Fixed duplicate function implementations in exportService.ts
- Added underscore prefixes to unused parameters
- Several linter errors still need to be addressed as outlined above 