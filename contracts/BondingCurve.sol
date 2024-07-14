// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOFT, SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { ILayerZeroComposer } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

import "./librairies/MsgUtils.sol";

/**
 * @title BondingCurve
 * @dev Implements a bonding curve for token trading and cross-chain interactions using LayerZero
 */
contract BondingCurve is OApp, ILayerZeroComposer, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OptionsBuilder for bytes;

    // Events
    event TokenAdded(address indexed tokenAddress);
    event TokenBought(address indexed buyer, address indexed tokenAddress, uint256 amount);
    event TokenSold(address indexed seller, address indexed tokenAddress, uint256 amount, uint256 payout);

    event LzReceiveLog(
        uint8 indexed msgType,
        address indexed tokenAddress,
        address indexed sender,
        uint32 eid,
        uint256 tokenAmount
    );
    event LzComposeLog(
        uint8 indexed msgType,
        address indexed tokenAddress,
        address indexed sender,
        uint32 eid,
        uint256 tokenAmount
    );

    // Custom errors
    error TokenNotSupported(address tokenAddress);
    error InsufficientBalance(address tokenAddress);
    error InsufficientUserBalance(address tokenAddress);
    error InsufficientLiquidity(uint256 requested, uint256 available);
    error InvalidAmount(uint256 amount);
    error TransferFailed(address token, address from, address to, uint256 amount);
    error InvalidMessageType(uint8 messageType);

    // State variables
    address public universalFactoryAddress;

    struct TokenInfo {
        uint256 reserveBalance;
        uint256 liquidity;
        bool exists;
    }

    address[] public tokenList;
    mapping(address => TokenInfo) public supportedTokens;

    // Constants
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    // uint256 public constant SLOPE = 0.001 * 1e18;
    uint256 public constant INITIAL_PRICE = 0.000000001 * 1e18;

    /**
     * @dev Constructor to initialize the contract
     * @param _endpoint The LayerZero endpoint address
     * @param _delegate The delegate address for ownership
     * @param _universalFactoryAddress The address of the universal factory
     */
    constructor(
        address _endpoint,
        address _delegate,
        address _universalFactoryAddress
    ) Ownable(_delegate) OApp(_endpoint, _delegate) {
        universalFactoryAddress = _universalFactoryAddress;
    }

    /**
     * @dev Calculates the amount of tokens that can be bought with a given amount of ETH
     * @param _tokenAddress The address of the token
     * @param _ethAmount The amount of ETH to spend
     * @return The amount of tokens that can be bought
     */
    function calculateBuyableAmount(address _tokenAddress, uint256 _ethAmount) public pure returns (uint256) {
        return (_ethAmount * 1e18) / INITIAL_PRICE; // TODO: Make this variable
    }

    /**
     * @dev Calculates the ETH payout for selling a given amount of tokens
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of tokens to sell
     * @return The ETH payout
     */
    function calculateSellPayout(address _tokenAddress, uint256 _tokenAmount) public pure returns (uint256) {
        return (_tokenAmount * INITIAL_PRICE) / 1e18; // TODO: Make this variable
    }

    /**
     * @dev Retrieves the token information for a given token address
     * @param _tokenAddress The address of the token
     * @return The TokenInfo struct containing token details
     */
    function getTokenInfo(address _tokenAddress) external view returns (TokenInfo memory) {
        return supportedTokens[_tokenAddress];
    }

    /**
     * @dev Adds a new token to the supported tokens list
     * @param _tokenAddress The address of the token to add
     */
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

    /**
     * @dev Allows users to buy tokens with ETH on Base
     * @param _tokenAddress The address of the token to buy
     */
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

    /**
     * @dev Internal function to handle remote token buying
     * @param _tokenAddress The address of the token to buy
     * @param _buyer The address of the buyer
     * @param _ethAmount The amount of ETH to spend
     * @param _eid The endpoint ID for LayerZero
     */
    function _buyTokensRemote(address _tokenAddress, address _buyer, uint256 _ethAmount, uint32 _eid) private {
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        IOFT oft = IOFT(_tokenAddress);

        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        SendParam memory quoteSendParam = SendParam({
            dstEid: _eid,
            to: MsgUtils.addressToBytes32(_buyer),
            amountLD: 0, // We don't know yet
            minAmountLD: 0, // We don't know yet
            extraOptions: extraOptions,
            composeMsg: bytes(""),
            oftCmd: bytes("")
        });

        // Estimate fees to send OFTs back to the buyer
        MessagingFee memory fee = oft.quoteSend(quoteSendParam, false);

        require(_ethAmount >= fee.nativeFee, "Insufficient fee provided");

        // Calculate the amount of tokens the buyer can buy after fees
        uint256 finalEthAmount = _ethAmount - fee.nativeFee;

        // The amount of tokens the buyer can buy
        uint256 buyableAmount = calculateBuyableAmount(_tokenAddress, finalEthAmount);
        if (tokenInfo.reserveBalance < buyableAmount) revert InsufficientBalance(_tokenAddress);

        tokenInfo.reserveBalance -= buyableAmount;
        tokenInfo.liquidity += finalEthAmount;

        quoteSendParam.amountLD = buyableAmount;
        quoteSendParam.minAmountLD = buyableAmount;

        IOFT(_tokenAddress).send(quoteSendParam, MessagingFee(fee.nativeFee, 0), payable(this));

        emit TokenBought(_buyer, _tokenAddress, buyableAmount);
    }

    /**
     * @dev Internal function to handle remote token selling
     * @param _tokenAddress The address of the token to sell
     * @param _buyer The address of the buyer
     * @param _tokenAmount The amount of tokens to sell
     * @param _eid The endpoint ID for LayerZero
     */
    function _sellTokensRemote(address _tokenAddress, address _buyer, uint256 _tokenAmount, uint32 _eid) private {
        if (_tokenAmount == 0) revert InvalidAmount(_tokenAmount);
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        IOFT oft = IOFT(_tokenAddress);

        uint256 payout = calculateSellPayout(_tokenAddress, _tokenAmount);

        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorNativeDropOption(
            uint128(payout),
            bytes32(uint256(uint160(_buyer)))
        );
        MessagingFee memory fee = _quote(_eid, bytes(""), extraOptions, false);
        require(payout >= fee.nativeFee, "Payout is insufficient to cover fees");

        require(address(this).balance >= payout, "Insufficient contract ETH balance");

        tokenInfo.reserveBalance += _tokenAmount;
        tokenInfo.liquidity -= payout;

        _lzSend(_eid, bytes(""), extraOptions, MessagingFee(payout, 0), payable(this));

        emit TokenSold(_buyer, _tokenAddress, _tokenAmount, payout);
    }

    /**
     * @dev Allows users to sell tokens for ETH on Base
     * @param _tokenAddress The address of the token to sell
     * @param _amount The amount of tokens to sell
     */
    function sellTokens(address _tokenAddress, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount(_amount);
        TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        IERC20 token = IERC20(_tokenAddress);
        if (token.balanceOf(msg.sender) < _amount) revert InsufficientUserBalance(_tokenAddress);

        uint256 payout = calculateSellPayout(_tokenAddress, _amount);
        if (address(this).balance < payout) revert InsufficientLiquidity(payout, address(this).balance);

        tokenInfo.reserveBalance += _amount;
        tokenInfo.liquidity -= payout;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        (bool success, ) = msg.sender.call{ value: payout }("");
        if (!success) revert TransferFailed(address(0), address(this), msg.sender, payout);

        emit TokenSold(msg.sender, _tokenAddress, _amount, payout);
    }

    /**
     * @dev Retrieves the current price of a token
     * @param _tokenAddress The address of the token
     * @return The current price of the token
     */
    function getTokenPrice(address _tokenAddress) public view returns (uint256) {
        TokenInfo memory tokenInfo = supportedTokens[_tokenAddress];
        if (!tokenInfo.exists) revert TokenNotSupported(_tokenAddress);

        return INITIAL_PRICE; // TODO: Make this variable
    }

    /**
     * @dev Handles incoming LayerZero messages
     * @param _origin The origin information of the message
     * @param _guid The globally unique identifier of the message
     * @param _message The message payload
     * @param _executor The address of the executor
     * @param _extraData Any extra data included with the message
     */
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) public payable override {
        (uint8 msgType, address tokenAddress, address sender, uint32 eid, uint256 tokenAmount) = abi.decode(
            _message,
            (uint8, address, address, uint32, uint256)
        );

        _buyTokensRemote(tokenAddress, sender, msg.value, eid);

        emit LzReceiveLog(msgType, tokenAddress, sender, eid, tokenAmount);
    }

    /**
     * @dev Handles LayerZero composed messages
     * @param _sender The address of the sender
     * @param _guid The globally unique identifier of the message
     * @param _message The message payload
     * @param _executor The address of the executor
     * @param _extraData Any extra data included with the message
     */
    function lzCompose(
        address _sender,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable override {
        (uint8 msgType, address tokenAddress, address sender, uint32 eid, uint256 tokenAmount) = abi.decode(
            _message,
            (uint8, address, address, uint32, uint256)
        );

        emit LzComposeLog(msgType, tokenAddress, sender, eid, tokenAmount);

        // if (msgType == 2) {
        //     _sellTokensRemote(tokenAddress, sender, tokenAmount, eid);
        // } else {
        //     revert InvalidMessageType(msgType);
        // }
    }

    /**
     * @dev Fallback function to receive ETH
     */
    fallback() external payable {}

    /**
     * @dev Receive function to receive ETH
     */
    receive() external payable {}

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {}
}
