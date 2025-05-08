use aiken/transaction/credential.{Address}

pub type OrderDatum {
  // the key hash of the wallet that placed the order that is used for cancelling the order
  owner_key_hash: ByteArray,
  // without asset label
  asset_name: ByteArray,
  // price of HAL NFT in lovelace
  price: Int,
  // the payment credential in the address that the Handle should be sent to
  destination_address: Address,
}
