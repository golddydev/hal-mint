use aiken/list
use aiken/transaction.{Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId, Value}
use hal_nft_mint/settings.{Settings, find_settings}
use hal_nft_mint/settings_v1.{SettingsV1}
use validations/orders_mint/utils.{are_all_orders_minted}

pub fn can_mint_orders(
  orders: List<(AssetName, Address)>,
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
      orders,
      outputs,
      value.zero(),
    )

  // check mint value is correct
  expect value.from_minted_value(mint) == expected_mint_value

  True
}

pub fn can_burn_orders(
  asset_names: List<AssetName>,
  policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  let Transaction { mint, .. } = transaction

  let expected_mint_value =
    list.foldl(
      asset_names,
      value.zero(),
      fn(asset_name, acc) -> Value {
        acc |> value.add(policy_id, asset_name, -1)
      },
    )

  value.from_minted_value(mint) == expected_mint_value
}
