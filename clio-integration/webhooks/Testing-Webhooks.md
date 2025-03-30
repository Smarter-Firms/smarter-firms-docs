# Testing Webhooks Locally

Webhooks are an essential part of the Clio Integration Service, allowing real-time data synchronization. This guide walks through the process of testing webhooks in a local development environment.

## Prerequisites

Before you begin, make sure you have:

1. The Clio Integration Service running locally.
2. A Clio developer account with API access.
3. [ngrok](https://ngrok.com/) or similar tool for creating a public URL to your local server.
4. Postman or similar tool for making HTTP requests.

## Setup

### 1. Configure Environment Variables

Ensure the following environment variables are set in your `.env` file:

```
WEBHOOK_SECRET=your_webhook_secret
WEBHOOK_BASE_URL=https://your-ngrok-url.ngrok.io/api/webhooks
WEBHOOK_CALLBACK_PATH=/webhooks/clio
```

### 2. Create a Tunnel to Your Local Server

Start ngrok to create a tunnel to your local server:

```bash
# If your local server runs on port 3002
ngrok http 3002
```

Take note of the HTTPS URL provided by ngrok (e.g., `https://a1b2c3d4.ngrok.io`).

### 3. Update the Webhook Base URL

Update your `.env` file with the ngrok URL:

```
WEBHOOK_BASE_URL=https://a1b2c3d4.ngrok.io/api/webhooks
```

## Testing Webhook Reception

### 1. Simulate a Webhook from Clio

Use Postman or curl to send a test webhook:

```bash
curl -X POST https://a1b2c3d4.ngrok.io/api/webhooks/clio \
  -H "Content-Type: application/json" \
  -H "X-Clio-Signature: YOUR_GENERATED_SIGNATURE" \
  -d '{
    "event": "contact.created",
    "data": {
      "id": "123456",
      "type": "Contact"
    },
    "user_id": "user123",
    "timestamp": "2023-03-29T12:34:56Z"
  }'
```

### 2. Generate a Valid Signature

To generate a valid signature, use the following Node.js code snippet:

```javascript
const crypto = require('crypto');

const generateSignature = (payload, secret) => {
  const hmac = crypto.createHmac('sha256', secret);
  return hmac.update(JSON.stringify(payload)).digest('hex');
};

const payload = {
  event: 'contact.created',
  data: {
    id: '123456',
    type: 'Contact'
  },
  user_id: 'user123',
  timestamp: '2023-03-29T12:34:56Z'
};

const secret = 'your_webhook_secret'; // Use the same secret as in your .env file
const signature = generateSignature(payload, secret);
console.log('Signature:', signature);
```

Use the generated signature in the `X-Clio-Signature` header.

## Testing Webhook Registration

To test webhook registration:

```bash
curl -X POST https://a1b2c3d4.ngrok.io/api/webhooks/register/user123 \
  -H "Content-Type: application/json" \
  -d '{}'
```

Replace `user123` with a valid user ID from your database.

## Testing with the Clio API

To fully test webhook registration and reception with the Clio API:

1. Register a webhook in the Clio developer portal.
2. Set the webhook URL to your ngrok URL.
3. Make changes to data in Clio (create/update contacts or matters).
4. Check the logs of your local server for webhook reception and processing.

## Troubleshooting

### Common Issues

1. **Invalid Signature**: Make sure you're using the same webhook secret for signature generation and validation.

2. **Webhook Not Received**: Check ngrok's web interface to see if the request reached your tunnel. If not, verify that Clio's webhook URL is correct.

3. **Database Connection Issues**: Ensure your local database is running and accessible.

4. **Webhook Processing Errors**: Check the logs for detailed error messages.

### Testing Tools

- Use the `enableLogging` flag in the webhook service to see detailed logs of webhook processing.
- Implement a webhook test endpoint that logs the raw request for debugging.
- Use the ngrok web interface to inspect webhook requests.

## Mock Webhook Payloads

### Contact Created Event

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

### Matter Updated Event

```json
{
  "event": "matter.updated",
  "data": {
    "id": "789012",
    "type": "Matter"
  },
  "user_id": "user123",
  "timestamp": "2023-03-29T12:34:56Z"
}
```

### Contact Deleted Event

```json
{
  "event": "contact.deleted",
  "data": {
    "id": "123456",
    "type": "Contact"
  },
  "user_id": "user123",
  "timestamp": "2023-03-29T12:34:56Z"
}
```

## Adding Webhook Support for New Entities

To add webhook support for new Clio entities:

1. Update the webhook service to handle the new entity type.
2. Create a transformer for the entity.
3. Implement a repository for storing the entity.
4. Update the webhook registration process to include the new entity.
5. Add test cases for the new entity webhook processing. 