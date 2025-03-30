# Notification System Documentation

This directory contains comprehensive documentation for the Smarter Firms Notification Service. The service is designed to provide a centralized system for sending and managing notifications across various channels, including email (via Mailgun), SMS (via Twilio), push notifications, and in-app notifications.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Component Documentation](#component-documentation)
4. [Integration Guide](#integration-guide)
5. [API Reference](#api-reference)
6. [Best Practices](#best-practices)

## System Overview

The Notification Service is a critical component of the Smarter Firms platform, responsible for all user communications. It centralizes notification logic across different channels, provides robust templating capabilities, manages user preferences, and ensures reliable delivery with retry mechanisms.

## Architecture

The service follows a modular architecture with the following key components:

- **API Layer**: Express routes and controllers for notification operations
- **Service Layer**: Core business logic for notification processing
- **Provider Layer**: Integration with external services (Mailgun, Twilio)
- **Template Engine**: Handlebars-based templating system
- **Queue System**: Bull/Redis for asynchronous processing and retries
- **Database Layer**: Prisma ORM with PostgreSQL for persistent storage

## Component Documentation

Detailed documentation for each component:

- [Template System](Template-System.md): How templates are managed, stored, and rendered
- [Mailgun Integration](Mailgun-Integration.md): Email delivery implementation details
- [Twilio Integration](Twilio-Integration.md): SMS notification implementation details
- [Notification Preferences](Notification-Preferences.md): User preference management
- [Queuing System](Queuing-System.md): Asynchronous processing architecture
- [API Documentation](API-Documentation.md): Comprehensive API reference

## Integration Guide

To integrate with the Notification Service, other services should:

1. Make HTTP requests to the notification API endpoints
2. Provide required data in the expected format
3. Handle success/failure responses appropriately

Example integration:

```typescript
// Example request to send a notification
const response = await fetch('http://notification-service/api/v1/notifications', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${apiToken}`
  },
  body: JSON.stringify({
    userId: 'user-123',
    notificationTypeId: 'welcome-email',
    channel: 'EMAIL',
    data: {
      firstName: 'John',
      dashboardUrl: 'https://app.smarterfirms.com/dashboard',
      currentYear: new Date().getFullYear()
    }
  })
});

const result = await response.json();
```

## API Reference

See [API Documentation](API-Documentation.md) for a complete API reference.

## Best Practices

When working with the Notification Service:

1. Always validate user preferences before sending notifications
2. Use appropriate notification types for different scenarios
3. Provide all required template variables to avoid rendering errors
4. Implement proper error handling for notification failures
5. Consider rate limiting for bulk notifications
6. Test templates across different email clients and devices 