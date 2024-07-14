import dotenv from 'dotenv';
dotenv.config();
import { ethers } from "hardhat";

const owner = "0x2b9C7122D6729B7CaE99234d3348D83186b1FCd3";

const endpointV2_BASE = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_SCROLL = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_ARB = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_OP = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_ZIRCUIT = "0x6EDCE65403992e310A62460808c4b910D972f10f";

const EID_BASE = "40245";
const EID_SCROLL = "40170";
const EID_ARB = "40231";
const EID_OP = "40232";
const EID_ZIRCUIT = "40275";

const main = async () => {

   const UniversalFactory = await ethers.getContractFactory("UniversalFactory");
   const universalFactory = await UniversalFactory.deploy(endpointV2_BASE, owner);

   console.log("UniversalFactory deployed to:", universalFactory.address);

   const OFTFactory = await ethers.getContractFactory("OFTFactory");
   const oftFactory = await OFTFactory.deploy(endpointV2_BASE, owner, EID_SCROLL, ethers.utils.zeroPad(universalFactory.address, 32));

   console.log("OFTFactory deployed to:", oftFactory.address);


  const BondingCurve = await ethers.getContractFactory("BondingCurve");
  const curve = await BondingCurve.deploy(endpointV2_ARB, owner, universalFactory.address);

  console.log("BondingCurve deployed to:", curve.address);


  const Router = await ethers.getContractFactory("OmneeRouter");
  const router = await Router.deploy(endpointV2_BASE, owner, EID_SCROLL);

  console.log("Router deployed to:", router.address);



}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});