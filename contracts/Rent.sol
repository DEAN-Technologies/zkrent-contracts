// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Rent {
    address public owner;
    uint256 public counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    struct Property {
        address owner;
        address guest;
        string name;
        string propertyAddress;
        string description;
        string imgUrl;
        uint64 bookingStartsAt;
        uint64 bookingEndsAt;
        uint256 pricePerDay;
        uint64 numberOfRooms;
        uint64 area;
        bool isBooked;
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
        uint256 id
    );

    event PropertyBookedEvent(
        uint256 id,
        address guest,
        uint64 numberOfDays,
        uint256 price
    );

    modifier onlyPropertyOwner (uint256 propertyId) {
        address propertyOwner = properties[propertyId].owner;
        require(propertyOwner == msg.sender, "Only property owner");
        _;
    }

    modifier onlyNotBooked (uint256 propertyId) {
        Property storage property = properties[propertyId];
        require(!property.isBooked, "Property is booked");
        _;
    }

    mapping(uint256 => Property) public properties;

    function listProperty(
        string memory name,
        string memory propertyAddress,
        string memory description,
        string memory imgUrl,
        uint64 pricePerDay,
        uint64 numberOfRooms,
        uint64 area
    ) public returns (uint256) {
        counter += 1;
        Property storage newProperty = properties[counter];

        newProperty.name = name;
        newProperty.propertyAddress = propertyAddress;
        newProperty.description = description;
        newProperty.imgUrl = imgUrl;
        newProperty.pricePerDay = pricePerDay;
        newProperty.isBooked = false;
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

        return counter;
    }

    function unlistProperty(
        uint256 propertyId
    ) public onlyPropertyOwner(propertyId)
             onlyNotBooked(propertyId) {
        Property storage property = properties[propertyId];
        require(property.isActive, "Propertyhas been already unlisted");
        property.isActive = false;
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

    function bookProperty(
        uint256 propertyId,
        uint64 startDate,
        uint64 endDate
    ) public payable {
        uint64 numberOfDays = (endDate - startDate) / 86400000;

        require(
            msg.value >= numberOfDays * properties[propertyId].pricePerDay,
            "Send more ETH."
        );
        payable(properties[propertyId].owner).transfer(msg.value);

        properties[propertyId].isBooked = true;
        properties[propertyId].bookingStartsAt = startDate;
        properties[propertyId].bookingEndsAt = endDate;
        properties[propertyId].guest = msg.sender;

        emit PropertyBookedEvent(
            propertyId,
            msg.sender,
            numberOfDays,
            msg.value
        );
    }

    function unBookProperty(uint256 propertyId) public {
        require(
            properties[propertyId].owner == msg.sender,
            "Only the Property Owner can unbook the property"
        );

        require(
            properties[propertyId].isBooked == true,
            "Property is not booked"
        );

        properties[propertyId].isBooked = false;
    }
}