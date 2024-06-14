// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RentStatistic} from "./RentStatistics.sol";

contract Rent is Ownable, RentStatistic {
    uint256 public counter;

    constructor() Ownable(msg.sender){
        counter = 0;
        whitelist[msg.sender] = true;
    }

    struct Property {
        address owner;
        address guest;
        string name;
        string propertyAddress;
        string description;
        string imgUrl;
        uint256 pricePerDay;
        uint64 bookingStartsAt;
        uint64 bookingEndsAt;
        uint64 numberOfRooms;
        uint64 area;
        bool isActive;
    }

    event PropertyListedEvent(
        string name,
        string propertyAddress,
        string description,
        string imgUrl,
        uint256 pricePerDay,
        uint64 numberOfRooms,
        uint64 area,
        uint256 propertyId
    );

    event PropertyBookedEvent(
        uint256 propertyId,
        address guest,
        uint64 numberOfDays,
        uint256 price
    );

    modifier onlyPropertyOwner(uint256 propertyId) {
        Property storage property = properties[propertyId];
        require(property.owner == msg.sender, "Only property owner");
        _;
    }

    modifier onlyBooked(uint256 propertyId) {
        Property storage property = properties[propertyId];
        require(property.guest != address(0), "Only booked");
        _;
    }

    modifier onlyNotBooked(uint256 propertyId) {
        Property storage property = properties[propertyId];
        require(property.guest == address(0), "Only not booked");
        _;
    }

    modifier onlyPropertyGuest(uint256 propertyId) {
        Property storage property = properties[propertyId];
        require(property.guest == msg.sender, "Only property guest");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Only whitelisted");
        _;
    }

    mapping(uint256 => Property) public properties;
    mapping(address => bool) public whitelist;

    function addUserToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
    }

    function listProperty(
        string memory name,
        string memory propertyAddress,
        string memory description,
        string memory imgUrl,
        uint256 pricePerDay,
        uint64 numberOfRooms,
        uint64 area
    ) public onlyWhitelisted() returns (uint256) {
        Property storage newProperty = properties[counter];

        newProperty.name = name;
        newProperty.propertyAddress = propertyAddress;
        newProperty.description = description;
        newProperty.imgUrl = imgUrl;
        newProperty.pricePerDay = pricePerDay;
        newProperty.isActive = true;
        newProperty.bookingStartsAt = 0;
        newProperty.bookingEndsAt = 0;
        newProperty.numberOfRooms = numberOfRooms;
        newProperty.area = area;
        newProperty.owner = msg.sender;
        newProperty.guest = address(0);

        emit PropertyListedEvent(
            name,
            propertyAddress,
            description,
            imgUrl,
            pricePerDay,
            numberOfRooms,
            area,
            counter
        );
        counter += 1;

        return counter;
    }

    function unlistProperty(
        uint256 propertyId
    ) public onlyPropertyOwner(propertyId)
             onlyNotBooked(propertyId) {
        Property storage property = properties[propertyId];
        require(property.isActive, "Property has been already unlisted");
        property.isActive = false;
    }

    function bookProperty(
        uint256 propertyId,
        uint64 startDate,
        uint64 endDate
    ) public payable onlyNotBooked(propertyId) onlyWhitelisted {
        // endDate and startDate are in milliseconds
        uint64 numberOfDays = (endDate - startDate) / (1 days * 1000);

        require(
            msg.value >= numberOfDays * properties[propertyId].pricePerDay,
            "Send more ETH."
        );
        payable(properties[propertyId].owner).transfer(msg.value);

        properties[propertyId].bookingStartsAt = startDate;
        properties[propertyId].bookingEndsAt = endDate;
        properties[propertyId].guest = msg.sender;
        
        // Statistic update
        updateStatistic(properties[propertyId].owner,
                        properties[propertyId].guest,
                        numberOfDays);

        emit PropertyBookedEvent(
            propertyId,
            msg.sender,
            numberOfDays,
            msg.value
        );
    }

    function getPropertyRentPrice(
        uint256 propertyId
    ) public view onlyBooked(propertyId) returns (uint256) {
        Property storage property = properties[propertyId];

        return getDuePrice(propertyId, property.bookingStartsAt, property.bookingEndsAt);
    }

    function getDuePrice(
        uint256 id,
        uint256 startDate,
        uint256 endDate
    ) public view returns (uint256) {
        Property storage property = properties[id];

        uint256 numberOfDays = (endDate - startDate) / 86400000;
        return numberOfDays * property.pricePerDay;
    }

    function unBookPropertyByOwner(
        uint256 propertyId
    ) public payable
             onlyBooked(propertyId)
             onlyPropertyOwner(propertyId)
    {
        uint256 rentPrice = getPropertyRentPrice(propertyId);

        require(
            msg.value == rentPrice,
            "ETH value not equal booking price"
        );
        payable(properties[propertyId].guest).transfer(msg.value);

        uint64 numberOfDays = 
            (properties[propertyId].bookingEndsAt - properties[propertyId].bookingStartsAt) / (1 days * 1000);

        // Statistic revert
        revertStatistic(properties[propertyId].owner,
                        properties[propertyId].guest,
                        numberOfDays);
        properties[propertyId].guest = address(0);
    }

    function unBookPropertyByGuest(
        uint256 propertyId
    ) public payable
             onlyBooked(propertyId)
             onlyPropertyGuest(propertyId)
    {
        properties[propertyId].guest = address(0);
    }
}