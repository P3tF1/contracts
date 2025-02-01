// SPDX-License-Identifier: MIT
//  Base sepolia address: 0xf987EE4e482ddBD4fB60Eb2F4213e7A530480B0C
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTGenerator is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFT {
        string name;
        uint256 level;
        uint256 strength;
        uint256 intelligence;
        string imageLink;
    }

    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public userNFTs;

    constructor() ERC721("NFTGenerator", "NFTG") {}

    function mintNFT(
        string memory name,
        uint256 level,
        uint256 strength,
        uint256 intelligence,
        string memory imageLink
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);

        nfts[newTokenId] = NFT({
            name: name,
            level: level,
            strength: strength,
            intelligence: intelligence,
            imageLink: imageLink
        });

        userNFTs[msg.sender].push(newTokenId);

        return newTokenId;
    }

    function incrementLevel(uint256 tokenId, uint256 incrementValue) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nfts[tokenId].level += incrementValue;
    }

    function decrementLevel(uint256 tokenId, uint256 decrementValue) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(nfts[tokenId].level >= decrementValue, "Level cannot be negative");
        nfts[tokenId].level -= decrementValue;
    }

    function incrementStrength(uint256 tokenId, uint256 incrementValue) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nfts[tokenId].strength += incrementValue;
    }

    function decrementStrength(uint256 tokenId, uint256 decrementValue) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(nfts[tokenId].strength >= decrementValue, "Strength cannot be negative");
        nfts[tokenId].strength -= decrementValue;
    }

    function incrementIntelligence(uint256 tokenId, uint256 incrementValue) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nfts[tokenId].intelligence += incrementValue;
    }

    function decrementIntelligence(uint256 tokenId, uint256 decrementValue) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(nfts[tokenId].intelligence >= decrementValue, "Intelligence cannot be negative");
        nfts[tokenId].intelligence -= decrementValue;
    }

    function getUserNFTs(address user) public view returns (uint256[] memory) {
        return userNFTs[user];
    }

    function getNFTDetails(uint256 tokenId) public view returns (NFT memory) {
        return nfts[tokenId];
    }
}