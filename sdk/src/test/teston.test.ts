import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

export function test() {
  describe("describe", () => {
    beforeAll(async () => {});

    beforeEach(async () => {});

    afterAll(async () => {});

    it("should create a keypair", async () => {
      const keypair = new Ed25519Keypair();
      expect(keypair).toBeInstanceOf(Ed25519Keypair);
      // const signer = new RawSigner(keypair, provider);
    });
  });
}
