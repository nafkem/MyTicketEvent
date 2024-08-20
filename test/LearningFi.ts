import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
const { ethers } = require("hardhat");

describe("LearningFi", function () {
  // ficture deployer

  async function deployLearningFiFixture() {
    const [owner, accountTwo, accountThree] = await ethers.getSigners();

    // deploy mLEFI
    const mLEFI = await ethers.getContractFactory("LEARNFI");
    const LEFI = await mLEFI.deploy();

    // deploy LarningFi contract
    const _aave_address: string = '0x0562453c3DAFBB5e625483af58f4E6D668c44e19';

    const LEARNINGFI = await ethers.getContractFactory("LearningFi");
    const learningFi = await LEARNINGFI.deploy(LEFI.getAddress(), _aave_address);

    // deploy governance contract
    const _minimumJoinDAO = BigInt(1e22);
    const _maximumJoinDAO = BigInt(1e23);
    
    const Governance = await ethers.getContractFactory("LearningFiGovernance");
    const governance = await Governance.deploy(
      LEFI.getAddress(),
      learningFi.getAddress(),
      _minimumJoinDAO,
      _maximumJoinDAO
    );

    console.log(LEFI, learningFi, _minimumJoinDAO, _maximumJoinDAO);

    return {
      LEFI,
      owner,
      accountTwo,
      accountThree,
      learningFi,
      governance,
      _minimumJoinDAO,
      _maximumJoinDAO,
    };
  }

  describe("AfterDeployment", function () {
    it("Should check owner balance", async function () {
      const { LEFI, owner } = await loadFixture(deployLearningFiFixture);
      const expectedAmount = ethers.parseUnits("1", 27);

      expect(Number(await LEFI.balanceOf(owner.address))).to.be.equal(
        Number(expectedAmount)
      );
    });
  });

  describe("StudentReg", function () {
    it("should register a student, and return an error if the student has already been registered", async function () {
      const { learningFi, governance, owner, LEFI, accountTwo, accountThree } =
        await loadFixture(deployLearningFiFixture);
        await learningFi.setGovernanceAddress(governance.getAddress());
      const _student = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";
      const _imageIPFSHash = "https://app.uniswap.org/";
      console.log("Learninf DI",learningFi,"STD", _student);

      await learningFi.registerStudent(
        _student,
        _imageIPFSHash
      );
      expect(
        Number(await learningFi.isStudent(_student))).to.be.equal((Number(true))
      );

      console.log(
        await learningFi.isStudent(_student),
        "student exists"
      );

    });
  })
});
