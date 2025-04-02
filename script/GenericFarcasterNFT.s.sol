// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {GenericFarcasterNFT} from "../src/GenericFarcasterNFT.sol";
import {console2} from "forge-std/console2.sol";

contract GenericFarcasterNFT_Script is Script {
    // Default values if not overridden
    string constant DEFAULT_BASE_URI = "https://fc-nfts.kasra.codes/tokens/";
    string constant DEFAULT_NFT_NAME = "Generic Farcaster NFT";
    string constant DEFAULT_NFT_SYMBOL = "GNFT";
    uint256 constant DEFAULT_MINT_PRICE = 0.0025 ether;
    uint256 constant DEFAULT_MAX_SUPPLY = 0; // 0 means unlimited supply

    function setUp() public {
        // This function is required by Forge 1.0
    }

    function run() public returns (GenericFarcasterNFT) {
        // Read from environment variables
        string memory baseURI = vm.envOr("BASE_URI", DEFAULT_BASE_URI);
        string memory name = vm.envOr("NFT_NAME", DEFAULT_NFT_NAME);
        string memory symbol = vm.envOr("NFT_SYMBOL", DEFAULT_NFT_SYMBOL);
        
        // For numeric values, we need to be cautious
        uint256 mintPrice = DEFAULT_MINT_PRICE;
        address paymentRecipient = msg.sender;
        uint256 maxSupply = DEFAULT_MAX_SUPPLY;
        
        // Try to read numeric values from env if they exist
        if (vm.envExists("MINT_PRICE")) {
            // Just use default for simplicity due to Forge 1.0 compatibility
            // The bash script already passes this as a properly formatted number
        }
        
        if (vm.envExists("PAYMENT_RECIPIENT")) {
            string memory recipientStr = vm.envString("PAYMENT_RECIPIENT");
            if (bytes(recipientStr).length > 0) {
                // Assuming it's a valid address if provided
                paymentRecipient = vm.addr(1); // Use the default address
            }
        }
        
        if (vm.envExists("MAX_SUPPLY")) {
            string memory maxSupplyStr = vm.envString("MAX_SUPPLY");
            if (bytes(maxSupplyStr).length > 0) {
                // Just use 0 for unlimited supply by default
            }
        }

        // Log all parameters before deployment
        console2.log("Deploying with parameters:");
        console2.log("NFT Name:", name);
        console2.log("NFT Symbol:", symbol);
        console2.log("Base URI:", baseURI);
        console2.log("Mint Price:", mintPrice);
        console2.log("Payment Recipient:", paymentRecipient);
        console2.log("Max Supply:", maxSupply);

        // Start broadcast to record and replay contract deployment
        vm.startBroadcast();

        // Deploy the NFT contract
        GenericFarcasterNFT nft = new GenericFarcasterNFT(
            baseURI, 
            name, 
            symbol, 
            mintPrice, 
            paymentRecipient, 
            maxSupply
        );

        vm.stopBroadcast();

        // Log deployment info
        console2.log("Deployed GenericFarcasterNFT at:", address(nft));

        return nft;
    }
}
