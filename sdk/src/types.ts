import { SuiObjectIdType } from "./modules/rpcModule";
import { SuiAddressType } from "./utils";

/**
 * Represents a paginated data page with optional cursor and limit.
 */
export type DataPage<T> = {
  data: T[];
  nextCursor?: any;
  hasNextPage: boolean;
};

export type SteammConfigs = {
  registryId: SuiObjectIdType;
  globalConfigId: SuiObjectIdType;
  adminCapId: SuiObjectIdType;
};

export type SuilendConfigs = {
  lendingMarketId: SuiObjectIdType;
  lendingMarketType: string;
};

export type BankList = {
  [key: string]: BankInfo;
};

export type PoolInfo = {
  creator: SuiAddressType;
  poolId: SuiObjectIdType;
  poolCapId: SuiObjectIdType;
  coinTypeA: string;
  coinTypeB: string;
  lpTokenType: string;
  quoterType: string;
};

export type BankInfo = {
  coinType: string;
  btokenType: string;
  lendingMarketType: string;
  bankId: SuiObjectIdType;
  bankType: string;
  lendingMarketId: SuiObjectIdType;
};

/**
 * Represents configuration data for a cryptocurrency coin.
 */
export type CoinConfig = {
  /**
   * The unique identifier of the coin.
   */
  id: string;

  /**
   * The name of the coin.
   */
  name: string;

  /**
   * The symbol of the coin.
   */
  symbol: string;

  /**
   * The address associated with the coin.
   */
  address: string;

  /**
   * The Pyth identifier of the coin.
   */
  pyth_id: string;

  /**
   * The project URL related to the coin.
   */
  project_url: string;

  /**
   * The URL to the logo image of the coin.
   */
  logo_url: string;

  /**
   * The number of decimal places used for the coin.
   */
  decimals: number;

  /**
   * Additional properties for the coin configuration.
   */
} & Record<string, any>;

/**
 * Represents a package containing specific configuration or data.
 * @template T - The type of configuration or data contained in the package.
 */
export type Package<T = undefined> = {
  /**
   * The unique identifier of the package.
   */
  package_id: string;
  /**
   * the package was published.
   */
  published_at: string;
  /**
   * The version number of the package (optional).
   */
  version?: number;
  /**
   * The configuration or data contained in the package (optional).
   */
  config?: T;
};
