// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import '@layerzerolabs/toolbox-hardhat'
import '@nomicfoundation/hardhat-verify'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-contract-sizer'
import 'hardhat-deploy'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
const MNEMONIC = process.env.MNEMONIC

// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.PRIVATE_KEY

const SCROLL_API_KEY = process.env.SCROLL_API_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
      ? [PRIVATE_KEY]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config: HardhatUserConfig = {
    paths: {
        cache: 'cache/hardhat',
    },
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        baseSepolia: {
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: 'https://sepolia.base.org',
            accounts,
        },
        scrollSepolia: {
            eid: EndpointId.SCROLL_V2_TESTNET,
            url: 'https://sepolia-rpc.scroll.io',
            accounts,
        },
        arbitrumSepolia: {
            eid: EndpointId.ARBSEP_V2_TESTNET,
            url: 'https://sepolia-rollup.arbitrum.io/rpc',
            accounts,
        },
        optimismSepolia: {
            eid: EndpointId.OPTSEP_V2_TESTNET,
            url: 'https://sepolia.optimism.io',
            accounts,
        },
        zircuitTestnet : {
            eid : EndpointId.ZIRCUIT_V2_TESTNET,
            url : 'https://zircuit1.p2pify.com/',
            accounts,
        }
    },
    etherscan: {
        apiKey: {
            baseSepolia: 'TT7ZRT8QYDAZBGZFVMU786TCJIKFF2JJHM', 
            arbitrumSepolia: 'mock', // not required by blockscout
            optimismSepolia: 'mock', // not required by blockscout
            scrollSepolia: SCROLL_API_KEY || '',
        },
        customChains: [
            {
                network: 'baseSepolia',
                chainId: 84532,
                urls: {
                    apiURL: 'https://base-sepolia.blockscout.com/api',
                    browserURL: 'https://base-sepolia.blockscout.com/',
                },
            },
            {
                network: 'arbitrumSepolia',
                chainId: 421614,
                urls: {
                    apiURL: 'https://arbitrum-sepolia.blockscout.com/api',
                    browserURL: 'https://arbitrum-sepolia.blockscout.com/',
                },
            },
            {
                network: 'optimismSepolia',
                chainId: 11155420,
                urls: {
                    apiURL: 'https://optimism-sepolia.blockscout.com/api',
                    browserURL: 'https://optimism-sepolia.blockscout.com/',
                },
            },
            {
                network: 'scrollSepolia',
                chainId: 534351,
                urls: {
                    apiURL: 'https://api-sepolia.scrollscan.com/api',
                    browserURL: 'https://sepolia.scrollscan.com/',
                },
            },
        ],
    },
    sourcify: {
        enabled: false,
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
}

export default config
