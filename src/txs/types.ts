import { Address, InlineTxOutputDatum, TxInput } from "@helios-lang/ledger";

interface OrderedAsset {
  // without asset name label
  hexName: string;
  utf8Name: string;
  destinationAddress: Address;
  price: bigint;
  // asset datum
  assetDatum: InlineTxOutputDatum;
}

interface Order {
  orderTxInput: TxInput;
  // without asset name label
  assetUtf8Name: string;
  // asset datum
  assetDatum: InlineTxOutputDatum;
}

export type { Order, OrderedAsset };
