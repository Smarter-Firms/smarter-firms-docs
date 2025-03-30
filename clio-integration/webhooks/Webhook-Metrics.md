# Webhook Metrics

The Webhook Metrics component of the Clio Integration Service provides real-time monitoring and historical data about webhook processing performance and reliability.

## Overview

Effective monitoring of webhook activity is crucial for maintaining a healthy integration with the Clio API. The metrics system tracks:

- Webhook processing success and failure rates
- Processing time statistics
- Error distribution by error type
- Event distribution by entity and action type

This data helps identify issues, optimize performance, and provide visibility into the synchronization process.

## Metrics Storage

Webhook metrics are stored in Redis with the following key structure:

- `webhook:metrics:<date>` - Daily aggregated metrics
- `webhook:metrics:<date>:<hour>` - Hourly metrics for more granular analysis
- `webhook:metrics:event:<event_type>` - Metrics grouped by event type (e.g., "contact.created")
- `webhook:metrics:error:<error_type>` - Metrics grouped by error type

Data is stored using Redis hashes for efficient storage and retrieval. Keys expire after 7 days to manage Redis memory usage.

## Available Metrics

The metrics component tracks:

### Success Metrics
- Total webhook count
- Successful webhooks count
- Success rate percentage
- Average processing time (ms)
- Processing time distribution

### Error Metrics
- Failure count by error type
- Failure rate percentage
- Most common errors

### Event Metrics
- Count by event type (e.g., contact.created, matter.updated)
- Distribution of events by entity type
- Success rate by event type

## API Endpoints

The metrics API provides several endpoints for retrieving webhook metrics:

### Dashboard Summary
```
GET /api/metrics/webhooks/dashboard
```
Returns a comprehensive summary of webhook metrics, including:
- Today's metrics
- Yesterday's metrics
- Event type distribution
- Error distribution

### Daily Metrics
```
GET /api/metrics/webhooks/daily/:date?
```
Returns metrics for a specific day, including hourly breakdown.
The date parameter is optional and defaults to today (format: YYYY-MM-DD).

### Event Type Metrics
```
GET /api/metrics/webhooks/events
```
Returns metrics grouped by webhook event type.

### Error Metrics
```
GET /api/metrics/webhooks/errors
```
Returns metrics grouped by error type.

### Success Rate
```
GET /api/metrics/webhooks/success-rate/:date?
```
Returns the webhook success rate percentage for a specific day.

### Processing Time
```
GET /api/metrics/webhooks/processing-time/:date?
```
Returns the average webhook processing time in milliseconds for a specific day.

## Implementation Details

### Metrics Collection

Metrics are collected directly in the WebhookService during webhook processing:

1. When a webhook request is received, a timer starts.
2. After processing (success or failure), the metrics are recorded in Redis.
3. For failures, the error type is captured for analysis.

### Efficiency Considerations

- Metrics recording is done asynchronously to avoid impacting webhook processing performance.
- Error handling ensures that metrics collection failures don't affect webhook processing.
- Redis pipeline operations are used for efficient batch updates when possible.

### Integration Points

The metrics system integrates with:

- **WebhookService**: Records metrics during webhook processing
- **Redis**: Stores metrics data
- **API Layer**: Exposes metrics through REST endpoints
- **Logging System**: Records metrics collection issues

## Monitoring and Alerting

The metrics component can be used for monitoring and alerting by:

1. Setting up alerts for low success rates (e.g., below 95%)
2. Monitoring for spikes in processing time
3. Alerting on high error rates for specific event types
4. Tracking unusual patterns in webhook volume

## Example Usage

### Monitoring Dashboard Integration

The metrics endpoints can be integrated with monitoring dashboards like Grafana:

1. Configure Grafana to poll the metrics API endpoints periodically
2. Create visualizations for success rates, processing times, and error distributions
3. Set up alerts for concerning metrics threshold breaches

### Debugging Example

When investigating webhooks issues:

1. Check the success rate endpoint to verify if failures are occurring
2. Examine the error distribution to identify the most common errors
3. Look at event-specific metrics to see if issues are isolated to specific event types
4. Review processing times to identify performance degradation

## Future Enhancements

Planned improvements for the metrics system include:

1. Real-time metrics streaming via WebSockets
2. Anomaly detection for webhook patterns
3. Integration with external monitoring systems
4. Expanded metric retention and historical analysis
5. User-specific webhook metrics tracking 