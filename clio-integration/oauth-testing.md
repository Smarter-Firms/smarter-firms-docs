# OAuth Testing Guide

This guide explains how to set up and run OAuth tests for the Clio Integration Service using our testing framework and ngrok.

## Prerequisites

Before you start:

1. Ensure you have ngrok installed:
   ```bash
   npm install -g ngrok
   ```

2. Have your Clio API credentials ready (client ID and client secret)

3. Make sure your local development server is running on port 3000

## Setup using the Permanent ngrok URL

We've set up a permanent ngrok URL (`quality-foal-skilled.ngrok-free.app`) to make testing OAuth flows easier and more consistent. This eliminates the need to update your Clio application's redirect URI each time you start a new ngrok session.

### Step 1: Start ngrok

Run the following command to start ngrok with our permanent URL:

```bash
ngrok http --url=quality-foal-skilled.ngrok-free.app 3000
```

This will forward requests made to `quality-foal-skilled.ngrok-free.app` to your local server running on port 3000.

### Step 2: Configure your test environment

Create or update your `config/default.json` file with the permanent ngrok URL as the redirect URI:

```json
{
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET",
  "redirectUri": "https://quality-foal-skilled.ngrok-free.app/api/clio/oauth/callback",
  "apiUrl": "https://app.clio.com/api/v4"
}
```

### Step 3: Configure Your Clio Application

Make sure your registered Clio application has the following redirect URI:

```
https://quality-foal-skilled.ngrok-free.app/api/clio/oauth/callback
```

You can add this URI in the Clio Developer Portal under your application settings.

## Running OAuth Tests

Our testing framework provides simple commands to test the OAuth flow:

### Basic OAuth Flow Test

Run a complete OAuth flow test:

```bash
npx clio-test oauth --mode test --ngrok
```

This will:
1. Generate an authorization URL using the ngrok redirect URI
2. Prompt you to visit the URL and authorize the application
3. Wait for you to complete the flow and obtain the authorization code
4. Exchange the code for tokens (you'll need to manually provide the code)

### Step-by-Step Testing

You can also test each step of the OAuth flow individually:

1. **Generate an authorization URL**:
   ```bash
   npx clio-test oauth --mode url --ngrok
   ```

2. **Exchange an authorization code for tokens**:
   ```bash
   npx clio-test oauth --mode exchange --code YOUR_CODE --ngrok
   ```

3. **Refresh an access token**:
   ```bash
   npx clio-test oauth --mode refresh
   ```

4. **Validate a token**:
   ```bash
   npx clio-test oauth --mode validate
   ```

## Testing in CI/CD Environments

For CI/CD pipelines, you can use environment variables to configure OAuth testing:

```yaml
# Example GitHub Actions workflow
jobs:
  oauth-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
      - name: Install dependencies
        run: npm ci
      - name: Run OAuth tests
        run: npm run test:oauth
        env:
          CLIO_CLIENT_ID: ${{ secrets.CLIO_CLIENT_ID }}
          CLIO_CLIENT_SECRET: ${{ secrets.CLIO_CLIENT_SECRET }}
          CLIO_REDIRECT_URI: https://quality-foal-skilled.ngrok-free.app/api/clio/oauth/callback
```

## Handling Callbacks Locally

To properly handle OAuth callbacks in your local application:

1. Make sure your server is listening on port 3000

2. Implement a route handler for `/api/clio/oauth/callback` that can:
   - Extract the authorization code from the query parameters
   - Display the code to the user or provide a way to copy it
   - Optionally, exchange the code for tokens automatically

Example Express.js route handler:

```javascript
app.get('/api/clio/oauth/callback', (req, res) => {
  const { code, state } = req.query;
  
  // Display the authorization code to the user
  res.send(`
    <html>
      <body>
        <h1>OAuth Callback Received</h1>
        <p>Authorization Code: <strong>${code}</strong></p>
        <p>State: ${state}</p>
        <p>Use this code in your test command:</p>
        <pre>npx clio-test oauth --mode exchange --code ${code} --ngrok</pre>
      </body>
    </html>
  `);
});
```

## Troubleshooting

If you encounter issues with the OAuth flow:

1. **Cannot connect to ngrok**: Make sure you're using the correct command to start ngrok. The `--url` parameter is required for the permanent URL.

2. **Invalid redirect URI**: Double-check that the redirect URI in your Clio application settings exactly matches the one used in your test configuration.

3. **Authorization code expired**: OAuth authorization codes are typically valid for a short time (usually 5-10 minutes). If you get an error about an expired code, restart the OAuth flow to get a new code.

4. **Invalid client ID or secret**: Verify your client credentials are correct and have the necessary permissions.

5. **Ngrok tunnel not working**: Make sure your ngrok tunnel is active and correctly forwarding requests to your local server.

6. **Local server not running**: Ensure your local server is running on port 3000 and can handle requests to the callback endpoint. 