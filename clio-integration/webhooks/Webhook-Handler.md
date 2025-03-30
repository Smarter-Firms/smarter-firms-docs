# Webhook Handler Component

The Webhook Handler is a key component of the Clio Integration Service, responsible for receiving and processing notifications from Clio when data changes.

## Overview

Webhooks allow the Clio Integration Service to receive real-time notifications about changes to data in the Clio system, such as when contacts or matters are created, updated, or deleted. This eliminates the need for constant polling and ensures that our system stays in sync with the latest changes.

## Architecture

The Webhook component consists of the following parts:

1. **Webhook Routes**: Express routes that receive incoming webhook requests from Clio.
2. **Webhook Controller**: Handles HTTP requests, validates webhook signatures, and delegates processing.
3. **Webhook Service**: Contains the core business logic for processing webhook payloads and interacting with repositories.
4. **Raw Body Middleware**: Captures the raw request body for signature validation.

## Webhook Flow

1. Clio sends a webhook notification to our `/webhooks/clio` endpoint when data changes.
2. The raw body middleware captures the request body as a string for signature verification.
3. The webhook controller validates the webhook signature using HMAC-SHA256.
4. If the signature is valid, the webhook service processes the payload:
   - For contact events, it fetches the contact from Clio, transforms it, and updates the local database.
   - For matter events, it fetches the matter from Clio, transforms it, and updates the local database.
5. A success response is sent back to Clio.

## Webhook Registration

Webhooks must be registered with Clio for each user who connects their Clio account. The registration process:

1. When a user connects their Clio account, we register for webhooks using `/webhooks/register/:userId`.
2. The webhook service calls the Clio API to register webhook endpoints for contacts and matters.
3. Clio stores these webhook registrations and begins sending notifications to our endpoint.

## Security

Webhook security is critical to ensure that only legitimate requests from Clio are processed:

1. **Signature Validation**: Each webhook request includes an `x-clio-signature` header containing an HMAC-SHA256 signature of the request body, using a shared secret.
2. **Request Verification**: The webhook service verifies this signature by calculating the expected signature and comparing it to the received signature.
3. **Webhook Secret Management**: The webhook secret is stored as an environment variable.

## Error Handling

The webhook handler implements comprehensive error handling:

1. Invalid signatures result in 401 Unauthorized responses.
2. Processing errors are caught, logged, and result in 500 Internal Server Error responses.
3. All operations are logged for debugging and monitoring.

## Testing

The webhook component includes multiple levels of testing:

1. **Unit Tests**: Test individual components in isolation with mocked dependencies.
2. **Integration Tests**: Test the interaction between components.
3. **End-to-End Tests**: Test the complete webhook flow using supertest.

## Example Webhook Payload

```json
{
  "event": "contact.created",
  "data": {
    "id": "123456",
    "type": "Contact"
  },
  "user_id": "user123",
  "timestamp": "2023-03-29T12:34:56Z"
}
```

## Setting Up Webhook Environment

To set up webhooks for development and testing:

1. Set the `WEBHOOK_SECRET` environment variable.
2. For local development, use a tool like ngrok to expose your local server to the internet.
3. Update the webhook URL in the Clio developer console to point to your ngrok URL.

## Monitoring and Debugging

For monitoring webhook processing:

1. Check the application logs for webhook related entries.
2. Set up alerts for webhook processing errors.
3. Implement webhook processing metrics to track success/failure rates. 