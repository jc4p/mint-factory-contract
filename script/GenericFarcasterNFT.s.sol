// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {GenericFarcasterNFT} from "../src/GenericFarcasterNFT.sol";
import {console2} from "forge-std/console2.sol";

contract DeployGenericFarcasterNFT is Script {
    // Default values if not overridden
    string constant DEFAULT_BASE_URI = "https://fc-nfts.kasra.codes/tokens/";
    string constant DEFAULT_NFT_NAME = "Generic Farcaster NFT";
    string constant DEFAULT_NFT_SYMBOL = "GNFT";
    uint256 constant DEFAULT_MINT_PRICE = 0.0025 ether;
    uint256 constant DEFAULT_MAX_SUPPLY = 0; // 0 means unlimited supply

    function run() public returns (GenericFarcasterNFT) {
        // Get values from environment variables or use defaults
        string memory baseURI = vm.envOr("BASE_URI", DEFAULT_BASE_URI);
        string memory name = vm.envOr("NFT_NAME", DEFAULT_NFT_NAME);
        string memory symbol = vm.envOr("NFT_SYMBOL", DEFAULT_NFT_SYMBOL);
        uint256 mintPrice = vm.envOr("MINT_PRICE", DEFAULT_MINT_PRICE);
        address paymentRecipient = vm.envOr("PAYMENT_RECIPIENT", msg.sender);
        uint256 maxSupply = vm.envOr("MAX_SUPPLY", DEFAULT_MAX_SUPPLY);

        // Start broadcast to record and replay contract deployment
        vm.startBroadcast();

        // Deploy the NFT contract
        GenericFarcasterNFT nft = new GenericFarcasterNFT(baseURI, name, symbol, mintPrice, paymentRecipient, maxSupply);

        vm.stopBroadcast();

        // Log deployment info
        console2.log("Deployed GenericFarcasterNFT at:", address(nft));
        console2.log("NFT Name:", name);
        console2.log("NFT Symbol:", symbol);
        console2.log("Base URI:", baseURI);
        console2.log("Mint Price:", mintPrice);
        console2.log("Payment Recipient:", paymentRecipient);
        console2.log("Max Supply:", maxSupply);

        return nft;
    }
}
