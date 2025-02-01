// SPDX-License-Identifier: MIT
// contract address: 0xf2d5caE224Efaccd99FCe9bAfE4c076414DbE697
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC721 and IERC721 interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    // Struct to store listed NFT details
    struct ListedNFT {
        uint256 listingId; // Unique ID for the listing
        address seller; // Address of the seller
        address nftContract; // Address of the NFT contract
        uint256 tokenId; // Token ID of the NFT
        uint256 price; // Price of the NFT in ETH
    }

    // Mapping to store listed NFTs
    mapping(uint256 => ListedNFT) public listedNFTs;

    // Counter for listing IDs
    uint256 public listingCounter;

    // Event emitted when an NFT is listed
    event NFTListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    // Event emitted when an NFT is purchased
    event NFTPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    // Event emitted when the price of a listed NFT is updated
    event NFTPriceUpdated(
        uint256 indexed listingId,
        uint256 newPrice
    );

    // Function to list an NFT for sale
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        // Ensure the price is greater than 0
        require(price > 0, "Price must be greater than 0");

        // Transfer the NFT to this contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // Increment the listing counter
        listingCounter++;

        // Store the NFT details
        listedNFTs[listingCounter] = ListedNFT({
            listingId: listingCounter,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price
        });

        // Emit the NFTListed event
        emit NFTListed(listingCounter, msg.sender, nftContract, tokenId, price);
    }

    // Function to update the price of a listed NFT
    function updateNFTPrice(uint256 listingId, uint256 newPrice) external {
        // Ensure the listing exists
        require(listedNFTs[listingId].seller != address(0), "Listing does not exist");

        // Ensure the caller is the seller
        require(listedNFTs[listingId].seller == msg.sender, "Only the seller can update the price");

        // Ensure the new price is greater than 0
        require(newPrice > 0, "Price must be greater than 0");

        // Update the price
        listedNFTs[listingId].price = newPrice;

        // Emit the NFTPriceUpdated event
        emit NFTPriceUpdated(listingId, newPrice);
    }

    // Function to buy a listed NFT
    function buyNFT(uint256 listingId) external payable nonReentrant {
        // Ensure the listing exists
        require(listedNFTs[listingId].seller != address(0), "Listing does not exist");

        // Get the NFT details
        ListedNFT memory nft = listedNFTs[listingId];

        // Ensure the buyer sent the correct amount of ETH
        if (msg.value != nft.price) {
            // Revert the transaction and return the sent ETH
            payable(msg.sender).transfer(msg.value);
            revert("Incorrect ETH amount sent");
        }

        // Transfer the NFT to the buyer
        IERC721(nft.nftContract).transferFrom(address(this), msg.sender, nft.tokenId);

        // Transfer the ETH to the seller
        payable(nft.seller).transfer(msg.value);

        // Emit the NFTPurchased event
        emit NFTPurchased(listingId, msg.sender, nft.nftContract, nft.tokenId, nft.price);

        // Delete the listing
        delete listedNFTs[listingId];
    }
}