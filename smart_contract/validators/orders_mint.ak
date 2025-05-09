use aiken/transaction.{Mint, ScriptContext}
use aiken/transaction/credential.{Address}
use validations/orders_mint/validation.{can_burn_orders, can_mint_orders}

type OrderMintRedeemer {
  MintOrders(List<Address>)
  BurnOrders
}

validator {
  fn mint(redeemer: OrderMintRedeemer, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect Mint(policy_id) = purpose

    when redeemer is {
      MintOrders(destination_addresses) ->
        can_mint_orders(destination_addresses, policy_id, transaction)
      BurnOrders -> can_burn_orders(policy_id, transaction)
    }
  }
}
