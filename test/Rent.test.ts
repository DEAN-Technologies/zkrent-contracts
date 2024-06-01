import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { wei } from "@/scripts/utils/utils";
import { Rent } from "@ethers-v6";
import exp from "constants";

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
      expect((await rent.properties(0)).isActive).to.eq(true);
      
      await rent.unlistProperty(0);

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
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
      await rent.bookProperty(0, 86400000, 86400000 * 2, { value: 10} );
      expect((await rent.properties(0)).guest).to.eq(OWNER);
      await rent.unBookPropertyByGuest(0);
      expect((await rent.properties(0)).guest).to.eq("0x0000000000000000000000000000000000000000");
    })
  })
});
