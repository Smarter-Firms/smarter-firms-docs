# Smarter Firms Onboarding Application

## Overview

The Onboarding Application is a client-facing Next.js web application that guides new users through setting up their account with Smarter Firms. The application implements a multi-step wizard flow that collects essential information from users and configures their account with proper permissions and integrations.

## Key Features

- Multi-step wizard interface for guided onboarding
- Responsive, mobile-friendly design
- Form validation with helpful error messages
- Integration with Auth, Clio, and Billing services
- Progress tracking and resumable flows
- Clear visual feedback and success states

## Architecture

The Onboarding Application follows a modern Next.js App Router architecture with React components and TypeScript. It uses the UI Service component library for all UI elements, ensuring a consistent look and feel across the Smarter Firms platform.

### Tech Stack

- **Frontend Framework**: Next.js 14 with App Router
- **UI Components**: @smarterfirms/ui-components library
- **State Management**: React Context API and React Hooks
- **Form Handling**: React Hook Form with Zod validation
- **Styling**: TailwindCSS with DaisyUI
- **HTTP Client**: Axios for API calls
- **Authentication**: NextAuth.js

### Project Structure

```
src/
├── app/
│   ├── _lib/
│   │   ├── onboarding/          # Onboarding context and state management
│   │   └── services/            # Service integrations (auth, clio, firm, subscription)
│   ├── onboarding/
│   │   ├── steps/               # Step components for each stage of onboarding
│   │   ├── clio/                # Clio OAuth callback handler
│   │   ├── api/                 # API routes for onboarding
│   │   └── page.tsx             # Main onboarding page with StepWizard
│   └── page.tsx                 # Root redirect to onboarding
├── styles/                      # Global styles
└── types/                       # TypeScript type definitions
```

## Component Integration

The Onboarding Application exclusively uses components from the UI Service component library. No custom UI components are created; instead, existing components are composed together to build the onboarding flow.

### Key Components Used

- `StepWizard`: For multi-step navigation and progress tracking
- `AuthForm`: For user registration and account creation
- `Card`: For content containers and grouping related form fields
- `Input`, `Select`, `MultiSelect`: For form fields
- `Button`: For actions and navigation
- `ClioConnectCard`: For Clio OAuth integration
- `SubscriptionPlanSelector`: For plan selection
- `Toast`: For success/error notifications
- `Modal`: For confirmations
- `LoadingIndicator`: For loading states

## Service Integrations

The Onboarding Application integrates with multiple backend services:

1. **Auth Service**: User registration and authentication
2. **Firm Service**: Creating and configuring firm details
3. **Clio Integration Service**: OAuth connection to Clio
4. **Subscription Service**: Plan selection and billing setup

## Getting Started

### Prerequisites

- Node.js 18.x or later
- npm or yarn

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy the `.env.local.example` to `.env.local` and fill in required variables
4. Start the development server:
   ```bash
   npm run dev
   ```

## Development Guidelines

1. Always use components from the UI Service component library
2. Follow TypeScript strict mode with proper type definitions
3. Use React hooks for state management
4. Implement proper error handling with appropriate UI feedback
5. Follow existing design patterns in the codebase

## Related Documentation

- [Onboarding Flow Documentation](./Onboarding-Flow.md)
- [Component Integration Documentation](./Component-Integration.md)
- [API Integration Documentation](./API-Integration.md)
- [State Management Documentation](./State-Management.md) 