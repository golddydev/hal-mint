use aiken/cbor.{serialise}
use aiken/hash.{Blake2b_256, Hash}
use aiken/list
use aiken/pairs
use aiken/transaction.{
  Datum, DatumHash, InlineDatum, Input, Output, OutputReference, find_input,
}
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, StakeCredential,
}
use common/hashes.{ScriptHash}

pub fn is_withdrawal_script_executed(
  withdrawals: Pairs<StakeCredential, Int>,
  script_hash: ScriptHash,
) -> Bool {
  pairs.has_key(withdrawals, Inline(ScriptCredential(script_hash)))
}

pub fn get_spending_script_hash(
  inputs: List<Input>,
  spending_output_reference: OutputReference,
) -> ScriptHash {
  expect Some(spending_input) = find_input(inputs, spending_output_reference)
  let Input {
    output: Output { address: Address { payment_credential, .. }, .. },
    ..
  } = spending_input
  expect ScriptCredential(spending_script_hash) = payment_credential

  spending_script_hash
}

pub fn get_own_utxos_count(
  inputs: List<Input>,
  spending_output_reference: OutputReference,
) -> Int {
  let spending_script_hash =
    get_spending_script_hash(inputs, spending_output_reference)
  let own_utxo_count =
    inputs
      |> list.count(
          fn(input: Input) -> Bool {
            let Input {
              output: Output { address: Address { payment_credential, .. }, .. },
              ..
            } = input
            when payment_credential is {
              ScriptCredential(script_hash) ->
                script_hash == spending_script_hash
              _ -> False
            }
          },
        )
  own_utxo_count
}

pub fn get_datum_hash(datum: Datum) -> Hash<Blake2b_256, Data> {
  when datum is {
    DatumHash(hash) -> hash
    InlineDatum(data) -> hash.blake2b_256(serialise(data))
    _ -> fail @"no datum"
  }
}
