# Decentralized Freelance Platform

A smart contract-based freelance marketplace built with Solidity that enables trustless job posting, proposal submission, escrow payments, and automated dispute resolution on the Ethereum blockchain.

## Overview

This project implements a fully functional decentralized freelance platform where clients can post jobs, freelancers can submit proposals, and payments are held in escrow until work completion. The platform includes automated dispute resolution for cases where clients fail to release payment within the agreed timeframe.

## Features

### Core Functionality

**Job Management**

- Clients can create job postings with title, description, budget, and deadline
- Each job receives a unique ID via counter-based system
- Jobs have status tracking: Open, Assigned, Completed, Cancelled
- Job creators can cancel jobs before assignment
- Deadline validation ensures all jobs have future completion dates

**Proposal System**

- Freelancers submit proposals with cover letter, proposed price, and estimated delivery time
- Multiple freelancers can propose on the same job
- Each proposal is linked to a specific job via job ID
- Proposals tracked with unique IDs
- Self-proposal prevention (cannot propose on own jobs)

**Escrow & Payment**

- Client accepts one proposal and deposits payment into contract
- Funds held securely in escrow until job completion
- Job status automatically updates to Assigned upon acceptance
- Only job creator can accept proposals
- Exact payment amount validation

**Payment Release**

- Client marks job as complete to release payment
- Platform automatically deducts 5% fee
- Freelancer receives 95% of agreed price
- Platform owner can withdraw accumulated fees
- Payment split handled atomically

**Dispute Resolution**

- Automated dispute handling after deadline expiration
- Freelancers can claim payment 7 days after deadline passes
- Same payment split applies (95% freelancer, 5% platform)
- Time-based validation using block timestamps
- Prevents premature payment claims

### Security Features

- Access control on all critical functions
- Exact payment amount validation
- Prevention of self-hiring and self-proposal acceptance
- Proposal-to-job verification
- Status-based operation restrictions
- Secure ETH transfers using low-level call

## Technical Details

### Smart Contract Structure

**Enums**

```solidity
enum Status { Open, Assigned, Completed, Cancelled }
```

**Structs**

- `Job`: Stores job information (creator, id, title, description, budget, deadline, status)
- `Proposal`: Stores proposal data (freelancer, id, jobId, cv, proposedPrice, estimateDelivery, isAccepted)

**Key Mappings**

- `jobs`: Maps job ID to Job struct
- `proposals`: Maps proposal ID to Proposal struct
- `jobProposals`: Maps job ID to array of proposal IDs
- `jobToAcceptedProposal`: Maps job ID to accepted proposal ID

**Core Functions**

```solidity
createJob(string _title, string _description, uint256 _budget, uint256 _deadline)
createProposal(uint256 _jobId, string _cv, uint256 _proposedPrice, uint256 _estimateDelivery)
acceptProposal(uint256 _jobId, uint256 _proposalId) payable
completeJob(uint256 _jobId)
handleDispute(uint256 _jobId)
cancelJob(uint256 _jobId)
getProposals(uint256 _jobId) view returns(uint256[])
```

**Helper Functions**

- `_paymentHandler(uint256 _jobId)`: Private function handling payment distribution to avoid code duplication

### Payment Flow

1. **Job Creation**: Client posts job with budget and deadline
2. **Proposal Submission**: Freelancers submit competitive proposals
3. **Proposal Acceptance**: Client selects proposal and sends payment to contract (escrow)
4. **Work Completion**: Freelancer completes work by deadline
5. **Payment Release**:
   - Normal: Client marks complete, triggering payment
   - Dispute: After deadline + 7 days, freelancer can claim payment
6. **Fee Distribution**: 5% to platform owner, 95% to freelancer

### Time-Based Logic

The contract uses Solidity's built-in time units and `block.timestamp` for deadline management:

```solidity
require(_deadline > block.timestamp, "Deadline must be in the future");
require(block.timestamp > jobs[_jobId].deadline + 7 days, "Must wait 7 days");
```

### Fee Calculation

Platform fees are calculated using integer arithmetic to avoid decimals:

```solidity
uint256 platformFee = (agreedPrice * 5) / 100;  // 5% fee
uint256 freelancerFee = agreedPrice - platformFee;  // 95% payment
```

## Usage

### Deployment

1. Compile with Solidity compiler version ^0.8.0
2. Deploy to preferred network (testnet recommended for testing)
3. Deployer becomes platform owner automatically via constructor
4. No constructor parameters required

### Creating a Job

```solidity
// Create job with 1 ETH budget, 30-day deadline
uint256 deadline = block.timestamp + 30 days;
createJob("Build Website", "Need React developer", 1000000000000000000, deadline);
```

### Submitting a Proposal

```solidity
// Propose for job #1 with slightly lower price
createProposal(1, "5 years React experience...", 900000000000000000, block.timestamp + 25 days);
```

### Accepting a Proposal

```solidity
// Accept proposal #1 for job #1, send exact payment amount
acceptProposal(1, 1); // Must send 900000000000000000 wei as msg.value
```

### Completing Work

```solidity
// Client marks job complete (normal flow)
completeJob(1);

// OR freelancer claims after deadline + 7 days (dispute flow)
handleDispute(1);
```

### Cancelling a Job

```solidity
// Only possible before any proposal is accepted
cancelJob(1);
```

## Events

The contract emits events for off-chain tracking and UI updates:

- `NewJob(uint256 jobId, string title)`
- `NewProposal(uint256 proposalId)`
- `ProposalAccepted(uint256 jobId, uint256 proposalId)`
- `PaymentsDone(address owner, address freelancer)`
- `JobCancelled(uint256 jobId)`

## Testing Scenarios

1. **Complete Job Flow**: Create job, submit proposals, accept one, complete work, verify payment
2. **Multiple Proposals**: Multiple freelancers propose, verify only one can be accepted
3. **Access Control**: Attempt unauthorized operations (non-creator cancelling, non-freelancer disputes)
4. **Payment Validation**: Try accepting with incorrect payment amount
5. **Dispute Resolution**: Simulate deadline expiration, verify freelancer can claim after 7 days
6. **Self-Hiring Prevention**: Attempt to accept own proposal
7. **Status Transitions**: Verify correct status changes throughout lifecycle
8. **Edge Cases**: Cancel after assignment (should fail), complete before assignment (should fail)

## Design Patterns

### Escrow Pattern

The contract acts as a trusted intermediary holding funds until conditions are met, eliminating need for direct client-to-freelancer trust.

### State Machine

Jobs transition through defined states (Open → Assigned → Completed) with validation at each step.

### Time-Based Automation

Leverages blockchain timestamps for deadline enforcement and dispute resolution triggers.

### DRY Principle

Payment logic extracted to `_paymentHandler` helper function to avoid duplication between normal completion and dispute resolution.

## Development Environment

- **Language**: Solidity ^0.8.0
- **License**: MIT
- **Recommended IDE**: Remix IDE for quick prototyping and testing
- **Testing Network**: Ethereum testnets (Sepolia, Goerli)
- **Tools**: Can be integrated with Hardhat or Foundry for advanced testing

## Future Enhancements

**Security Improvements**

- Implement ReentrancyGuard from OpenZeppelin
- Add pause functionality for emergency stops
- Implement withdrawal pattern for platform fees

**Feature Additions**

- Milestone-based payments for large projects
- Review and rating system for freelancers and clients
- Proposal editing and withdrawal capabilities
- Job editing before assignment
- Refund mechanism for cancelled jobs
- Multi-signature arbitration for disputes
- Category/tag system for job discovery
- Freelancer profile and portfolio

**Gas Optimizations**

- Pack struct variables for storage efficiency
- Optimize array operations in proposal retrieval
- Implement pagination for large proposal lists

## Contract Interactions

### For Clients

1. Call `createJob()` with job details and future deadline
2. Review proposals using `getProposals(jobId)`
3. Call `acceptProposal()` with payment to accept chosen freelancer
4. Call `completeJob()` when satisfied with deliverables
5. Optionally call `cancelJob()` if no proposals accepted yet

### For Freelancers

1. Browse available jobs (off-chain or via events)
2. Call `createProposal()` to bid on interesting jobs
3. Complete work by agreed deadline
4. If client doesn't release payment, wait 7 days after deadline
5. Call `handleDispute()` to claim payment automatically

### For Platform Owner

1. Deploy contract (becomes owner automatically)
2. Platform fee accumulates in contract from each completed job
3. Implement separate withdrawal function to claim accumulated fees

## License

MIT License - see LICENSE file for details

## Author

Built as a learning project to practice advanced Solidity concepts including:

- Escrow payment patterns
- Time-based contract logic
- Complex state management with enums
- Multi-entity coordination
- Fee calculation without decimals
- Access control patterns
- Event emission for off-chain tracking
- Code reusability with helper functions
