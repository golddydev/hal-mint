use aiken/bytearray
use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{Address, ScriptCredential}
use aiken/transaction/value.{PolicyId, Value}
use common/cip68.{prefix_100, prefix_222}
use common/hashes.{DatumHash, ScriptHash}
use common/utils.{get_datum_hash}
use hal_nft_mint/orders.{OrderDatum}

// This function checks only new handles orders are satisfied
pub fn all_orders_are_satisfied(
  order_script_hash: ScriptHash,
  inputs: List<Input>,
  outputs: List<Output>,
  policy_id: PolicyId,
  hal_nft_price: Int,
  cip68_script_address: Address,
  proofs: List<mpt.Proof>,
  root: mpt.MerklePatriciaForestry,
  expected_mint_value: Value,
  continuation: fn(mpt.MerklePatriciaForestry, Value) -> result,
) -> result {
  // go through inputs and process order UTxO
  when inputs is {
    [] -> continuation(root, expected_mint_value)
    [order_input, ..rest_inputs] -> {
      let Output { address, datum, value: order_input_value, .. } =
        order_input.output
      let is_order = is_order_script_address(address, order_script_hash)
      when is_order is {
        True -> {
          // parse order datum
          expect InlineDatum(order_inline_datum) = datum
          expect order_datum: OrderDatum = order_inline_datum
          let OrderDatum { asset_name, destination_address, .. } = order_datum

          // check order hash enough lovelace for hal_nft_price
          let does_order_have_enough_lovelace =
            value.lovelace_of(order_input_value) >= hal_nft_price
          expect does_order_have_enough_lovelace

          // parse proofs
          expect [mpt_proof, ..rest_proofs] = proofs

          // extract ref & user output
          // check minted assets are correctly sent to correct address
          // and new_mint_value and ref output's datum hash (to update mpt)
          expect [ref_output, user_output, ..rest_outputs] = outputs
          let (new_mint_value, ref_output_datum_hash) =
            check_ref_and_user_outputs(
              ref_output,
              user_output,
              policy_id,
              asset_name,
              cip68_script_address,
              destination_address,
              expected_mint_value,
            )

          // update root
          // this function also checks asset name is in trie
          // with old value (empty bytearray)
          let new_root =
            update_root(root, asset_name, mpt_proof, ref_output_datum_hash)

          all_orders_are_satisfied(
            order_script_hash,
            rest_inputs,
            rest_outputs,
            policy_id,
            hal_nft_price,
            cip68_script_address,
            rest_proofs,
            new_root,
            new_mint_value,
            continuation,
          )
        }

        False ->
          all_orders_are_satisfied(
            order_script_hash,
            rest_inputs,
            outputs,
            policy_id,
            hal_nft_price,
            cip68_script_address,
            proofs,
            root,
            expected_mint_value,
            continuation,
          )
      }
    }
  }
}

fn is_order_script_address(
  address: Address,
  order_script_hash: ScriptHash,
) -> Bool {
  when address.payment_credential is {
    ScriptCredential(sc) -> sc == order_script_hash
    _ -> False
  }
}

// This function checks if asset name is valid or not
// check asset_name is in merkle tree 
// with empty value
//
pub fn is_asset_name_valid(
  asset_name: ByteArray,
  root: mpt.MerklePatriciaForestry,
  proof: mpt.Proof,
) -> Bool {
  root |> mpt.has(asset_name, #"", proof)
}

// This function checks ref and user outputs
// and returns new mint value
// and returns asset's datum's hash
// we expect datum not to be NoDatum
//
fn check_ref_and_user_outputs(
  ref_output: Output,
  user_output: Output,
  policy_id: PolicyId,
  asset_name: ByteArray,
  cip68_script_address: Address,
  destination_address: Address,
  mint_value: Value,
) -> (Value, DatumHash) {
  // make ref asset name and user asset name from asset_name
  let ref_asset_name = bytearray.concat(prefix_100, asset_name)
  let user_asset_name = bytearray.concat(prefix_222, asset_name)

  let Output {
    address: ref_output_address,
    value: ref_output_value,
    datum: ref_output_datum,
    reference_script: ref_output_reference_script,
  } = ref_output
  let Output { address: user_output_address, value: user_output_value, .. } =
    user_output

  // check ref output
  expect ref_output_address == cip68_script_address
  let expected_ref_value =
    value.zero()
      |> value.add(policy_id, ref_asset_name, 1)
  expect value.without_lovelace(ref_output_value) == expected_ref_value
  // get ref asset's datum's hash
  let ref_output_datum_hash = get_datum_hash(ref_output_datum)
  expect ref_output_reference_script == None

  // check user output
  expect user_output_address == destination_address
  let does_user_output_value_have_asset =
    value.quantity_of(user_output_value, policy_id, user_asset_name) == 1
  expect does_user_output_value_have_asset

  // update mint value
  let new_mint_value =
    mint_value
      |> value.add(policy_id, ref_asset_name, 1)
      |> value.add(policy_id, user_asset_name, 1)

  (new_mint_value, ref_output_datum_hash)
}

// This function updates the mpt root
// and returns new root
// update asset name (as key) value 
// to datum hash
// we assume old value is empty string
// because asset is not minted yet
//
fn update_root(
  root: mpt.MerklePatriciaForestry,
  asset_name: ByteArray,
  mpt_proof: mpt.Proof,
  datum_hash: DatumHash,
) -> mpt.MerklePatriciaForestry {
  root |> mpt.update(asset_name, mpt_proof, #"", datum_hash)
}
