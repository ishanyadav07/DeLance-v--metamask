// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EscrowMarketplace {
    enum JobStatus {
        Open,
        InProgress,
        Completed,
        Disputed
    }

    enum MilestoneStatus {
        Pending,
        Funded,
        Submitted,
        Approved
    }

    struct Job {
        address client;
        address freelancer;
        JobStatus status;
        uint256 milestoneCount;
        uint256 fundedTotal;
    }

    struct Milestone {
        string metadata;
        uint256 amount;
        MilestoneStatus status;
    }

    struct Dispute {
        address openedBy;
        string reason;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool resolved;
        bool approved;
    }

    address public owner;
    uint256 public disputeQuorum;
    uint256 public nextJobId;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => Milestone[]) public milestones;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public disputeVotes;
    mapping(address => bool) public daoVoters;
    mapping(address => uint256) public freelancerReputation;

    event JobCreated(uint256 indexed jobId, address indexed client, address indexed freelancer);
    event MilestoneAdded(uint256 indexed jobId, uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneFunded(uint256 indexed jobId, uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneSubmitted(uint256 indexed jobId, uint256 indexed milestoneIndex);
    event MilestoneApproved(uint256 indexed jobId, uint256 indexed milestoneIndex, uint256 amount);
    event DisputeOpened(uint256 indexed jobId, address indexed openedBy, uint256 deadline);
    event DisputeVoted(uint256 indexed jobId, address indexed voter, bool support);
    event DisputeResolved(uint256 indexed jobId, bool approved);
    event DisputeQuorumUpdated(uint256 quorum);
    event ReputationUpdated(address indexed freelancer, uint256 score, string reason);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner');
        _;
    }

    modifier onlyClient(uint256 jobId) {
        require(msg.sender == jobs[jobId].client, 'Only client');
        _;
    }

    modifier onlyFreelancer(uint256 jobId) {
        require(msg.sender == jobs[jobId].freelancer, 'Only freelancer');
        _;
    }

    modifier onlyDaoVoter() {
        require(daoVoters[msg.sender], 'Only DAO voter');
        _;
    }

    constructor() {
        owner = msg.sender;
        daoVoters[msg.sender] = true;
        disputeQuorum = 1;
    }

    function setDaoVoter(address voter, bool enabled) external onlyOwner {
        require(voter != address(0), 'Invalid voter');
        daoVoters[voter] = enabled;
    }

    function setDisputeQuorum(uint256 quorum) external onlyOwner {
        require(quorum > 0, 'Invalid quorum');
        disputeQuorum = quorum;
        emit DisputeQuorumUpdated(quorum);
    }

    function createJob(address freelancer) external returns (uint256 jobId) {
        require(freelancer != address(0), 'Invalid freelancer');

        jobId = nextJobId;
        nextJobId += 1;

        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            status: JobStatus.Open,
            milestoneCount: 0,
            fundedTotal: 0
        });

        emit JobCreated(jobId, msg.sender, freelancer);
    }

    function addMilestone(uint256 jobId, string calldata metadata, uint256 amount) external onlyClient(jobId) {
        require(amount > 0, 'Invalid amount');
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Open || job.status == JobStatus.InProgress, 'Job closed');

        milestones[jobId].push(Milestone({
            metadata: metadata,
            amount: amount,
            status: MilestoneStatus.Pending
        }));

        job.milestoneCount += 1;
        emit MilestoneAdded(jobId, milestones[jobId].length - 1, amount);
    }

    function fundMilestone(uint256 jobId, uint256 milestoneIndex) external payable onlyClient(jobId) {
        Milestone storage milestone = milestones[jobId][milestoneIndex];
        require(milestone.status == MilestoneStatus.Pending, 'Already funded');
        require(msg.value == milestone.amount, 'Incorrect value');

        milestone.status = MilestoneStatus.Funded;
        jobs[jobId].status = JobStatus.InProgress;
        jobs[jobId].fundedTotal += msg.value;

        emit MilestoneFunded(jobId, milestoneIndex, msg.value);
    }

    function submitMilestone(uint256 jobId, uint256 milestoneIndex) external onlyFreelancer(jobId) {
        Milestone storage milestone = milestones[jobId][milestoneIndex];
        require(milestone.status == MilestoneStatus.Funded, 'Not funded');

        milestone.status = MilestoneStatus.Submitted;
        emit MilestoneSubmitted(jobId, milestoneIndex);
    }

    function approveMilestone(uint256 jobId, uint256 milestoneIndex) external onlyClient(jobId) {
        Milestone storage milestone = milestones[jobId][milestoneIndex];
        require(milestone.status == MilestoneStatus.Submitted, 'Not submitted');

        milestone.status = MilestoneStatus.Approved;
        jobs[jobId].fundedTotal -= milestone.amount;

        (bool success, ) = jobs[jobId].freelancer.call{value: milestone.amount}('');
        require(success, 'Transfer failed');

        _increaseReputation(jobs[jobId].freelancer, 'milestone_approved');

        emit MilestoneApproved(jobId, milestoneIndex, milestone.amount);
    }

    function openDispute(uint256 jobId, string calldata reason, uint256 votingPeriodSeconds) external {
        Job storage job = jobs[jobId];
        require(job.client == msg.sender || job.freelancer == msg.sender, 'Unauthorized');
        require(job.status == JobStatus.InProgress, 'Job not active');
        require(!disputes[jobId].resolved && disputes[jobId].deadline == 0, 'Dispute exists');
        require(votingPeriodSeconds > 0, 'Invalid voting period');

        disputes[jobId] = Dispute({
            openedBy: msg.sender,
            reason: reason,
            deadline: block.timestamp + votingPeriodSeconds,
            yesVotes: 0,
            noVotes: 0,
            resolved: false,
            approved: false
        });

        job.status = JobStatus.Disputed;
        emit DisputeOpened(jobId, msg.sender, disputes[jobId].deadline);
    }

    function voteDispute(uint256 jobId, bool support) external onlyDaoVoter {
        Dispute storage dispute = disputes[jobId];
        require(dispute.deadline > 0, 'No dispute');
        require(block.timestamp <= dispute.deadline, 'Voting ended');
        require(!disputeVotes[jobId][msg.sender], 'Already voted');

        disputeVotes[jobId][msg.sender] = true;

        if (support) {
            dispute.yesVotes += 1;
        } else {
            dispute.noVotes += 1;
        }

        emit DisputeVoted(jobId, msg.sender, support);
    }

    function resolveDispute(uint256 jobId) external onlyDaoVoter {
        Dispute storage dispute = disputes[jobId];
        Job storage job = jobs[jobId];
        require(dispute.deadline > 0, 'No dispute');
        require(block.timestamp > dispute.deadline, 'Voting active');
        require(!dispute.resolved, 'Already resolved');
        require(dispute.yesVotes + dispute.noVotes >= disputeQuorum, 'Quorum not met');

        bool approved = dispute.yesVotes > dispute.noVotes;
        dispute.resolved = true;
        dispute.approved = approved;

        uint256 payout;
        Milestone[] storage jobMilestones = milestones[jobId];

        for (uint256 i = 0; i < jobMilestones.length; i++) {
            Milestone storage milestone = jobMilestones[i];
            if (milestone.status == MilestoneStatus.Funded || milestone.status == MilestoneStatus.Submitted) {
                payout += milestone.amount;
                milestone.status = approved ? MilestoneStatus.Approved : MilestoneStatus.Pending;
            }
        }

        if (payout > 0) {
            jobs[jobId].fundedTotal -= payout;
            address recipient = approved ? job.freelancer : job.client;
            (bool success, ) = recipient.call{value: payout}('');
            require(success, 'Dispute payout failed');
        }

        job.status = JobStatus.Completed;
        if (approved) {
            _increaseReputation(job.freelancer, 'dispute_won');
        } else {
            _decreaseReputation(job.freelancer, 'dispute_lost');
        }
        emit DisputeResolved(jobId, approved);
    }

    function _increaseReputation(address freelancer, string memory reason) internal {
        freelancerReputation[freelancer] += 1;
        emit ReputationUpdated(freelancer, freelancerReputation[freelancer], reason);
    }

    function _decreaseReputation(address freelancer, string memory reason) internal {
        if (freelancerReputation[freelancer] > 0) {
            freelancerReputation[freelancer] -= 1;
            emit ReputationUpdated(freelancer, freelancerReputation[freelancer], reason);
        }
    }
}
