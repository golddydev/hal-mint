# Overview

> This is smart contract for Koralabs' HAL NFT

The smart contract enables users to mint HAL NFTs among pre-defined 10,000 NFTs.

> Project's Story

There are 10,000 pre-defined HAL NFTs.

When user requests mint, they will be given one asset name (which is not minted already).

But in the first transaction (when user request minting), users couldn't see anything about HAL NFT's datum.
(Because that is requesting order, not minting.)

Minting will be done by authorized batchers.

`Why is this necessary?`

Because, if users can see datum in minting transaction (when they sign transaction using wallet), it opens possibility for them to assess the datums and choose their favorite one.

And to prevent this, we just use empty datum in initial minting transaction, and immediately updates metadata to correct one.

## Use Cases

### Actors

- User: An entity who mints HAL NFT
- Koralab: An entity who runs this project. Assign HAL NFT to users when they request, prepare minting transaction.

### Tokens

- HAL NFTs: There are 10,000 pre-defined NFTs with its corresponding datum (also pre-defined)
- HAL settings NFT: This is NFT which holds current settings of HAL NFT minting engine. Possibly Koralab's handle
- HAL minting data NFT: This is NFT which holds current global state of HAL NFT minting (as [Merkle Patricia Trie](https://github.com/aiken-lang/merkle-patricia-forestry)) Possibly Koralab's handle

## Smart Contracts

In this project, we need 4 smart contracts.

- For Minting: `mint_proxy`, `mint_v1`, `minting_data`, `orders`

- For CIP68 Update: `cip68_spend`

### HAL NFT Mint Proxy

This is minting policy of HAL NFT. Just checking small thing (withdraw 0)

#### Parameters

- `version`: HAL NFT's version. This is needed when we want to change policy id without updating contract logic.

#### Datum

No Datum (minting policy)

#### Redeemer

Any Data

#### Validation

- Find `settings` asset from `reference_inputs`

- Get `mint_governor` from `settings_datum`

- Check `mint_governor` withdrawal script is executed.

- Check `version` is non-negative, and `version` in `settings` is correct.

### HAL NFT Mint V1

This is withdrawal script, `mint_proxy` contract checks for logic. Even this contract works like proxy because all minting logic is handled by `minting_data` spending validator (when we update MPT root hash)

#### Parameters

- minting_data_script_hash: This is ScriptHash of `minting_data_script`

#### Datum

No datum (this is withdrawal validator)

#### Redeemer

```rust
pub type HalMintRedeemer {
  MintNFTs
  BurnNFTs
}
```

#### Validations

- **MintNFTs**

  - Find `minting_data` asset in inputs which is holding global minting state (MPT root hash)

  - Check `minting_data` input's payment_credential is same as parameter's minting_data_script_hash from `SettingsV1`

- **BurnNFT**

  For now not supported

### Minting Data Spend Smart contract

This is spending validator which holds `minting_data` asset with global minting state as MPT.

And all minting engine's logic

#### Data Structure

We use [Merkle Patricia Trie](https://github.com/aiken-lang/merkle-patricia-forestry) to allow only pre-defined 10,000 NFTs can be minted or burnt. `MPT` is mainly key & value store.

`key`: Pre-defined 10,000 asset names (without asset name label)

`value`: Either `""` (empty string - initial value) or `hash of HAL NFT's datum`

#### Preparation

We need to prepare data structures (`MPT`)

Initial data structure of `MPT`

- `key`: 10,000 pre-defined asset name (without asset name label)

- `value`: Just empty string (`""` - meaning it is not minted yet)

#### Parameters

- `admin_verification_key_hash`: This is verification key hash of admin who has authority to update MPT without actually minting HAL NFT. (This is Koralab's Admin)

#### Datum

Any Data (Must most of time that is `MintingData`)

Only we set it as Data in case `minting_data` asset is accidentally sent to with invalid datum.

#### Redeemer

```rust
pub type MintingDataRedeemer {
  // mint hal nfts
  Mint(List<mpt.Proof>, Int)
  // update MPT root has
  UpdateMPT
}
```

#### Important NOTE

- Proofs in redeemer must be in same order as orders from transaction inputs

  Because transaction inputs are sorted by ledger (lexicographically), but outputs are sorted by transaction

#### Validations

- **Mint(List<mpt.Proof>, Int)**

  `proofs`: `List<mpt.Proof>` Merkle Trie's Proof of asset to mint (inclusion proof with old value)

  - Find `settings` asset and its input from reference inputs and parse `Settings` and `SettingsV1`

  - Get `allowed_minter` from `SettingsV1`

    And Check tx is signed by `allowed_minter`

  - Find `minting_data` input (which is spending input) and parse its datum (old MPT root hash) and make MPT (root) from root hash

  - Parse transaction outputs

    First output is `minting_data_output`, rest outputs are reference assets' outputs to `cip68_spending_validator` and user assets' outputs to `destination_address`

  - Check all orders are satisfied and calculate correctly update MPT root hash and expected mint value

    - Walk through transaction inputs and check all inputs from `order_script_hash` from `SettingsV1` and skip other inputs

    - Parse Order datum and get `asset_name` to mint, `destination_address` for user asset.

      And parse rest outputs for `reference asset output` and `user asset output` for current order. [Note](#important-note)

      Check reference output (address - `cip68_script_address`, value, no-ref-script) and user output (address - `destination_address`, value)

    - Get updated MPT root for `asset_name` (as key) and `#""` (as old value - since this is minting, old value must be empty bytearray) with `proof` (from Redeemer) to `datum_hash` (as new value)

      This `update_root` function checks inclusion of `asset_name` (as key) : `#""` (as value) using given `proof`

    - Get `expected_mint_value` (add reference asset and user asset)

    - Recursively call this function until we reach end of transaction inputs

  - Check `minting_data_output` with calculated `new_mpt_root`'s root hash

    And value stays same (without lovelace), no reference script

  - Check `expected_mint_value` is same as actual transaction `mint` value

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

  - Check only one input and output are there in `cip68_script_address`

  - Check presence of HAL `User NFT` in transaction inputs.

  - Check HAL `User NFT` stays unchanged in transaction outputs

  - Check HAL `Reference NFT` is sent to `CIP68 Spend` validator with updated datum

## White-listed

We will have white listed users who will have early access to HAL NFT minting.

1. OG Holders & Ultra rare holders

They have 2 hours early access

2. All handle holders

They have 1 hour early access
