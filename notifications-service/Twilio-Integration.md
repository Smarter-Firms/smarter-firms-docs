# Twilio Integration

This document details the integration between the Smarter Firms Notification Service and Twilio for SMS delivery, with a primary focus on two-factor authentication (2FA).

## Overview

The Notification Service uses Twilio as its SMS delivery provider. Twilio provides a reliable, global API for sending SMS messages, with features for delivery tracking, number management, and international coverage.

## Architecture

The integration follows a provider pattern, which abstracts SMS delivery behind an interface and allows for potential future provider swaps or multi-provider strategies.

```typescript
export interface SmsProvider {
  sendSms(to: string, message: string): Promise<void>;
}

export class TwilioProvider implements SmsProvider {
  // Implementation specific to Twilio
}
```

## Configuration

Twilio integration requires the following environment variables:

```
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+15551234567
```

These values can be obtained from your Twilio dashboard after setting up an account.

## Implementation

The integration uses the official `twilio` SDK:

```typescript
import twilio from 'twilio';
import { logger } from '../utils/logger';

export class TwilioProvider implements SmsProvider {
  private client: twilio.Twilio;
  private from: string;

  constructor(accountSid: string, authToken: string, from: string) {
    this.client = twilio(accountSid, authToken);
    this.from = from;
  }

  async sendSms(to: string, message: string): Promise<void> {
    try {
      await this.client.messages.create({
        body: message,
        from: this.from,
        to
      });
      logger.info('SMS sent successfully', { to });
    } catch (error) {
      logger.error('Failed to send SMS via Twilio', { error, to });
      throw new Error('SMS delivery failed');
    }
  }
}
```

## SMS Delivery Process

1. When a notification is queued for the SMS channel, the notification service processes it
2. The template service renders the SMS content using Handlebars
3. The TwilioProvider is called with the recipient phone number and rendered content
4. The provider sends the SMS through Twilio's API
5. Success or failure is logged and the notification status is updated accordingly

## Two-Factor Authentication (2FA)

The primary use case for SMS in Smarter Firms is two-factor authentication:

1. When a user attempts to log in or perform a sensitive action, the Auth Service requests a verification code
2. The Notification Service generates a random code (typically 6 digits)
3. A notification is sent using the SMS channel with a two-factor-auth template
4. The user receives the code and enters it to complete authentication

Example 2FA template (stored as `src/templates/two-factor-auth.hbs`):

```
Your Smarter Firms verification code is: {{code}}. This code will expire in {{expiryMinutes}} minutes. Do not share this code with anyone.
```

## Error Handling

The Twilio integration includes comprehensive error handling:

- Network errors during API calls are caught and logged
- API-specific errors from Twilio are captured and reported
- All SMS send attempts are logged with appropriate metadata
- Failed deliveries update the notification status to FAILED
- The retry mechanism will attempt to resend failed notifications based on the configured retry policy

## International Phone Number Support

Twilio supports international phone numbers, but requires proper formatting:

- Phone numbers should be stored in E.164 format (e.g., +15551234567)
- Country codes must be included for proper routing
- The Notification Service expects phone numbers to already be in the correct format

## Best Practices

When working with the Twilio integration:

1. Keep SMS messages concise (under 160 characters when possible)
2. Use clear, direct language for authentication messages
3. Include the company name to establish legitimacy
4. Don't include sensitive information in SMS messages
5. Follow SMS compliance regulations for your target countries
6. Monitor delivery rates and costs 

## Cost Management

SMS delivery incurs costs per message. To manage costs:

1. Only use SMS for critical notifications (like 2FA)
2. Monitor usage and set up alerts for unusual patterns
3. Consider rate limiting for specific notification types
4. Explore using WhatsApp or other messaging channels for some use cases

## Troubleshooting

Common issues and solutions:

- **Messages not being sent**: Verify Twilio API credentials and phone number capabilities
- **Delivery failures**: Check phone number format and international restrictions
- **Template rendering errors**: Ensure all required variables are provided
- **Rate limiting errors**: Implement proper throttling or queue processing strategies
- **High costs**: Review SMS usage patterns and optimize where possible

## Future Enhancements

Planned improvements to the Twilio integration:

1. Add support for WhatsApp messaging
2. Implement delivery receipt handling
3. Add phone number validation before sending
4. Support for more SMS templates beyond 2FA
5. Implement SMS analytics and reporting 