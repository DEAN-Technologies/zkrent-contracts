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
  })
});
