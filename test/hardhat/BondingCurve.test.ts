/* eslint-disable @typescript-eslint/no-non-null-assertion */
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Contract, ContractFactory } from 'ethers'
import { deployments, ethers } from 'hardhat'

describe('Bonding Curve Test', function () {
    // Constant representing a mock Endpoint ID for testing purposes
    const eidA = 1
    const eidB = 2

    let BondingCurve: ContractFactory
    let UniversalFactory: ContractFactory
    let OmneeOFT: ContractFactory

    let EndpointV2Mock: ContractFactory
    let protocolOwner: SignerWithAddress
    let endpointOwner: SignerWithAddress
    let ownerA: SignerWithAddress

    let mockEndpointA: Contract
    let mockEndpointB: Contract

    let mockUniversalFactory: Contract
    let mockBondingCurve: Contract
    let mockOFT1: Contract

    before(async function () {
        UniversalFactory = await ethers.getContractFactory('UniversalFactory')
        BondingCurve = await ethers.getContractFactory('BondingCurve')
        OmneeOFT = await ethers.getContractFactory('OmneeOFT')

        const [ownerA, protocolOwner, endpointOwner] = await ethers.getSigners()

        const EndpointV2MockArtifact = await deployments.getArtifact('EndpointV2Mock')
        EndpointV2Mock = new ContractFactory(EndpointV2MockArtifact.abi, EndpointV2MockArtifact.bytecode, endpointOwner)
    })

    beforeEach(async function () {
        // Create endpoints
        mockEndpointA = await EndpointV2Mock.deploy(eidA)
        mockEndpointB = await EndpointV2Mock.deploy(eidB)

        mockUniversalFactory = await UniversalFactory.deploy(mockEndpointA.address, protocolOwner.address)
        mockBondingCurve = await BondingCurve.deploy(protocolOwner.address, mockUniversalFactory.address)
        await mockUniversalFactory.deployOFT('MEOW', 'MEOW', [2], options, { value: nativeFee })

        // // Setting destination endpoints in the LZEndpoint mock for each MyOFT instance
        // await mockEndpointA.setDestLzEndpoint(oftFactory.address, mockEndpointB.address)
        // await mockEndpointB.setDestLzEndpoint(uf.address, mockEndpointA.address)

        // Setting each MyOFT instance as a peer of the other in the mock LZEndpoint
        // await oftFactory.connect(ownerA).setPeer(eidA, ethers.utils.zeroPad(uf.address, 32))
        // await uf.connect(ownerA).setPeer(eidB, ethers.utils.zeroPad(oftFactory.address, 32))

        console.log('UF address', mockUniversalFactory.address)
        console.log('Bonding Curve address', mockBondingCurve.address)

        // console.log(await uf.peers(2))
        // console.log(await oftFactory.peers(1))

        console.log('🚀 Deployment Done 🚀')
    })

    describe('method:addToken', async function () {
        it('should add a new entry to the mapping of supported tokens', async function () {})
    })

    describe('method:buyTokens', async function () {
        it('should check that the token is supported', async function () {})
        it('should check that the Bonding Curve has enough tokens to sell to user', async function () {})
        it('should update the token entry', async function () {})
        it('should transfer the token without any LZ message', async function () {})
    })

    describe('method:sellTokens', async function () {
        it('should check that the token is supported', async function () {})
        it('should check that the user has enough tokens to sell', async function () {})
        it('should check that the pool has enough liquidity', async function () {})
        it('should update the token entry', async function () {})
        it('should transfer the token without any LZ message', async function () {})
    })

    describe('method:calculateBuyableAmount', async function () {
        it('should follow the bonding curve formula', async function () {})
    })

    describe('method:calculateSellPayout', async function () {
        it('should follow the bonding curve formula', async function () {})
    })

    describe('method:getTokenPrice', async function () {
        it('should follow the bonding curve formula', async function () {})
    })
})
