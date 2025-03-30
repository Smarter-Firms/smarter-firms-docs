# UAT Test Cases - Smarter Firms Onboarding Application

## Test Case Structure
Each test case follows this structure:
- **ID**: Unique identifier for the test case
- **Description**: What the test case is verifying
- **Preconditions**: Required state before executing the test
- **Test Steps**: Step-by-step instructions
- **Expected Results**: What should happen when the steps are executed
- **Actual Results**: [To be filled by tester]
- **Status**: Not Started / Pass / Fail
- **Notes**: Any additional observations

---

## 1. Account Creation & Management

### TC-AC-001: New User Registration
- **Description**: Verify that a new user can successfully register
- **Preconditions**: User has a valid email address
- **Test Steps**:
  1. Navigate to the onboarding start page
  2. Click "Get Started"
  3. Fill in all required fields with valid data
  4. Click "Continue"
  5. Verify email received (if implemented)
  6. Click verification link (if implemented)
- **Expected Results**: 
  - User account is created successfully
  - User advances to Step 2 (Firm Information)
  - Confirmation email is sent (if implemented)

### TC-AC-002: Registration with Invalid Data
- **Description**: Verify that validation errors are shown for invalid registration data
- **Preconditions**: None
- **Test Steps**:
  1. Navigate to the onboarding start page
  2. Click "Get Started"
  3. Enter invalid email format
  4. Enter password less than 8 characters
  5. Leave required fields empty
  6. Click "Continue"
- **Expected Results**: 
  - Form submission is prevented
  - Appropriate validation errors are displayed
  - Focus is set to the first invalid field

### TC-AC-003: Password Reset
- **Description**: Verify that a user can reset their password
- **Preconditions**: User has a registered account
- **Test Steps**:
  1. Navigate to the login page
  2. Click "Forgot Password"
  3. Enter registered email
  4. Submit form
  5. Check email for reset link
  6. Click reset link
  7. Enter new password
  8. Submit form
- **Expected Results**: 
  - Password reset email is sent
  - User can set a new password
  - User can log in with new password

---

## 2. Firm Setup

### TC-FS-001: Creating a New Law Firm
- **Description**: Verify that a user can create a new law firm
- **Preconditions**: User has completed Step 1 (Account Creation)
- **Test Steps**:
  1. Navigate to Step 2 (Firm Information)
  2. Enter firm name
  3. Select firm size
  4. Select practice areas
  5. Enter address details
  6. Click "Continue"
- **Expected Results**: 
  - Firm information is saved
  - User advances to Step 3 (Clio Integration)

### TC-FS-002: Firm Setup with Invalid Data
- **Description**: Verify validation for invalid firm data
- **Preconditions**: User has completed Step 1 (Account Creation)
- **Test Steps**:
  1. Navigate to Step 2 (Firm Information)
  2. Leave firm name empty
  3. Leave firm size unselected
  4. Enter invalid zip code format
  5. Click "Continue"
- **Expected Results**: 
  - Form submission is prevented
  - Appropriate validation errors are displayed

### TC-FS-003: Save and Resume Firm Setup
- **Description**: Verify that partial firm information is saved and can be resumed
- **Preconditions**: User has started Step 2 (Firm Information)
- **Test Steps**:
  1. Enter partial firm information
  2. Log out or close browser
  3. Log back in
  4. Navigate to onboarding
- **Expected Results**: 
  - User is returned to Step 2
  - Previously entered information is preserved

---

## 3. Clio Integration

### TC-CI-001: Authorizing Connection to Clio
- **Description**: Verify that a user can connect to Clio
- **Preconditions**: User has completed Step 2 (Firm Information)
- **Test Steps**:
  1. Navigate to Step 3 (Clio Integration)
  2. Click "Connect to Clio"
  3. Log in with Clio credentials in the popup
  4. Authorize the application
- **Expected Results**: 
  - User is redirected back to the onboarding app
  - Success message is displayed
  - User can proceed to Step 4

### TC-CI-002: Skipping Clio Integration
- **Description**: Verify that a user can skip Clio integration
- **Preconditions**: User has completed Step 2 (Firm Information)
- **Test Steps**:
  1. Navigate to Step 3 (Clio Integration)
  2. Click "Skip for now"
- **Expected Results**: 
  - User advances to Step 4 (Subscription)
  - A note indicates they can set up integration later

### TC-CI-003: Revoking Clio Authorization
- **Description**: Verify that a user can revoke Clio integration
- **Preconditions**: User has connected to Clio
- **Test Steps**:
  1. Navigate to Step 3 (Clio Integration)
  2. Click "Disconnect from Clio"
  3. Confirm the action
- **Expected Results**: 
  - Connection is revoked
  - Interface shows option to connect again

---

## 4. Subscription Management

### TC-SM-001: Viewing and Selecting a Plan
- **Description**: Verify that a user can view and select a subscription plan
- **Preconditions**: User has completed Step 3 (Clio Integration)
- **Test Steps**:
  1. Navigate to Step 4 (Subscription)
  2. View available plans
  3. Select a plan
  4. Choose billing frequency (monthly/annual)
  5. Click "Continue"
- **Expected Results**: 
  - Selected plan is highlighted
  - Plan details are displayed
  - User advances to Step 5 (Payment)

### TC-SM-002: Changing Billing Frequency
- **Description**: Verify that changing billing frequency updates the price
- **Preconditions**: User is on Step 4 (Subscription)
- **Test Steps**:
  1. Select a plan
  2. Switch between monthly and annual billing
- **Expected Results**: 
  - Price updates according to selected frequency
  - Annual discount is applied when selecting annual billing

### TC-SM-003: Comparing Plans
- **Description**: Verify that plan comparison is clear and usable
- **Preconditions**: User is on Step 4 (Subscription)
- **Test Steps**:
  1. Review all plan options
  2. Compare features between plans
  3. Identify the "popular" plan
- **Expected Results**: 
  - Features are clearly listed for each plan
  - Differences between plans are highlighted
  - Popular plan is visually distinct

---

## 5. Payment Processing

### TC-PP-001: Adding Payment Method
- **Description**: Verify that a user can add a payment method
- **Preconditions**: User has selected a subscription plan
- **Test Steps**:
  1. Navigate to Step 5 (Payment)
  2. Enter payment card details
  3. Enter billing address
  4. Click "Complete Setup"
- **Expected Results**: 
  - Payment method is accepted
  - Subscription is created
  - User is directed to the dashboard

### TC-PP-002: Payment with Invalid Card
- **Description**: Verify validation for invalid payment details
- **Preconditions**: User has selected a subscription plan
- **Test Steps**:
  1. Navigate to Step 5 (Payment)
  2. Enter invalid card number
  3. Enter expired expiration date
  4. Enter invalid CVC
  5. Click "Complete Setup"
- **Expected Results**: 
  - Payment is rejected
  - Appropriate error messages are displayed
  - User remains on the payment form

### TC-PP-003: Payment Processing Feedback
- **Description**: Verify that user receives appropriate feedback during payment processing
- **Preconditions**: User has entered valid payment details
- **Test Steps**:
  1. Click "Complete Setup"
  2. Observe UI during processing
- **Expected Results**: 
  - Loading indicator is displayed during processing
  - Success message is shown after completion
  - Error message is shown if processing fails

---

## 6. Navigation Through Onboarding

### TC-NO-001: Navigating Between Steps
- **Description**: Verify that a user can navigate between onboarding steps
- **Preconditions**: User has started the onboarding process
- **Test Steps**:
  1. Complete Step 1
  2. Navigate to Step 2
  3. Click "Back" button
  4. Click "Continue" button again
- **Expected Results**: 
  - Back button returns to previous step
  - Continue button advances to next step
  - Step indicator shows current position

### TC-NO-002: Progress Saving
- **Description**: Verify that progress is saved between sessions
- **Preconditions**: User has partially completed onboarding
- **Test Steps**:
  1. Complete steps 1 and 2
  2. Log out or close browser
  3. Log back in
  4. Navigate to onboarding
- **Expected Results**: 
  - User is returned to the last completed step + 1
  - Previously entered information is preserved

### TC-NO-003: Progress Indicator
- **Description**: Verify that progress indicator accurately reflects current step
- **Preconditions**: User has started the onboarding process
- **Test Steps**:
  1. Navigate through each step of onboarding
  2. Observe progress indicator at each step
- **Expected Results**: 
  - Current step is highlighted in the progress indicator
  - Completed steps are marked as complete
  - Future steps are visually distinct

---

## 7. Cross-Functional Tests

### TC-CF-001: Browser Compatibility
- **Description**: Verify that the application works in all supported browsers
- **Preconditions**: None
- **Test Steps**:
  1. Complete the onboarding flow in Chrome
  2. Complete the onboarding flow in Firefox
  3. Complete the onboarding flow in Safari
  4. Complete the onboarding flow in Edge
- **Expected Results**: 
  - Application functions correctly in all browsers
  - UI renders consistently across browsers

### TC-CF-002: Mobile Responsiveness
- **Description**: Verify that the application is usable on mobile devices
- **Preconditions**: None
- **Test Steps**:
  1. Access the application on a smartphone
  2. Complete the onboarding flow
  3. Access the application on a tablet
  4. Complete the onboarding flow
- **Expected Results**: 
  - UI adapts appropriately to screen size
  - All functions work on mobile devices
  - Forms are usable on touchscreens

### TC-CF-003: Accessibility Compliance
- **Description**: Verify that the application meets accessibility standards
- **Preconditions**: None
- **Test Steps**:
  1. Navigate through the onboarding flow using keyboard only
  2. Use a screen reader to navigate through the flow
  3. Check color contrast ratios
  4. Test with browser zoom at 200%
- **Expected Results**: 
  - All functionality is accessible via keyboard
  - Screen readers can access all content
  - Color contrast meets WCAG AA standards
  - UI is usable with zoom up to 200% 