import dotenv from 'dotenv';
dotenv.config();
import { ethers } from "hardhat";

const owner = "0x5e7fDe833Ca77049f15E80e88ef744d9FE2e463b";

const endpointV2_BASE = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_SCROLL = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_ARB = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_OP = "0x6EDCE65403992e310A62460808c4b910D972f10f";

const EID_BASE = "40245";
const EID_SCROLL = "40170";
const EID_ARB = "40231";
const EID_OP = "40232";

const main = async () => {


  const UniversalFactory = await ethers.getContractFactory("UniversalFactory");
  const factory = await UniversalFactory.deploy(endpointV2_BASE, owner);

  console.log("UniversalFactory deployed to:", factory.address);

  const OFTFactory = await ethers.getContractFactory("OFTFactory");
  const oftFactory = await OFTFactory.deploy(endpointV2_BASE, owner, EID_OP, ethers.utils.zeroPad("0xF803d75844195266E9a0Db97b17832Bb14F5Ca91", 32));

  console.log("OFTFactory deployed to:", oftFactory.address);


}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});