import {
  SteammConfigs,
  Package,
  SuilendConfigs,
  BankList,
  DataPage,
  PoolInfo,
} from "./types";
import { RpcModule } from "./modules/rpcModule";
import { patchFixSuiObjectId, SuiAddressType } from "./utils";
import { PoolModule } from "./modules/poolModule";

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

  /**
   * After connecting the wallet, set the current wallet address to senderAddress.
   */
  protected _senderAddress = "";

  constructor(options: SdkOptions) {
    this._sdkOptions = options;
    this._rpcModule = new RpcModule({
      url: options.fullRpcUrl,
    });

    this._pool = new PoolModule(this);

    patchFixSuiObjectId(this._sdkOptions);
  }

  /**
   * Getter for the sender address property.
   * @returns {SuiAddressType} The sender address.
   */
  get senderAddress(): SuiAddressType {
    return this._senderAddress;
  }

  /**
   * Setter for the sender address property.
   * @param {string} value - The new sender address value.
   */
  set senderAddress(value: string) {
    this._senderAddress = value;
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

  async getBankList(): Promise<BankList> {
    const pkgAddy = this.sdkOptions.steamm_config.package_id;

    let bankList: BankList = {};
    let nextCursor: string | null | undefined = null;

    const res: DataPage<BankList> = await this.fullClient.queryEventsByPage({
      MoveEventType: `${pkgAddy}::events::Event<${pkgAddy}::bank::NewBankEvent>`,
    });

    bankList = res.data.reduce((acc, curr) => {
      return { ...acc, ...curr };
    }, {});

    return bankList;
  }

  async getPools(): Promise<PoolInfo[]> {
    const pkgAddy = this.sdkOptions.steamm_config.package_id;

    let pools: PoolInfo[] = [];
    let nextCursor: string | null | undefined = null;

    const res: DataPage<PoolInfo[]> = await this.fullClient.queryEventsByPage({
      MoveEventType: `${pkgAddy}::events::Event<${pkgAddy}::pool::NewPoolResult>`,
    });

    pools = res.data.reduce((acc, curr) => acc.concat(curr), []);

    return pools;
  }
}
