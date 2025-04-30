use aiken/transaction/credential.{Address}
use aiken/transaction/value.{PolicyId}
use common/hashes.{ScriptHash, VerificationKeyHash}

pub type SettingsV1 {
  policy_id: PolicyId,
  // hal nft's price
  hal_nft_price: Int,
  // anyone who buy minting credit will be listed here
  allowed_minters: List<VerificationKeyHash>,
  // CIP68 Spending validator address
  // ref asset is sent to this address
  cip68_script_address: Address,
  // user makes an order (as UTxO) in order script
  order_script_hash: ScriptHash,
  // minting data script is used to check
  // all minting handles logic (for both new and legacy)
  // minting_data_asset is locked inside that script
  minting_data_script_hash: ScriptHash,
}
