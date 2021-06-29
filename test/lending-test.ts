import { ethers, upgrades } from "hardhat"

import { expect } from "chai"
import { Contract, Signer } from "ethers"
import { bytes32, timeout, wait, now, timeoutAppended } from "./utils/utils"
import { Lending, TestERC20, Token } from "../typechain"

import { tokens } from "./utils/utils"

describe("Lending", async () => {
  let owner: Signer
  let users: Signer[]
  let tokenBUSD, tokenWBNB: TestERC20
  let lending: Lending

  beforeEach(async () => {
    ;[owner, ...users] = await ethers.getSigners()

    tokenBUSD = (await (await ethers.getContractFactory("TestERC20")).deploy("BUSD", "BUSD")) as TestERC20
	    await tokenBUSD.deployed()
    for (const user of users) {
      await tokenBUSD.transfer(await user.getAddress(), tokens(10000))
    }
	
    tokenWBNB = (await (await ethers.getContractFactory("TestERC20")).deploy("WBNB", "WBNB")) as TestERC20
    await tokenWBNB.deployed()
    await tokenWBNB.transfer(await owner.getAddress(), tokens(10000))
  
    lending = (await (await ethers.getContractFactory("Lending")).deploy()) as Lending
    await lending.deployed()
  })

  it('There are not any tokens on contract', async () => {
    const status = await lending.isPossible()
    expect(status).to.be.false
  })

  it('Does not allow entry if lottery is not live', async () => {
    await expect(lending.borrow(100)).to.be.revertedWith("loan is impossible");
  })

  it('There are some tokens on contract', async () => {
    await lending.activateLending(50)
    await expect(lending.isPossible()).to.be.true
  })

  it('Loan for an allowable amount', async () => {
    await lending.activateLending(50)
    await lending.borrow(1);
    await expect(lending.isPossible()).to.be.true
  })

  it('Loan for an inadmissible amount', async () => {
    await lending.activateLending(50)
    await lending.borrow(50);
    await expect(lending.isPossible()).to.be.false
  })

  it('Loan repayment', async () => {
    await lending.activateLending(50)
    await lending.borrow(50);
    await lending.repay();
    await expect(lending.isPossible()).to.be.true
  })

})
