import { bytesToHex } from "@helios-lang/codec-utils";
import { blake2b } from "@helios-lang/crypto";
import { InlineTxOutputDatum } from "@helios-lang/ledger";

const getDatumHash = (datum: InlineTxOutputDatum): string => {
  return bytesToHex(blake2b(datum.data.toCbor()));
};

export { getDatumHash };
