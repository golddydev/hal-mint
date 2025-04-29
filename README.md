# Overview

> This is smart contract for Koralabs' HAL NFT

The smart contract enables users to mint HAL NFTs among pre-defined 10,000 NFTs.

> Project's Story

There are 10,000 pre-defined HAL NFTs.

When user requests mint, they will be given one asset name (which is not minted already).

But in the minting transaction, users couldn't see anything about HAL NFT's datum (because we use empty datum in the initial mint)

`Why is this necessary?`

Because, if users can see datum in minting transaction (when they sign transaction using wallet), it opens possibility for them to assess the datums and choose their favorite one.

And to prevent this, we just use empty datum in initial minting transaction, and immediately updates metadata to correct one.

## Use Cases

### Actors

- User: An entity who mints HAL NFT
- Koralab: An entity who runs this project. Assign HAL NFT to users when they request, prepare minting transaction, update initial empty datum to correct one.

### Tokens

- HAL NFTs: There are 10,000 pre-defined NFTs with its corresponding datum (also pre-defined)

- HAL settings NFT: This is NFT which holds current setting of HAL NFT minting. Possibly Koralab's handle
- HAL data NFT: This is NFT which holds current global state of HAL NFT minting (as [Merkle Patricia Trie](https://github.com/aiken-lang/merkle-patricia-forestry)) Possibly Koralab's handle

## Smart Contracts

In this project, we need 2 smart contracts, one is for minting, other is for handling CIP68 datum.

### HAL NFT Mint Proxy

This is minting policy of HAL NFT.

#### Parameters

No Parameter

#### Datum

No Datum (minting policy)

#### Redeemer

Any Data

#### Validation

- Find `settings` asset from `reference_inputs`

- Get `mint_governor` from `settings_datum`

- Check `mint_governor` withdrawal script is executed.

### HAL NFT Mint V1

This is withdrawal script which holds all of `HAL NFT Mint` logic.

#### Parameters

No Parameters

#### Datum

No datum (this is withdrawal validator)

#### Redeemer

```rust
pub type HalMintRedeemer {
  MintNFT
  BurnNFT
}
```

#### Validations

- **MintNFT**

  - Gather Order UTxOs from `Order Script`

    Order script hash is from `Settings`

  - Parse Orders and get ordered asset name

    Check each Order datum is valid

  - Check each asset name is in `MPT`

  - Check each asset name's value in `MPT` is `""` (empty string)

  - Corresponding assets are minted (both reference and user tokens)

  - Check all reference tokens are sent to `CIP68 Spend` validator

  - Check each user token is sent to correct `destination address` (from Order datum)

- **BurnNFT**

  For now not supported

### Minting Data Spend Smart contract

This is spending validator which holds `minting_data` asset.

And handle logic of updating `MPT`

#### Data Structure

The data structures we use in [HAL NFT Mint V1](#hal-nft-mint-v1)

We use [Merkle Patricia Trie](https://github.com/aiken-lang/merkle-patricia-forestry) to allow only pre-defined 10,000 NFTs can be minted or burnt. `MPT` is mainly key & value store.

`key`: Pre-defined 10,000 asset names (without asset name label)

`value`: Either `""` (empty string - initial value) or `hash of HAL NFT's datum`

#### Preparation

We need to prepare data structures (`MPT`)

Initial data structure of `MPT`

- `key`: 10,000 pre-defined asset name (without asset name label)

- `value`: Just empty string (`""` - meaning it is not minted yet)

### CIP68 Spend Smart Contract

This is spending validator which handles all CIP68 spend logic.

#### Parameters

No Parameters

#### Datum

CIP68 Datum

```rust
pub type CIP68Datum {
  nft: Pairs<Data, Data>,
  version: Int,
  extra: Data,
}
```

#### Redeemer

```rust
pub type CIP68Redeemer {
  Update
}
```

#### Validations

- **Update**

  - Check only one input and output are there in `cip68_spend_script_address`

  - Check presence of HAL `User NFT` in transaction inputs.

  - Check HAL `User NFT` stays unchanged in transaction outputs

  - Check HAL `Reference NFT` is sent to `CIP68 Spend` validator with updated datum
