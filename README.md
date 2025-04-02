# Generic Farcaster NFT Contract

A simple and customizable ERC721 NFT contract designed for Farcaster creators.

## Features

- Create customizable NFT collections with configurable name, symbol, and metadata
- Set custom mint price
- Designate payment recipient
- Update baseURI, mint price, and payment recipient as needed
- Simple minting process for users

## Contract Details

`GenericFarcasterNFT` is an ERC721 contract with the following features:
- The creator can set and update the base URI for token metadata
- Configurable mint price with ability to update
- Payments can be directed to a designated recipient
- Sequential token IDs starting from 0

## Usage

### Deployment

Deploy the contract with the following parameters:
- `initialBaseURI`: Base URI for NFT metadata
- `_name`: Name of the NFT collection
- `_symbol`: Symbol for the NFT collection
- `_mintPrice`: Price to mint each NFT (in wei)
- `_paymentRecipient`: Address to receive mint payments (defaults to creator if zero address)

### Minting

Users can mint NFTs by calling the `mint()` function and sending the exact mint price.

### Admin Functions

The contract creator can:
- Update the base URI with `setBaseURI()`
- Change the mint price with `setMintPrice()`
- Update the payment recipient with `setPaymentRecipient()`

## Development

This project uses [Foundry](https://github.com/foundry-rs/foundry) for development and testing.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Deploy

```shell
$ forge script script/GenericFarcasterNFT.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## License

MIT License - see LICENSE file for details