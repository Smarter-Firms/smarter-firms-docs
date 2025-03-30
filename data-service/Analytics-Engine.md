# Analytics Engine Documentation

## Overview

The Analytics Engine is the core component of the Data Service responsible for calculating key metrics for law firm performance analysis. It processes raw data from various sources, performs statistical calculations, and generates insights that help law firms make data-driven decisions.

## Implemented KPIs

The following KPIs have been implemented in the latest version:

### Billable Hour Utilization

**Status: Fully Implemented**

- **Definition**: Measures how effectively timekeepers are utilizing their working hours on billable matters.
- **Formula**: `billableHours / totalHours`
- **Calculated For**: Individual timekeepers, teams, practice areas, and firm-wide
- **Target Benchmark**: 75% (configurable)
- **Data Sources**: Time entries with billable status
- **Implementation Details**:
  - Groups time entries by timekeeper
  - Calculates utilization rates for each timekeeper
  - Computes overall firm utilization
  - Generates time-based trend data for visualization
  - Provides practice area breakdown
  - Accounts for different billable statuses (billable, non-billable, no charge)

### Collection Rates

**Status: Fully Implemented**

- **Definition**: Measures the percentage of billed amounts that are collected from clients.
- **Formula**: `collectedAmount / invoicedAmount`
- **Calculated For**: Individual clients, practice areas, and firm-wide
- **Target Benchmark**: 90% (configurable)
- **Data Sources**: Invoices and payment records
- **Implementation Details**:
  - Calculates overall collection rate across the firm
  - Provides client-specific collection metrics
  - Includes aging receivables analysis with customizable buckets
  - Tracks average days to payment 
  - Generates month-by-month collection trends
  - Supports filtering by date ranges and client

### Matter Profitability

**Status: Partially Implemented**

- **Definition**: Measures the profit margin on individual legal matters.
- **Formula**: `(revenue - cost) / revenue`
- **Calculated For**: Individual matters, clients, practice areas, and firm-wide
- **Data Sources**: Time entries, invoices, expenses, and cost allocation
- **Current Limitations**: 
  - Cost tracking needs further development
  - Currently using simplified calculations with mock data for demonstration
  - Full implementation pending cost tracking enhancement

### Client Value Metrics

**Status: Partially Implemented**

- **Definition**: Comprehensive score that evaluates client relationships based on revenue, growth, efficiency, and collection rates.
- **Components**: Revenue, active matters, billable hours, collection rate, longevity
- **Calculated For**: Individual clients
- **Data Sources**: Client records, matters, time entries, invoices
- **Current Limitations**:
  - Currently using simplified calculations with mock data
  - Full implementation pending client relationship metrics

## Data Flow

1. **Data Retrieval**: The Analytics Engine retrieves data from repositories, which provide filtered access to the underlying data store.
2. **Data Processing**: Raw data is processed, aggregated, and transformed into meaningful metrics.
3. **Caching**: Results are cached to improve performance for frequently requested metrics.
4. **Delivery**: Processed metrics are made available through REST APIs.

## Implementation Details

### Service Architecture

The AnalyticsService is the main entry point for analytics calculations. It:

1. Depends on various repositories (TimeEntryRepository, InvoiceRepository, etc.)
2. Uses a multi-tenant approach to ensure data isolation
3. Implements caching for performance optimization
4. Provides detailed metrics with drill-down capabilities

### Core Methods

The Analytics Engine exposes the following primary methods:

```typescript
// Get billable hours metrics with utilization rates
async getBillableHoursMetrics(params: TimeEntryFilters): Promise<BillableHoursMetrics>

// Get collection rate metrics with aging analysis
async getCollectionRateMetrics(params: InvoiceFilters): Promise<CollectionRateMetrics>

// Get matter profitability metrics
async getMatterProfitabilityMetrics(params: MatterFilters): Promise<MatterProfitabilityMetrics>

// Get client value metrics
async getClientValueMetrics(params: ClientFilters): Promise<ClientValueMetrics>

// Get a comprehensive overview dashboard
async getAnalyticsOverview(params: any): Promise<any>
```

### Helper Methods

The engine uses several helper methods for calculations:

- `groupTimeEntriesByTimekeeper()`: Groups time entries for utilization calculation
- `calculateTimekeeperUtilization()`: Calculates utilization metrics per timekeeper
- `calculateUtilizationByPracticeArea()`: Calculates utilization by practice area
- `generateTimeEntryTrend()`: Creates time-series data for time entries
- `groupInvoicesByClient()`: Groups invoices for client-specific metrics
- `calculateClientCollectionMetrics()`: Calculates collection metrics by client
- `generateCollectionTrend()`: Creates time-series data for collections

## API Response Format

### Billable Hours Response

```typescript
{
  totalBillableHours: 1250.5,
  totalNonBillableHours: 420.25,
  utilizationRate: 0.748,
  targetUtilization: 0.75,
  utilizationPercentage: 0.997,
  utilizationByTimekeeper: [
    {
      timekeeperId: "timekeeper-123",
      timekeeperName: "Jane Smith",
      billableHours: 165.5,
      totalHours: 180.0,
      utilization: 0.92,
      percentageOfTarget: 1.23
    },
    // Additional timekeepers...
  ],
  utilizationByPracticeArea: [
    {
      practiceAreaId: "practice-123",
      practiceAreaName: "Corporate",
      billableHours: 725.0,
      totalHours: 950.0,
      utilization: 0.76
    },
    // Additional practice areas...
  ],
  timeEntryTrend: [
    {
      date: "2023-01-01",
      billableHours: 45.5,
      nonBillableHours: 12.0,
      utilization: 0.79
    },
    // Additional trend data points...
  ]
}
```

### Collection Rates Response

```typescript
{
  totalInvoicedAmount: 450000.00,
  totalCollectedAmount: 405000.00,
  overallCollectionRate: 0.90,
  targetCollectionRate: 0.90,
  collectionPercentage: 1.0,
  averageDaysToPayment: 32.5,
  collectionsByClient: [
    {
      clientId: "client-123",
      clientName: "Acme Corporation",
      invoicedAmount: 125000.00,
      collectedAmount: 118750.00,
      collectionRate: 0.95,
      averageDaysToPayment: 28.3
    },
    // Additional clients...
  ],
  agingBuckets: [
    {
      name: "Current",
      amount: 150000.00,
      percentage: 0.33
    },
    {
      name: "1-30 days",
      amount: 125000.00,
      percentage: 0.28
    },
    // Additional aging buckets...
  ],
  collectionTrend: [
    {
      month: "2023-01",
      invoicedAmount: 75000.00,
      collectedAmount: 67500.00,
      collectionRate: 0.90
    },
    // Additional trend data points...
  ]
}
```

## Performance Optimization

The Analytics Engine implements several performance optimization strategies:

1. **Efficient Data Retrieval**: Uses optimized database queries with proper indexing
2. **Caching**: Implements multi-level caching with appropriate TTLs
3. **Lazy Loading**: Loads detailed data only when needed
4. **Batch Processing**: Processes data in efficient batches
5. **Query Optimization**: Minimizes database round-trips

## Future Enhancements

1. **Enhanced Cost Tracking**: Implement more sophisticated cost allocation for better profitability metrics
2. **Predictive Analytics**: Add predictive models for forecasting key metrics
3. **Client Lifecycle Analysis**: Analyze client relationship stages and development
4. **Timekeeper Performance Scoring**: Comprehensive scoring system for timekeeper performance
5. **Industry Benchmarking**: Compare metrics against industry standards

## Usage Examples

### Getting Billable Hours Utilization

```typescript
// Inject the analytics service
const analyticsService = new AnalyticsService(
  timeEntryRepository,
  invoiceRepository,
  matterRepository,
  clientRepository,
  cacheManager
);

// Get utilization metrics for the last 30 days
const startDate = new Date();
startDate.setDate(startDate.getDate() - 30);
const endDate = new Date();

const utilizationMetrics = await analyticsService.getBillableHoursMetrics({
  startDate,
  endDate,
  // Optionally filter by timekeeper, practice area, etc.
});

console.log(`Firm-wide utilization: ${utilizationMetrics.utilizationRate * 100}%`);
console.log(`Top timekeeper: ${utilizationMetrics.utilizationByTimekeeper[0].timekeeperName}`);
```

### Getting Collection Rate Metrics

```typescript
// Get collection metrics for a specific client
const collectionMetrics = await analyticsService.getCollectionRateMetrics({
  clientId: 'client-123',
  startDate: new Date('2023-01-01'),
  endDate: new Date('2023-12-31')
});

console.log(`Collection rate: ${collectionMetrics.overallCollectionRate * 100}%`);
console.log(`Average days to payment: ${collectionMetrics.averageDaysToPayment}`);
``` 