<<<<<<< HEAD:sdk/src/test/teston.test.ts
import { assert, expect } from "chai";
import { SUILEND_TESTNET_PKG, TESTNET_REGISTRY } from "../consts";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/dist/cjs/client";
import { Bank } from "../bank/bank";
import { describe, it, beforeAll, beforeEach, afterAll } from "@jest/globals";
=======
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
>>>>>>> origin/init-sdk:sdk/src/test/teston.ts

export function test() {
  describe("describe", () => {
    beforeAll(async () => {});

    beforeEach(async () => {});

    afterAll(async () => {});

    it("should create a keypair", async () => {
      const keypair = new Ed25519Keypair();
      expect(keypair).to.be.an("object");
      // const signer = new RawSigner(keypair, provider);
<<<<<<< HEAD:sdk/src/test/teston.test.ts

      // const tx = new Transaction();

      // Bank.createBank(
      //   `${SUILEND_TESTNET_PKG}::lending_market::LENDING_MARKET`,
      //   `0x0::sui::SUI`,
      //   TESTNET_REGISTRY,
      //   tx
      // );

      // const client = new SuiClient({ url: getFullnodeUrl("localnet") });
      // const bytes = await tx.build({ client });
      // const { signature } = await keypair.signTransaction(bytes);

      //   const { digest, effects } = await client.signAndExecuteTransaction(
      //     {
      //       transaction,
      //     },
      //     {}
      //   );
=======
>>>>>>> origin/init-sdk:sdk/src/test/teston.ts
    });
  });
}
