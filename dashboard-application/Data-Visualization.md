# Data Visualization

This document describes the data visualization components used in the Dashboard Application, including the chart types, implementation details, and best practices.

## Visualization Library

The Dashboard Application uses Chart.js with the React-Chartjs-2 wrapper for creating interactive data visualizations. This combination provides:

- **Performance**: Optimized rendering performance for large datasets
- **Responsiveness**: Charts that automatically adapt to different screen sizes
- **Accessibility**: Built-in accessibility features for screen readers
- **Animation**: Smooth animations and transitions
- **Customization**: Extensive customization options for appearance and behavior

## Chart Components

### Base Chart Components

The application implements the following base chart components:

1. **LineChart**: For visualizing trends over time
2. **BarChart**: For comparing values across categories
3. **PieChart**: For showing composition and part-to-whole relationships
4. **DoughnutChart**: Similar to pie charts but with a center area for additional information
5. **ScatterChart**: For showing relationships between variables
6. **AreaChart**: For emphasizing volume beneath trend lines

Each chart component follows a consistent API pattern:

```tsx
interface ChartProps<T> {
  data: T[];
  xKey: keyof T | ((item: T) => string | number);
  yKey: keyof T | ((item: T) => number);
  title?: string;
  subtitle?: string;
  height?: number;
  width?: number;
  options?: ChartOptions<'line' | 'bar' | 'pie' | etc.>;
  className?: string;
  onDataPointClick?: (dataPoint: T, index: number) => void;
}

// Example usage
<LineChart
  data={revenueData}
  xKey="date"
  yKey="value"
  title="Monthly Revenue"
  height={300}
  options={{
    plugins: {
      tooltip: {
        callbacks: {
          label: (context) => `$${context.formattedValue}`,
        },
      },
    },
  }}
  onDataPointClick={(dataPoint) => showDetailedView(dataPoint)}
/>
```

### Higher-Level Chart Components

Built on top of the base components, these higher-level components handle specific visualization needs:

1. **TimeSeriesChart**: Specialized for time-based data with proper date formatting
2. **ComparisonChart**: For comparing values across different time periods or categories
3. **DistributionChart**: For visualizing distributions of values
4. **MetricTrendChart**: For visualizing KPI trends with indicators for increase/decrease
5. **StackedBarChart**: For showing part-to-whole relationships across categories

Example implementation:

```tsx
const TimeSeriesChart: React.FC<TimeSeriesChartProps> = ({
  data,
  dateKey,
  valueKey,
  title,
  ...restProps
}) => {
  // Process data for proper date formatting
  const formattedData = useMemo(() => {
    return data.map(item => ({
      ...item,
      formattedDate: format(new Date(item[dateKey]), 'MMM dd, yyyy')
    }));
  }, [data, dateKey]);
  
  // Configure chart options
  const options: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      x: {
        type: 'time',
        time: {
          unit: 'month',
          tooltipFormat: 'MMM dd, yyyy',
        },
        title: {
          display: true,
          text: 'Date',
        },
      },
      y: {
        beginAtZero: false,
        title: {
          display: true,
          text: 'Value',
        },
      },
    },
    ...restProps.options,
  };

  return (
    <div className="chart-container">
      <h3 className="chart-title">{title}</h3>
      <div className="chart-area">
        <LineChart
          data={formattedData}
          xKey="formattedDate"
          yKey={valueKey}
          options={options}
          {...restProps}
        />
      </div>
    </div>
  );
};
```

## Dashboard Widgets

Charts are integrated into dashboard widgets that provide context and interactivity:

1. **KPICard**: Displays a key performance indicator with trend visualization
2. **MetricWidget**: Displays a metric with supporting visualization
3. **ChartWidget**: Displays a chart with title, filters, and export options
4. **ComparisonWidget**: Displays a comparison of metrics with visualizations

Example implementation:

```tsx
const KPICard: React.FC<KPICardProps> = ({
  title,
  value,
  previousValue,
  change,
  changeType,
  format,
  trendData,
}) => {
  // Format value based on type
  const formattedValue = useMemo(() => {
    if (format === 'currency') {
      return formatCurrency(value);
    } else if (format === 'percentage') {
      return formatPercentage(value);
    } else {
      return value.toLocaleString();
    }
  }, [value, format]);

  // Format change value
  const formattedChange = useMemo(() => {
    return formatPercentage(Math.abs(change));
  }, [change]);

  return (
    <div className="kpi-card">
      <div className="kpi-header">
        <h3 className="kpi-title">{title}</h3>
      </div>
      <div className="kpi-body">
        <div className="kpi-value">{formattedValue}</div>
        <div className={`kpi-change ${changeType}`}>
          {changeType === 'increase' && <ArrowUpIcon />}
          {changeType === 'decrease' && <ArrowDownIcon />}
          <span>{formattedChange}</span>
        </div>
      </div>
      <div className="kpi-trend">
        <SparklineChart data={trendData} height={40} />
      </div>
    </div>
  );
};
```

## Custom Visualizations

Beyond standard charts, the application includes custom visualizations for specific use cases:

1. **HeatMap**: For visualizing intensity across two dimensions
2. **TreeMap**: For hierarchical data visualization
3. **Gauge**: For displaying progress toward a goal
4. **Funnel**: For visualizing pipeline or conversion processes
5. **Radar**: For comparing multiple variables

Example implementation of a Gauge component:

```tsx
const Gauge: React.FC<GaugeProps> = ({
  value,
  min = 0,
  max = 100,
  threshold,
  label,
  size = 'medium',
}) => {
  // Calculate percentage
  const percentage = ((value - min) / (max - min)) * 100;
  
  // Determine color based on threshold
  const color = useMemo(() => {
    if (!threshold) return 'primary';
    
    if (Array.isArray(threshold)) {
      if (percentage < threshold[0]) return 'danger';
      if (percentage < threshold[1]) return 'warning';
      return 'success';
    }
    
    return percentage >= threshold ? 'success' : 'danger';
  }, [percentage, threshold]);
  
  // Size classes
  const sizeClasses = {
    small: 'w-24 h-24',
    medium: 'w-32 h-32',
    large: 'w-40 h-40',
  };
  
  return (
    <div className={`gauge ${sizeClasses[size]}`}>
      <svg viewBox="0 0 100 100" className="gauge-svg">
        {/* Background arc */}
        <path
          d="M 10 90 A 40 40 0 1 1 90 90"
          fill="none"
          stroke="#e6e6e6"
          strokeWidth="8"
          strokeLinecap="round"
        />
        
        {/* Value arc */}
        <path
          d={`M 10 90 A 40 40 0 ${percentage > 50 ? 1 : 0} 1 ${calculatePoint(percentage)}`}
          fill="none"
          stroke={colorMap[color]}
          strokeWidth="8"
          strokeLinecap="round"
        />
        
        {/* Value text */}
        <text x="50" y="60" textAnchor="middle" fontSize="18" fontWeight="bold">
          {value}
        </text>
        
        {/* Label text */}
        <text x="50" y="78" textAnchor="middle" fontSize="12">
          {label}
        </text>
      </svg>
    </div>
  );
};
```

## Animation and Interactivity

Chart components include animations and interactive features:

1. **Tooltips**: Contextual information on hover
2. **Zoom and Pan**: For exploring large datasets
3. **Click Handling**: For drill-down or detailed views
4. **Animations**: For transitions and data updates
5. **Highlights**: For emphasizing specific data points

Example configuration:

```tsx
const chartOptions: ChartOptions<'line'> = {
  responsive: true,
  maintainAspectRatio: false,
  animation: {
    duration: 800,
    easing: 'easeOutQuart',
  },
  interaction: {
    mode: 'index',
    intersect: false,
  },
  plugins: {
    tooltip: {
      enabled: true,
      mode: 'index',
      intersect: false,
      callbacks: {
        // Custom tooltip formatting
      },
    },
    zoom: {
      pan: {
        enabled: true,
        mode: 'x',
      },
      zoom: {
        wheel: {
          enabled: true,
        },
        pinch: {
          enabled: true,
        },
        mode: 'x',
      },
    },
  },
};
```

## Data Transformation

The application includes utilities for transforming raw data into chart-ready formats:

1. **Aggregation**: Functions for summing, averaging, or counting data
2. **Filtering**: Functions for excluding irrelevant data
3. **Formatting**: Functions for formatting dates, numbers, and currencies
4. **Grouping**: Functions for organizing data by category or time period
5. **Normalization**: Functions for transforming data to comparable scales

Example utility functions:

```tsx
// Group data by time period
export const groupByTimePeriod = <T,>(
  data: T[],
  dateKey: keyof T,
  valueKey: keyof T,
  period: 'day' | 'week' | 'month' | 'quarter' | 'year'
): TimeSeriesData[] => {
  // Create map for grouping
  const groups = new Map<string, number[]>();
  
  // Process each data point
  data.forEach(item => {
    const date = new Date(item[dateKey] as string);
    let groupKey: string;
    
    // Format key based on period
    switch (period) {
      case 'day':
        groupKey = format(date, 'yyyy-MM-dd');
        break;
      case 'week':
        groupKey = `Week ${getWeek(date)}, ${getYear(date)}`;
        break;
      case 'month':
        groupKey = format(date, 'MMM yyyy');
        break;
      case 'quarter':
        const quarter = Math.floor(date.getMonth() / 3) + 1;
        groupKey = `Q${quarter} ${date.getFullYear()}`;
        break;
      case 'year':
        groupKey = date.getFullYear().toString();
        break;
    }
    
    // Add value to group
    if (!groups.has(groupKey)) {
      groups.set(groupKey, []);
    }
    groups.get(groupKey)!.push(Number(item[valueKey]));
  });
  
  // Calculate averages and create result
  return Array.from(groups.entries())
    .map(([date, values]) => ({
      date,
      value: values.reduce((sum, val) => sum + val, 0) / values.length,
    }))
    .sort((a, b) => {
      // Sort by date
      if (period === 'month') {
        return compareAsc(parse(a.date, 'MMM yyyy', new Date()), parse(b.date, 'MMM yyyy', new Date()));
      }
      // Handle other period types
      return a.date.localeCompare(b.date);
    });
};
```

## Color System

The application uses a consistent color system for visualizations:

1. **Primary Colors**: For main data series
2. **Secondary Colors**: For supporting data series
3. **Accent Colors**: For highlighting important data points
4. **Semantic Colors**: For representing status (success, warning, error)
5. **Neutral Colors**: For backgrounds and non-data elements

Implementation example:

```tsx
// Color system
export const chartColors = {
  // Primary palette
  primary: [
    'rgba(14, 165, 233, 1)',   // Primary blue
    'rgba(139, 92, 246, 1)',   // Purple
    'rgba(59, 130, 246, 1)',   // Blue
    'rgba(16, 185, 129, 1)',   // Green
    'rgba(245, 158, 11, 1)',   // Amber
  ],
  
  // Status colors
  status: {
    success: 'rgba(16, 185, 129, 1)',
    warning: 'rgba(245, 158, 11, 1)',
    danger: 'rgba(239, 68, 68, 1)',
    neutral: 'rgba(156, 163, 175, 1)',
  },
  
  // Background colors (with transparency)
  background: {
    primary: 'rgba(14, 165, 233, 0.1)',
    success: 'rgba(16, 185, 129, 0.1)',
    warning: 'rgba(245, 158, 11, 0.1)',
    danger: 'rgba(239, 68, 68, 0.1)',
    neutral: 'rgba(156, 163, 175, 0.1)',
  },
  
  // Get colors for a dataset
  getColors: (index: number, alpha: number = 1): { backgroundColor: string; borderColor: string } => {
    const color = chartColors.primary[index % chartColors.primary.length];
    const backgroundColor = color.replace('1)', `${alpha})`);
    return {
      backgroundColor,
      borderColor: color,
    };
  },
  
  // Generate colors for multiple datasets
  generateColors: (count: number, alpha: number = 0.5): Array<{ backgroundColor: string; borderColor: string }> => {
    return Array.from({ length: count }, (_, i) => chartColors.getColors(i, alpha));
  },
};
```

## Accessibility

Visualization components follow accessibility best practices:

1. **Screen Reader Support**: Alternative text and descriptions for charts
2. **Keyboard Navigation**: Interactive elements that can be used with keyboard
3. **Color Contrast**: Sufficient contrast for text and data elements
4. **Focus Indicators**: Visible focus indicators for interactive elements
5. **Alternative Formats**: Table views of chart data

Implementation example:

```tsx
const AccessibleChart: React.FC<AccessibleChartProps> = ({
  data,
  chartComponent: ChartComponent,
  title,
  description,
  tableCaption,
  ...restProps
}) => {
  const [showTable, setShowTable] = useState(false);
  
  // Table column definitions based on data
  const columns = useMemo(() => {
    if (!data || !data.length) return [];
    
    // Get keys from first data item
    return Object.keys(data[0])
      .filter(key => !key.startsWith('_')) // Filter out private keys
      .map(key => ({
        header: startCase(key),
        accessor: key,
        Cell: ({ value }: { value: any }) => formatValue(value),
      }));
  }, [data]);
  
  return (
    <div className="accessible-chart">
      <div className="chart-header">
        <h3 id={`chart-title-${idSuffix}`} className="chart-title">
          {title}
        </h3>
        
        <button
          className="view-toggle-button"
          onClick={() => setShowTable(!showTable)}
          aria-pressed={showTable}
        >
          {showTable ? 'Show Chart' : 'Show Data Table'}
        </button>
      </div>
      
      {description && (
        <p id={`chart-desc-${idSuffix}`} className="chart-description">
          {description}
        </p>
      )}
      
      <div 
        className="chart-container"
        aria-hidden={showTable}
        style={{ display: showTable ? 'none' : 'block' }}
      >
        <ChartComponent
          data={data}
          aria-labelledby={`chart-title-${idSuffix}`}
          aria-describedby={description ? `chart-desc-${idSuffix}` : undefined}
          {...restProps}
        />
      </div>
      
      {showTable && (
        <div className="data-table-container">
          <table className="data-table" summary={tableCaption || title}>
            <caption>{tableCaption || title}</caption>
            <thead>
              <tr>
                {columns.map(column => (
                  <th key={column.accessor} scope="col">
                    {column.header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.map((row, rowIndex) => (
                <tr key={rowIndex}>
                  {columns.map(column => (
                    <td key={column.accessor}>
                      {formatValue(row[column.accessor])}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
```

## Export and Sharing

The application provides export and sharing capabilities for visualizations:

1. **Image Export**: Export charts as PNG or JPEG
2. **PDF Export**: Export reports with charts as PDF
3. **CSV Export**: Export underlying data as CSV
4. **Direct Sharing**: Share visualizations via URL or email
5. **Embedding**: Embed visualizations in other applications

Implementation example:

```tsx
const ChartExport: React.FC<ChartExportProps> = ({
  chartRef,
  data,
  title,
  onExportStart,
  onExportComplete,
}) => {
  const handleImageExport = () => {
    if (!chartRef.current) return;
    
    onExportStart?.();
    
    // Get chart canvas
    const canvas = chartRef.current.canvas;
    
    // Create image
    const image = canvas.toDataURL('image/png', 1.0);
    
    // Create download link
    const link = document.createElement('a');
    link.download = `${title.replace(/\s+/g, '-').toLowerCase()}-${format(new Date(), 'yyyy-MM-dd')}.png`;
    link.href = image;
    link.click();
    
    onExportComplete?.();
  };
  
  const handleCSVExport = () => {
    if (!data) return;
    
    onExportStart?.();
    
    // Convert data to CSV
    const csv = convertToCSV(data);
    
    // Create download link
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.download = `${title.replace(/\s+/g, '-').toLowerCase()}-${format(new Date(), 'yyyy-MM-dd')}.csv`;
    link.href = url;
    link.click();
    
    onExportComplete?.();
  };
  
  return (
    <div className="chart-export-controls">
      <button
        className="export-button"
        onClick={handleImageExport}
        title="Export as PNG"
      >
        <ImageIcon className="icon" />
        <span>PNG</span>
      </button>
      
      <button
        className="export-button"
        onClick={handleCSVExport}
        title="Export data as CSV"
      >
        <TableIcon className="icon" />
        <span>CSV</span>
      </button>
    </div>
  );
};
```

## Performance Considerations

The visualization components follow these performance best practices:

1. **Lazy Loading**: Charts are loaded only when needed
2. **Data Sampling**: Large datasets are sampled for better performance
3. **Memoization**: Expensive calculations are memoized
4. **Canvas Rendering**: Chart.js uses canvas for efficient rendering
5. **Throttling**: Frequent updates are throttled to prevent excessive re-renders

Implementation example:

```tsx
const OptimizedChart: React.FC<OptimizedChartProps> = ({
  data,
  ...restProps
}) => {
  // Sample data if too large
  const processedData = useMemo(() => {
    if (data.length <= 100) return data;
    
    // For large datasets, sample data points
    return sampleData(data, 100);
  }, [data]);
  
  // Memoize chart options
  const chartOptions = useMemo(() => ({
    // Chart.js options
    responsive: true,
    maintainAspectRatio: false,
    // Additional options...
  }), []);
  
  // Create chart data structure once
  const chartData = useMemo(() => {
    return {
      labels: processedData.map(item => item.label),
      datasets: [{
        data: processedData.map(item => item.value),
        // Dataset styling...
      }],
    };
  }, [processedData]);
  
  // Lazy load the chart component
  const LazyChart = useMemo(() => React.lazy(() => import('./LazyChart')), []);
  
  return (
    <div className="chart-container">
      <React.Suspense fallback={<div className="chart-loading">Loading chart...</div>}>
        <LazyChart
          data={chartData}
          options={chartOptions}
          {...restProps}
        />
      </React.Suspense>
    </div>
  );
};
```

## Testing Visualization Components

The visualization components include comprehensive tests:

1. **Unit Tests**: Test individual component functionality
2. **Integration Tests**: Test integration with data services
3. **Visual Regression Tests**: Test visual appearance of charts
4. **Accessibility Tests**: Test chart accessibility
5. **Performance Tests**: Test chart rendering performance

Example test:

```tsx
describe('LineChart', () => {
  // Mock data
  const mockData = [
    { date: '2023-01-01', value: 100 },
    { date: '2023-02-01', value: 200 },
    { date: '2023-03-01', value: 150 },
    { date: '2023-04-01', value: 300 },
  ];
  
  // Test rendering
  it('renders correctly with data', () => {
    const { container } = render(
      <LineChart
        data={mockData}
        xKey="date"
        yKey="value"
        title="Test Chart"
      />
    );
    
    expect(container.querySelector('canvas')).toBeInTheDocument();
    expect(screen.getByText('Test Chart')).toBeInTheDocument();
  });
  
  // Test interactivity
  it('calls onDataPointClick when a data point is clicked', () => {
    const handleClick = jest.fn();
    
    render(
      <LineChart
        data={mockData}
        xKey="date"
        yKey="value"
        onDataPointClick={handleClick}
      />
    );
    
    // Simulate click on chart
    // Note: This is a simplified example. In practice, testing Chart.js interactions
    // may require more complex setup or mocking.
    const canvas = screen.getByRole('img');
    fireEvent.click(canvas);
    
    expect(handleClick).toHaveBeenCalled();
  });
  
  // Test accessibility
  it('has proper accessibility attributes', () => {
    render(
      <LineChart
        data={mockData}
        xKey="date"
        yKey="value"
        title="Test Chart"
        description="A test chart showing values over time"
      />
    );
    
    const canvas = screen.getByRole('img');
    expect(canvas).toHaveAttribute('aria-label');
    // Check for other accessibility attributes
  });
}); 