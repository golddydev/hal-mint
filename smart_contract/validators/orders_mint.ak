use aiken/transaction.{Mint, ScriptContext}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName}
use validations/orders_mint/validation.{can_burn_orders, can_mint_orders}

type OrderMintRedeemer {
  MintOrders(List<(AssetName, Address)>)
  BurnOrders(List<AssetName>)
}

validator {
  fn mint(redeemer: OrderMintRedeemer, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect Mint(policy_id) = purpose

    when redeemer is {
      MintOrders(orders) -> can_mint_orders(orders, policy_id, transaction)
      BurnOrders(asset_names) ->
        can_burn_orders(asset_names, policy_id, transaction)
    }
  }
}
