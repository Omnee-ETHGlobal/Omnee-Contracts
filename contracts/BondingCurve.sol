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
    uint256 public constant INITIAL_PRICE = 0.000000001 * 1e18;

    event TokenAdded(address indexed tokenAddress);
    event TokenBought(address indexed buyer, address indexed tokenAddress, uint256 amount, uint256 cost);
    event TokenSold(address indexed seller, address indexed tokenAddress, uint256 amount, uint256 payout);

    error TokenNotSupported(address tokenAddress);
    error InsufficientLiquidity(uint256 requested, uint256 available);
    error InvalidAmount(uint256 amount);
    error TransferFailed(address token, address from, address to, uint256 amount);

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

        emit TokenAdded(_tokenAddress);
    }

    function buyTokens(address tokenAddress, uint256 amount) external payable nonReentrant {
        if (amount == 0) revert InvalidAmount(amount);
        TokenInfo storage tokenInfo = supportedTokens[tokenAddress];
        if (address(tokenInfo.token) == address(0)) revert TokenNotSupported(tokenAddress);

        uint256 cost = calculatePurchaseCost(tokenInfo.reserveBalance, amount);
        if (msg.value < cost) revert InsufficientLiquidity(cost, msg.value);

        tokenInfo.reserveBalance += amount;
        tokenInfo.liquidity += msg.value;
        tokenInfo.token.safeTransfer(msg.sender, amount);

        emit TokenBought(msg.sender, tokenAddress, amount, cost);
    }

    function sellTokens(address tokenAddress, uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount(amount);
        TokenInfo storage tokenInfo = supportedTokens[tokenAddress];
        if (address(tokenInfo.token) == address(0)) revert TokenNotSupported(tokenAddress);

        uint256 payout = calculateSellPayout(tokenInfo.reserveBalance, amount);
        if (address(this).balance < payout) revert InsufficientLiquidity(payout, address(this).balance);

        tokenInfo.reserveBalance -= amount;
        tokenInfo.liquidity -= payout;
        tokenInfo.token.safeTransferFrom(msg.sender, address(this), amount);

        (bool success, ) = msg.sender.call{ value: payout }("");
        if (!success) revert TransferFailed(address(0), address(this), msg.sender, payout);

        emit TokenSold(msg.sender, tokenAddress, amount, payout);
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
