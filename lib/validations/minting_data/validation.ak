use aiken/list
use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use aiken/transaction/value
use common/hashes.{VerificationKeyHash}
use hal_nft_mint/minting_data.{MintingData, resolve_minting_data}
use hal_nft_mint/settings.{Settings, find_settings}
use hal_nft_mint/settings_v1.{SettingsV1}
use validations/minting_data/utils.{all_orders_are_satisfied}

// Validation:
// All Decentralized Minting logic is here
//
// Checks
// - signed by allowed_minter
// - all orders are satisfied correctly
// and minted values are sent to correct addresses
// - Proofs are valid (NOTE: must be in same order as orders UTxOs)
//
pub fn can_mint(
  transaction: Transaction,
  spending_output_reference: OutputReference,
  proofs: List<mpt.Proof>,
  minter_index: Int,
) -> Bool {
  trace @"can_mint"
  let Transaction {
    inputs,
    reference_inputs,
    outputs,
    extra_signatories,
    mint,
    ..
  } = transaction

  // find settings and parse
  let Settings { data: settings_data, .. } = find_settings(reference_inputs)
  expect settings_datum: SettingsV1 = settings_data
  let SettingsV1 {
    policy_id,
    allowed_minters,
    cip68_script_address,
    order_script_hash,
    ..
  } = settings_datum

  // get allowed minter
  expect Some(allowed_minter) = allowed_minters |> list.at(minter_index)

  // check if allowed_minter sign tx
  expect list.has(extra_signatories, allowed_minter)

  // find minting data input which is own input
  expect Some(spending_input) = find_input(inputs, spending_output_reference)
  let Input { output: minting_data_input, .. } = spending_input
  let MintingData { mpt_root_hash } = resolve_minting_data(minting_data_input)

  // parse outputs
  expect [minting_data_output, ..rest_outputs] = outputs

  // expect proofs are not empty
  expect list.length(proofs) > 0

  // build merkle patricia trie from old root hash
  let root = mpt.from_root(mpt_root_hash)

  // check orders with proofs
  let
    new_root,
    expected_mint_value,
  <-
    all_orders_are_satisfied(
      order_script_hash,
      inputs,
      rest_outputs,
      policy_id,
      cip68_script_address,
      proofs,
      root,
      value.zero(),
    )

  // calculate new root and expected mint value
  let new_mpt_root_hash = new_root |> mpt.root

  // check minting data output
  expect minting_data_output.address == minting_data_input.address
  expect
    value.without_lovelace(minting_data_output.value) == value.without_lovelace(
      minting_data_input.value,
    )
  expect
    minting_data_output.datum == InlineDatum(
      MintingData { mpt_root_hash: new_mpt_root_hash },
    )
  expect minting_data_output.reference_script == None

  // check minted handles
  expect
    value.merge(
      value.from_minted_value(mint),
      value.negate(expected_mint_value),
    ) == value.zero()

  True
}

pub fn can_update_mpt(
  transaction: Transaction,
  admin_verification_key_hash: VerificationKeyHash,
) -> Bool {
  let Transaction { extra_signatories, mint, .. } = transaction

  // must not mint anything
  expect value.from_minted_value(mint) == value.zero()

  // must be signed by god
  expect list.has(extra_signatories, admin_verification_key_hash)

  True
}
