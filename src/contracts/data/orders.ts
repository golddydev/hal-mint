import { ShelleyAddress, TxOutputDatum } from "@helios-lang/ledger";
import { NetworkName } from "@helios-lang/tx-utils";
import {
  expectByteArrayData,
  expectConstrData,
  expectIntData,
  makeByteArrayData,
  makeConstrData,
  makeIntData,
  makeListData,
  UplcData,
} from "@helios-lang/uplc";

import { invariant } from "../../helpers/index.js";
import { OrderDatum } from "../types/index.js";
import { buildAddressData, decodeAddressFromData } from "./common.js";

const decodeOrderDatum = (
  datum: TxOutputDatum | undefined,
  network: NetworkName
): OrderDatum => {
  invariant(
    datum?.kind == "InlineTxOutputDatum",
    "OrderDatum must be inline datum"
  );
  const datumData = datum.data;
  const orderConstrData = expectConstrData(datumData, 0, 3);

  const owner_key_hash = expectByteArrayData(orderConstrData.fields[0]).toHex();
  const price = expectIntData(orderConstrData.fields[1]).value;
  const destination_address = decodeAddressFromData(
    orderConstrData.fields[2],
    network
  );

  return {
    owner_key_hash,
    price,
    destination_address,
  };
};

const buildOrderData = (order: OrderDatum): UplcData => {
  const { owner_key_hash, price, destination_address } = order;
  return makeConstrData(0, [
    makeByteArrayData(owner_key_hash),
    makeIntData(price),
    buildAddressData(destination_address),
  ]);
};

const buildOrdersMintMintOrdersRedeemer = (
  destination_addresses: ShelleyAddress[]
): UplcData => {
  return makeConstrData(0, [
    makeListData(destination_addresses.map(buildAddressData)),
  ]);
};

const buildOrdersMintBurnOrdersRedeemer = (): UplcData => {
  return makeConstrData(1, []);
};

const buildOrdersMintCancelOrderRedeemer = (): UplcData => {
  return makeConstrData(2, []);
};

const buildOrdersSpendExecuteRedeemer = (): UplcData => {
  return makeConstrData(0, []);
};

const buildOrdersSpendCancelRedeemer = (): UplcData => {
  return makeConstrData(1, []);
};

export {
  buildOrderData,
  buildOrdersMintBurnOrdersRedeemer,
  buildOrdersMintCancelOrderRedeemer,
  buildOrdersMintMintOrdersRedeemer,
  buildOrdersSpendCancelRedeemer,
  buildOrdersSpendExecuteRedeemer,
  decodeOrderDatum,
};
