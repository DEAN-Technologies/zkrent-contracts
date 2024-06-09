// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RentStatistic {
    mapping(address => Statistic) public addressToStatistic;

    struct Statistic {
        uint256 totalEarned;
        uint256 totalSpent;
        uint256 daysBookedAsOwner;
        uint256 daysBookedAsGuest;
        uint256 timesBookedAsOwner;
        uint256 timesBookedAsGuest;
    }

    function getStatistic(address user) external view returns (Statistic memory statistic) {
        statistic = addressToStatistic[user];
    }

    function updateStatistic(address owner, address guest, uint64 numberOfDays) internal {
        Statistic storage ownerStatistic = addressToStatistic[owner];
        Statistic storage guestStatistic = addressToStatistic[guest];
        ownerStatistic.totalEarned += msg.value;
        guestStatistic.totalSpent += msg.value;
        ownerStatistic.daysBookedAsOwner += numberOfDays;
        guestStatistic.daysBookedAsGuest += numberOfDays;
        ownerStatistic.timesBookedAsOwner += 1;
        guestStatistic.timesBookedAsGuest += 1;
    }

    function revertStatistic(address owner, address guest, uint64 numberOfDays) internal {
        Statistic storage ownerStatistic = addressToStatistic[owner];
        Statistic storage guestStatistic = addressToStatistic[guest];
        ownerStatistic.totalEarned -= msg.value;
        guestStatistic.totalSpent -= msg.value;
        ownerStatistic.daysBookedAsOwner -= numberOfDays;
        guestStatistic.daysBookedAsGuest -= numberOfDays;
        ownerStatistic.timesBookedAsOwner -= 1;
        guestStatistic.timesBookedAsGuest -= 1;
    }
    
}