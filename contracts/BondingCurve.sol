// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";

import "./librairies/MsgUtils.sol";
import "./interfaces/IBondingCurve.sol";

contract BondingCurve is ReentrancyGuard, Ownable, OApp {
    using SafeERC20 for IERC20;

    struct TokenInfo {
        uint256 reserveBalance;
        uint256 liquidity;
        bool exists;
    }

    event TokenAdded(address indexed tokenAddress);
    event TokenBought(address indexed buyer, address indexed tokenAddress, uint256 amount);
    event TokenSold(address indexed seller, address indexed tokenAddress, uint256 amount, uint256 payout);

    error TokenNotSupported(address tokenAddress);
    error InsufficientBalance(address tokenAddress);
    error InsufficientLiquidity(uint256 requested, uint256 available);
    error InvalidAmount(uint256 amount);
    error TransferFailed(address token, address from, address to, uint256 amount);
    error InvalidMessageType(uint8 messageType);

    address public universalFactoryAddress;

    address[] public tokenList;
    mapping(address => TokenInfo) public supportedTokens;

    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    // uint256 public constant SLOPE = 0.001 * 1e18;
    uint256 public constant INITIAL_PRICE = 0.000000001 * 1e18;

    constructor(
        address _endpoint,
        address _delegate,
        address _universalFactoryAddress
    ) OApp(_endpoint, _delegate) Ownable(_delegate) {
        universalFactoryAddress = _universalFactoryAddress;
    }

    function getTokenInfo(address _tokenAddress) external view returns (TokenInfo memory) {
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

    function buyTokens(address _tokenAddress) external payable nonReentrant {
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        uint256 buyableAmount = calculateBuyableAmount(_tokenAddress, msg.value);
        if (tokenInfo.reserveBalance < buyableAmount) revert InsufficientBalance(_tokenAddress);

        tokenInfo.reserveBalance -= buyableAmount;
        tokenInfo.liquidity += msg.value;

        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(msg.sender, buyableAmount);

        emit TokenBought(msg.sender, _tokenAddress, buyableAmount);
    }

    function sellTokens(address _tokenAddress, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount(_amount);
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        uint256 payout = calculateSellPayout(_tokenAddress, _amount);
        if (address(this).balance < payout) revert InsufficientLiquidity(payout, address(this).balance);

        tokenInfo.reserveBalance += _amount;
        tokenInfo.liquidity -= payout;

        IERC20 token = IERC20(_tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        (bool success, ) = msg.sender.call{ value: payout }("");
        if (!success) revert TransferFailed(address(0), address(this), msg.sender, payout);

        emit TokenSold(msg.sender, _tokenAddress, _amount, payout);
    }

    function calculateBuyableAmount(address _tokenAddress, uint256 _amount) public pure returns (uint256) {
        return _amount / INITIAL_PRICE;
    }

    function calculateSellPayout(address _tokenAddress, uint256 _amount) public pure returns (uint256) {
        return _amount * INITIAL_PRICE;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32,
        bytes calldata _message,
        address,
        bytes calldata
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

    fallback() external payable {}
    receive() external payable {}
}
