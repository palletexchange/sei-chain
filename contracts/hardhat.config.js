require('dotenv').config({path:__dirname+'/.env'})
require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  paths: {
    sources: "./src", // contracts are in ./src
  },
  networks: {
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/NHwLuOObixEHj3aKD4LzN5y7l21bopga", // Replace with your JSON-RPC URL
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e"], // Replace with your private key
    },
    seilocal: {
      url: "http://127.0.0.1:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52", "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    devnet: {
      url: "https://evm-rpc.arctic-1.seinetwork.io/",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    arctic1: {
      url: "http://3.133.59.72:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    arctic1node17: {
      url: "http://18.197.42.160:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2node0: {
      url: "http://18.159.252.65:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2node1: {
      url: "http://3.78.242.100:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2node2: {
      url: "http://18.195.21.5:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2node3: {
      url: "http://3.73.44.62:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2node4: {
      url: "http://35.158.115.225:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2rpc: {
      url: "http://3.71.188.202:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2rpc2: {
      url: "http://18.194.205.178:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    },
    atlantic2rpc3: {
      url: "http://3.73.66.165:8545",
      address: ["0xF87A299e6bC7bEba58dbBe5a5Aa21d49bCD16D52"],
      accounts: ["0x57acb95d82739866a5c29e40b0aa2590742ae50425b7dd5b5d279a986370189e", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
    }
  },
};
