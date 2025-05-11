use aiken/transaction.{ScriptContext, Spend}
use aiken/transaction/value.{PolicyId}
use hal_nft_mint/orders.{OrderDatum}
use validations/orders_spend/validation.{can_cancel, can_execute}

type OrderSpendRedeemer {
  Execute
  Cancel
}

// This is Spending validator
// Where Order Tx Input is sent
// with Order NFT (orders_mint)
//
// ===== Parameters =====
// `hal_policy_id`: Policy id of HAL NFT
// `order_mint_policy_id`: Policy id of Order NFT
//
validator(hal_policy_id: PolicyId, order_mint_policy_id: PolicyId) {
  fn spend(
    datum: OrderDatum,
    redeemer: OrderSpendRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext(transaction, purpose) = ctx
    expect Spend(spending_output_reference) = purpose

    when redeemer is {
      Execute -> can_execute(transaction, hal_policy_id)
      Cancel ->
        can_cancel(
          transaction,
          datum,
          spending_output_reference,
          order_mint_policy_id,
        )
    }
  }
}
