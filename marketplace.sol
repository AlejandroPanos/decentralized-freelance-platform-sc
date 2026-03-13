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

    
}