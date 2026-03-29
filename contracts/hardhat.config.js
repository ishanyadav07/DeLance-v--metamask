import dotenv from 'dotenv'
import '@nomicfoundation/hardhat-toolbox'

dotenv.config()

const { SEPOLIA_RPC_URL, PRIVATE_KEY } = process.env

export default {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL || '',
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
}
