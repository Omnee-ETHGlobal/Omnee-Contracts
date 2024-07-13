import { ethers } from "ethers";
import dotenv from "dotenv";
import { Options } from '@layerzerolabs/lz-v2-utilities';

dotenv.config();

const main = async () => {

    const universalFactoryABI = require("../artifacts/contracts/UniversalFactory.sol/UniversalFactory.json").abi;
    const oftFactoryABI = require("../artifacts/contracts/OFTFactory.sol/OFTFactory.json").abi;

    const baseProvider = new ethers.providers.JsonRpcProvider("https://sepolia.base.org", 84532);
    const scrollProvider = new ethers.providers.JsonRpcProvider("https://sepolia-rpc.scroll.io", 534351);
    const arbProvider = new ethers.providers.JsonRpcProvider("https://sepolia-rollup.arbitrum.io/rpc", 421614);
    const opProvider = new ethers.providers.JsonRpcProvider("https://sepolia.optimism.io", 11155420);

    const walletBASE = new ethers.Wallet(process.env.PRIVATE_KEY as string, baseProvider);
    const walletSCROLL = new ethers.Wallet(process.env.PRIVATE_KEY as string, scrollProvider);
    const walletARB = new ethers.Wallet(process.env.PRIVATE_KEY as string, arbProvider);
    const walletOP = new ethers.Wallet(process.env.PRIVATE_KEY as string, opProvider);

    const universalFactorySC = new ethers.Contract("0x4948A0dF2255a245c2a027DF6723FA3B0693ccDC", universalFactoryABI, walletBASE);
    const oftFactorySCROLL = new ethers.Contract("0xD51d7213163e2A29f042516d98cB3Db628Cc7456", oftFactoryABI, walletSCROLL);
    const oftFactoryARB = new ethers.Contract("0x2D3Cbd710523b86a1b44Cb7720b0873bAd47f6cc", oftFactoryABI, walletARB);
    const oftFactoryOP = new ethers.Contract("0xfBE63Ddb6B2068700bCCC85C41829d141841ad6c", oftFactoryABI, walletOP);

    const EID_BASE = "40245";
    const EID_SCROLL = "40170";
    const EID_ARB = "40231";
    const EID_OP = "40232";

    /*

    let tx = await universalFactorySC.setPeer(EID_SCROLL, ethers.utils.zeroPad(oftFactorySCROLL.address, 32));
    await tx.wait();
    tx = await universalFactorySC.setPeer(EID_ARB, ethers.utils.zeroPad(oftFactoryARB.address, 32));
    await tx.wait();
    tx = await universalFactorySC.setPeer(EID_OP, ethers.utils.zeroPad(oftFactoryOP.address, 32));
    await tx.wait();
    tx = await oftFactorySCROLL.setPeer(EID_BASE, ethers.utils.zeroPad(universalFactorySC.address, 32));
    await tx.wait();
    tx = await oftFactoryARB.setPeer(EID_BASE, ethers.utils.zeroPad(universalFactorySC.address, 32));
    await tx.wait();
    tx = await oftFactoryOP.setPeer(EID_BASE, ethers.utils.zeroPad(universalFactorySC.address, 32));
    await tx.wait();
 

    console.log(await universalFactorySC.peers(EID_SCROLL));
    console.log(await universalFactorySC.peers(EID_ARB));

    console.log(await oftFactorySCROLL.peers(EID_BASE));
    console.log(await oftFactoryARB.peers(EID_BASE));

    */

    const options = Options.newOptions().addExecutorLzReceiveOption(1000000, 0).toHex().toString();

    console.log("Options =>", options);

   /// const nativeFee = await universalFactorySC.quoteDeployOFT("MEOW", "MEOW", [EID_ARB], options);

   /// console.log("Deployment Fee =>", ethers.utils.formatEther(nativeFee.toString()), "ETH");

   /// let tx = await universalFactorySC.deployOFT("MEOW", "MEOW", [EID_ARB, EID_OP], options, { value: nativeFee });

   ///  console.log("Transaction Hash =>", tx.hash);
}

main();