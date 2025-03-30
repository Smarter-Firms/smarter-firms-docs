# Mailgun Integration

This document details the integration between the Smarter Firms Notification Service and Mailgun for email delivery.

## Overview

The Notification Service uses Mailgun as its primary email delivery provider. Mailgun provides a reliable, scalable API for sending transactional and marketing emails, with features like delivery tracking, bounce handling, and analytics.

## Architecture

The integration follows a provider pattern, which abstracts email delivery behind an interface and allows for potential future provider swaps or multi-provider strategies.

```typescript
export interface EmailProvider {
  sendEmail(to: string, subject: string, html: string, text?: string): Promise<void>;
}

export class MailgunProvider implements EmailProvider {
  // Implementation specific to Mailgun
}
```

## Configuration

Mailgun integration requires the following environment variables:

```
MAILGUN_API_KEY=your-mailgun-api-key
MAILGUN_DOMAIN=mg.smarterfirms.com
MAILGUN_FROM_EMAIL=notifications@smarterfirms.com
MAILGUN_FROM_NAME=Smarter Firms
```

These values can be obtained from your Mailgun dashboard after setting up a domain.

## Implementation

The integration uses the official `mailgun.js` SDK and `form-data` package:

```typescript
import formData from 'form-data';
import Mailgun from 'mailgun.js';
import { logger } from '../utils/logger';

export class MailgunProvider implements EmailProvider {
  private mailgun: any;
  private domain: string;
  private from: string;

  constructor(apiKey: string, domain: string, from: string) {
    const mailgun = new Mailgun(formData);
    this.mailgun = mailgun.client({ username: 'api', key: apiKey });
    this.domain = domain;
    this.from = from;
  }

  async sendEmail(to: string, subject: string, html: string, text?: string): Promise<void> {
    try {
      await this.mailgun.messages.create(this.domain, {
        from: this.from,
        to,
        subject,
        html,
        text: text || this.stripHtml(html)
      });
      logger.info('Email sent successfully', { to, subject });
    } catch (error) {
      logger.error('Failed to send email via Mailgun', { error, to, subject });
      throw new Error('Email delivery failed');
    }
  }

  private stripHtml(html: string): string {
    return html.replace(/<[^>]*>?/gm, '');
  }
}
```

## Email Delivery Process

1. When a notification is queued for the EMAIL channel, the notification service processes it
2. The template service renders the email content using Handlebars
3. The MailgunProvider is called with the recipient, subject, and rendered content
4. The provider sends the email through Mailgun's API
5. Success or failure is logged and the notification status is updated accordingly

## Error Handling

The Mailgun integration includes comprehensive error handling:

- Network errors during API calls are caught and logged
- API-specific errors from Mailgun are captured and reported
- All email send attempts are logged with appropriate metadata
- Failed deliveries update the notification status to FAILED
- The retry mechanism will attempt to resend failed notifications based on the configured retry policy

## Tracking and Reporting

Mailgun provides delivery tracking through webhooks. Future enhancements will include:

- Setting up webhooks for delivery, bounce, and complaint tracking
- Updating notification status based on webhook events
- Aggregating delivery statistics for reporting

## Best Practices

When working with the Mailgun integration:

1. Always include both HTML and plain text versions of emails
2. Use descriptive subject lines to improve open rates
3. Follow email deliverability best practices
4. Monitor bounces and complaints to maintain sender reputation
5. Use template variables properly to personalize content
6. Test emails across different email clients and devices

## Troubleshooting

Common issues and solutions:

- **Emails not being sent**: Verify Mailgun API credentials and domain verification status
- **Emails in spam folder**: Check sender reputation and SPF/DKIM records
- **Template rendering errors**: Ensure all required variables are provided
- **Rate limiting errors**: Implement proper throttling or queue processing strategies
- **Delivery failures**: Check logs for specific error messages from Mailgun

## Future Enhancements

Planned improvements to the Mailgun integration:

1. Implement webhook handling for better delivery tracking
2. Add support for email templates stored in Mailgun
3. Implement email analytics and reporting
4. Add support for email scheduling
5. Implement batching for bulk email sending 