import dotenv from 'dotenv';
dotenv.config();
import { ethers } from "hardhat";

const owner = "0x0666899825Ffe6C9afA2e0b3F08b2049DD8BdB1f";

const endpointV2_BASE = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_SCROLL = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_ARB = "0x6EDCE65403992e310A62460808c4b910D972f10f";
const endpointV2_OP = "0x6EDCE65403992e310A62460808c4b910D972f10f";

const EID_BASE = "40245";
const EID_SCROLL = "40170";
const EID_ARB = "40231";
const EID_OP = "40232";

const main = async () => {


  /// const UniversalFactory = await ethers.getContractFactory("UniversalFactory");
  /// const factory = await UniversalFactory.deploy(endpointV2_BASE, owner);

  /// console.log("UniversalFactory deployed to:", factory.address);


  const OFTFactory = await ethers.getContractFactory("OFTFactory");
  const oftFactory = await OFTFactory.deploy(endpointV2_SCROLL, owner, EID_SCROLL, ethers.utils.zeroPad("0x4948A0dF2255a245c2a027DF6723FA3B0693ccDC", 32));

  console.log("OFTFactory deployed to:", oftFactory.address);


  /// TODO: SET PEERS

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});