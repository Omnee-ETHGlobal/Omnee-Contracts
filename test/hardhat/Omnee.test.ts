import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Contract, ContractFactory } from 'ethers'
import { deployments, ethers } from 'hardhat'

import { Options } from '@layerzerolabs/lz-v2-utilities'

describe('Omnee Test', function () {
    // Constant representing a mock Endpoint ID for testing purposes
    const eidA = 1
    const eidB = 2
    // Declaration of variables to be used in the test suite
    let OFTFactory: ContractFactory
    let UniversalFactory: ContractFactory
    let EndpointV2Mock: ContractFactory
    let ownerA: SignerWithAddress
    let endpointOwner: SignerWithAddress
    let mockEndpointV2A: Contract
    let mockEndpointV2B: Contract

    let uf: Contract
    let oftFactory: Contract
    let ofFactoryBASE: Contract

    // Before hook for setup that runs once before all tests in the block
    before(async function () {
        // Contract factory for our tested contract
        // We are using a derived contract that exposes a mint() function for testing purposes
        UniversalFactory = await ethers.getContractFactory('UniversalFactory')
        OFTFactory = await ethers.getContractFactory('OFTFactory')

        // Fetching the first three signers (accounts) from Hardhat's local Ethereum network
        const signers = await ethers.getSigners()

        ownerA = signers.at(0)!
        endpointOwner = signers.at(1)!

        // The EndpointV2Mock contract comes from @layerzerolabs/test-devtools-evm-hardhat package
        // and its artifacts are connected as external artifacts to this project
        //
        // Unfortunately, hardhat itself does not yet provide a way of connecting external artifacts,
        // so we rely on hardhat-deploy to create a ContractFactory for EndpointV2Mock
        //
        // See https://github.com/NomicFoundation/hardhat/issues/1040
        const EndpointV2MockArtifact = await deployments.getArtifact('EndpointV2Mock')
        EndpointV2Mock = new ContractFactory(EndpointV2MockArtifact.abi, EndpointV2MockArtifact.bytecode, endpointOwner)
    })

    // beforeEach hook for setup that runs before each test in the block
    beforeEach(async function () {
        // Deploying a mock LZEndpoint with the given Endpoint ID
        mockEndpointV2A = await EndpointV2Mock.deploy(eidA)
        mockEndpointV2B = await EndpointV2Mock.deploy(eidB)

        /// DEPLOY UniversalFactory

        uf = await UniversalFactory.deploy(mockEndpointV2A.address, ownerA.address)
        oftFactory = await OFTFactory.deploy(
            mockEndpointV2B.address,
            ownerA.address,
            2,
            ethers.utils.zeroPad(uf.address, 32)
        ) /// side chain
        ofFactoryBASE = await OFTFactory.deploy(
            mockEndpointV2A.address,
            ownerA.address,
            1,
            ethers.utils.zeroPad(uf.address, 32)
        ) /// main chain

        // Setting destination endpoints in the LZEndpoint mock for each MyOFT instance
        await mockEndpointV2A.setDestLzEndpoint(oftFactory.address, mockEndpointV2B.address)
        await mockEndpointV2B.setDestLzEndpoint(uf.address, mockEndpointV2A.address)

        // Setting each MyOFT instance as a peer of the other in the mock LZEndpoint
        await oftFactory.connect(ownerA).setPeer(eidA, ethers.utils.zeroPad(uf.address, 32))
        await uf.connect(ownerA).setPeer(eidB, ethers.utils.zeroPad(oftFactory.address, 32))

        console.log('UF address', uf.address)
        console.log('OFTB address', oftFactory.address)

        console.log(await uf.peers(2))
        console.log(await oftFactory.peers(1))

        await uf.setBaseFactory(ofFactoryBASE.address)

        console.log('🚀 Deployment Done 🚀')
    })

    it('Should deploy OFT from FACTORY', async function () {
        console.log('\n------------------------------------\n')

        const options = Options.newOptions().addExecutorLzReceiveOption(5000000, 0).toHex().toString()
        const nativeFee = await uf.quoteDeployOFT('MEOW', 'MEOW', [2], options)

        console.log('Native Fee =>', nativeFee.toString())

        await uf.deployOFT('MEOW', 'MEOW', [2], options, { value: nativeFee })

        console.log('Deployed OFT => ', await oftFactory.deployIdToAddress(1))
    })
})
