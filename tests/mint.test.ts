import { makeTxOutputId } from "@helios-lang/ledger";
import { Ok } from "ts-res";
import { assert, describe } from "vitest";

import {
  decodeMintingDataDatum,
  fetchSettings,
  inspect,
  invariant,
  mayFailTransaction,
  mint,
  request,
} from "../src/index.js";
import { myTest } from "./setup.js";
import {
  balanceOf,
  logMemAndCpu,
  makeHalAssetDatum,
  referenceAssetValue,
  userAssetValue,
} from "./utils.js";

describe.sequential("Koralab H.A.L Tests", () => {
  // user_1 orders new asset
  myTest(
    "user_1 orders new asset",
    async ({ network, emulator, wallets, ordersTxInputs, deployedScripts }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      const { usersWallets } = wallets;
      const user1Wallet = usersWallets[0];

      const txBuilderResult = await request({
        network,
        address: user1Wallet.address,
        deployedScripts,
      });
      invariant(txBuilderResult.ok, "Order tx failed");

      const txBuilder = txBuilderResult.data;
      const tx = await txBuilder.build({
        changeAddress: user1Wallet.address,
        spareUtxos: await user1Wallet.utxos,
      });
      tx.addSignatures(await user1Wallet.signTx(tx));
      const txId = await user1Wallet.submitTx(tx);
      emulator.tick(200);

      const orderTxInput = await emulator.getUtxo(makeTxOutputId(txId, 0));
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );
      ordersTxInputs.push(orderTxInput);
    }
  );

  // mint new asset - <hal-1>
  myTest(
    "mint new asset - <hal-1>",
    async ({
      mockedFunctions,
      db,
      network,
      emulator,
      wallets,
      ordersTxInputs,
    }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      const { usersWallets, allowedMinterWallet, cip68Wallet } = wallets;
      const user1Wallet = usersWallets[0];

      const orders = ordersTxInputs.map((orderTxInput) => ({
        orderTxInput,
        assetUtf8Name: "hal-1",
        assetDatum: makeHalAssetDatum("hal-1"),
      }));
      const assetNames = ["hal-1"];

      const txBuilderResult = await mint({
        address: allowedMinterWallet.address,
        orders,
        db,
        blockfrostApiKey: "",
      });
      invariant(txBuilderResult.ok, "Mint Tx Building Failed");

      const txBuilder = txBuilderResult.data;
      const txResult = await mayFailTransaction(
        txBuilder,
        allowedMinterWallet.address,
        await allowedMinterWallet.utxos
      ).complete();
      invariant(txResult.ok, "Mint Tx Complete Failed");
      logMemAndCpu(txResult);

      const { tx } = txResult.data;
      tx.addSignatures(await allowedMinterWallet.signTx(tx));
      const txId = await allowedMinterWallet.submitTx(tx);
      emulator.tick(200);

      // check minted values
      const settingsResult = await fetchSettings(network);
      invariant(settingsResult.ok, "Settings Fetch Failed");
      const { settingsV1 } = settingsResult.data;
      const user1Balance = await balanceOf(user1Wallet);
      const cip68Balance = await balanceOf(cip68Wallet);

      assert(
        user1Balance.isGreaterOrEqual(
          userAssetValue(settingsV1.policy_id, assetNames[0])
        ) == true,
        "User 1 Wallet Balance is not correct"
      );
      assert(
        cip68Balance.isGreaterOrEqual(
          referenceAssetValue(settingsV1.policy_id, assetNames[0])
        ) == true,
        "CIP68 Wallet Balance is not correct"
      );

      // update minting data input
      const mintingDataAssetTxInput = await emulator.getUtxo(
        makeTxOutputId(txId, 0)
      );
      const mintingData = decodeMintingDataDatum(mintingDataAssetTxInput.datum);
      mockedFunctions.mockedFetchMintingData.mockReturnValue(
        new Promise((resolve) =>
          resolve(
            Ok({
              mintingData,
              mintingDataAssetTxInput,
            })
          )
        )
      );

      // empty orders detail
      ordersTxInputs.length = 0;

      // inspect db
      inspect(db);
    }
  );
});
