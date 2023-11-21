require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const { MNEMONIC, INFURA_PROJECT_ID } = process.env;

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1", // Localhost
      port: 8545,        // Standard Ethereum port (Ganache default)
      network_id: "*",   // Any network (Ganache uses network_id 1337 by default, but "*" works for any)
    },
    /*sepolia: {
      provider: () => new HDWalletProvider(
        MNEMONIC,
        `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`
      ),
      network_id: 11155111, // Sepolia's network id
      gas: 8000000,         // Gas limit used for deploys
      confirmations: 2,     // # of confs to wait between deployments
      timeoutBlocks: 200,   // # of blocks before a deployment times out
      skipDryRun: true      // Skip dry run before migrations
    },
    */
    // ... other network configurations
  },

  mocha: {
    // timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.8.22", // Fetch exact version from solc-bin (default: truffle's version)
    }
  },

  // Define other configurations (if necessary)
};
