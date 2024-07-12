// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BondingCurve is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct TokenInfo {
        IERC20 token;
        uint256 reserveBalance;
        uint256 liquidity;
    }
    address public universalFactoryAddress;

    address[] public tokenList;

    mapping(address => TokenInfo) public supportedTokens;

    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    uint256 public constant SLOPE = 0.001 * 1e18;
    uint256 public constant INITIAL_PRICE = 0.001 * 1e18;

    constructor(address _universalFactoryAddress) {
        universalFactoryAddress = _universalFactoryAddress;
    }

    function addToken(address _tokenAddress) external {
        require(msg.sender == universalFactoryAddress, "Unauthorized");
        require(_tokenAddress != address(0), "Invalid token address");
        require(supportedTokens[_tokenAddress].token == IERC20(address(0)), "Token already supported");

        IERC20 token = IERC20(_tokenAddress);

        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= INITIAL_SUPPLY, "Insufficient token balance in contract");

        supportedTokens[_tokenAddress] = TokenInfo({ token: token, reserveBalance: INITIAL_SUPPLY, liquidity: 0 });
        tokenList.push(_tokenAddress);
    }

    function buyTokens(address tokenAddress, uint256 amount) external payable nonReentrant {
        TokenInfo storage tokenInfo = supportedTokens[tokenAddress];

        uint256 cost = calculatePurchaseCost(tokenInfo.reserveBalance, amount);
        require(msg.value >= cost, "Insufficient funds");

        tokenInfo.reserveBalance += amount;
        tokenInfo.liquidity += msg.value;
        tokenInfo.token.safeTransfer(msg.sender, amount);
    }

    function sellTokens(address tokenAddress, uint256 amount) external nonReentrant {
        TokenInfo storage tokenInfo = supportedTokens[tokenAddress];
        uint256 payout = calculateSellPayout(tokenInfo.reserveBalance, amount);

        tokenInfo.reserveBalance -= amount;
        tokenInfo.liquidity -= payout;
        tokenInfo.token.safeTransferFrom(msg.sender, address(this), amount);

        (bool success, ) = msg.sender.call{ value: payout }("");
        require(success, "Transfer failed");
    }

    function calculatePurchaseCost(uint256 reserveBalance, uint256 amount) public pure returns (uint256) {
        uint256 area = (reserveBalance * SLOPE) / 1e18 + INITIAL_PRICE;
        uint256 newArea = ((reserveBalance + amount) * SLOPE) / 1e18 + INITIAL_PRICE;
        return ((area + newArea) * amount) / 2;
    }

    function calculateSellPayout(uint256 reserveBalance, uint256 amount) public pure returns (uint256) {
        uint256 area = (reserveBalance * SLOPE) / 1e18 + INITIAL_PRICE;
        uint256 newArea = ((reserveBalance - amount) * SLOPE) / 1e18 + INITIAL_PRICE;
        return ((area + newArea) * amount) / 2;
    }

    receive() external payable {}
}
