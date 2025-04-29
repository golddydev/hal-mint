use aiken/transaction/credential.{Address}
use aiken/transaction/value.{PolicyId}
use common/hashes.{ScriptHash, VerificationKeyHash}

// constants
pub const min_treasury_fee: Int = 2_000_000

pub const min_minter_fee: Int = 2_000_000

pub type SettingsV1 {
  policy_id: PolicyId,
  // anyone who buy minting credit will be listed here
  allowed_minters: List<VerificationKeyHash>,
  // treasury fee percentage * total handle price will go to this address
  treasury_address: Address,
  // treasury fee percentage (0-100)
  treasury_fee_percentage: Int,
  // personalization script where ref asset is sent
  pz_script_address: Address,
  // user makes an order (as UTxO) in order script
  order_script_hash: ScriptHash,
  // minting data script is used to check
  // all minting handles logic (for both new and legacy)
  // minting_data_asset is locked inside that script
  minting_data_script_hash: ScriptHash,
}
