import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { wei } from "@/scripts/utils/utils";
import { Rent } from "@ethers-v6";
import exp from "constants";
import { randomInt } from "crypto";

const MILLISECONDS_IN_DAY = 60 * 60 * 24 * 1000;

describe("Rent", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let rent: Rent;

  before(async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const Rent = await ethers.getContractFactory("Rent");
    rent = await Rent.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#constructor", () => {
    it("should set parameters correctly", async () => {
        expect(await rent.owner()).to.eq(OWNER);
        expect(await rent.counter()).to.eq(0);
    });
  });

  describe("#listProperty", () => {
    it("should increase counter", async () => {
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);
      expect(await rent.counter()).to.eq(1);
    })

    it("should return valid id", async () => {
      const id1 = await rent.listProperty.staticCall("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);

      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);

      const id2 = await rent.listProperty.staticCall("home2", 
                        "home address2",
                        "some description2",
                        "imgUrl2",
                        10,
                        2,
                        68);

      expect(id1).to.eq(1);
      expect(id2).to.eq(2);
    })

    it("should set parameters correctly", async () => {
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);

      expect((await rent.properties(0)).name).to.eq("home");
      expect((await rent.properties(0)).propertyAddress).to.eq("home address");
      expect((await rent.properties(0)).description).to.eq("some description");
      expect((await rent.properties(0)).imgUrl).to.eq("imgUrl");
      expect((await rent.properties(0)).pricePerDay).to.eq(10);
      expect((await rent.properties(0)).numberOfRooms).to.eq(2);
      expect((await rent.properties(0)).area).to.eq(68);

      expect((await rent.properties(0)).isActive).to.eq(true);
      expect((await rent.properties(0)).bookingStartsAt).to.eq(0);
      expect((await rent.properties(0)).bookingEndsAt).to.eq(0);
      expect((await rent.properties(0)).owner).to.eq(OWNER);
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
    })
  })

  describe("#unlistProperty", () => {
    it("should unlist correctly", async () => {
      await rent.listProperty("home", 
                  "home address",
                  "some description",
                  "imgUrl",
                  10,
                  2,
                  68);
      // Expect the property to be active
      expect((await rent.properties(0)).isActive).to.eq(true);
      // Unlisting the property by the owner
      await rent.unlistProperty(0);
      // Expect the property to become inactive
      expect((await rent.properties(0)).isActive).to.eq(false);
    })
    
    it("should not unlist (caller is not an owner)", async () => {
      await rent.listProperty("home", 
                  "home address",
                  "some description",
                  "imgUrl",
                  10,
                  2,
                  68);
      // Expect the property to be active
      expect((await rent.properties(0)).isActive).to.eq(true);
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      // Trying to unlist without ownership
      await expect(rent.connect(SECOND).unlistProperty(0)).to.revertedWith("Only property owner");
      // Expect the property to stay active
      expect((await rent.properties(0)).isActive).to.eq(true);
    })

    it("should not unlist (property is booked)", async () => {
      await rent.listProperty("home", 
                  "home address",
                  "some description",
                  "imgUrl",
                  10,
                  2,
                  68);
      // Expect the property to be active
      expect((await rent.properties(0)).isActive).to.eq(true);
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      // Booking the property
      await rent.connect(SECOND).bookProperty(0, 86400000, 86400000 * 2, { value: 10} );
      // Trying to unlist (propertiy is booked)
      await expect(rent.unlistProperty(0)).to.revertedWith("Only not booked");
      // Expect the property to stay active
      expect((await rent.properties(0)).isActive).to.eq(true);
    })

    it("should not unlist (property is already unlisted)", async () => {
      await rent.listProperty("home", 
                  "home address",
                  "some description",
                  "imgUrl",
                  10,
                  2,
                  68);
      // Expect the property to be active
      expect((await rent.properties(0)).isActive).to.eq(true);
      // Trying to unlist (propertiy is booked)
      await rent.unlistProperty(0);
      // Expect the property to be inactive
      expect((await rent.properties(0)).isActive).to.eq(false);
      // Expect unlisting to revert
      await expect(rent.unlistProperty(0)).to.revertedWith("Property has been already unlisted");
      // Expect the property to stay inactive
      expect((await rent.properties(0)).isActive).to.eq(false);
    })
    
  })

  describe("#unBookPropertyByGuest", () => {
    it("should set guest to address(0)", async() => {
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);
      // Guest address equals 0 - no one has booked the property
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      // Send transaction to book the property by the SECOND 
      await rent.connect(SECOND).bookProperty(0, 86400000, 86400000 * 2, { value: 10} );
      // Expect the property guest to be equal to the SECOND address.
      expect((await rent.properties(0)).guest).to.eq(SECOND);
      // Expect unBookByGuest to revert when called from OWNER address (SECOND is the guest)
      await expect((rent.unBookPropertyByGuest(0))).to.revertedWith("Only property guest");
      // Should correctly unbook
      await rent.connect(SECOND).unBookPropertyByGuest(0);
      // Property guest is address(0)
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
    })
  })

  describe("#unBookPropertyByOwner", () => {
    it("should set guest to address(0) and return rent payment", async() => {
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);
      // Except newly created property to guest == address(0)
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      // Booking property by the SECOND
      await rent.connect(SECOND).bookProperty(0, MILLISECONDS_IN_DAY, MILLISECONDS_IN_DAY * 2, { value: 10} );
      // Expect the SECOND account to be a property guest
      expect((await rent.properties(0)).guest).to.eq(SECOND);
      // Expect owner to unbook the property and return the deposit to the guest
      await expect(rent.unBookPropertyByOwner(0, {value: 10})).to.changeEtherBalance(SECOND, 10);
      // Expect the property guest to be address(0)
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
    })
  })

  describe("#addUserToWhitelist", () => {
    it("should add user to whitelist", async() => {
      expect(await rent.whitelist("0x0000000000000000000000000000000000123456")).to.eq(false);
      await rent.addUserToWhitelist("0x0000000000000000000000000000000000123456");
      expect(await rent.whitelist("0x0000000000000000000000000000000000123456")).to.eq(true);
    })
  })

  describe("#getPropertyRentPrice", () => {
    it("should calculate rent price properly (constant)", async() => {
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        10,
                        2,
                        68);
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      await rent.connect(SECOND).bookProperty(0, MILLISECONDS_IN_DAY, MILLISECONDS_IN_DAY * 2, { value: 10} );
      const price = rent.getPropertyRentPrice(0);
      expect(await price).to.eq(10);
    })

    it("should calculate rent price properly (random)", async() => {
      const price = randomInt(100000) + 1;
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        price,
                        2,
                        68);
      const start = randomInt(100) * MILLISECONDS_IN_DAY;
      const end = randomInt(100) * MILLISECONDS_IN_DAY + start;
      const calculatedPrice = ((end - start) / MILLISECONDS_IN_DAY) * price;
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      await rent.connect(SECOND).bookProperty(0, start, end, { value: calculatedPrice} );

      const contractPrice = rent.getPropertyRentPrice(0);
      
      expect(await contractPrice).to.eq(calculatedPrice);
    })
  })
  describe("#statistic", () => {
    it("should correctly update statistic when booking property", async() => {
      const price = 100;
      await rent.listProperty("home", 
                        "home address",
                        "some description",
                        "imgUrl",
                        price,
                        2,
                        68);
      // Whitelisting second account
      await rent.addUserToWhitelist(SECOND);
      
      // Checking that statistic is empty
      const statisticSecondNoRent = await rent.getStatistic.staticCall(SECOND);
      expect(statisticSecondNoRent).to.deep.eq([0, 0, 0, 0, 0, 0]);

      const start = randomInt(100) * MILLISECONDS_IN_DAY;
      const end = randomInt(100) * MILLISECONDS_IN_DAY + start;
      const days = (end - start) / MILLISECONDS_IN_DAY;
      const calculatedPrice = (days * price);

      await rent.connect(SECOND).bookProperty(0, start, end, {value: calculatedPrice});
      
      const statisticSecondAfterRent = await rent.getStatistic.staticCall(SECOND);
      expect(statisticSecondAfterRent.totalEarned).to.eq(0);
      expect(statisticSecondAfterRent.totalSpent).to.eq(calculatedPrice);
      expect(statisticSecondAfterRent.daysBookedAsOwner).to.eq(0);
      expect(statisticSecondAfterRent.daysBookedAsGuest).to.eq(days);
      expect(statisticSecondAfterRent.timesBookedAsOwner).to.eq(0);
      expect(statisticSecondAfterRent.timesBookedAsGuest).to.eq(1);
      
      const statisticOwnerAfterRent = await rent.getStatistic.staticCall(OWNER);
      expect(statisticOwnerAfterRent.totalEarned).to.eq(calculatedPrice);
      expect(statisticOwnerAfterRent.totalSpent).to.eq(0);
      expect(statisticOwnerAfterRent.daysBookedAsOwner).to.eq(days);
      expect(statisticOwnerAfterRent.daysBookedAsGuest).to.eq(0);
      expect(statisticOwnerAfterRent.timesBookedAsOwner).to.eq(1);
      expect(statisticOwnerAfterRent.timesBookedAsGuest).to.eq(0);
    })
  })
});
