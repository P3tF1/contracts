// SPDX-License-Identifier: MIT
// contract address: 0x3b3a6712fDD49E0eC46245439B3917675eaa0541
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC721 and IERC721 interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct ListedNFT {
        uint256 listingId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
    }

    mapping(uint256 => ListedNFT) public listedNFTs;

    uint256 public listingCounter;

    event NFTListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );
    event NFTBurned(uint256 indexed listingId);

    event NFTPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    event NFTPriceUpdated(
        uint256 indexed listingId,
        uint256 newPrice
    );

    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than 0");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        listingCounter++;

        listedNFTs[listingCounter] = ListedNFT({
            listingId: listingCounter,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price
        });

        emit NFTListed(listingCounter, msg.sender, nftContract, tokenId, price);
    }

    function updateNFTPrice(uint256 listingId, uint256 newPrice) external {
        require(listedNFTs[listingId].seller != address(0), "Listing does not exist");
        require(listedNFTs[listingId].seller == msg.sender, "Only the seller can update the price");
        require(newPrice > 0, "Price must be greater than 0");
        listedNFTs[listingId].price = newPrice;

        emit NFTPriceUpdated(listingId, newPrice);
    }

    function buyNFT(uint256 listingId) external payable nonReentrant {
        require(listedNFTs[listingId].seller != address(0), "Listing does not exist");
        ListedNFT memory nft = listedNFTs[listingId];
        if (msg.value != nft.price) {
            payable(msg.sender).transfer(msg.value);
            revert("Incorrect ETH amount sent");
        }
        IERC721(nft.nftContract).transferFrom(address(this), msg.sender, nft.tokenId);
        payable(nft.seller).transfer(msg.value);
        emit NFTPurchased(listingId, msg.sender, nft.nftContract, nft.tokenId, nft.price);
        delete listedNFTs[listingId];
    }

    function burnNFT(uint256 listingId) external nonReentrant {
        ListedNFT memory nft = listedNFTs[listingId];
        require(nft.seller == msg.sender, "Not the seller");
        require(nft.nftContract != address(0), "Listing does not exist");

        IERC721(nft.nftContract).transferFrom(address(this), address(0), nft.tokenId);

        delete listedNFTs[listingId];
        
        emit NFTBurned(listingId);
    }

    function getAllListedNFTs() external view returns (ListedNFT[] memory) {
        uint256 activeCount = 0;
        
        for(uint256 i = 1; i <= listingCounter; i++) {
            if(listedNFTs[i].seller != address(0)) {
                activeCount++;
            }
        }

        ListedNFT[] memory activeListings = new ListedNFT[](activeCount);
        uint256 currentIndex = 0;
        for(uint256 i = 1; i <= listingCounter; i++) {
            if(listedNFTs[i].seller != address(0)) {
                activeListings[currentIndex] = listedNFTs[i];
                currentIndex++;
            }
        }

        return activeListings;
    }

}