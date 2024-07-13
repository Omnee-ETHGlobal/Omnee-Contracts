// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBondingCurve {
    struct TokenInfo {
        IERC20 token;
        uint256 reserveBalance;
        uint256 liquidity;
    }

    event TokenAdded(address indexed tokenAddress);
    event TokenBought(address indexed buyer, address indexed tokenAddress, uint256 amount, uint256 cost);
    event TokenSold(address indexed seller, address indexed tokenAddress, uint256 amount, uint256 payout);

    error TokenNotSupported(address tokenAddress);
    error InsufficientLiquidity(uint256 requested, uint256 available);
    error InvalidAmount(uint256 amount);
    error TransferFailed(address token, address from, address to, uint256 amount);

    function universalFactoryAddress() external view returns (address);
    function tokenList(uint256 index) external view returns (address);
    function getTokenInfo(address tokenAddress) external view returns (TokenInfo memory);
    function addToken(address _tokenAddress) external;
    function buyTokens(address tokenAddress, uint256 amount) external payable;
    function sellTokens(address tokenAddress, uint256 amount) external;
    function calculatePurchaseCost(uint256 reserveBalance, uint256 amount) external pure returns (uint256);
    function calculateSellPayout(uint256 reserveBalance, uint256 amount) external pure returns (uint256);
}
