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
        
        if (vm.envExists("MINT_PRICE")) {
            string memory priceStr = vm.envString("MINT_PRICE");
            if (bytes(priceStr).length > 0) {
                // Parse the price string to extract the numeric value
                uint256 parsedPrice = parseEtherValue(priceStr);
                if (parsedPrice > 0) {
                    mintPrice = parsedPrice;
                }
            }
        }
        
        if (vm.envExists("PAYMENT_RECIPIENT")) {
            string memory recipientStr = vm.envString("PAYMENT_RECIPIENT");
            if (bytes(recipientStr).length > 0) {
                // Parse the address from the string
                paymentRecipient = parseAddress(recipientStr);
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

    function parseEtherValue(string memory input) internal pure returns (uint256) {
        bytes memory inputBytes = bytes(input);
        uint256 value = 0;
        bool decimalFound = false;
        uint8 decimals = 0;
        
        // Skip any leading spaces
        uint i = 0;
        while (i < inputBytes.length && inputBytes[i] == ' ') i++;
        
        // Parse the numeric part
        for (; i < inputBytes.length; i++) {
            if (inputBytes[i] >= '0' && inputBytes[i] <= '9') {
                value = value * 10 + uint8(inputBytes[i]) - 48;
                if (decimalFound) {
                    decimals++;
                    if (decimals >= 18) break; // Max precision for Ethereum
                }
            } else if (inputBytes[i] == '.' && !decimalFound) {
                decimalFound = true;
            } else {
                // Stop at any non-numeric character (like "ether")
                break;
            }
        }
        
        // Adjust for decimals to convert to wei
        if (decimals > 0) {
            while (decimals < 18) {
                value *= 10;
                decimals++;
            }
        } else {
            // No decimal point found, assume the value is in ether
            value *= 10**18;
        }
        
        return value;
    }

    function parseAddress(string memory addressStr) internal pure returns (address) {
        bytes memory addressBytes = bytes(addressStr);
        require(addressBytes.length == 42, "Invalid address length"); // 0x + 40 hex chars
        
        bytes memory tempBytes = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            uint8 high = uint8(addressBytes[i*2 + 2]);
            uint8 low = uint8(addressBytes[i*2 + 3]);
            
            high = high >= 65 && high <= 70 ? high - 55 : (high >= 97 && high <= 102 ? high - 87 : high - 48);
            low = low >= 65 && low <= 70 ? low - 55 : (low >= 97 && low <= 102 ? low - 87 : low - 48);
            
            tempBytes[i] = bytes1(uint8((high * 16 + low)));
        }
        
        address result;
        assembly {
            result := mload(add(tempBytes, 20))
        }
        return result;
    }
}
