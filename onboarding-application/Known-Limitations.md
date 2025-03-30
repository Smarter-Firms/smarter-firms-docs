# Known Limitations and Issues

This document outlines the current known limitations and issues with the Smarter Firms Onboarding Application. These are items that are acknowledged but either are not critical for the initial release or have planned fixes in the next iteration.

## Authentication

### Session Persistence
- **Issue**: Session persistence requires refresh on page reload
- **Impact**: Users may lose session state when refreshing the page during onboarding
- **Workaround**: Complete the onboarding flow without refreshing the page
- **Planned Fix**: Implement persistent storage of onboarding progress with server-side sessions in v1.1

### Password Reset
- **Issue**: Password reset flow not fully implemented
- **Impact**: Users who forget their password during onboarding can't easily recover
- **Workaround**: Support team can manually assist users with password resets
- **Planned Fix**: Complete password reset flow implementation in v1.1

## Clio Integration

### Limited Permissions
- **Issue**: Limited to Matter sync permissions only
- **Impact**: Users can't sync contacts and other Clio data
- **Workaround**: None available; feature limitation
- **Planned Fix**: Expand Clio integration scope in v1.2

### OAuth Token Refresh
- **Issue**: OAuth token refresh not automatically handled
- **Impact**: Clio tokens can expire requiring manual reconnection
- **Workaround**: Users can reconnect to Clio when prompted
- **Planned Fix**: Implement automatic token refresh in v1.1

### Sandbox Testing Only
- **Issue**: Integration currently works only with Clio sandbox accounts
- **Impact**: Can't connect to production Clio accounts
- **Workaround**: Use sandbox accounts for demonstration purposes
- **Planned Fix**: Complete production Clio integration before general release

## Subscription

### Payment Method Storage
- **Issue**: Payment method storage requires additional security review
- **Impact**: Limited payment processing options available
- **Workaround**: Manual payment setup after onboarding
- **Planned Fix**: Complete security review and implement enhanced payment storage in v1.1

### Plan Limitations
- **Issue**: Limited to three pre-defined plans
- **Impact**: No custom plans or promotions available
- **Workaround**: Sales team can manually adjust plans after onboarding
- **Planned Fix**: Implement dynamic plan loading and custom plan options in v1.3

### Billing Cycle Changes
- **Issue**: Billing cycle can't be changed after selection
- **Impact**: Users must contact support to change from monthly to annual or vice versa
- **Workaround**: Support team can manually adjust billing cycles
- **Planned Fix**: Add self-service billing cycle changes in v1.2

## Performance

### Form Submission Delays
- **Issue**: Large form submissions may experience delay on slower connections
- **Impact**: Users may perceive the application as unresponsive
- **Workaround**: Improved loading indicators implemented
- **Planned Fix**: Optimize form submission process and add submission chunking in v1.1

### StepWizard Initial Load
- **Issue**: StepWizard rendering can be optimized for initial load time
- **Impact**: First page load may be slower than optimal
- **Workaround**: None needed; performance is acceptable for most users
- **Planned Fix**: Implement code splitting and lazy loading of wizard steps in v1.1

### Mobile Performance
- **Issue**: Performance on low-end mobile devices may be suboptimal
- **Impact**: Slower transitions and form submissions on older mobile devices
- **Workaround**: Recommend desktop use for optimal experience
- **Planned Fix**: Mobile performance optimization in v1.2

## Browser Compatibility

### IE Support
- **Issue**: No support for Internet Explorer
- **Impact**: Users on IE cannot use the application
- **Workaround**: Use modern browsers (Chrome, Firefox, Safari, Edge)
- **Planned Fix**: No plans to support IE; will officially support Edge only

### Older Safari Versions
- **Issue**: Limited support for Safari versions older than 14
- **Impact**: Users on older Safari versions may experience UI issues
- **Workaround**: Update to latest Safari version
- **Planned Fix**: Broader Safari compatibility in v1.2

## Data Management

### Data Persistence
- **Issue**: Onboarding data not persisted between sessions
- **Impact**: Users must complete onboarding in one session
- **Workaround**: Complete onboarding without closing browser
- **Planned Fix**: Implement data persistence in v1.1

### Data Export
- **Issue**: No option to export entered data
- **Impact**: Users cannot save a copy of their information
- **Workaround**: Support can provide data exports upon request
- **Planned Fix**: Add data export functionality in v1.3

## Integration Limitations

### Third-Party Services
- **Issue**: Limited to Clio integration only
- **Impact**: Users of other practice management systems cannot sync data
- **Workaround**: Manual data entry for non-Clio users
- **Planned Fix**: Add additional integrations (Rocket Matter, PracticePanther) in v2.0

### API Rate Limits
- **Issue**: Potential API rate limiting on high-volume usage
- **Impact**: Delays possible during peak onboarding periods
- **Workaround**: Retry mechanism implemented for API calls
- **Planned Fix**: Implement queuing system for API calls in v1.2

## Process Limitations

### Multi-User Onboarding
- **Issue**: No support for collaborative onboarding by multiple firm users
- **Impact**: Only one user can complete the onboarding process
- **Workaround**: Share login credentials for collaborative setup (not recommended)
- **Planned Fix**: Implement team onboarding features in v2.0

### Progress Recovery
- **Issue**: Limited ability to recover from catastrophic errors
- **Impact**: Users may need to restart onboarding after major errors
- **Workaround**: Support team can assist with recovery
- **Planned Fix**: Implement comprehensive error recovery in v1.2 