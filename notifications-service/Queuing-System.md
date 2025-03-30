# Queuing System

This document details the queuing system used by the Smarter Firms Notification Service for reliable, asynchronous notification processing.

## Overview

The Notification Service uses Bull, a Redis-based queue, to handle asynchronous processing of notifications. This architecture provides reliability, scalability, and failure recovery for all notification operations.

## Architecture

The queuing system consists of:

1. **Queue Infrastructure**: Bull/Redis for job management
2. **Queue Service**: Interface for adding jobs to queues
3. **Workers**: Processes that consume jobs from queues
4. **Retry Logic**: Automatic handling of failed jobs
5. **Monitoring**: Queue statistics and health metrics

## Queue Structure

The service maintains separate queues for each notification channel:

```typescript
export const QUEUE_NAMES = {
  EMAIL: 'email-notifications',
  SMS: 'sms-notifications',
  PUSH: 'push-notifications',
  IN_APP: 'in-app-notifications',
};
```

This separation allows for:
- Channel-specific processing logic
- Independent scaling and throughput control
- Isolated failure handling
- Channel-specific monitoring

## Configuration

The queue system is configured through environment variables:

```
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
JOB_CONCURRENCY=5
JOB_ATTEMPT_LIMIT=3
```

## Implementation

### Queue Setup

The queues are initialized with their specific options:

```typescript
// Redis connection config
const redisConfig = {
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: Number(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD,
  },
};

// Queue options
const queueOptions = {
  defaultJobOptions: {
    attempts: Number(process.env.JOB_ATTEMPT_LIMIT) || 3,
    backoff: {
      type: 'exponential',
      delay: 5000, // 5 seconds
    },
    removeOnComplete: true,
    removeOnFail: false,
  },
};

// Create queues
const emailQueue = new Queue(QUEUE_NAMES.EMAIL, { ...redisConfig, ...queueOptions });
const smsQueue = new Queue(QUEUE_NAMES.SMS, { ...redisConfig, ...queueOptions });
const pushQueue = new Queue(QUEUE_NAMES.PUSH, { ...redisConfig, ...queueOptions });
const inAppQueue = new Queue(QUEUE_NAMES.IN_APP, { ...redisConfig, ...queueOptions });
```

### Queue Workers

Workers process jobs from the queues:

```typescript
// Process email notifications
emailQueue.process(concurrency, async (job) => {
  logger.info('Processing email notification job', { jobId: job.id });
  await this.processNotificationJob(job.data);
});
```

### Job Processing Flow

The notification processing flow follows these steps:

1. Client makes a request to send a notification
2. The notification is stored in the database with PENDING status
3. A job is added to the appropriate channel queue
4. A worker picks up the job and processes it
5. The notification provider (Mailgun, Twilio) sends the notification
6. The notification status is updated to SENT or FAILED
7. If failed, the job may be retried based on the retry configuration

## Retry Logic

Failed notifications are automatically retried with exponential backoff:

```typescript
defaultJobOptions: {
  attempts: Number(process.env.JOB_ATTEMPT_LIMIT) || 3,
  backoff: {
    type: 'exponential',
    delay: 5000, // 5 seconds
  },
  // ...
}
```

Additionally, the service provides an API to manually retry failed notifications:

```typescript
/**
 * Retry a failed notification
 */
async retryNotification(notificationId: string): Promise<void> {
  // Get the failed notification
  const notification = await prisma.notification.findUnique({
    where: { id: notificationId },
  });

  if (!notification) {
    throw new Error(`Notification not found: ${notificationId}`);
  }

  if (notification.status !== NotificationStatus.FAILED) {
    throw new Error(`Cannot retry notification with status ${notification.status}`);
  }

  // Add to queue again
  await this.queueNotification({
    userId: notification.userId,
    notificationTypeId: notification.notificationTypeId,
    channel: notification.channel,
    data: notification.content as Record<string, any>,
    metadata: {
      ...(notification.metadata as Record<string, any> || {}),
      isRetry: true,
      originalNotificationId: notification.id,
    },
  });

  // Update original notification
  await prisma.notification.update({
    where: { id: notificationId },
    data: {
      status: NotificationStatus.PENDING,
      errorMessage: 'Scheduled for retry',
    },
  });
}
```

## Monitoring and Maintenance

The service provides endpoints for monitoring queue health:

```typescript
/**
 * Get queue statistics
 */
async getQueueStats(): Promise<any> {
  const stats = await Promise.all([
    emailQueue.getJobCounts(),
    smsQueue.getJobCounts(),
    pushQueue.getJobCounts(),
    inAppQueue.getJobCounts(),
  ]);

  return {
    email: stats[0],
    sms: stats[1],
    push: stats[2],
    inApp: stats[3],
  };
}
```

Regular maintenance includes cleaning completed and failed jobs:

```typescript
/**
 * Clean queues - remove completed and failed jobs
 */
async cleanQueues(): Promise<void> {
  await Promise.all([
    emailQueue.clean(24 * 60 * 60 * 1000, 'completed'), // 24 hours
    smsQueue.clean(24 * 60 * 60 * 1000, 'completed'), 
    pushQueue.clean(24 * 60 * 60 * 1000, 'completed'),
    inAppQueue.clean(24 * 60 * 60 * 1000, 'completed'),
  ]);

  await Promise.all([
    emailQueue.clean(7 * 24 * 60 * 60 * 1000, 'failed'), // 7 days
    smsQueue.clean(7 * 24 * 60 * 60 * 1000, 'failed'),
    pushQueue.clean(7 * 24 * 60 * 60 * 1000, 'failed'),
    inAppQueue.clean(7 * 24 * 60 * 60 * 1000, 'failed'),
  ]);

  logger.info('Notification queues cleaned');
}
```

## Benefits

The queuing system provides several key benefits:

1. **Reliability**: No notifications are lost if the system crashes
2. **Asynchronous Processing**: Clients don't have to wait for notifications to be sent
3. **Scalability**: Workers can be scaled independently for high-volume channels
4. **Rate Limiting**: Prevents overwhelming external providers
5. **Retry Capability**: Failed notifications are automatically retried
6. **Monitoring**: Visibility into notification processing status
7. **Prioritization**: Different notification types can be prioritized (future enhancement)

## Best Practices

When working with the queuing system:

1. **Monitor Queue Size**: Large backlogs may indicate processing issues
2. **Check Failed Jobs**: Regularly review and address failed notifications
3. **Tune Concurrency**: Adjust worker concurrency based on system performance
4. **Implement Circuit Breakers**: Prevent overwhelming external services during outages
5. **Schedule Maintenance**: Regularly clean old jobs to prevent Redis memory issues
6. **Log Queue Events**: Track important queue events for troubleshooting

## Future Enhancements

Planned improvements to the queuing system:

1. Job prioritization for critical notifications
2. Delayed notifications (scheduled for future delivery)
3. Batch processing for bulk notifications
4. Advanced rate limiting per provider
5. Queue visualization in admin interface
6. Enhanced metrics and alerting
7. Distributed worker deployment 