// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Mock imports
import { UniversalFactory } from "../../contracts/UniversalFactory.sol";
import { OFTFactory } from "../../contracts/OFTFactory.sol";

// OApp imports
import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { MessagingFee, MessagingReceipt, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";


// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Forge imports
import "forge-std/console.sol";
import { Vm } from "forge-std/Test.sol";
import "forge-std/Test.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract UniversalFactoryTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 aEid = 1;
    uint32 bEid = 2;
    uint32 cEid = 3;
    uint32 dEid = 4;

    uint16 SEND = 1;
        
    UniversalFactory aSender;

    OFTFactory bReceiver;
    OFTFactory cReceiver;
    OFTFactory dReceiver;

    address public userA = address(0x1);
    address public userB = address(0x2);
    address public userC = address(0x3);
    address public userD = address(0x4);

    uint256 public initialBalance = 100 ether;

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.deal(userC, 1000 ether);
        vm.deal(userD, 1000 ether);

        super.setUp();
        setUpEndpoints(4, LibraryType.UltraLightNode);

        aSender = UniversalFactory(
            payable(_deployOApp(type(UniversalFactory).creationCode, abi.encode(address(endpoints[aEid]), address(this))))
        );

        bReceiver = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[bEid]), address(this), 2, bytes32(uint256(uint160(address(aSender)))))))
        );

        cReceiver = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[cEid]), address(this), 3, bytes32(uint256(uint160(address(aSender)))))))
        );

        dReceiver = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[dEid]), address(this), 4, bytes32(uint256(uint160(address(aSender)))))))
        );

        // config and wire the
        address[] memory oapps = new address[](4);
        oapps[0] = address(aSender);
        oapps[1] = address(bReceiver);
        oapps[2] = address(cReceiver);
        oapps[3] = address(dReceiver);
        this.wireOApps(oapps);
    }
    
    function test_batch_send() public {
        
        bytes memory _extraSendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(10000000, 0); // extra gas limit and msg.value to request for A -> B

        uint32[] memory _dstEids = new uint32[](2);
        _dstEids[0] = bEid;
        _dstEids[1] = cEid;

        // Use the return call quote to generate a new quote for A -> B.
        // src chain cost + price of gas that I want to send + fees for my chosen security Stack / Executor
        uint256 nativeFee = aSender.quoteDeployOFT("MEOW", "MEOW", _dstEids, _extraSendOptions);

        // Use the new quote for the msg.value of the send call.
        vm.prank(userA);
        aSender.deployOFT{value: nativeFee}(
            "MEOW",
            "MEOW",
            _dstEids,
            _extraSendOptions
        );

        verifyPackets(bEid, addressToBytes32(address(bReceiver)));
        verifyPackets(cEid, addressToBytes32(address(cReceiver)));
        verifyPackets(dEid, addressToBytes32(address(dReceiver)));


        ///assertEq(bReceiver.data(), "Chain A says hello!");
        ///assertEq(cReceiver.data(), "Chain A says hello!");
        ///assertEq(dReceiver.data(), "Chain A says hello!");
    }
}