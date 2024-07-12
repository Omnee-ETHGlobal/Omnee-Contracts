import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const baseContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'MyOApp',
}

const scrollContract: OmniPointHardhat = {
    eid: EndpointId.SCROLL_V2_TESTNET,
    contractName: 'MyOApp',
}

const arbContract: OmniPointHardhat = {
    eid: EndpointId.ARBSEP_V2_TESTNET,
    contractName: 'MyOApp',
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
    ],
    connections: [
        {
            from : baseContract,
            to: scrollContract,
        },
        {
            from : baseContract,
            to : arbContract,
        }
    ],
}

export default config
