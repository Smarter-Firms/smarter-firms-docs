# Rate Limiting and Best Practices

This document outlines rate limits and best practices for services consuming the Notifications API.

## Rate Limits

The Notifications Service implements tiered rate limiting to ensure stability and prevent abuse:

| Endpoint | Rate Limit | Window | Scope | Notes |
|----------|------------|--------|-------|-------|
| All endpoints | 100 requests | 1 minute | Per IP | Global limit for all API endpoints |
| POST /notifications | 50 requests | 1 minute | Per user ID | User-specific limit for sending notifications |

Rate limit responses return status code `429 Too Many Requests` with the following headers:
- `RateLimit-Limit`: Total requests allowed in the window
- `RateLimit-Remaining`: Remaining requests in current window
- `RateLimit-Reset`: Time in seconds until the rate limit window resets

Example rate limit response:
```json
{
  "status": "error",
  "message": "Too many requests, please try again later."
}
```

## Best Practices for Consuming Services

### General Best Practices

1. **Implement Backoff Strategy**: When receiving 429 responses, implement exponential backoff:
   ```typescript
   async function sendWithBackoff(data, retries = 3, baseDelay = 1000) {
     for (let attempt = 0; attempt < retries; attempt++) {
       try {
         const response = await fetch('/api/v1/notifications', {
           method: 'POST',
           body: JSON.stringify(data),
           headers: { 'Content-Type': 'application/json' }
         });
         
         if (response.status === 429) {
           // Calculate backoff delay: 1s, 2s, 4s, etc.
           const delay = baseDelay * Math.pow(2, attempt);
           await new Promise(resolve => setTimeout(resolve, delay));
           continue; // Retry after delay
         }
         
         return await response.json();
       } catch (error) {
         if (attempt === retries - 1) throw error;
       }
     }
   }
   ```

2. **Batch Notifications**: For bulk operations, batch notifications instead of sending individually:
   ```typescript
   // Bad: Sending many individual notifications
   for (const user of users) {
     await sendNotification(user.id, 'welcome');
   }
   
   // Good: Use batching when possible (future enhancement)
   await sendBatchNotifications(users.map(user => ({
     userId: user.id,
     notificationTypeId: 'welcome-email',
     // ... other properties
   })));
   ```

3. **Prioritize Notifications**: Critical notifications should be sent before less important ones:
   - Security notifications (2FA, security alerts)
   - Transactional notifications (order confirmations, account changes)
   - System notifications (maintenance alerts)
   - Marketing notifications (promotions, newsletters)

4. **Verify Templates**: Always ensure all required template variables are provided:
   ```typescript
   // Before sending, verify template data
   if (!templateData.hasOwnProperty('firstName')) {
     throw new Error('Required variable "firstName" missing from template data');
   }
   ```

5. **Handle Failures**: Implement proper error handling for notification failures:
   ```typescript
   try {
     await sendNotification(userId, notificationTypeId, data);
   } catch (error) {
     if (error.status === 429) {
       // Rate limited - add to retry queue
     } else if (error.message.includes('user preferences')) {
       // User has opted out - log and continue
     } else {
       // Other error - log and alert if critical
     }
   }
   ```

6. **Monitor Usage**: Track your service's notification usage to anticipate rate limit issues:
   - Log notification success/failure rates
   - Set up alerts for high failure rates
   - Monitor rate limit headers to adapt to remaining capacity

7. **Use Webhooks**: For status updates, use webhooks instead of polling:
   ```typescript
   // Webhook handler for notification status updates
   app.post('/webhook/notification-status', (req, res) => {
     const { notificationId, status } = req.body;
     // Update local status tracking
     updateLocalStatus(notificationId, status);
     res.status(200).send();
   });
   ```

## Security Best Practices

1. **API Key Management**: Rotate API keys regularly and use different keys for different environments:
   - Production and development should use separate API keys
   - Rotate keys quarterly or after staff changes
   - Never expose API keys in client-side code

2. **Data Minimization**: Only send necessary personal data in notification content:
   ```typescript
   // Bad: Including unnecessary sensitive information
   await sendNotification(userId, 'order-confirmation', {
     firstName: user.firstName,
     lastName: user.lastName,
     email: user.email,
     address: user.address,
     cardNumber: user.cardNumber, // Unnecessary sensitive data
     orderNumber: order.id
   });
   
   // Good: Including only necessary information
   await sendNotification(userId, 'order-confirmation', {
     firstName: user.firstName,
     orderNumber: order.id,
     orderTotal: order.total
   });
   ```

3. **Content Security**: Never include sensitive data like passwords in notifications:
   - Never send passwords, even temporary ones
   - Use tokenized reset links instead of codes when possible
   - Mask sensitive identifiers (e.g., "xxxx-xxxx-xxxx-1234")

4. **Template Validation**: Validate templates for injection vulnerabilities:
   - Review templates for HTML injection risks in email content
   - Use appropriate HTML encoding for user-provided content
   - Implement content security policies for email templates

5. **Authentication**: Always authenticate API requests:
   ```typescript
   // Always include authentication
   const response = await fetch('/api/v1/notifications', {
     method: 'POST',
     headers: {
       'Content-Type': 'application/json',
       'Authorization': `Bearer ${apiToken}`
     },
     body: JSON.stringify(data)
   });
   ```

6. **Audit Logging**: Enable audit logging for all notification operations:
   - Log who initiated each notification
   - Track notification content for compliance purposes
   - Maintain logs for appropriate retention periods

## Performance Optimization

1. **Template Precompilation**: Precompile frequently used templates:
   - Cache rendered templates when possible
   - Reuse template compilations for repeated notifications

2. **Queueing Strategy**: Use appropriate queueing strategies:
   - Set appropriate priorities for different notification types
   - Configure TTL (time-to-live) for time-sensitive notifications
   - Implement dead-letter queues for failed notifications

3. **Monitoring**: Monitor notification performance:
   - Track delivery times across different channels
   - Set up alerts for queue backlog increases
   - Monitor external provider performance 