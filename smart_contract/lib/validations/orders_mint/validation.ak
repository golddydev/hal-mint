use aiken/list
use aiken/transaction.{Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{PolicyId}
use hal_nft_mint/orders.{order_asset_name}
use hal_nft_mint/settings.{Settings, find_settings}
use hal_nft_mint/settings_v1.{SettingsV1}
use validations/orders_mint/utils.{are_all_orders_minted}

pub fn can_mint_orders(
  destination_addresses: List<Address>,
  own_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  let Transaction { outputs, reference_inputs, mint, .. } = transaction

  // find settings and parse
  let Settings { data: settings_data, .. } = find_settings(reference_inputs)
  expect settings_datum: SettingsV1 = settings_data
  let SettingsV1 {
    hal_nft_price,
    order_spend_script_address,
    order_mint_policy_id,
    ..
  } = settings_datum

  // check order mint policy id is correct
  expect order_mint_policy_id == own_policy_id

  let expected_mint_value <-
    are_all_orders_minted(
      own_policy_id,
      hal_nft_price,
      order_spend_script_address,
      destination_addresses,
      outputs,
      value.zero(),
    )

  // check mint value is correct
  expect value.from_minted_value(mint) == expected_mint_value

  True
}

pub fn can_burn_orders(
  transaction: Transaction,
  hal_policy_id: PolicyId,
) -> Bool {
  let Transaction { mint, .. } = transaction

  let is_hal_minted =
    list.has(mint |> value.from_minted_value |> value.policies, hal_policy_id)
  expect is_hal_minted

  True
}

pub fn can_cancel_order(policy_id: PolicyId, transaction: Transaction) -> Bool {
  let Transaction { mint, .. } = transaction

  let only_burn_one_order_token =
    value.from_minted_value(mint) == (
      value.zero()
        |> value.add(policy_id, order_asset_name, -1)
    )

  expect only_burn_one_order_token

  True
}
