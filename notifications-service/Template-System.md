# Template System

This document details the template system used by the Smarter Firms Notification Service for generating notification content across different channels.

## Overview

The Notification Service uses a flexible template system powered by Handlebars to generate notification content. Templates can be stored either in the database or as files on disk, and support variables, conditionals, and formatting helpers.

## Architecture

The template system consists of:

1. **Template Storage**: Both database and file-based storage
2. **Template Engine**: Handlebars for rendering templates
3. **Template Service**: Business logic for retrieving and rendering templates
4. **Cache**: Optimized template caching for performance

## Template Storage Options

### Database Templates

Templates are primarily stored in the database using the `NotificationTemplate` model, which allows for:

- Association with specific notification types and channels
- Versioning and tracking changes
- Dynamic updates without deployment
- Different templates for different channels

### File-Based Templates

For development and fallbacks, templates can also be stored as files in `src/templates/` with a `.hbs` extension.

## Template Structure

Templates consist of the following components:

1. **Subject**: For email notifications (optional)
2. **Content**: The main message body
   - HTML version for email
   - Plain text version for SMS and fallback

Example email template:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Welcome to Smarter Firms</title>
  <style>/* CSS styles */</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to Smarter Firms</h1>
    </div>
    <div class="content">
      <p>Hello {{firstName}},</p>
      <p>Welcome to Smarter Firms! We're excited to have you on board.</p>
      <!-- More content -->
    </div>
  </div>
</body>
</html>
```

Example SMS template:

```
Your Smarter Firms verification code is: {{code}}. This code will expire in {{expiryMinutes}} minutes.
```

## Template Variables

Templates support dynamic content insertion using double curly braces `{{ variable }}` syntax. Common variables include:

- User attributes (firstName, lastName, email)
- Application links (dashboardUrl, verificationLink)
- System values (currentYear, expiryMinutes)
- Custom data specific to each notification type

## Helpers and Formatting

Handlebars helpers are registered to enhance templates with formatting functions:

```typescript
// Register Handlebars helpers
Handlebars.registerHelper('formatDate', (date: Date) => {
  return new Date(date).toLocaleDateString();
});

Handlebars.registerHelper('formatCurrency', (amount: number) => {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
});
```

Examples in templates:

```
Date: {{formatDate createdAt}}
Amount: {{formatCurrency invoiceAmount}}
```

## Implementation

The template service handles retrieving and rendering templates:

```typescript
export class TemplateService {
  private templatesCache: Map<string, Handlebars.TemplateDelegate> = new Map();
  private templateDirPath: string = path.join(__dirname, '../../src/templates');

  /**
   * Get a template from the database by notification type and channel
   */
  async getTemplateFromDb(notificationTypeId: string, channel: NotificationChannel): Promise<RenderedTemplate | null> {
    // Implementation to retrieve template from database
  }

  /**
   * Get a template from the filesystem
   */
  async getTemplateFromFile(templateName: string): Promise<string> {
    // Implementation to retrieve template from file
  }

  /**
   * Render a template with data
   */
  async renderTemplate(templateContent: string, data: TemplateData): Promise<string> {
    // Implementation to render the template with Handlebars
  }

  /**
   * Process a template for notification
   */
  async processTemplate(notificationTypeId: string, channel: NotificationChannel, data: TemplateData): Promise<RenderedTemplate> {
    // Main method to get and render a template
  }
}
```

## Template Caching

For performance optimization, the template service caches compiled templates:

1. When a template is first used, it's compiled and cached in memory
2. Subsequent uses retrieve the compiled template from cache
3. Template content changes require service restart to update the cache

## Channel-Specific Templates

Different channels require different template formats:

- **Email**: HTML and plain text versions with subject
- **SMS**: Brief, plain text only
- **Push**: Title and short message
- **In-App**: JSON structure with title, message, and potentially action links

## Best Practices

When creating templates:

1. **Keep templates modular** - Use consistent header/footer components
2. **Validate variables** - Ensure all required variables exist before rendering
3. **Test responsiveness** - Email templates should work on all device sizes
4. **Consider plain text** - Always provide plain text alternatives for emails
5. **Be concise** - Keep SMS and push notification content brief and clear
6. **Include branding** - Maintain consistent branding across templates
7. **Check for compliance** - Ensure templates follow email/SMS regulations

## Future Enhancements

Planned improvements to the template system:

1. Template versioning and history
2. A/B testing of templates
3. Visual template editor in admin interface
4. Internationalization support
5. More sophisticated template inheritance
6. Improved template validation 