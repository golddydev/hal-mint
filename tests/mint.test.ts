import { makeTxOutputId } from "@helios-lang/ledger";
import { Ok } from "ts-res";
import { assert, describe } from "vitest";

import { HAL_NFT_PRICE } from "../src/constants/index.js";
import {
  buildOrdersSpendCancelOrderRedeemer,
  cancel,
  decodeMintingDataDatum,
  fetchSettings,
  inspect,
  invariant,
  mayFailTransaction,
  mint,
  Order,
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
      invariant(txBuilderResult.ok, "Order Tx Building failed");

      const txBuilder = txBuilderResult.data;
      const txResult = await mayFailTransaction(
        txBuilder,
        user1Wallet.address,
        await user1Wallet.utxos
      ).complete();
      invariant(txResult.ok, "Order Tx Complete failed");

      logMemAndCpu(txResult);
      const { tx } = txResult.data;
      tx.addSignatures(await user1Wallet.signTx(tx));
      const txId = await user1Wallet.submitTx(tx);
      emulator.tick(200);

      const orderTxInput = await emulator.getUtxo(makeTxOutputId(txId, 0));
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

      const orders: Order[] = ordersTxInputs.map((orderTxInput) => ({
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

  // user_2 orders 2 new assets
  myTest(
    "user_2 orders 2 new assets",
    async ({ network, emulator, wallets, ordersTxInputs, deployedScripts }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      const { usersWallets } = wallets;
      const user2Wallet = usersWallets[1];

      for (let i = 0; i < 2; i++) {
        const txBuilderResult = await request({
          network,
          address: user2Wallet.address,
          deployedScripts,
        });
        invariant(txBuilderResult.ok, "Order Tx Building failed");

        const txBuilder = txBuilderResult.data;
        const txResult = await mayFailTransaction(
          txBuilder,
          user2Wallet.address,
          await user2Wallet.utxos
        ).complete();
        invariant(txResult.ok, "Order Tx Complete failed");
        logMemAndCpu(txResult);

        const { tx } = txResult.data;
        tx.addSignatures(await user2Wallet.signTx(tx));
        const txId = await user2Wallet.submitTx(tx);
        emulator.tick(200);

        const orderTxInput = await emulator.getUtxo(makeTxOutputId(txId, 0));
        ordersTxInputs.push(orderTxInput);
      }
    }
  );

  // cannot mint 2 new assets because one asset name is not pre-defined in MPT - <hal-2, no-hal-1>
  myTest(
    "cannot mint 2 new assets because one asset name is not pre-defined in MPT - <hal-2, no-hal-1>",
    async ({ db, wallets, ordersTxInputs }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      const { allowedMinterWallet } = wallets;

      const assetNames = ["hal-2", "no-hal-1"];
      const orders: Order[] = ordersTxInputs.map((orderTxInput, i) => ({
        orderTxInput,
        assetUtf8Name: assetNames[i],
        assetDatum: makeHalAssetDatum(assetNames[i]),
      }));

      const txResult = await mint({
        address: allowedMinterWallet.address,
        orders,
        db,
        blockfrostApiKey: "",
      });
      invariant(!txResult.ok, "Mint Tx Building Should Fail");
      assert(txResult.error.message.includes("Asset name is not pre-defined"));
    }
  );

  // cannot cancel 2 orders in a transaction
  myTest(
    "cannot cancel 2 orders in a transaction",
    async ({ network, wallets, ordersTxInputs, deployedScripts }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      const { usersWallets } = wallets;
      const user2Wallet = usersWallets[1];

      const txBuilderResult = await cancel({
        network,
        address: user2Wallet.address,
        orderTxInput: ordersTxInputs[0],
        deployedScripts,
      });
      invariant(txBuilderResult.ok, "Cancel Tx Building failed");

      // hack: cancel one other order also
      // without burning order token
      const txBuilder = txBuilderResult.data;
      txBuilder.spendUnsafe(
        ordersTxInputs[1],
        buildOrdersSpendCancelOrderRedeemer()
      );

      const txResult = await mayFailTransaction(
        txBuilder,
        user2Wallet.address,
        await user2Wallet.utxos
      ).complete();
      invariant(!txResult.ok, "Cancel Tx Complete should fail");
      assert(txResult.error.message.includes("expect own_utxo_count == 1"));
    }
  );

  // can cancel orders one by one
  myTest(
    "can cancel orders one by one",
    async ({ network, emulator, wallets, ordersTxInputs, deployedScripts }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      for (let i = 0; i < 2; i++) {
        const { usersWallets } = wallets;
        const user2Wallet = usersWallets[1];
        const beforeUser2Lovelace = (await balanceOf(user2Wallet)).lovelace;

        const txBuilderResult = await cancel({
          network,
          address: user2Wallet.address,
          orderTxInput: ordersTxInputs[i],
          deployedScripts,
        });
        invariant(txBuilderResult.ok, "Cancel Tx Building failed");

        const txBuilder = txBuilderResult.data;
        const txResult = await mayFailTransaction(
          txBuilder,
          user2Wallet.address,
          await user2Wallet.utxos
        ).complete();
        invariant(txResult.ok, "Cancel Tx Complete failed");
        logMemAndCpu(txResult);

        const { tx } = txResult.data;
        tx.addSignatures(await user2Wallet.signTx(tx));
        await user2Wallet.submitTx(tx);
        emulator.tick(200);

        const afterUser2Lovelace = (await balanceOf(user2Wallet)).lovelace;

        invariant(
          afterUser2Lovelace - beforeUser2Lovelace > HAL_NFT_PRICE - 1_000_000n,
          "User 2 Lovelace is not correct"
        );
      }

      ordersTxInputs.length = 0;
    }
  );

  // ======= mint many assets =======

  // user_1 orders many assets - <16 assets>
  myTest(
    "user_1 orders many assets - <16 assets>",
    async ({ network, emulator, wallets, deployedScripts, ordersTxInputs }) => {
      invariant(
        Array.isArray(ordersTxInputs),
        "Orders tx inputs is not an array"
      );

      const { usersWallets } = wallets;
      const user1Wallet = usersWallets[0];

      for (let i = 0; i < 16; i++) {
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
        ordersTxInputs.push(orderTxInput);
      }
    }
  );

  // mint many assets - <16 assets>
  myTest(
    "mint many assets - <16 assets>",
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

      const orders: Order[] = ordersTxInputs.map((orderTxInput, i) => ({
        orderTxInput,
        assetUtf8Name: `hal-${i + 101}`,
        assetDatum: makeHalAssetDatum(`hal-${i + 101}`),
      }));

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

      orders.map((order) => {
        assert(
          user1Balance.isGreaterOrEqual(
            userAssetValue(settingsV1.policy_id, order.assetUtf8Name)
          ) == true,
          "User 1 Wallet Balance is not correct"
        );
        assert(
          cip68Balance.isGreaterOrEqual(
            referenceAssetValue(settingsV1.policy_id, order.assetUtf8Name)
          ) == true,
          "CIP68 Wallet Balance is not correct"
        );
      });

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
