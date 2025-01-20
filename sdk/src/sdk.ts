import {
  SteammConfigs,
  Package,
  SuilendConfigs,
  BankList,
  DataPage,
  PoolInfo,
  EventData,
  NewPoolEvent,
  extractPoolInfo,
  NewBankEvent,
  extractBankList,
} from "./types";
import { RpcModule } from "./modules/rpcModule";
import { patchFixSuiObjectId, SuiAddressType } from "./utils";
import { PoolModule } from "./modules/poolModule";
import { Signer } from "@mysten/sui/dist/cjs/cryptography/keypair";

export type SdkOptions = {
  fullRpcUrl: string;
  steamm_config: Package<SteammConfigs>;
  suilend_config: Package<SuilendConfigs>;
};

export class SteammSDK {
  _rpcModule: RpcModule;

  protected _pool: PoolModule;

  /**
   *  Provide sdk options
   */
  _sdkOptions: SdkOptions;

  signer: Signer | undefined;

  /**
   * After connecting the wallet, set the current wallet address to senderAddress.
   */
  senderAddress = "";

  constructor(options: SdkOptions) {
    this._sdkOptions = options;
    this._rpcModule = new RpcModule({
      url: options.fullRpcUrl,
    });

    this._pool = new PoolModule(this);

    patchFixSuiObjectId(this._sdkOptions);
  }

  // /**
  //  * Getter for the sender address property.
  //  * @returns {SuiAddressType} The sender address.
  //  */
  // get senderAddress(): SuiAddressType {
  //   return this.senderAddress;
  // }

  // /**
  //  * Setter for the sender address property.
  //  * @param {string} value - The new sender address value.
  //  */
  // set senderAddress(value: string) {
  //   this.senderAddress = value;
  // }

  setSigner(signer: Signer) {
    this.signer = signer;
    this.senderAddress = signer.getPublicKey().toSuiAddress();
  }

  /**
   * Getter for the fullClient property.
   * @returns {RpcModule} The fullClient property value.
   */
  get fullClient(): RpcModule {
    return this._rpcModule;
  }

  /**
   * Getter for the sdkOptions property.
   * @returns {SdkOptions} The sdkOptions property value.
   */
  get sdkOptions(): SdkOptions {
    return this._sdkOptions;
  }

  /**
   * Getter for the Pool property.
   * @returns {PoolModule} The Pool property value.
   */
  get Pool(): PoolModule {
    return this._pool;
  }

  async getBanks(): Promise<BankList> {
    const pkgAddy = this.sdkOptions.steamm_config.package_id;

    let eventData: EventData<NewBankEvent>[] = [];
    let bankList: BankList = {};

    const res: DataPage<EventData<NewBankEvent>[]> =
      await this.fullClient.queryEventsByPage({
        MoveEventType: `${pkgAddy}::events::Event<${pkgAddy}::bank::NewBankEvent>`,
      });

    eventData = res.data.reduce((acc, curr) => acc.concat(curr), []);

    bankList = extractBankList(eventData);

    return bankList;
  }

  async getPools(): Promise<PoolInfo[]> {
    const pkgAddy = this.sdkOptions.steamm_config.package_id;

    let eventData: EventData<NewPoolEvent>[] = [];
    let pools: PoolInfo[] = [];

    const res: DataPage<EventData<NewPoolEvent>[]> =
      await this.fullClient.queryEventsByPage({
        MoveEventType: `${pkgAddy}::events::Event<${pkgAddy}::pool::NewPoolResult>`,
      });

    eventData = res.data.reduce((acc, curr) => acc.concat(curr), []);
    pools = extractPoolInfo(eventData);

    return pools;
  }
}
