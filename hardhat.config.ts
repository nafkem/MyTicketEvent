import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const EDU_RPC_URL = process.env.EDU_RPC_URL || "";
const API_KEY = process.env.API_KEY || "";

type HttpNetworkAccountsUserConfig = any;
module.exports = {
  solidity: "0.8.24",
  networks: {
    // for testnet
    "Open-Campus-Codex": {
      url: EDU_RPC_URL,
      accounts: [process.env.WALLET_KEY as string],
      gasPrice: 1000000000,
    },
  },
  sourcify: {
    enabled: true,
  },

  etherscan: {
    apiKey: {
      "Open-Campus-Codex": "123",
    },
    customChains: [
      {
        network: "Open-Campus-Codex",
        chainId: 656476,
        urls: {
          apiURL: "https://opencampus-codex.blockscout.com/api",
          browserURL: "https://opencampus-codex.blockscout.com",
        },
      },
    ],
  },
};
