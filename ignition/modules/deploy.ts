import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const JAN_1ST_2030 = 1893456000;
const ONE_GWEI: bigint = 1_000_000_000n;

const LockModule = buildModule("LockModule", (m) => {
  // const defaultAdmin = m.getParameter("defaultAdmin", "0x52C40108eC0865F3461Cfeec7591B504E4304405");
  // const pauser = m.getParameter("pauser", "0x52C40108eC0865F3461Cfeec7591B504E4304405");
  // const minter = m.getParameter("minter", "0x52C40108eC0865F3461Cfeec7591B504E4304405");

  // const lock = m.contract("MyToken", [defaultAdmin, pauser, minter]);

  //const owner = m.getParameter("owner", "0x52C40108eC0865F3461Cfeec7591B504E4304405");
  const eventId = 1
  const organizer = "0x52C40108eC0865F3461Cfeec7591B504E4304405 "
  const eventName = "Nafisat Party"
  const description = "Party"
  const eventAddress = ""
  const date = ""
  const startTime = ""
  const endTime = ""
  const virtualEvent = ""
  const lock = m.contract("EventPass", [ eventId, organizer, eventName, description, 
    eventAddress, date, startTime, endTime, virtualEvent]);

  return { lock };
});

export default LockModule;
// import { ethers } from "hardhat";
// import { ContractFactory, Contract } from "ethers";

// async function main() {
//   Deploy MyToken contract

//   const MyToken: ContractFactory = await ethers.getContractFactory("MyToken");
//   const myToken: Contract = await MyToken.deploy(
    
//     "0xYourDefaultAdminAddress",
//     "0xYourPauserAddress",
//     "0xYourMinterAddress"
//   );
//   await myToken.deployed();
//   console.log(`MyToken deployed to: ${myToken.address}`);

//   // Deploy EventPassFactory contract
//   const EventPassFactory: ContractFactory = await ethers.getContractFactory("EventPassFactory");
//   const eventPassFactory: Contract = await EventPassFactory.deploy();
//   await eventPassFactory.deployed();
//   console.log(`EventPassFactory deployed to: ${eventPassFactory.address}`);

//   // Deploy EventPassRegistry contract
//   const EventPassRegistry: ContractFactory = await ethers.getContractFactory("EventPassRegistry");
//   const eventPassRegistry: Contract = await EventPassRegistry.deploy();
//   await eventPassRegistry.deployed();
//   console.log(`EventPassRegistry deployed to: ${eventPassRegistry.address}`);

//   // Deploy EventToken contract
//   const EventToken: ContractFactory = await ethers.getContractFactory("EventToken");
//   const eventToken: Contract = await EventToken.deploy();
//   await eventToken.deployed();
//   console.log(`EventToken deployed to: ${eventToken.address}`);
//  }

// main().catch((error: Error) => {
//   console.error(error);
//   process.exitCode = 1;
// });
