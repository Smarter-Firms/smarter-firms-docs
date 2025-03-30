# AI Agent Coordination for Standardization Initiative

## Overview

This document outlines the process for coordinating the standardization initiative across multiple AI agents representing different microservice teams. This approach allows us to simulate team interactions and ensure comprehensive implementation of the standardization requirements.

## Coordination Strategy

### 1. Agent Assignment

Assign dedicated AI agents to represent each team or service:

| Agent ID | Representing | Primary Responsibilities |
|----------|--------------|--------------------------|
| Agent-UI | UI-Service Team | Tailwind configuration extraction and documentation |
| Agent-Infra | Infrastructure Team | AWS development environment setup |
| Agent-API | API Gateway Team | API standards and service discovery |
| Agent-Auth | Auth Service Team | Implementing standards in Auth Service |
| Agent-Data | Data Service Team | Implementing standards in Data Service |
| Agent-Notification | Notification Service Team | Implementing standards in Notification Service |
| Agent-Dashboard | Dashboard Team | Implementing standards in Dashboard Service |
| Agent-PM | Project Management | Coordination and progress tracking |

### 2. Kickoff Meeting Simulation

#### Step 1: Initial Briefing

For each agent, provide the following information:

1. The [Standardization-Memo.md](./Standardization-Memo.md) document
2. The [Standardization-Tasks.md](./Standardization-Tasks.md) document
3. Their team-specific task document (e.g., [UI-Service-Tasks.md](./UI-Service-Tasks.md))
4. The [Service-Teams-Tasks.md](./Service-Teams-Tasks.md) document (for service implementation teams)

#### Step 2: Initial Response Collection

Ask each agent to produce:

1. A brief acknowledgment of the standardization initiative
2. Any clarifying questions they have
3. Initial thoughts on implementation approach
4. Potential challenges specific to their team/service

#### Step 3: Centralized Questions & Answers

1. Compile all questions from agents
2. Provide a consolidated response addressing common themes
3. Share this Q&A document with all agents

#### Step 4: Implementation Planning

Ask each agent to produce:

1. A detailed implementation plan for their specific tasks
2. Resources/dependencies they need from other teams
3. Timeline with key milestones
4. Success criteria for their deliverables

### 3. Ongoing Coordination

#### Regular Check-ins

Simulate sprint check-ins by asking each agent to provide:

1. Progress updates on key tasks
2. Blockers or dependencies needed from other teams
3. Revised timeline if applicable
4. Questions for other teams

#### Document Sharing

When an agent produces a significant document or artifact:

1. Store it in the appropriate location in the documentation repository
2. Notify other relevant agents about its availability
3. Ask affected agents to review and provide feedback

#### Cross-Team Collaboration

For tasks requiring collaboration:

1. Identify the agents that need to work together
2. Provide both agents with the same context and requirements
3. Have each agent propose their part of the solution
4. Synthesize their responses into a cohesive approach

### 4. Key Agent Prompts

#### Kickoff Prompt Template

```
You are the AI agent representing the [TEAM NAME]. You have been assigned to implement the standardization initiative for your team.

Please review the following documents:
1. Standardization-Memo.md - Overview of the initiative
2. Standardization-Tasks.md - Master task list
3. [TEAM-SPECIFIC]-Tasks.md - Your team's specific tasks
4. Service-Teams-Tasks.md - How other teams will integrate with your work

Based on these documents:
1. Acknowledge your understanding of the initiative
2. List any questions you have about the requirements
3. Provide your initial thoughts on implementation approach
4. Identify potential challenges specific to your team
5. Outline next steps you would take to begin implementation
```

#### Progress Update Prompt Template

```
As the AI agent for the [TEAM NAME], provide a progress update on your standardization tasks:

1. What tasks have you completed since the last update?
2. What tasks are you currently working on?
3. Are there any blockers preventing progress?
4. Do you need anything from other teams?
5. Is your timeline still on track? If not, what's the new projection?
6. What will you focus on next?
```

#### Technical Implementation Prompt Template

```
As the [TEAM NAME] AI agent, you need to implement [SPECIFIC TASK].

Context:
- [Relevant technical details]
- [Existing infrastructure/code references]
- [Requirements and constraints]

Please provide:
1. A technical design for implementation
2. Code samples or configuration examples
3. Testing approach
4. Documentation for other teams

Remember to follow the project's established standards and patterns.
```

### 5. Document Approval Workflow

For major deliverables, implement an approval workflow:

1. Agent creates initial document/artifact
2. Share with Agent-PM for review
3. Share with any dependent team agents for feedback
4. Collect and synthesize feedback
5. Have original agent implement revisions
6. Finalize and distribute the approved version

## Example Workflow: Tailwind Configuration Package

1. **Kickoff**: Agent-UI receives the standardization documents and responds with implementation plan
2. **Implementation**: Agent-UI produces package structure, configuration examples, and documentation
3. **Review**: Agent-PM and Agent-Dashboard review the package design
4. **Feedback**: Compile feedback and share with Agent-UI
5. **Revision**: Agent-UI revises the implementation based on feedback
6. **Distribution**: Share final package details with all service team agents
7. **Integration**: Agent-Dashboard demonstrates implementation in their service
8. **Verification**: Agent-UI verifies correct implementation

## Tips for Effective Agent Coordination

1. **Maintain Context**: Always remind each agent of their role and prior conversations
2. **Document Everything**: Save all significant outputs to the documentation repository
3. **Clear Handoffs**: When transitioning work between agents, provide complete context
4. **Consistent Formatting**: Use consistent document formats for better synthesis
5. **Realistic Timing**: Simulate realistic project timelines in your prompts
6. **Challenge Testing**: Occasionally introduce realistic challenges to test robustness
7. **Cross-Pollination**: Share innovative approaches between agents when relevant

## Next Steps

1. Create a directory structure for agent outputs
2. Draft initial prompts for each agent based on the templates
3. Begin with the kickoff meeting simulation
4. Establish a tracking mechanism for cross-agent dependencies 