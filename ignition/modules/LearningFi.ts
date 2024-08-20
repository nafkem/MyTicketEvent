import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// const JAN_1ST_2030 = 1893456000;
// const ONE_GWEI: bigint = 1_000_000_000n;

const _minimumJoinDAO: bigint = 10_000_000_000_000_000_000_000n;
const _maximumJoinDAO: bigint = 100_000_000_000_000_000_000_000n;
const _aave_address: string = "0x0562453c3DAFBB5e625483af58f4E6D668c44e19";

const LearningFiModule = buildModule("LearningFiModule", (m) => {

  const LEFI = m.contract("LEARNFI");
  const LEARNFI = m.contract("LearningFi", [LEFI, _aave_address]);
  const GOVERNANCE = m.contract("LearningFiGovernance", [
    LEFI,
    LEARNFI,
    _minimumJoinDAO,
    _maximumJoinDAO,
  ]);

  return { LEFI, LEARNFI, GOVERNANCE };
});

export default LearningFiModule;

// LearningFiModule#LEARNFI - 0xDa2E5fc8C5EA74cad122Af60EbA2245b95725Fb8
// LearningFiModule#LearningFi - 0xb52c8c5E4Cebb61deeF52099F6Da1377f03a4834
// LearningFiModule#LearningFiGovernance - 0xf2738c9ac4ECcddbe62541e7420D975Cdc7B4e1d
