use aiken/cbor.{serialise}
use aiken/hash.{Blake2b_256, Hash}
use aiken/pairs
use aiken/transaction.{Datum, DatumHash, InlineDatum}
use aiken/transaction/credential.{Inline, ScriptCredential, StakeCredential}
use common/hashes.{ScriptHash}

pub fn is_withdrawal_script_executed(
  withdrawals: Pairs<StakeCredential, Int>,
  script_hash: ScriptHash,
) -> Bool {
  pairs.has_key(withdrawals, Inline(ScriptCredential(script_hash)))
}

pub fn get_datum_hash(datum: Datum) -> Hash<Blake2b_256, Data> {
  when datum is {
    DatumHash(hash) -> hash
    InlineDatum(data) -> hash.blake2b_256(serialise(data))
    _ -> fail @"no datum"
  }
}
