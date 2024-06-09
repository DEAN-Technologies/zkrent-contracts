// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RentStatistic {
    mapping(address => uint256) public totalEarned;
    mapping(address => uint256) public totalSpent;
    
    mapping(address => uint256) public daysBookedAsOwner;
    mapping(address => uint256) public daysBookedAsGuest;

    mapping(address => uint256) public timesBookedAsOwner;
    mapping(address => uint256) public timesBookedAsGuest;

    struct Statistic {
        uint256 totalEarned;
        uint256 totalSpent;
        uint256 daysBookedAsOwner;
        uint256 daysBookedAsGuest;
        uint256 timesBookedAsOwner;
        uint256 timesBookedAsGuest;
    }

    function getStatistic(address user) external view returns (Statistic memory statistic) {
        statistic = Statistic(totalEarned[user],
                                               totalSpent[user],
                                               daysBookedAsOwner[user],
                                               daysBookedAsGuest[user],
                                               timesBookedAsOwner[user],
                                               timesBookedAsGuest[user]);
    }

    function updateStatistic(address owner, address guest, uint64 numberOfDays) internal {
        totalEarned[owner] += msg.value;
        totalSpent[guest] += msg.value;
        daysBookedAsOwner[owner] += numberOfDays;
        daysBookedAsGuest[guest] += numberOfDays;
        timesBookedAsOwner[owner] += 1;
        timesBookedAsGuest[guest] += 1;
    }

    function revertStatistic(address owner, address guest, uint64 numberOfDays) internal {
        totalEarned[owner] -= msg.value;
        totalSpent[guest] -= msg.value;
        daysBookedAsOwner[owner] -= numberOfDays;
        daysBookedAsGuest[guest] -= numberOfDays;
        timesBookedAsOwner[owner] -= 1;
        timesBookedAsGuest[guest] -= 1;
    }
    
}