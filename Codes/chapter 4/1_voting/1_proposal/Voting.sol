// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    event ProposalCreated(uint);
    event VoteCast(uint, address);

    enum Vote {
        NOT_CAST,
        YES,
        NO
    }

    struct Proposal {
        address target;
        bytes data;
        uint yesCount;
        uint noCount;
    }

    Proposal[] public proposals;
    mapping(uint => mapping(address => Vote)) public votes;
    mapping(address => bool) public members;
    mapping(uint => bool) public executionState;

    error Forbidden();

    constructor(address[] memory _members) {
        members[msg.sender] = true;
        for (uint i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
    }

    modifier onlyMember() {
        if (!members[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    function newProposal(address _target, bytes calldata _data) external onlyMember {
        proposals.push(Proposal(_target, _data, 0, 0));
        emit ProposalCreated(proposals.length - 1);
    }

    function castVote(uint _id, bool _vote) external onlyMember {
        if (hasVoted(_id, msg.sender)) {
            reduceVote(_id, votes[_id][msg.sender]);
        }
        if (_vote) {
            proposals[_id].yesCount++;
            votes[_id][msg.sender] = Vote.YES;
        } else {
            proposals[_id].noCount++;
            votes[_id][msg.sender] = Vote.NO;
        }

        if (proposals[_id].yesCount > 9 && !executionState[_id]) {
            (bool success,) = proposals[_id].target.call(proposals[_id].data);
            require(success);

            executionState[_id] = true;
        }

        emit VoteCast(_id, msg.sender);
    }

    function hasVoted(uint _id, address _addr) private view returns (bool) {
        return votes[_id][_addr] != Vote.NOT_CAST;
    }

    function reduceVote(uint _id, Vote _vote) private {
        if (_vote == Vote.YES) {
            proposals[_id].yesCount--;
        } else {
            proposals[_id].noCount--;
        }
    }
}

