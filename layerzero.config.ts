import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const baseContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'UniversalFactory',
}

const scrollContract: OmniPointHardhat = {
    eid: EndpointId.SCROLL_V2_TESTNET,
    contractName: 'OFTFactory',
}

const arbContract: OmniPointHardhat = {
    eid: EndpointId.ARBSEP_V2_TESTNET,
    contractName: 'OFTFactory',
}

const opContract: OmniPointHardhat = {
    eid: EndpointId.OPTSEP_V2_TESTNET,
    contractName: 'OFTFactory',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: baseContract,
        },
        {
            contract: scrollContract,
        },
        {
            contract: arbContract,
        },
        {
            contract: opContract,
        },
    ],
    connections: [
        {
            from : baseContract,
            to: scrollContract,
        },
        {
            from : baseContract,
            to : arbContract,
        },
        {
            from : baseContract,
            to : opContract,
        },
        {
            from : scrollContract,
            to : arbContract,
        },
        {
            from : arbContract,
            to : scrollContract,
        },
        {
            from : arbContract,
            to : baseContract,
        }, 
        {
            from : scrollContract,
            to : baseContract,
        },
        {
            from : opContract,
            to : baseContract,
        },
        {
            from : opContract,
            to : scrollContract,
        },
        {
            from : opContract,
            to : arbContract,
        },
        {
            from : scrollContract,
            to : opContract,
        },
        {
            from : arbContract,
            to : opContract,
        }
        
    ],
}

export default config
