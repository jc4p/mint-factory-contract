// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {FarcasterNFT} from "../src/GenericFarcasterNFT.sol";
import {console2} from "forge-std/console2.sol";

contract DeployFarcasterNFT is Script {
    // Default values if not overridden
    string constant DEFAULT_BASE_URI = "https://styled-nfts.kasra.codes/tokens/";
    string constant DEFAULT_NFT_NAME = "Generic Farcaster NFT";
    string constant DEFAULT_NFT_SYMBOL = "GNFT";
    uint256 constant DEFAULT_MINT_PRICE = 0.0025 ether;

    function run() public returns (FarcasterNFT) {
        // Get values from environment variables or use defaults
        string memory baseURI = vm.envOr("BASE_URI", DEFAULT_BASE_URI);
        string memory name = vm.envOr("NFT_NAME", DEFAULT_NFT_NAME);
        string memory symbol = vm.envOr("NFT_SYMBOL", DEFAULT_NFT_SYMBOL);
        uint256 mintPrice = vm.envOr("MINT_PRICE", DEFAULT_MINT_PRICE);
        address paymentRecipient = vm.envOr("PAYMENT_RECIPIENT", msg.sender);

        // Start broadcast to record and replay contract deployment
        vm.startBroadcast();

        // Deploy the NFT contract
        FarcasterNFT nft = new FarcasterNFT(
            baseURI, 
            name, 
            symbol, 
            mintPrice, 
            paymentRecipient
        );

        vm.stopBroadcast();

        // Log deployment info
        console2.log("Deployed FarcasterNFT at:", address(nft));
        console2.log("NFT Name:", name);
        console2.log("NFT Symbol:", symbol);
        console2.log("Base URI:", baseURI);
        console2.log("Mint Price:", mintPrice);
        console2.log("Payment Recipient:", paymentRecipient);

        return nft;
    }
}
