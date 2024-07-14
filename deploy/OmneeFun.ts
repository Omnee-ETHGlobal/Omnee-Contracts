import assert from 'assert'

import { ethers } from 'hardhat'
import { type DeployFunction } from 'hardhat-deploy/types'

const uf = 'UniversalFactory'
const oftFactoryScroll = 'OFTFactory'
const oftFactoryArb = 'OFTFactory'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    const endpointV2Deployment = await hre.deployments.get('EndpointV2')

    const { address: ufAddress } = await deploy(uf, {
        from: deployer,
        args: [endpointV2Deployment.address, deployer],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${uf}, network: ${hre.network.name}, address: ${ufAddress}`)

    const { address: oftFactoryScrollAddress } = await deploy(oftFactoryScroll, {
        from: deployer,
        args: [endpointV2Deployment.address, deployer, 40170, ethers.utils.zeroPad(ufAddress, 32)],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(
        `Deployed contract: ${oftFactoryScroll}, network: ${hre.network.name}, address: ${oftFactoryScrollAddress}`
    )

    const { address: oftFactoryArbAddress } = await deploy(oftFactoryArb, {
        from: deployer,
        args: [endpointV2Deployment.address, deployer, 40231, ethers.utils.zeroPad(ufAddress, 32)],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${oftFactoryArb}, network: ${hre.network.name}, address: ${oftFactoryArbAddress}`)
}

deploy.tags = [uf, oftFactoryScroll, oftFactoryArb]

export default deploy
