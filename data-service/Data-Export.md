# Data Export Documentation

## Overview

The Data Export system enables users to export data from the Smarter Firms platform in various formats for external analysis, reporting, and integration with other systems. The system handles exports asynchronously to allow for large data sets and complex transformations.

## Supported Export Formats

- **CSV (Comma-Separated Values)**: Simple tabular format compatible with spreadsheet applications and data analysis tools
- **Excel (.xlsx)**: Microsoft Excel format with formatting, multiple sheets, and advanced features
- **PDF**: Formatted document suitable for presentation and sharing

## Export Process Flow

1. **Export Request:**
   - User submits an export request via the API
   - Request specifies data source, filters, and format
   - System validates the request and creates an export job

2. **Background Processing:**
   - Export job is queued for asynchronous processing
   - System fetches data based on specified parameters
   - Data is transformed into the requested format
   - Generated file is stored temporarily for retrieval

3. **Status Tracking:**
   - User can check export status via the API
   - Status updates include progress indicators
   - System provides estimated completion time

4. **Download:**
   - When export is complete, a download link is provided
   - Link is valid for a limited time (24 hours by default)
   - System handles secure access to the generated file

## Implementation Details

### Export Service

The `ExportService` is responsible for managing the export process:

- `createExport()`: Creates a new export job and queues it for processing
- `getExportStatus()`: Retrieves the current status of an export job
- `getExportDownloadUrl()`: Generates a secure download URL for completed exports
- `processExportJob()`: Processes the export job (data retrieval, transformation, file generation)

### Export Job Management

Export jobs are tracked throughout the process:

- **Export ID**: Unique identifier for tracking the export
- **Status**: Current state of the export (pending, processing, completed, failed)
- **Parameters**: Data source and filters used for the export
- **File Path**: Location of the generated file (when completed)
- **Expiration**: Time when the export file will be deleted

### Data Sources

The system supports exporting data from various sources:

- **Matters**: Matter details, status, practice area, responsible attorneys
- **Clients**: Client information, contact details, matter history
- **Timekeepers**: Timekeeper profiles, rates, specialties
- **Time Entries**: Billable and non-billable time records
- **Invoices**: Invoice details, line items, payment status
- **Analytics**: Processed analytics data for specific metrics

### Security Considerations

- **Tenant Isolation**: All exports are scoped to the user's tenant
- **Permission Checking**: Access to data sources is validated before processing
- **Secure Storage**: Export files are stored securely with tenant isolation
- **Secure Downloads**: Download URLs are signed and time-limited
- **Automatic Cleanup**: Expired export files are automatically deleted

## API Endpoints

### Create Export

```
POST /api/v1/export/{format}
```

- Formats: `csv`, `excel`, `pdf`
- Body: Data source and filter parameters
- Returns: Export job ID and status information

### Check Export Status

```
GET /api/v1/export/status/{exportId}
```

- Returns: Current status, progress information, and download URL (if completed)

### Download Export File

```
GET /api/v1/export/download/{exportId}
```

- Returns: The exported file with appropriate content-type

## Example Usage

### Request CSV Export

```javascript
// Request export of timekeeper data
fetch('/api/v1/export/csv', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-tenant-id': 'tenant-uuid'
  },
  body: JSON.stringify({
    dataSource: 'timekeepers',
    practiceAreaId: 'practice-area-uuid',
    activeOnly: true
  })
})
.then(response => response.json())
.then(data => {
  const exportId = data.data.exportId;
  // Use exportId to check status later
});
```

### Check Export Status

```javascript
// Check status of an export
fetch(`/api/v1/export/status/${exportId}`, {
  headers: {
    'x-tenant-id': 'tenant-uuid'
  }
})
.then(response => response.json())
.then(data => {
  if (data.data.status === 'completed') {
    // Download is ready
    window.location.href = data.data.downloadUrl;
  }
});
```

## Performance Considerations

- **Chunked Processing**: Large data sets are processed in chunks to minimize memory usage
- **Progress Tracking**: Export progress is tracked and reported
- **Storage Optimization**: Temporary files are stored efficiently and cleaned up automatically
- **Rate Limiting**: Export requests are rate-limited to prevent system overload
- **Resource Allocation**: Background processing uses dedicated resources to avoid impacting application performance

## Error Handling

- **Validation Errors**: Invalid export requests return immediate error responses
- **Processing Errors**: Errors during processing are logged and reflected in export status
- **Retries**: Transient failures are automatically retried with exponential backoff
- **Partial Exports**: When possible, partial exports are provided with error information

## Limitations

- **Maximum Size**: There are limits on the maximum size of exports (configurable)
- **Timeout**: Long-running exports that exceed the timeout will be marked as failed
- **Rate Limits**: Users are limited to a certain number of export requests per time period
- **Retention Period**: Export files are retained for a limited time (24 hours by default) 