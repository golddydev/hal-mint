use aiken/transaction.{InlineDatum, Output}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId, Value}
use hal_nft_mint/orders.{OrderDatum}

pub fn are_all_orders_minted(
  own_policy_id: PolicyId,
  hal_nft_price: Int,
  order_spend_script_address: Address,
  orders: List<(AssetName, Address)>,
  outputs: List<Output>,
  expected_mint_value: Value,
  continuation: fn(Value) -> result,
) -> result {
  when orders is {
    [] -> continuation(expected_mint_value)
    [(asset_name, destination_address), ..rest_orders] -> {
      // parse outputs
      expect [output, ..rest_outputs] = outputs

      let Output {
        address: output_address,
        datum: output_datum,
        value: output_value,
        reference_script: output_reference_script,
      } = output

      // output address must be order spend script address
      expect output_address == order_spend_script_address

      // check output datum is order datum
      // and asset name and price and destination address
      // are correctly set
      expect InlineDatum(output_datum) = output_datum
      expect order_datum: OrderDatum = output_datum
      let OrderDatum {
        asset_name: output_asset_name,
        price,
        destination_address: output_destination_address,
        ..
      } = order_datum
      expect output_asset_name == asset_name
      expect price == hal_nft_price
      expect output_destination_address == destination_address

      // check output value
      // has order nft and correct amount of lovelace (hal_nft_price)
      let has_order_nft =
        value.without_lovelace(output_value) == (
          value.zero()
            |> value.add(own_policy_id, asset_name, 1)
        )
      let has_enough_lovelace = value.lovelace_of(output_value) >= hal_nft_price
      expect has_order_nft
      expect has_enough_lovelace

      // check output reference script is none
      expect output_reference_script == None

      // update expected mint value
      let new_expected_mint_value =
        expected_mint_value |> value.add(own_policy_id, asset_name, 1)

      // continue with rest of orders
      are_all_orders_minted(
        own_policy_id,
        hal_nft_price,
        order_spend_script_address,
        rest_orders,
        rest_outputs,
        new_expected_mint_value,
        continuation,
      )
    }
  }
}
