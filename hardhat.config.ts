import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const EDU_RPC_URL = process.env.EDU_RPC_URL || "";
const WALLET_KEY = process.env.WALLET_KEY || "";
const API_KEY = process.env.API_KEY || "";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    "Open-Campus-Codex": {
      url: EDU_RPC_URL,
      accounts: [WALLET_KEY],
      gasPrice: 1000000000, // 1 Gwei
    },
  },
  sourcify: {
    enabled: true,
  },
  etherscan: {
    apiKey: {
      "Open-Campus-Codex": API_KEY,
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

export default config;
