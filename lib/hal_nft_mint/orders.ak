use aiken/transaction/credential.{Address}

// OrderDatum now consists of owner (to close order), 
// requested_handle (handle name - any string)
// and destination (for now it is address)
//
pub type OrderDatum {
  // the key hash of the wallet that placed the order that is used for cancelling the order
  owner: Data,
  // without asset label
  asset_name: ByteArray,
  // the payment credential in the address that the Handle should be sent to
  destination_address: Address,
}

pub type OrderRedeemer {
  Execute
  Cancel
}
