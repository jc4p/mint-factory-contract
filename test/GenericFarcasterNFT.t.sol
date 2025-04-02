// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {GenericFarcasterNFT} from "../src/GenericFarcasterNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// Helper contract that rejects ETH transfers to test the ETH transfer failure scenario
contract RejectEther {
    // This fallback function will revert all incoming ETH transfers
    fallback() external payable {
        revert("I reject all ETH transfers");
    }

    receive() external payable {
        revert("I reject all ETH transfers");
    }
}

string constant BASE_URI = "https://fc-nfts.kasra.codes/tokens/";
string constant NFT_NAME = "Generic Farcaster NFT";
string constant NFT_SYMBOL = "GNFT";

contract GenericFarcasterNFTTest is Test {
    GenericFarcasterNFT public nft;
    address constant ALICE = address(0x1);
    address constant BOB = address(0x2);
    address constant CHARLIE = address(0x3);
    uint256 constant MINT_PRICE = 0.0025 ether;
    uint256 constant NEW_MINT_PRICE = 0.005 ether;
    uint256 constant ZERO_MINT_PRICE = 0;
    uint256 constant DEFAULT_MAX_SUPPLY = 0; // 0 means unlimited supply
    uint256 constant SMALL_MAX_SUPPLY = 3;

    // Add receive function to allow the test contract to receive ETH
    receive() external payable {}

    function setUp() public {
        nft = new GenericFarcasterNFT(BASE_URI, NFT_NAME, NFT_SYMBOL, MINT_PRICE, address(this), DEFAULT_MAX_SUPPLY);
    }

    function testInitialState() public view {
        assertEq(nft.currentTokenId(), 0);
        assertEq(nft.creator(), address(this));
        assertEq(nft.mintPrice(), MINT_PRICE);
        assertEq(nft.paymentRecipient(), address(this));
        assertEq(nft.baseURI(), BASE_URI);
        assertEq(nft.maxSupply(), 0); // 0 means unlimited supply
        assertEq(nft.maxMintsPerTx(), 1);
    }

    function testPublicMint() public {
        // Mint the first token as this contract (already initialized in setUp)
        uint256 firstTokenId = nft.mint{value: MINT_PRICE}();
        assertEq(firstTokenId, 0);
        assertEq(nft.ownerOf(0), address(this));
        assertEq(nft.tokenURI(0), string(abi.encodePacked(BASE_URI, "0")));
        assertEq(nft.currentTokenId(), 1);

        // Verify contract has no balance (all ETH sent to payment recipient)
        assertEq(address(nft).balance, 0);

        // Alice initializes and mints a token
        vm.startPrank(ALICE);
        vm.deal(ALICE, MINT_PRICE); // Give Alice some ETH to pay for mint
        uint256 aliceTokenId = nft.mint{value: MINT_PRICE}();
        vm.stopPrank();

        assertEq(aliceTokenId, 1);
        assertEq(nft.ownerOf(1), ALICE);
        assertEq(nft.tokenURI(1), string(abi.encodePacked(BASE_URI, "1")));
        assertEq(nft.currentTokenId(), 2);

        // Verify contract still has no balance (all ETH sent to payment recipient)
        assertEq(address(nft).balance, 0);

        // Bob initializes and mints a token
        vm.startPrank(BOB);
        vm.deal(BOB, MINT_PRICE); // Give Bob some ETH to pay for mint
        uint256 bobTokenId = nft.mint{value: MINT_PRICE}();
        vm.stopPrank();

        assertEq(bobTokenId, 2);
        assertEq(nft.ownerOf(2), BOB);
        assertEq(nft.tokenURI(2), string(abi.encodePacked(BASE_URI, "2")));
        assertEq(nft.currentTokenId(), 3);

        // Verify contract still has no balance (all ETH sent to payment recipient)
        assertEq(address(nft).balance, 0);
    }

    function testTokenURI() public {
        // Mint a token
        uint256 tokenId = nft.mint{value: MINT_PRICE}();

        // Check that the URI follows the expected pattern
        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(BASE_URI, toString(tokenId))));
    }

    function testMetadataInterface() public view {
        // Test name and symbol
        assertEq(nft.name(), NFT_NAME);
        assertEq(nft.symbol(), NFT_SYMBOL);

        // Test interface support
        assertTrue(nft.supportsInterface(type(IERC721).interfaceId), "Should support ERC721");
        assertTrue(nft.supportsInterface(type(IERC721Metadata).interfaceId), "Should support ERC721Metadata");
    }

    function testRevertWhenNonexistentTokenURI() public {
        // This should revert with the ERC721 nonexistent token error
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999));
        nft.tokenURI(999);
    }

    function testCreatorAddress() public view {
        assertEq(nft.creator(), address(this));
    }

    function testTransferToken() public {
        // Mint a token
        uint256 tokenId = nft.mint{value: MINT_PRICE}();

        // Transfer token from this contract to Alice
        nft.transferFrom(address(this), ALICE, tokenId);
        assertEq(nft.ownerOf(tokenId), ALICE);

        // Have Alice transfer to Bob
        vm.prank(ALICE);
        nft.transferFrom(ALICE, BOB, tokenId);
        assertEq(nft.ownerOf(tokenId), BOB);
    }

    function testApproveAndTransferToken() public {
        // Mint a token
        uint256 tokenId = nft.mint{value: MINT_PRICE}();

        // Approve Alice to transfer token
        nft.approve(ALICE, tokenId);

        // Have Alice transfer the token to herself
        vm.prank(ALICE);
        nft.transferFrom(address(this), ALICE, tokenId);
        assertEq(nft.ownerOf(tokenId), ALICE);
    }

    function testRevertWhenUnauthorizedTransfer() public {
        // Mint a token
        uint256 tokenId = nft.mint{value: MINT_PRICE}();

        // Try to transfer token without approval (should fail)
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSignature("ERC721InsufficientApproval(address,uint256)", ALICE, 0));
        nft.transferFrom(address(this), ALICE, tokenId);
    }

    function testRevertWhenMintWithoutETH() public {
        // Attempt to mint without sending ETH (should fail)
        vm.expectRevert("Must send exactly the mint price");
        nft.mint();
    }

    function testRevertWhenMintWithWrongETHAmount() public {
        // Attempt to mint with incorrect ETH amount (should fail)
        vm.expectRevert("Must send exactly the mint price");
        nft.mint{value: 0.001 ether}();
    }

    function testCurrentTokenId() public {
        // Check initial token ID
        assertEq(nft.currentTokenId(), 0);

        // Mint a new token and check increment
        nft.mint{value: MINT_PRICE}();
        assertEq(nft.currentTokenId(), 1);

        // Mint another token and check increment
        nft.mint{value: MINT_PRICE}();
        assertEq(nft.currentTokenId(), 2);
    }

    function testETHTransferToPaymentRecipient() public {
        uint256 initialBalance = address(this).balance;

        // Mint a token and verify no ETH is stored in the contract
        nft.mint{value: MINT_PRICE}();

        // Verify no ETH is stored in the contract
        assertEq(address(nft).balance, 0);

        // Verify payment was received by payment recipient
        // We need to account for gas costs which reduce the balance
        assertGe(address(this).balance, initialBalance);
        // Check that we received the MINT_PRICE
        assertEq(address(this).balance, initialBalance);
    }

    function testBatchMintETHTransfer() public {
        uint256 initialBalance = address(this).balance;

        // Mint 3 tokens in a row
        nft.mint{value: MINT_PRICE}();
        nft.mint{value: MINT_PRICE}();
        nft.mint{value: MINT_PRICE}();

        // Verify no ETH is stored in the contract
        assertEq(address(nft).balance, 0);

        // Verify all payments were received by payment recipient
        // We need to account for gas costs which reduce the balance
        assertGe(address(this).balance, initialBalance);
        // Check that we received the MINT_PRICE × 3
        assertEq(address(this).balance, initialBalance);
    }

    function testRevertWhenPaymentRecipientRejectsETH() public {
        // Deploy a RejectEther contract
        RejectEther rejector = new RejectEther();

        // Set the payment recipient to the rejector
        nft.setPaymentRecipient(address(rejector));

        // Now try to mint - this should fail because the payment recipient rejects ETH
        vm.expectRevert("Transfer failed");
        nft.mint{value: MINT_PRICE}();
    }

    function testUpdateMintPrice() public {
        // Verify initial mint price
        assertEq(nft.mintPrice(), MINT_PRICE);

        // Update the mint price
        nft.setMintPrice(NEW_MINT_PRICE);

        // Verify mint price was updated
        assertEq(nft.mintPrice(), NEW_MINT_PRICE);

        // Mint with new price should succeed
        uint256 tokenId = nft.mint{value: NEW_MINT_PRICE}();
        assertEq(tokenId, 0);

        // Mint with old price should fail
        vm.expectRevert("Must send exactly the mint price");
        nft.mint{value: MINT_PRICE}();
    }

    function testRevertWhenUnauthorizedMintPriceUpdate() public {
        // Try to update mint price as unauthorized user (should fail)
        vm.prank(ALICE);
        vm.expectRevert("Only creator or payment recipient can update");
        nft.setMintPrice(NEW_MINT_PRICE);
    }

    function testUpdatePaymentRecipient() public {
        // Verify initial payment recipient
        assertEq(nft.paymentRecipient(), address(this));

        // Update the payment recipient to Bob
        nft.setPaymentRecipient(BOB);

        // Verify payment recipient was updated
        assertEq(nft.paymentRecipient(), BOB);

        // Mint should send ETH to Bob now
        uint256 bobInitialBalance = BOB.balance;
        vm.deal(ALICE, MINT_PRICE);

        vm.prank(ALICE);
        nft.mint{value: MINT_PRICE}();

        // Verify bob received the ETH
        assertEq(BOB.balance, bobInitialBalance + MINT_PRICE);
    }

    function testRevertWhenUpdatePaymentRecipientToZeroAddress() public {
        // Try to update payment recipient to zero address (should fail)
        vm.expectRevert("Cannot set to zero address");
        nft.setPaymentRecipient(address(0));
    }

    function testRevertWhenUnauthorizedPaymentRecipientUpdate() public {
        // Try to update payment recipient as unauthorized user (should fail)
        vm.prank(ALICE);
        vm.expectRevert("Only creator or payment recipient can update");
        nft.setPaymentRecipient(BOB);
    }

    function testUpdateBaseURI() public {
        // Mint a token with original base URI
        uint256 tokenId = nft.mint{value: MINT_PRICE}();
        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(BASE_URI, "0")));

        // Update the base URI
        string memory newBaseURI = "https://new-uri.example.com/tokens/";
        nft.setBaseURI(newBaseURI);

        // Verify token URI now uses the new base URI
        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(newBaseURI, "0")));
    }

    function testRevertWhenUnauthorizedBaseURIUpdate() public {
        // Try to update base URI as unauthorized user (should fail)
        vm.prank(ALICE);
        vm.expectRevert("Only creator or payment recipient can update");
        nft.setBaseURI("https://evil.example.com/tokens/");
    }

    function testPaymentRecipientCanUpdateBaseURI() public {
        // First set payment recipient to BOB
        nft.setPaymentRecipient(BOB);

        // Mint a token with original base URI
        uint256 tokenId = nft.mint{value: MINT_PRICE}();
        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(BASE_URI, "0")));

        // Have BOB update the base URI
        string memory newBaseURI = "https://payment-recipient-uri.example.com/tokens/";
        vm.prank(BOB);
        nft.setBaseURI(newBaseURI);

        // Verify token URI now uses the new base URI
        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(newBaseURI, "0")));
    }

    function testPaymentRecipientCanUpdateMintPrice() public {
        // First set payment recipient to BOB
        nft.setPaymentRecipient(BOB);

        // Verify initial mint price
        assertEq(nft.mintPrice(), MINT_PRICE);

        // Have BOB update the mint price
        vm.prank(BOB);
        nft.setMintPrice(NEW_MINT_PRICE);

        // Verify mint price was updated
        assertEq(nft.mintPrice(), NEW_MINT_PRICE);

        // Mint with new price should succeed
        uint256 tokenId = nft.mint{value: NEW_MINT_PRICE}();
        assertEq(tokenId, 0);
    }

    function testPaymentRecipientCanUpdatePaymentRecipient() public {
        // First set payment recipient to BOB
        nft.setPaymentRecipient(BOB);

        // Have BOB update the payment recipient to CHARLIE
        vm.prank(BOB);
        nft.setPaymentRecipient(CHARLIE);

        // Verify payment recipient was updated
        assertEq(nft.paymentRecipient(), CHARLIE);

        // Mint should send ETH to CHARLIE now
        uint256 charlieInitialBalance = CHARLIE.balance;
        vm.deal(ALICE, MINT_PRICE);

        vm.prank(ALICE);
        nft.mint{value: MINT_PRICE}();

        // Verify CHARLIE received the ETH
        assertEq(CHARLIE.balance, charlieInitialBalance + MINT_PRICE);
    }

    function testCustomPaymentRecipientInConstructor() public {
        // Deploy a new NFT with custom payment recipient
        GenericFarcasterNFT customNft =
            new GenericFarcasterNFT(BASE_URI, NFT_NAME, NFT_SYMBOL, MINT_PRICE, CHARLIE, 10000);

        // Verify payment recipient is set to Charlie
        assertEq(customNft.paymentRecipient(), CHARLIE);

        // Mint a token and verify ETH goes to Charlie
        uint256 charlieInitialBalance = CHARLIE.balance;
        customNft.mint{value: MINT_PRICE}();

        // Verify Charlie received the ETH
        assertEq(CHARLIE.balance, charlieInitialBalance + MINT_PRICE);
    }

    function testDefaultPaymentRecipientInConstructor() public {
        // Deploy a new NFT with zero address as payment recipient (should default to creator)
        GenericFarcasterNFT defaultNft =
            new GenericFarcasterNFT(BASE_URI, NFT_NAME, NFT_SYMBOL, MINT_PRICE, address(0), 10000);

        // Verify payment recipient is set to creator (this contract)
        assertEq(defaultNft.paymentRecipient(), address(this));
    }

    function testZeroMintPrice() public {
        // Deploy a new NFT with zero mint price
        GenericFarcasterNFT zeroNft =
            new GenericFarcasterNFT(BASE_URI, NFT_NAME, NFT_SYMBOL, ZERO_MINT_PRICE, address(this), 10000);

        // Verify mint price is set to zero
        assertEq(zeroNft.mintPrice(), ZERO_MINT_PRICE);

        // Mint a token with zero price
        uint256 initialBalance = address(this).balance;
        uint256 tokenId = zeroNft.mint{value: ZERO_MINT_PRICE}();

        // Verify token was minted successfully
        assertEq(tokenId, 0);
        assertEq(zeroNft.ownerOf(0), address(this));

        // Verify no ETH was transferred
        assertEq(address(this).balance, initialBalance);
    }

    function testMaxSupplyLimit() public {
        // Deploy a new NFT with a small max supply limit
        GenericFarcasterNFT limitedNft =
            new GenericFarcasterNFT(BASE_URI, NFT_NAME, NFT_SYMBOL, MINT_PRICE, address(this), SMALL_MAX_SUPPLY);

        // Verify max supply is set correctly
        assertEq(limitedNft.maxSupply(), SMALL_MAX_SUPPLY);

        // Check mintingAvailable initially
        (bool canMint, uint256 remaining) = limitedNft.mintingAvailable();
        assertTrue(canMint);
        assertEq(remaining, SMALL_MAX_SUPPLY);

        // Check totalSupply initially
        assertEq(limitedNft.totalSupply(), 0);

        // Mint tokens up to the max supply
        for (uint256 i = 0; i < SMALL_MAX_SUPPLY; i++) {
            uint256 tokenId = limitedNft.mint{value: MINT_PRICE}();
            assertEq(tokenId, i);

            // Check totalSupply after each mint
            assertEq(limitedNft.totalSupply(), i + 1);

            // Check mintingAvailable after each mint
            (bool canMintAfter, uint256 remainingAfter) = limitedNft.mintingAvailable();

            if (i < SMALL_MAX_SUPPLY - 1) {
                // Should still be able to mint
                assertTrue(canMintAfter);
                assertEq(remainingAfter, SMALL_MAX_SUPPLY - (i + 1));
            } else {
                // On the last iteration, should not be able to mint anymore
                assertFalse(canMintAfter);
                assertEq(remainingAfter, 0);
            }
        }

        // The next mint should fail due to max supply
        vm.expectRevert("Would exceed max supply");
        limitedNft.mint{value: MINT_PRICE}();
    }

    function testMintingAvailable() public {
        // Initialize with unlimited supply (0)
        (bool canMint, uint256 remaining) = nft.mintingAvailable();
        assertTrue(canMint);
        assertEq(remaining, type(uint256).max); // Virtually unlimited

        // Mint one token
        nft.mint{value: MINT_PRICE}();

        // Check mintingAvailable after minting
        (bool canMintAfter, uint256 remainingAfter) = nft.mintingAvailable();
        assertTrue(canMintAfter);
        assertEq(remainingAfter, type(uint256).max - 1); // Still virtually unlimited
    }

    function testTotalSupply() public {
        // Initialize with total supply of 0
        assertEq(nft.totalSupply(), 0);

        // Mint 3 tokens
        nft.mint{value: MINT_PRICE}();
        assertEq(nft.totalSupply(), 1);

        nft.mint{value: MINT_PRICE}();
        assertEq(nft.totalSupply(), 2);

        nft.mint{value: MINT_PRICE}();
        assertEq(nft.totalSupply(), 3);
    }

    function testUnlimitedSupply() public {
        // Deploy a new NFT with unlimited supply (0)
        GenericFarcasterNFT unlimitedNft =
            new GenericFarcasterNFT(BASE_URI, NFT_NAME, NFT_SYMBOL, MINT_PRICE, address(this), 0);

        // Verify max supply is set correctly
        assertEq(unlimitedNft.maxSupply(), 0);

        // Check mintingAvailable
        (bool canMint, uint256 remaining) = unlimitedNft.mintingAvailable();
        assertTrue(canMint);
        // Should be virtually unlimited (maxUint - currentTokenId which is 0)
        assertEq(remaining, type(uint256).max);

        // Mint a few tokens
        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = unlimitedNft.mint{value: MINT_PRICE}();
            assertEq(tokenId, i);
        }

        // Check mintingAvailable again
        (bool canMintAfter, uint256 remainingAfter) = unlimitedNft.mintingAvailable();
        assertTrue(canMintAfter);
        // Should still be virtually unlimited
        assertEq(remainingAfter, type(uint256).max - 10);
    }

    // Helper function to convert uint256 to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
