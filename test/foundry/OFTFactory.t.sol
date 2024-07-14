// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Mock imports
import { UniversalFactory } from "../../contracts/UniversalFactory.sol";
import { OFTFactory } from "../../contracts/OFTFactory.sol";
import { BondingCurve } from "../../contracts/BondingCurve.sol";
import { OmneeRouter } from "../../contracts/OmneeRouter.sol";

// OApp imports
import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { MessagingFee, MessagingReceipt, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";


// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IOmneeOFT } from "../../contracts/interfaces/IOmneeOFT.sol";

// Forge imports
import "forge-std/console.sol";
import { Vm } from "forge-std/Test.sol";
import "forge-std/Test.sol";

import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract UniversalFactoryTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 aEid = 40245;
    uint32 bEid = 40231;
    uint32 cEid = 40170;
    uint32 dEid = 40232;

    uint16 SEND = 1;
        
    UniversalFactory aUniversalFactory;

    OFTFactory aOFTFactory;
    OFTFactory bOFTFactory;
    OFTFactory cOFTFactory;
    OFTFactory dOFTFactory;

    BondingCurve aBondingCurve;

    OmneeRouter bRouter;
    OmneeRouter cRouter;
    OmneeRouter dRouter;

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

        aUniversalFactory = UniversalFactory(
            payable(_deployOApp(type(UniversalFactory).creationCode, abi.encode(address(endpoints[aEid]), address(this))))
        );

        aOFTFactory = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[aEid]), address(this), 1, bytes32(uint256(uint160(address(aUniversalFactory)))))))
        );

        bOFTFactory = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[bEid]), address(this), 2, bytes32(uint256(uint160(address(aUniversalFactory)))))))
        );

        cOFTFactory = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[cEid]), address(this), 3, bytes32(uint256(uint160(address(aUniversalFactory)))))))
        );

        dOFTFactory = OFTFactory(
            payable(_deployOApp(type(OFTFactory).creationCode, abi.encode(address(endpoints[dEid]), address(this), 4, bytes32(uint256(uint160(address(aUniversalFactory)))))))
        );

        aBondingCurve = BondingCurve(
            payable(_deployOApp(type(BondingCurve).creationCode, abi.encode(address(this), address(aUniversalFactory))))
        );

        bRouter = OmneeRouter(
            payable(_deployOApp(type(OmneeRouter).creationCode, abi.encode(address(endpoints[bEid]), address(this), 2)))
        );

        cRouter = OmneeRouter(
            payable(_deployOApp(type(OmneeRouter).creationCode, abi.encode(address(endpoints[cEid]), address(this), 3)))
        );

        dRouter = OmneeRouter(
            payable(_deployOApp(type(OmneeRouter).creationCode, abi.encode(address(endpoints[dEid]), address(this), 4)))
        );

        aUniversalFactory.setBaseFactory(address(aOFTFactory));
        aUniversalFactory.setBondingCurve(address(aBondingCurve));

        aOFTFactory.setBondingCurve(address(aBondingCurve));
        bOFTFactory.setBondingCurve(address(aBondingCurve));
        cOFTFactory.setBondingCurve(address(aBondingCurve));

        bRouter.setBondingCurve(bytes32(uint256(uint160(address(aBondingCurve)))));
        cRouter.setBondingCurve(bytes32(uint256(uint160(address(aBondingCurve)))));
        dRouter.setBondingCurve(bytes32(uint256(uint160(address(aBondingCurve)))));

        aUniversalFactory.setPeer(2, bytes32(uint256(uint160(address(bOFTFactory)))));
        aUniversalFactory.setPeer(3, bytes32(uint256(uint160(address(cOFTFactory)))));
        aUniversalFactory.setPeer(4, bytes32(uint256(uint160(address(dOFTFactory)))));

        bOFTFactory.setPeer(1, bytes32(uint256(uint160(address(aUniversalFactory)))));
        cOFTFactory.setPeer(1, bytes32(uint256(uint160(address(aUniversalFactory)))));
        dOFTFactory.setPeer(1, bytes32(uint256(uint160(address(aUniversalFactory)))));

        bRouter.setPeer(1, bytes32(uint256(uint160(address(aBondingCurve)))));
        cRouter.setPeer(1, bytes32(uint256(uint160(address(aBondingCurve)))));
        dRouter.setPeer(1, bytes32(uint256(uint160(address(aBondingCurve)))));

    }
    
    function test_batch_send() public {
        
        bytes memory _extraSendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(50000000, 0); // extra gas limit and msg.value to request for A -> B

        uint32[] memory _dstEids = new uint32[](3);
        _dstEids[0] = bEid;
        _dstEids[1] = cEid;
        _dstEids[2] = dEid;

        // Use the return call quote to generate a new quote for A -> B.
        // src chain cost + price of gas that I want to send + fees for my chosen security Stack / Executor
        uint256 nativeFee = aUniversalFactory.quoteDeployOFT("MEOW", "MEOW", _dstEids, _extraSendOptions);

        aUniversalFactory.deployOFT{value: nativeFee}(
            "MEOW",
            "MEOW",
            _dstEids,
            _extraSendOptions
        );

    }
}