import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { PoolModule } from "../modules/poolModule";
import { SteammSDK } from "../sdk";
import { STEAMM_PKG_ID, SUILEND_PKG_ID } from "./packages";

export function test() {
  describe("describe", () => {
    beforeAll(async () => {});

    beforeEach(async () => {});

    afterAll(async () => {});

    it("should create a keypair", async () => {
      const keypair = new Ed25519Keypair();
      expect(keypair).toBeInstanceOf(Ed25519Keypair);

      const sdk = new SteammSDK({
        fullRpcUrl: "https://fullnode.testnet.sui.io",
        steamm_config: {
          package_id: STEAMM_PKG_ID,
          published_at: STEAMM_PKG_ID,
        },
        suilend_config: {
          package_id: SUILEND_PKG_ID,
          published_at: SUILEND_PKG_ID,
        },
      });
      const pools = await sdk.getPools();

      console.log(pools);
      const bankList = await sdk.getBankList();
      console.log(bankList);

      // const poolModule = new PoolModule(sdk);

      // const signer = new RawSigner(keypair, provider);
    });
  });
}
