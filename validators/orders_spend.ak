use aiken/list
use aiken/transaction.{ScriptContext, Spend, Transaction}
use common/utils.{is_withdrawal_script_executed}
use hal_nft_mint/orders.{OrderDatum}
use hal_nft_mint/settings.{Settings, find_settings}

type OrderSpendRedeemer {
  Execute
  Cancel
}

validator {
  fn spend(
    datum: OrderDatum,
    redeemer: OrderSpendRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext(
      Transaction { reference_inputs, extra_signatories, withdrawals, .. },
      purpose,
    ) = ctx
    expect Spend(_) = purpose

    when redeemer is {
      Cancel -> {
        let is_owner_signed = list.has(extra_signatories, datum.owner_key_hash)
        expect is_owner_signed
        True
      }
      Execute -> {
        let Settings { mint_governor, .. } = find_settings(reference_inputs)
        is_withdrawal_script_executed(withdrawals, mint_governor)
      }
    }
  }
}
