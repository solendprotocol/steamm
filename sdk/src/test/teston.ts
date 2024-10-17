import { assert, expect } from "chai";
import { SUILEND_TESTNET_PKG, TESTNET_REGISTRY } from "../consts";
import { Transaction } from "@mysten/sui/transactions";
// import { JsonRpcProvider, Ed25519Keypair, RawSigner } from "@mysten/sui.js";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/dist/cjs/client";
import { Bank } from "../bank/bank";
// import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
// import { getFullnodeUrl, SuiClient } from "@mysten/sui/dapp_kit";
// import {
//   signAndExecuteTransaction,
//   signTransaction,
// } from "@mysten/wallet-standard";

export function test() {
  describe("describe", () => {
    beforeAll(async () => {});

    beforeEach(async () => {});

    afterAll(async () => {});

    it("it", async () => {
      const keypair = new Ed25519Keypair();
      // const signer = new RawSigner(keypair, provider);

      const tx = new Transaction();

      Bank.createBank(
        `${SUILEND_TESTNET_PKG}::lending_market::LENDING_MARKET`,
        `0x0::sui::SUI`,
        TESTNET_REGISTRY,
        tx
      );

      const client = new SuiClient({ url: getFullnodeUrl("testnet") });
      const bytes = await tx.build({ client });
      const { signature } = await keypair.signTransaction(bytes);

      //   const { digest, effects } = await client.signAndExecuteTransaction(
      //     {
      //       transaction,
      //     },
      //     {}
      //   );
    });
  });
}
