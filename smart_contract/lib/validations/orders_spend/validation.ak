use aiken/list
use aiken/transaction.{OutputReference, Transaction}
use aiken/transaction/value.{PolicyId}
use common/utils.{get_own_utxos_count}
use hal_nft_mint/orders.{OrderDatum, order_asset_name}

// Check if HAL NFT is minted
// if any HAL NFT is minted, then UTxO can be spent
//
pub fn can_execute_orders(
  transaction: Transaction,
  hal_policy_id: PolicyId,
) -> Bool {
  let Transaction { mint, .. } = transaction
  let is_hal_minted =
    list.has(mint |> value.from_minted_value |> value.policies, hal_policy_id)
  expect is_hal_minted

  True
}

// Check if transaction is signed by owner of Order
// Check there is only one UTxO from this script
// Check one Order NFT is burnt
//
pub fn can_cancel_order(
  transaction: Transaction,
  datum: OrderDatum,
  spending_output_reference: OutputReference,
  orders_mint_policy_id: PolicyId,
) -> Bool {
  let Transaction { inputs, extra_signatories, mint, .. } = transaction

  // check if transaction is signed by owner of Order
  let is_owner_signed = list.has(extra_signatories, datum.owner_key_hash)
  expect is_owner_signed

  // check there is only one UTxO from this script
  let own_utxo_count = get_own_utxos_count(inputs, spending_output_reference)
  expect own_utxo_count == 1

  let expected_mint_value =
    value.zero()
      |> value.add(orders_mint_policy_id, order_asset_name, -1)
  let is_order_burnt = value.from_minted_value(mint) == expected_mint_value
  expect is_order_burnt

  True
}
