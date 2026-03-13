// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {

    //Constructor
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Initial Declarations
    uint256 jobIdCounter = 0;
    struct Job {
        address creator;
        uint256 id;
        string title;
        string description;
        uint256 budget;
        uint256 deadline;
        Status status;
    }

    enum Status {
        Open, 
        Assigned,
        Completed,
        Cancelled
    }

    uint256 proposalIdCounter = 0;
    struct Proposal {
        address freelancer;
        uint256 id;
        uint256 jobId;
        string cv;
        uint256 proposedPrice;
        uint256 estimateDelivery;
        bool isAccepted;
    }

    mapping(uint256 => Job) jobs;
    mapping(uint256 => Proposal) proposals;
    mapping(uint256 => uint256[]) jobProposals;
    mapping(uint256 => uint256) jobToAcceptedProposal;

    // Events
    event NewJob(uint256, string);
    event NewProposal(uint256);
    event ProposalAccepted(uint256, uint256);
    event PaymentsDone(address, address);
    event JobCancelled(uint256);

    // Function to create job
    function createJob(string memory _title, string memory _description, uint256 _budget, uint256 _deadline) external {

        // Perform checks before creating job
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(_budget > 0, "Budget must be greater than 0.");

        // Increment ID counter for unique ID
        jobIdCounter += 1;

        // Create a new job
        Job memory newJob = Job({
            creator: msg.sender,
            id: jobIdCounter,
            title: _title,
            description: _description,
            budget: _budget,
            deadline: _deadline,
            status: Status.Open
        });

        // Add to mapping
        jobs[jobIdCounter] = newJob;

        // Emit event
        emit NewJob(jobIdCounter, _title);
    }

    // Function to create a proposal
    function createProposal(uint256 _jobId, string memory _cv, uint256 _proposedPrice, uint256 _estimateDelivery) external {

        // Perform checks
        require(_proposedPrice > 0, "Proposed price must be greater than 0.");
        require(_estimateDelivery > block.timestamp, "Delivery date must be in the future.");
        require(jobs[_jobId].creator != msg.sender, "Can't send a proposal for your own job.");
        require(jobs[_jobId].status == Status.Open, "Can't submit proposal as job has been assigned, completed or cancelled.");

        // Create ID
        proposalIdCounter += 1;

        // Create a new proposal
        Proposal memory newProposal = Proposal({
            freelancer: msg.sender,
            id: proposalIdCounter,
            jobId: _jobId,
            cv: _cv,
            proposedPrice: _proposedPrice,
            estimateDelivery: _estimateDelivery,
            isAccepted: false
        });

        // Save proposal to mapping
        proposals[proposalIdCounter] = newProposal;

        // Add proposal ID to mapping with job ID
        jobProposals[_jobId].push(proposalIdCounter);

        // Emit event
        emit NewProposal(proposalIdCounter);
    }

    // Function to retrieve proposals from job
    function getProposals(uint256 _jobId) public view returns(uint256[] memory){
        return jobProposals[_jobId];
    }

    // Function to accept a proposal
    function acceptProposal(uint256 _jobId, uint256 _proposalId) external payable {

        // Perform checks
        require(msg.sender == jobs[_jobId].creator, "Only job creator can accept a proposal.");
        require(jobs[_jobId].creator != proposals[_proposalId].freelancer, "Can't accept your own proposal.");
        require(msg.value == proposals[_proposalId].proposedPrice, "Amount sent must be the agreed amount.");
        require(proposals[_proposalId].jobId == _jobId, "The proposal is not assigned to the job.");

        // Change the proposal status to accepted
        proposals[_proposalId].isAccepted = true;

        // Relate job to proposal
        jobToAcceptedProposal[_jobId] = _proposalId;

        // Change the job status
        jobs[_jobId].status = Status.Assigned;

        // Emit an event
        emit ProposalAccepted(_jobId, _proposalId);
    }

    // Helper function to stay DRY
    function _paymentHandler(uint256 _jobId) private {

        // Get the proposal ID
        uint256 proposalId = jobToAcceptedProposal[_jobId];

        // Figure out fees
        uint256 agreedPrice = proposals[proposalId].proposedPrice;
        uint256 platformFee =  (agreedPrice * 5) / 100;
        uint256 freelancerFee = agreedPrice - platformFee;

        // Substract 5% from contract to owner
        (bool ownerPayment, ) = payable(owner).call{value: platformFee}('');
        require(ownerPayment, "ETH transfer was not completed.");

        // Substract 95% from contract to freelancer
        (bool freelancerPayment, ) = payable(proposals[proposalId].freelancer).call{value: freelancerFee}('');
        require(freelancerPayment, "ETH transfer was not completed.");

        // Mark job as completed
        jobs[_jobId].status = Status.Completed;

        // Emit event
        emit PaymentsDone(owner, proposals[proposalId].freelancer);
    }

    // Function to complete the job
    function completeJob(uint256 _jobId) external {

        // Get proposal ID
        uint256 proposalId = jobToAcceptedProposal[_jobId];

        // Perform checks
        require(proposalId != 0, "No proposal accepted yet.");
        require(msg.sender == jobs[_jobId].creator, "Only job creator can complete the job.");
        require(jobs[_jobId].status == Status.Assigned, "Status must be 'assigned' to be able to complete job.");
        
        // Call helper function to handle payments
        _paymentHandler(_jobId);
    }

    // Function to cancel the job (only when marked as open)
    function cancelJob(uint256 _jobId) external {

        // Perform checks
        require(msg.sender == jobs[_jobId].creator, "Only job creator can accept a proposal.");
        require(jobs[_jobId].status == Status.Open, "Job status must be open.");

        // Change the job's status
        jobs[_jobId].status = Status.Cancelled;

        // Emit event
        emit JobCancelled(_jobId);
    }

    // Function to handle disputes
    function handleDispute(uint256 _jobId) external {

        // Get proposal ID
        uint256 proposalId = jobToAcceptedProposal[_jobId];

        // Perform checks
        require(proposalId != 0, "No proposal accepted yet.");
        require(msg.sender == proposals[proposalId].freelancer, "Only the freelancer can handle disputes.");
        require(proposals[proposalId].jobId == _jobId, "The proposal is not assigned to the job.");
        require(block.timestamp > jobs[_jobId].deadline + 7 days, "7 days have not elapsed yet.");

        // Call helper function to handle payments
        _paymentHandler(_jobId);
    }
}