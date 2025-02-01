// SPDX-License-Identifier: MIT
// 0x2258D27a3e0452D31A51c66f15C3C72EbD55eEB9

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract P3TF1Token is ERC20, Ownable {
    uint256 public constant RATE = 0.000001 ether;

    constructor() ERC20("P3TF1 Coin", "P3TF1") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    } 

    function buyTokens() external payable {
        require(msg.value >= RATE, "Minimum purchase is 0.000001 ETH");

        uint256 tokensToMint = (msg.value / RATE) * 10 ** decimals();
        _mint(msg.sender, tokensToMint);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function transferTokens(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function mintTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        _mint(owner(), amount * 10 ** decimals());
    }
}
