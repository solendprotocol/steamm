import {PUBLISHED_AT} from "..";
import {obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface CtokenAmountArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amount: bigint | TransactionArgument }

export function ctokenAmount( tx: Transaction, typeArgs: [string, string], args: CtokenAmountArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::ctoken_amount`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amount, `u64`) ], }) }

export interface DepositArgs { bank: TransactionObjectInput; balance: TransactionObjectInput }

export function deposit( tx: Transaction, typeArgs: [string, string], args: DepositArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::deposit`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.balance) ], }) }

export interface WithdrawArgs { bank: TransactionObjectInput; amount: bigint | TransactionArgument }

export function withdraw( tx: Transaction, typeArgs: [string, string], args: WithdrawArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::withdraw`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), pure(tx, args.amount, `u64`) ], }) }

export function reserveArrayIndex( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::reserve_array_index`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface MigrateAsGlobalAdminArgs { bank: TransactionObjectInput; admin: TransactionObjectInput }

export function migrateAsGlobalAdmin( tx: Transaction, typeArgs: [string, string], args: MigrateAsGlobalAdminArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::migrate_as_global_admin`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.admin) ], }) }

export function fundsAvailable( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::funds_available`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function fundsDeployed( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::funds_deployed`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function targetUtilisationBps( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::target_utilisation_bps`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function assertUtilisation( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::assert_utilisation`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function createBank( tx: Transaction, typeArgs: [string, string], registry: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::create_bank`, typeArguments: typeArgs, arguments: [ obj(tx, registry) ], }) }

export function createBankAndShare( tx: Transaction, typeArgs: [string, string], registry: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::create_bank_and_share`, typeArguments: typeArgs, arguments: [ obj(tx, registry) ], }) }

export interface DeployArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amountToDeploy: bigint | TransactionArgument; clock: TransactionObjectInput }

export function deploy( tx: Transaction, typeArgs: [string, string], args: DeployArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::deploy`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amountToDeploy, `u64`), obj(tx, args.clock) ], }) }

export function effectiveUtilisationBps( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::effective_utilisation_bps`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function fundsDeployedUnchecked( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::funds_deployed_unchecked`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface InitLendingArgs { bank: TransactionObjectInput; globalAdmin: TransactionObjectInput; lendingMarket: TransactionObjectInput; targetUtilisationBps: number | TransactionArgument; utilisationBufferBps: number | TransactionArgument }

export function initLending( tx: Transaction, typeArgs: [string, string], args: InitLendingArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::init_lending`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.globalAdmin), obj(tx, args.lendingMarket), pure(tx, args.targetUtilisationBps, `u16`), pure(tx, args.utilisationBufferBps, `u16`) ], }) }

export function utilisationBufferBps( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::utilisation_buffer_bps`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function lending( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::lending`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface PrepareForPendingWithdraw_Args { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; withdrawAmount: bigint | TransactionArgument; clock: TransactionObjectInput }

export function prepareForPendingWithdraw_( tx: Transaction, typeArgs: [string, string], args: PrepareForPendingWithdraw_Args ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::prepare_for_pending_withdraw_`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.withdrawAmount, `u64`), obj(tx, args.clock) ], }) }

export interface RebalanceArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function rebalance( tx: Transaction, typeArgs: [string, string], args: RebalanceArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::rebalance`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface RecallArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amountToRecall: bigint | TransactionArgument; clock: TransactionObjectInput }

export function recall( tx: Transaction, typeArgs: [string, string], args: RecallArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::recall`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amountToRecall, `u64`), obj(tx, args.clock) ], }) }

export interface SetUtilisationBpsArgs { bank: TransactionObjectInput; globalAdmin: TransactionObjectInput; targetUtilisationBps: number | TransactionArgument; utilisationBufferBps: number | TransactionArgument }

export function setUtilisationBps( tx: Transaction, typeArgs: [string, string], args: SetUtilisationBpsArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::set_utilisation_bps`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.globalAdmin), pure(tx, args.targetUtilisationBps, `u16`), pure(tx, args.utilisationBufferBps, `u16`) ], }) }

export function targetUtilisationBpsUnchecked( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::target_utilisation_bps_unchecked`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function totalFunds( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::total_funds`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function utilisationBufferBpsUnchecked( tx: Transaction, typeArgs: [string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::utilisation_buffer_bps_unchecked`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }
