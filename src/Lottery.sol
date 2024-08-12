// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
    struct buyer {
        uint16 guess;
        bool isbuyer;
    }

    uint16 public winningNumber;
    uint public totalbuy;
    uint public SellPhaseTime;
    bool public isSellPhase;
    bool public isClaimPhase;
    uint public buyerCount;
    uint public winners;

    mapping(uint => address) public matchbuyer;
    mapping(address => buyer) public buyers;

    function buy(uint16 guess) public payable {
        require(winners == 0, "claim not finished");
        require(msg.value == 0.1 ether, "wrong value");
        require(buyers[msg.sender].isbuyer == false, "no duplicate");

        if (isSellPhase == false) {
            SellPhaseTime = block.timestamp; // sell phase start
            isSellPhase = true;
        }
        require(block.timestamp - SellPhaseTime < 24 hours, "sell phase end");

        if (isClaimPhase) {isClaimPhase = false;}

        totalbuy += msg.value;
        buyers[msg.sender].guess = guess;
        buyers[msg.sender].isbuyer = true;
        matchbuyer[buyerCount] = msg.sender;
        buyerCount++;
    }

    function draw() public {
        require(block.timestamp - SellPhaseTime >= 24 hours, "no draw during sell phase");
        require(!isClaimPhase, "now is claim phase");

        winningNumber = uint16(uint256(keccak256(abi.encode(winningNumber)))); // weak random

        for(uint i = 0; i < buyerCount; i++) {
            if (buyers[matchbuyer[i]].guess == winningNumber) {winners++;}
        }

        isSellPhase = false;
        isClaimPhase = true;
    }

    function claim() public {
        require(buyers[msg.sender].isbuyer, "you are not a buyer");
        require(block.timestamp - SellPhaseTime >= 24 hours, "no draw during sell phase");

        if (buyers[msg.sender].guess == winningNumber) {
            msg.sender.call{value: totalbuy / winners}("");
            totalbuy -= (totalbuy / winners);
            winners--;
        }
        buyers[msg.sender].isbuyer = false;
        if (winners == 0) {init();}
    }

    function init() public {
        for(uint i = 0; i < buyerCount; i++) {
            buyers[matchbuyer[i]].guess = 0;
            buyers[matchbuyer[i]].isbuyer = false;
            matchbuyer[i] = address(0);
        }

        winners = 0;
        buyerCount = 0;        
    }
}