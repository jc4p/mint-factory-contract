// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FarcasterNFT is ERC721 {
    address public immutable creator;
    address public paymentRecipient;
    string public baseURI;
    uint256 public currentTokenId;
    uint256 public mintPrice;
    
    constructor(
        string memory initialBaseURI, 
        string memory _name, 
        string memory _symbol, 
        uint256 _mintPrice,
        address _paymentRecipient
    ) ERC721(_name, _symbol) {
        creator = msg.sender;
        baseURI = initialBaseURI;
        mintPrice = _mintPrice;
        paymentRecipient = _paymentRecipient == address(0) ? msg.sender : _paymentRecipient;
    }

    function mint() public payable returns (uint256) {
        require(msg.value == mintPrice, "Must send exactly the mint price");
        
        // Send payment to recipient before minting
        (bool success, ) = payable(paymentRecipient).call{value: msg.value}("");
        require(success, "Transfer failed");
        
        uint256 tokenId = currentTokenId;
        _mint(msg.sender, tokenId);
        currentTokenId = tokenId + 1;
        
        return tokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    // Optional: Allow creator to update baseURI if needed
    function setBaseURI(string memory newBaseURI) external {
        require(msg.sender == creator, "Only creator can update");
        baseURI = newBaseURI;
    }
    
    // Allow creator to update mint price if needed
    function setMintPrice(uint256 _mintPrice) external {
        require(msg.sender == creator, "Only creator can update");
        mintPrice = _mintPrice;
    }
    
    // Allow creator to update payment recipient if needed
    function setPaymentRecipient(address _paymentRecipient) external {
        require(msg.sender == creator, "Only creator can update");
        require(_paymentRecipient != address(0), "Cannot set to zero address");
        paymentRecipient = _paymentRecipient;
    }
}