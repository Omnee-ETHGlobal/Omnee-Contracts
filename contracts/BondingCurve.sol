// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";

import "./interfaces/IBondingCurve.sol";
import "./librairies/MsgUtils.sol";

contract BondingCurve is IBondingCurve, ReentrancyGuard, OApp {
    using SafeERC20 for IERC20;

    address public override universalFactoryAddress;

    address[] public override tokenList;
    mapping(address => TokenInfo) public supportedTokens;

    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    uint256 public constant SLOPE = 0.001 * 1e18;
    uint256 public constant INITIAL_PRICE = 0.000000001 * 1e18;

    constructor(
        address _endpoint,
        address _delegate,
        address _universalFactoryAddress
    ) OApp(_endpoint, _delegate) Ownable(_delegate) {
        universalFactoryAddress = _universalFactoryAddress;
    }

    function getTokenInfo(address _tokenAddress) external view override returns (TokenInfo memory) {
        return supportedTokens[_tokenAddress];
    }

    function addToken(address _tokenAddress) external {
        require(msg.sender == universalFactoryAddress, "Unauthorized");
        require(_tokenAddress != address(0), "Invalid token address");
        require(!supportedTokens[_tokenAddress].exists, "Token already supported");

        IERC20 token = IERC20(_tokenAddress);

        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= INITIAL_SUPPLY, "Insufficient token balance in contract");

        supportedTokens[_tokenAddress] = TokenInfo({ reserveBalance: INITIAL_SUPPLY, liquidity: 0, exists: true });
        tokenList.push(_tokenAddress);

        emit TokenAdded(_tokenAddress);
    }

    function buyTokens(address _tokenAddress, uint256 _amount) external payable nonReentrant {
        if (_amount == 0) revert InvalidAmount(_amount);
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        uint256 cost = calculatePurchaseCost(_tokenAddress, _amount);
        if (msg.value < cost) revert InsufficientLiquidity(cost, msg.value);

        tokenInfo.reserveBalance += _amount;
        tokenInfo.liquidity += msg.value;

        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(msg.sender, _amount);

        emit TokenBought(msg.sender, _tokenAddress, _amount, cost);
    }

    function sellTokens(address _tokenAddress, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount(_amount);
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        uint256 payout = calculateSellPayout(_tokenAddress, _amount);
        if (address(this).balance < payout) revert InsufficientLiquidity(payout, address(this).balance);

        tokenInfo.reserveBalance -= _amount;
        tokenInfo.liquidity -= payout;

        IERC20 token = IERC20(_tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        (bool success, ) = msg.sender.call{ value: payout }("");
        if (!success) revert TransferFailed(address(0), address(this), msg.sender, payout);

        emit TokenSold(msg.sender, _tokenAddress, _amount, payout);
    }

    function calculatePurchaseCost(address _tokenAddress, uint256 amount) public view returns (uint256) {
        TokenInfo memory tokenInfo = supportedTokens[_tokenAddress];
        uint256 area = (tokenInfo.reserveBalance * SLOPE) / 1e18 + INITIAL_PRICE;
        uint256 newArea = ((tokenInfo.reserveBalance + amount) * SLOPE) / 1e18 + INITIAL_PRICE;
        return ((area + newArea) * amount) / 2;
    }

    function calculateSellPayout(address _tokenAddress, uint256 amount) public view returns (uint256) {
        TokenInfo memory tokenInfo = supportedTokens[_tokenAddress];
        uint256 area = (tokenInfo.reserveBalance * SLOPE) / 1e18 + INITIAL_PRICE;
        uint256 newArea = ((tokenInfo.reserveBalance - amount) * SLOPE) / 1e18 + INITIAL_PRICE;
        return ((area + newArea) * amount) / 2;
    }

    fallback() external payable {}
    receive() external payable {}

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address,
        bytes calldata _extraData
    ) internal override {
        address senderAddress = address(uint160(uint256(bytes32(_origin.sender))));

        MsgUtils.StdMsg memory message = abi.decode(_message, (MsgUtils.StdMsg));

        if (message.messageType == MsgCodecs.MSG_BUY_REMOTE) {
            MsgUtils.BuyTokenMsg memory buyMessage = abi.decode(message.encodedContent, (MsgUtils.BuyTokenMsg));
            // TODO: Receive ETH in SC
            // TODO: Buy tokens in bonding curve
        } else if (message.messageType == MsgCodecs.MSG_SELL_REMOTE) {
            MsgUtils.SellTokenMsg memory sellMessage = abi.decode(message.encodedContent, (MsgUtils.SellTokenMsg));
            // TODO: Sell tokens in bonding curve
            // TODO: Transfer ETH back to user
        } else {
            revert InvalidMessageType(message.messageType);
        }
    }
}
