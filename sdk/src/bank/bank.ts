// import { lending } from "../codegen/_generated/slamm/bank/functions";

// export interface BankTypes {
//   lendingMarketType: string;
//   coinType: string;
// }

// export interface CreateBankAndShareArgs extends BankTypes {
//   registry: string;
// }

// export interface InitLendingArgs extends BankTypes {
//   bank: string;
//   lendingMarket: string;
//   targetUtilisationBps: number;
//   utilisationBufferBps: number;
// }

// export interface RebalanceArgs extends BankTypes {
//   bank: string;
//   lending_market: string;
// }

// export interface CTokenAmountArgs extends BankTypes {
//   bank: string;
//   lending_market: string;
//   amount: number;
// }

// export interface SetUtilisationBpsArgs extends BankTypes {
//   bank: string;
//   globalAdmin: string;
//   targetUtilisationBps: number;
//   utilisationBufferBps: number;
// }

// export interface MigrateAsGlobalAdminArgs extends BankTypes {
//   bank: string;
//   globalAdmin: string;
// }

// export interface ViewArgs extends BankTypes {
//   bank: string;
// }

// // create_bank_and_share;
// // init_lending;
// // rebalance;
// // ctoken_amount;
// // set_utilisation_bps;
// // migrate_as_global_admin;

// // view
// // lending;
// // total_funds;
// // effective_utilisation_bps;
// // funds_deployed;
// // target_utilisation_bps;
// // utilisation_buffer_bps;
// // funds_available;
// // funds_deployed_unchecked;
// // target_utilisation_bps_unchecked;
// // utilisation_buffer_bps_unchecked;
// // reserve_array_index;
