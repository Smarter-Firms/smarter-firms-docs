# Notification Preferences

This document details the notification preferences system used by the Smarter Firms Notification Service to manage user communication preferences.

## Overview

The Notification Preferences system allows users to control which notifications they receive across different channels. It provides a fine-grained approach where users can enable or disable specific notification types for individual channels.

## Architecture

The preferences system consists of:

1. **Preference Model**: Data structure for storing preferences
2. **Preference API**: Endpoints for managing preferences
3. **Preference Service**: Business logic for preference management
4. **Preference Validation**: Checking preferences before sending notifications

## Data Model

Preferences are stored in the `NotificationPreference` table with the following structure:

```prisma
model NotificationPreference {
  id                String              @id @default(uuid())
  userId            String
  user              User                @relation(fields: [userId], references: [id])
  notificationType  NotificationType    @relation(fields: [notificationTypeId], references: [id])
  notificationTypeId String
  channel           NotificationChannel
  enabled           Boolean             @default(true)
  createdAt         DateTime            @default(now())
  updatedAt         DateTime            @updatedAt

  @@unique([userId, notificationTypeId, channel])
}
```

This structure creates a unique preference entry for each combination of:
- User
- Notification Type
- Channel

## Default Preferences

By default, all notifications are enabled for all channels. The system follows these rules:

1. If no preference entry exists for a user-type-channel combination, notifications are enabled
2. Only explicit opt-outs are stored as preference entries
3. When a user resets preferences, all explicit preference entries are deleted

## API Endpoints

The service provides the following endpoints for managing preferences:

### Get User Preferences

```
GET /api/v1/preferences/user/:userId
```

Returns all notification types with the user's preferences for each channel:

```json
{
  "status": "success",
  "data": {
    "preferences": [
      {
        "notificationTypeId": "type-123",
        "code": "account-update",
        "name": "Account Updates",
        "category": "SYSTEM",
        "channels": {
          "EMAIL": {
            "enabled": true,
            "preferenceId": "pref-456"
          },
          "SMS": {
            "enabled": false,
            "preferenceId": "pref-789"
          },
          "PUSH": {
            "enabled": true,
            "preferenceId": null
          },
          "IN_APP": {
            "enabled": true,
            "preferenceId": null
          }
        }
      },
      // More notification types...
    ]
  }
}
```

### Update Preference

```
PUT /api/v1/preferences/user/:userId/type/:notificationTypeId/channel/:channel
```

Body:
```json
{
  "enabled": false
}
```

Updates the preference for a specific notification type and channel:

```json
{
  "status": "success",
  "data": {
    "preference": {
      "id": "pref-123",
      "userId": "user-123",
      "notificationTypeId": "type-123",
      "channel": "EMAIL",
      "enabled": false,
      "createdAt": "2023-01-01T00:00:00.000Z",
      "updatedAt": "2023-01-01T00:00:00.000Z"
    }
  }
}
```

### Reset Preferences

```
POST /api/v1/preferences/user/:userId/reset
```

Deletes all preference entries for a user, reverting to default settings:

```json
{
  "status": "success",
  "message": "Notification preferences reset to defaults"
}
```

## Implementation

The preference system is implemented in the notification processing flow:

```typescript
/**
 * Check if the user has enabled this notification type for this channel
 */
private async checkUserPreferences(userId: string, notificationTypeId: string, channel: NotificationChannel): Promise<boolean> {
  // Get user preference for this notification type and channel
  const preference = await prisma.notificationPreference.findUnique({
    where: {
      userId_notificationTypeId_channel: {
        userId,
        notificationTypeId,
        channel,
      },
    },
  });

  // If no preference is set, assume enabled
  if (!preference) {
    return true;
  }

  return preference.enabled;
}
```

Before sending any notification, the system checks if the user has explicitly disabled it:

```typescript
// Check user preferences
const canSend = await this.checkUserPreferences(userId, notificationTypeId, channel);
if (!canSend) {
  logger.info('Notification skipped due to user preferences', { userId, notificationTypeId, channel });
  throw new Error('Notification disabled by user preferences');
}
```

## Preference Categories

Notification preferences are organized by notification types, which are categorized as:

- `TRANSACTIONAL`: Essential account-related notifications
- `MARKETING`: Promotional content
- `SYSTEM`: System updates and service information
- `ALERT`: Time-sensitive alerts
- `SECURITY`: Security-related notifications

These categories help users understand the purpose of each notification type when managing preferences.

## Channel Types

Users can set preferences for these channels independently:

- `EMAIL`: Email notifications
- `SMS`: Text messages
- `PUSH`: Mobile push notifications
- `IN_APP`: In-application notifications

## Best Practices

When working with the preference system:

1. **Critical Notifications**: Some critical notifications (like security alerts) should potentially override preferences
2. **Preference UI**: Provide a clear, user-friendly interface for managing preferences
3. **Unsubscribe Links**: Include unsubscribe or preference management links in emails
4. **Onboarding**: Set sensible default preferences during user onboarding
5. **Legal Compliance**: Respect legal requirements for marketing consent
6. **Notification Types**: Keep notification types granular enough for meaningful user control

## Future Enhancements

Planned improvements to the preference system:

1. Time-based preferences (e.g., quiet hours)
2. Notification frequency controls
3. Preference templates and bulk settings
4. Channel priority (try email first, then SMS)
5. Category-level preference management
6. Preference analytics
7. Migration tools for preference changes when restructuring notification types 