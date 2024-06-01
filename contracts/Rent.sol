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

    mapping(uint256 => Property) public properties;

    function listProperty(
        string memory name,
        string memory propertyAddress,
        string memory description,
        string memory imgUrl,
        uint256 pricePerDay,
        uint64 numberOfRooms,
        uint64 area
    ) public returns (uint256) {
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
    ) public payable onlyNotBooked(propertyId) {
        uint64 numberOfDays = (endDate - startDate) / 86400000;

        require(
            msg.value >= numberOfDays * properties[propertyId].pricePerDay,
            "Send more ETH."
        );
        payable(properties[propertyId].owner).transfer(msg.value);

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

    function getPropertyRentPrice(
        uint256 propertyId
    ) public view onlyBooked(propertyId) returns (uint256) {
        Property storage property = properties[propertyId];

        uint64 numberOfDays = (property.bookingEndsAt - property.bookingStartsAt) / 86400000;
        return numberOfDays * properties[propertyId].pricePerDay;
    }

    function unBookPropertyByOwner(
        uint256 propertyId
    ) public payable
             onlyBooked(propertyId)
             onlyPropertyOwner(propertyId)
    {
        uint256 rentPrice = getPropertyRentPrice(propertyId);

        require(
            msg.value >= rentPrice,
            "Send more ETH."
        );
        payable(properties[propertyId].guest).transfer(msg.value);

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