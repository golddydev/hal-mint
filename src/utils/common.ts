import { InlineTxOutputDatum } from "@helios-lang/ledger";

const getDatumHash = (datum: InlineTxOutputDatum): string => {
  return datum.hash.toHex();
};

export { getDatumHash };
