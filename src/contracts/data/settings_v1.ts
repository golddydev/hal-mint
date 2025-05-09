import { ShelleyAddress } from "@helios-lang/ledger";
import { NetworkName } from "@helios-lang/tx-utils";
import {
  expectByteArrayData,
  expectConstrData,
  expectIntData,
  makeByteArrayData,
  makeConstrData,
  makeIntData,
  UplcData,
} from "@helios-lang/uplc";

import { SettingsV1 } from "../types/index.js";
import { buildAddressData, decodeAddressFromData } from "./common.js";

const buildSettingsV1Data = (settings: SettingsV1): UplcData => {
  const {
    policy_id,
    allowed_minter,
    hal_nft_price,
    payment_address,
    cip68_script_address,
    order_spend_script_address,
    order_mint_policy_id,
    minting_data_script_hash,
  } = settings;

  return makeConstrData(0, [
    makeByteArrayData(policy_id),
    makeByteArrayData(allowed_minter),
    makeIntData(hal_nft_price),
    buildAddressData(payment_address as ShelleyAddress),
    buildAddressData(cip68_script_address as ShelleyAddress),
    buildAddressData(order_spend_script_address as ShelleyAddress),
    makeByteArrayData(order_mint_policy_id),
    makeByteArrayData(minting_data_script_hash),
  ]);
};

const decodeSettingsV1Data = (
  data: UplcData,
  network: NetworkName
): SettingsV1 => {
  const settingsV1ConstrData = expectConstrData(data, 0, 8);

  const policy_id = expectByteArrayData(
    settingsV1ConstrData.fields[0],
    "policy_id must be ByteArray"
  ).toHex();

  // allowed_minters
  const allowed_minter = expectByteArrayData(
    settingsV1ConstrData.fields[1],
    "allowed_minter must be ByteArray"
  ).toHex();

  // hal_nft_price
  const hal_nft_price = expectIntData(
    settingsV1ConstrData.fields[2],
    "hal_nft_price must be Int"
  ).value;

  // payment_address
  const payment_address = decodeAddressFromData(
    settingsV1ConstrData.fields[3],
    network
  );

  // cip68_script_address
  const cip68_script_address = decodeAddressFromData(
    settingsV1ConstrData.fields[4],
    network
  );

  // order_spend_script_address
  const order_spend_script_address = decodeAddressFromData(
    settingsV1ConstrData.fields[5],
    network
  );

  // order_mint_policy_id
  const order_mint_policy_id = expectByteArrayData(
    settingsV1ConstrData.fields[6],
    "order_mint_policy_id must be ByteArray"
  ).toHex();

  // minting_data_script_hash
  const minting_data_script_hash = expectByteArrayData(
    settingsV1ConstrData.fields[7],
    "minting_data_script_hash must be ByteArray"
  ).toHex();

  return {
    policy_id,
    allowed_minter,
    hal_nft_price,
    payment_address,
    cip68_script_address,
    order_spend_script_address,
    order_mint_policy_id,
    minting_data_script_hash,
  };
};

export { buildSettingsV1Data, decodeSettingsV1Data };
