# Onboarding Application UAT Guide

This guide provides instructions for conducting User Acceptance Testing on the Smarter Firms Onboarding Application.

## Setup Instructions

### Prerequisites
- Node.js 18.x or later
- npm or yarn
- Git access to the repository

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/Smarter-Firms/Onboarding-Application.git
   ```

2. Install dependencies:
   ```
   cd Onboarding-Application
   npm install
   ```

3. Set up environment:
   ```
   cp .env.local.example .env.local
   ```

4. Start the application with mock API:
   ```
   npm run mock-api
   ```
   In a separate terminal:
   ```
   npm run dev:mock
   ```

5. Navigate to http://localhost:3000 in your browser

## Test Credentials

Use the following test credentials during testing:

### User Account
- Email: uat-tester@smarterfirms.com
- Password: TestPassword123!

### Clio Sandbox
- Email: clio-sandbox@smarterfirms.com
- Password: ClioTest456!
- Application ID: Available in 1Password "Clio UAT Credentials" entry

### Stripe Test Cards
- Successful payment: 4242 4242 4242 4242
- Declined payment: 4000 0000 0000 0002
- Use any future expiration date and any 3-digit CVC

## Test Scenarios

Please complete the following test scenarios and record your findings.

### 1. Complete Onboarding Flow

1. Access the application at http://localhost:3000
2. Complete all 5 steps of the onboarding process:
   - Account Creation
   - Firm Details
   - Clio Connection
   - Subscription Selection
   - Confirmation
3. Verify you are redirected to the dashboard after completion

**Expected Result**: All steps complete successfully with appropriate feedback at each stage.

### 2. Skipping Optional Steps

1. Complete the Account Creation step
2. Complete the Firm Details step
3. Skip the Clio Connection step
4. Skip the Subscription Selection step
5. Verify on the Confirmation page that both steps are marked as "Not connected/selected"
6. Complete the onboarding process

**Expected Result**: Application allows skipping optional steps while maintaining data integrity.

### 3. Form Validation Testing

1. On the Account Creation step:
   - Try submitting with invalid email formats
   - Try using a weak password
   - Attempt to submit with missing required fields
2. On the Firm Details step:
   - Try submitting without selecting a practice area
   - Try submitting without entering required address fields

**Expected Result**: Clear validation messages appear for each field with an appropriate error.

### 4. Error Handling

1. During testing, disconnect from the internet
2. Attempt to submit a form
3. Reconnect and try again

**Expected Result**: User-friendly error messages appear; data persists when connection is restored.

### 5. UI/UX Feedback

Please document your observations about:
- Clarity of instructions at each step
- Visual feedback during loading states
- Responsiveness on different devices
- Accessibility (keyboard navigation, screen reader compatibility)

## Reporting Issues

If you encounter any issues during testing, please record:
1. The specific step/scenario where the issue occurred
2. Steps to reproduce the issue
3. Expected vs. actual behavior
4. Screenshots if applicable
5. Device, browser, and screen size

Submit issues via the [UAT Issue Tracker](https://github.com/Smarter-Firms/Onboarding-Application/issues/new?template=uat-feedback.md) using the UAT Feedback template.

## Test Completion

Once you've completed all test scenarios, please submit your feedback via the UAT Feedback form, including:
- Overall assessment of the application
- Any critical issues that should block release
- Suggestions for improvements
- Assessment of user journey and flow

Thank you for participating in User Acceptance Testing for the Smarter Firms Onboarding Application. 