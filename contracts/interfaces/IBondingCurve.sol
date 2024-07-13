// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBondingCurve {
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

    function universalFactoryAddress() external view returns (address);
    function tokenList(uint256 _index) external view returns (address);
    function getTokenInfo(address _tokenAddress) external view returns (TokenInfo memory);
    function addToken(address _tokenAddress) external;
    function buyTokens(address _tokenAddress) external payable;
    function sellTokens(address _tokenAddress, uint256 _amount) external;
    function calculatePurchaseCost(address _tokenAddress, uint256 _amount) external view returns (uint256);
    function calculateSellPayout(address _tokenAddress, uint256 _amount) external view returns (uint256);
}
