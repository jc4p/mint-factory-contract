// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GenericFarcasterNFT is ERC721, ReentrancyGuard {
    address public immutable creator;
    address public paymentRecipient;
    string public baseURI;
    uint256 public currentTokenId;
    uint256 public mintPrice;

    // Settings
    uint256 public immutable maxMintsPerTx = 1; // Always 1 token per transaction
    uint256 public immutable maxSupply; // Set in constructor, 0 means unlimited supply

    constructor(
        string memory initialBaseURI,
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        address _paymentRecipient,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        creator = msg.sender;
        baseURI = initialBaseURI;
        mintPrice = _mintPrice;
        paymentRecipient = _paymentRecipient == address(0) ? msg.sender : _paymentRecipient;
        maxSupply = _maxSupply; // 0 will represent unlimited supply
    }

    function mint() public payable nonReentrant returns (uint256) {
        // Check if the mint would exceed max supply
        // We only enforce the max supply check if it's not set to 0
        // If it's set to 0, it means unlimited supply
        if (maxSupply != 0) {
            require(currentTokenId < maxSupply, "Would exceed max supply");
        }

        // Check if they sent the right amount of ETH
        require(msg.value == mintPrice, "Must send exactly the mint price");

        // Store the starting tokenId
        uint256 tokenId = currentTokenId;

        // Update state before external call to prevent reentrancy
        currentTokenId = tokenId + 1;

        // Mint the token
        _mint(msg.sender, tokenId);

        // Send payment to recipient after minting (following CEI pattern)
        (bool success,) = payable(paymentRecipient).call{value: msg.value}("");
        require(success, "Transfer failed");

        return tokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Modifier to check if caller is authorized (creator or paymentRecipient)
    modifier onlyAuthorized() {
        require(msg.sender == creator || msg.sender == paymentRecipient, "Only creator or payment recipient can update");
        _;
    }

    // Allow creator or payment recipient to update baseURI if needed
    function setBaseURI(string memory newBaseURI) external onlyAuthorized {
        baseURI = newBaseURI;
    }

    // Allow creator or payment recipient to update mint price if needed
    function setMintPrice(uint256 _mintPrice) external onlyAuthorized {
        mintPrice = _mintPrice;
    }

    // Allow creator or payment recipient to update payment recipient if needed
    function setPaymentRecipient(address _paymentRecipient) external onlyAuthorized {
        require(_paymentRecipient != address(0), "Cannot set to zero address");
        paymentRecipient = _paymentRecipient;
    }

    // Max mints per tx is immutable at 1 and max supply is immutable from constructor

    /**
     * @notice Checks if minting is still possible
     * @return hasMintingAvailable True if tokens are still available for minting
     * @return remainingTokens The number of tokens still available to be minted
     */
    function mintingAvailable() public view returns (bool hasMintingAvailable, uint256 remainingTokens) {
        // If maxSupply is set to 0, it means unlimited supply
        if (maxSupply == 0) {
            return (true, type(uint256).max - currentTokenId); // Return "virtually unlimited"
        }

        if (currentTokenId >= maxSupply) {
            return (false, 0);
        }

        uint256 remaining = maxSupply - currentTokenId;
        return (true, remaining);
    }

    /**
     * @notice Returns the total supply of minted tokens
     * @return The number of tokens minted so far
     */
    function totalSupply() public view returns (uint256) {
        return currentTokenId;
    }
}
