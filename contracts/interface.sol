// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ============= flashloan related
interface IFlashLoan {
  function flashLoan(
    IFlashLoanRecipient recipient,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}

interface IFlashLoanRecipient {
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}

// ============= Fei protocol related
interface IController {
  function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
  function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);
  function exitMarket(address cTokenAddress) external returns (uint256);
}

interface IFToken {
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function mint(uint256 mintAmount) external returns (uint256);
  function borrow(uint256 borrowAmount) external returns (uint256);
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
  function getCash() external view returns (uint);
  function totalBorrows() external view returns (uint256);
  function totalReserves() external view returns (uint256);
}

interface IFETH {
  function mint() external payable;
  function getCash() external view returns (uint);
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

interface IPriceOracle {
  function getUnderlyingPrice(address rToken) external view returns (uint256);
}

interface IJumpRateModel {
  function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);
}

// ============= others
interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
  function transfer(address dst, uint256 wad) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
}

interface IUSDT {
  function transfer(address dst, uint256 wad) external;
  function balanceOf(address owner) external view returns (uint256);
}




