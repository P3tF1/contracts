// SPDX-License-Identifier: MIT
// 0x950Ed51EE6A2D74Ff23e69090664a8f109006a1d
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTGenerator is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFT {
        string name;
        uint256 level;
        uint256 strength;
        uint256 intelligence;
        string imageLink;
        uint256 xP;
    }

    struct PetFood {
        uint256 id;
        string name;
        uint256 strengthBoost;
        uint256 intelligenceBoost;
        uint256 price;
    }

    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public userNFTs;
    mapping(uint256 => PetFood) public petFoods;
    mapping(address => mapping(uint256 => uint256)) public userPetFoodBalance; // user => petFoodId => amount
    uint256 public petFoodCounter;

    constructor() ERC721("NFTGenerator", "NFTG") Ownable(msg.sender) {}

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
            imageLink: imageLink,
            xP: 0
        });

        userNFTs[msg.sender].push(newTokenId);
        return newTokenId;
    }

    function addPetFood(
        string memory name,
        uint256 strengthBoost,
        uint256 intelligenceBoost,
        uint256 price
    ) public onlyOwner {
        petFoodCounter++;
        petFoods[petFoodCounter] = PetFood({
            id: petFoodCounter,
            name: name,
            strengthBoost: strengthBoost,
            intelligenceBoost: intelligenceBoost,
            price: price
        });
    }

    function buyPetFood(uint256 petFoodId, uint256 amount) public payable {
        require(petFoods[petFoodId].id != 0, "Pet food does not exist");
        uint256 totalCost = petFoods[petFoodId].price * amount;
        require(msg.value >= totalCost, "Insufficient payment");

        userPetFoodBalance[msg.sender][petFoodId] += amount;

        uint256 refundAmount = msg.value - totalCost;
        if (refundAmount > 0) {
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
    }

    function feedPet(uint256 tokenId, uint256 petFoodId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(userPetFoodBalance[msg.sender][petFoodId] > 0, "No pet food left");

        userPetFoodBalance[msg.sender][petFoodId]--;

        NFT storage nft = nfts[tokenId];
        PetFood storage food = petFoods[petFoodId];

        nft.strength += food.strengthBoost;
        nft.intelligence += food.intelligenceBoost;
    }

    function increaseXP(uint256 tokenId, uint256 amount) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        NFT storage nft = nfts[tokenId];
        nft.xP += amount;

        while (nft.xP >= 100) {
            nft.xP -= 100;
            nft.level++;
        }
    }

    function updateNFTStats(uint256 tokenId, uint256 level, uint256 strength, uint256 intelligence) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        NFT storage nft = nfts[tokenId];
        nft.level += level;
        nft.strength += strength;
        nft.intelligence += intelligence;
    }

    function updateImageURI(uint256 tokenId, string memory newImageLink) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        NFT storage nft = nfts[tokenId];
        nft.imageLink = newImageLink;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }

    function getUserNFTs(address user) public view returns (uint256[] memory) {
        return userNFTs[user];
    }

    function getNFTDetails(uint256 tokenId) public view returns (NFT memory) {
        return nfts[tokenId];
    }

    function getPetFoodDetails(uint256 petFoodId) public view returns (PetFood memory) {
        require(petFoods[petFoodId].id != 0, "Pet food does not exist");
        return petFoods[petFoodId];
    }

    function getUserPetFoodBalance(address user, uint256 petFoodId) public view returns (uint256) {
        return userPetFoodBalance[user][petFoodId];
    }

    function getUserPetFoodDetails(address user) public view returns (PetFood[] memory, uint256[] memory) {
        uint256 userPetFoodCount = 0;

        for (uint256 i = 1; i <= petFoodCounter; i++) {
            if (userPetFoodBalance[user][i] > 0) {
                userPetFoodCount++;
            }
        }

        PetFood[] memory userPetFoods = new PetFood[](userPetFoodCount);
        uint256[] memory amounts = new uint256[](userPetFoodCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= petFoodCounter; i++) {
            if (userPetFoodBalance[user][i] > 0) {
                userPetFoods[index] = petFoods[i];
                amounts[index] = userPetFoodBalance[user][i];
                index++;
            }
        }

        return (userPetFoods, amounts);
    }
}