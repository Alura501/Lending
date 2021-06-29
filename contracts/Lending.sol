//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Token} from "./Token.sol";

contract Lending {

    struct Borrower{
        uint loanAmount;
        uint time;
        uint summ;
    }

    address creditor;
    mapping (address =>Borrower) borrower;

    uint public creditTerm;
    uint public startTime;

    bool loanIsPossible;

    address constant addrBUSD=0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    address constant addrWBNB=0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    uint percent;
    uint deposite;


    constructor(){
        creditor = msg.sender;
        creditTerm = 60 minutes;
        loanIsPossible = false;
        percent = 20;
        deposite = 1;
    }

    function activateLending(uint WBNBcount) public{
        console.log('try to put %s tokens', WBNBcount);
        console.log('loan is possible: %s', loanIsPossible);
        require(msg.sender == creditor);
        console.log('There are %s WBNB tokens', Token(addrWBNB).balanceOf(creditor));
        require(Token(addrWBNB).allowance(msg.sender, address(this)) >= WBNBcount);
        loanIsPossible = true;
        console.log('loan is possible: %s', loanIsPossible);
        Token(addrWBNB).transferFrom(creditor, address(this), WBNBcount);
         console.log('%s tokens was put on contract', WBNBcount);
    }

    function borrow(uint WBNBcount) public payable{
        console.log('try to borrow %s tokens', WBNBcount);
        require(loanIsPossible, "loan is impossible");
        console.log('loan is possible: %s', loanIsPossible);
        console.log('There are %s WBNB tokens', Token(addrWBNB).balanceOf(address(this)));
        require(Token(addrWBNB).allowance(address(this), msg.sender) >= WBNBcount);
        console.log('There are enouth WBNB tokens');
        require(Token(addrBUSD).allowance(msg.sender, address(this)) >= WBNBcount*deposite);
        console.log('Borrower Has enouth BUSD tokens');

        borrower[msg.sender].loanAmount=WBNBcount*deposite;
        borrower[msg.sender].time=block.timestamp;

        Token(addrBUSD).transferFrom(msg.sender, address(this), WBNBcount*deposite);
        Token(addrWBNB).transferFrom(address(this), msg.sender, WBNBcount);
        if(Token(addrWBNB).balanceOf(address(this))<0)
           loanIsPossible = false;
        emit borrowedTokens(msg.sender);

    }

    function repay() public payable{
        require(block.timestamp<=borrower[msg.sender].time+creditTerm);
        uint pay = refundAmount(msg.sender);
        require(Token(addrWBNB).allowance( msg.sender, address(this)) >= pay);

        Token(addrWBNB).transferFrom(msg.sender, address(this), pay);
        Token(addrBUSD).transferFrom(address(this), msg.sender, borrower[msg.sender].loanAmount);

        emit repayTokens(msg.sender);
    }
   
   function refundAmount(address addr) private view returns(uint){
       return borrower[addr].summ*((block.timestamp-borrower[addr].time)*percent);
   }

    function isPossible() public view returns(bool){
       console.log('loan is possible: %s', loanIsPossible);
       return loanIsPossible;
   }

   event borrowedTokens(address borrowerAddr);
   event repayTokens(address borrowerAddr);
}


