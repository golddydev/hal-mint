use aiken/list
use aiken/transaction.{ScriptContext, Spend, Transaction}
use aiken/transaction/value.{PolicyId}
use hal_nft_mint/orders.{OrderDatum}

type OrderSpendRedeemer {
  Execute
  Cancel
}

validator(hal_policy_id: PolicyId) {
  fn spend(
    datum: OrderDatum,
    redeemer: OrderSpendRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext(Transaction { extra_signatories, mint, .. }, purpose) =
      ctx
    expect Spend(_) = purpose

    when redeemer is {
      Execute -> {
        let is_hal_minted =
          list.has(
            mint |> value.from_minted_value |> value.policies,
            hal_policy_id,
          )
        expect is_hal_minted

        True
      }
      Cancel -> {
        let is_owner_signed = list.has(extra_signatories, datum.owner_key_hash)
        expect is_owner_signed

        True
      }
    }
  }
}
