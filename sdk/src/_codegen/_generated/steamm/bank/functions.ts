import {PUBLISHED_AT} from "..";
import {obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface RebalanceArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function rebalance( tx: Transaction, typeArgs: [string, string, string], args: RebalanceArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::rebalance`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface CtokenAmountArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amount: bigint | TransactionArgument }

export function ctokenAmount( tx: Transaction, typeArgs: [string, string, string], args: CtokenAmountArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::ctoken_amount`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amount, `u64`) ], }) }

export function reserveArrayIndex( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::reserve_array_index`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface MigrateArgs { bank: TransactionObjectInput; admin: TransactionObjectInput }

export function migrate( tx: Transaction, typeArgs: [string, string, string], args: MigrateArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::migrate`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.admin) ], }) }

export function fundsAvailable( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::funds_available`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface FundsDeployedArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function fundsDeployed( tx: Transaction, typeArgs: [string, string, string], args: FundsDeployedArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::funds_deployed`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export function targetUtilisationBps( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::target_utilisation_bps`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function assertBtokenType( tx: Transaction, typeArgs: [string, string], ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::assert_btoken_type`, typeArguments: typeArgs, arguments: [ ], }) }

export interface BtokenRatioArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function btokenRatio( tx: Transaction, typeArgs: [string, string, string], args: BtokenRatioArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::btoken_ratio`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface BurnBtokensArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; btokens: TransactionObjectInput; btokenAmount: bigint | TransactionArgument; clock: TransactionObjectInput }

export function burnBtokens( tx: Transaction, typeArgs: [string, string, string], args: BurnBtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::burn_btokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.btokens), pure(tx, args.btokenAmount, `u64`), obj(tx, args.clock) ], }) }

export interface CompoundInterestIfAnyArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function compoundInterestIfAny( tx: Transaction, typeArgs: [string, string, string], args: CompoundInterestIfAnyArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::compound_interest_if_any`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface CreateBankArgs { registry: TransactionObjectInput; metaT: TransactionObjectInput; metaB: TransactionObjectInput; btokenTreasury: TransactionObjectInput; lendingMarket: TransactionObjectInput }

export function createBank( tx: Transaction, typeArgs: [string, string, string], args: CreateBankArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::create_bank`, typeArguments: typeArgs, arguments: [ obj(tx, args.registry), obj(tx, args.metaT), obj(tx, args.metaB), obj(tx, args.btokenTreasury), obj(tx, args.lendingMarket) ], }) }

export interface CreateBankAndShareArgs { registry: TransactionObjectInput; metaT: TransactionObjectInput; metaB: TransactionObjectInput; btokenTreasury: TransactionObjectInput; lendingMarket: TransactionObjectInput }

export function createBankAndShare( tx: Transaction, typeArgs: [string, string, string], args: CreateBankAndShareArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::create_bank_and_share`, typeArguments: typeArgs, arguments: [ obj(tx, args.registry), obj(tx, args.metaT), obj(tx, args.metaB), obj(tx, args.btokenTreasury), obj(tx, args.lendingMarket) ], }) }

export interface DeployArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amountToDeploy: bigint | TransactionArgument; clock: TransactionObjectInput }

export function deploy( tx: Transaction, typeArgs: [string, string, string], args: DeployArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::deploy`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amountToDeploy, `u64`), obj(tx, args.clock) ], }) }

export interface EffectiveUtilisationBpsArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function effectiveUtilisationBps( tx: Transaction, typeArgs: [string, string, string], args: EffectiveUtilisationBpsArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::effective_utilisation_bps`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface FromBtokensArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; btokenAmount: bigint | TransactionArgument; clock: TransactionObjectInput }

export function fromBtokens( tx: Transaction, typeArgs: [string, string, string], args: FromBtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::from_btokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.btokenAmount, `u64`), obj(tx, args.clock) ], }) }

export interface InitLendingArgs { bank: TransactionObjectInput; globalAdmin: TransactionObjectInput; lendingMarket: TransactionObjectInput; targetUtilisationBps: number | TransactionArgument; utilisationBufferBps: number | TransactionArgument }

export function initLending( tx: Transaction, typeArgs: [string, string, string], args: InitLendingArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::init_lending`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.globalAdmin), obj(tx, args.lendingMarket), pure(tx, args.targetUtilisationBps, `u16`), pure(tx, args.utilisationBufferBps, `u16`) ], }) }

export function utilisationBufferBps( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::utilisation_buffer_bps`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export function lending( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::lending`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface MintBtokensArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; coins: TransactionObjectInput; coinAmount: bigint | TransactionArgument; clock: TransactionObjectInput }

export function mintBtokens( tx: Transaction, typeArgs: [string, string, string], args: MintBtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::mint_btokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.coins), pure(tx, args.coinAmount, `u64`), obj(tx, args.clock) ], }) }

export interface NeedsRebalanceArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function needsRebalance( tx: Transaction, typeArgs: [string, string, string], args: NeedsRebalanceArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::needs_rebalance`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface PrepareForPendingWithdrawArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; withdrawAmount: bigint | TransactionArgument; clock: TransactionObjectInput }

export function prepareForPendingWithdraw( tx: Transaction, typeArgs: [string, string, string], args: PrepareForPendingWithdrawArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::prepare_for_pending_withdraw`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.withdrawAmount, `u64`), obj(tx, args.clock) ], }) }

export interface RecallArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amountToRecall: bigint | TransactionArgument; clock: TransactionObjectInput }

export function recall( tx: Transaction, typeArgs: [string, string, string], args: RecallArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::recall`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amountToRecall, `u64`), obj(tx, args.clock) ], }) }

export interface SetUtilisationBpsArgs { bank: TransactionObjectInput; globalAdmin: TransactionObjectInput; targetUtilisationBps: number | TransactionArgument; utilisationBufferBps: number | TransactionArgument }

export function setUtilisationBps( tx: Transaction, typeArgs: [string, string, string], args: SetUtilisationBpsArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::set_utilisation_bps`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.globalAdmin), pure(tx, args.targetUtilisationBps, `u16`), pure(tx, args.utilisationBufferBps, `u16`) ], }) }

export function targetUtilisationBpsUnchecked( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::target_utilisation_bps_unchecked`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }

export interface ToBtokensArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; amount: bigint | TransactionArgument; clock: TransactionObjectInput }

export function toBtokens( tx: Transaction, typeArgs: [string, string, string], args: ToBtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::to_btokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), pure(tx, args.amount, `u64`), obj(tx, args.clock) ], }) }

export interface TotalFundsArgs { bank: TransactionObjectInput; lendingMarket: TransactionObjectInput; clock: TransactionObjectInput }

export function totalFunds( tx: Transaction, typeArgs: [string, string, string], args: TotalFundsArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::total_funds`, typeArguments: typeArgs, arguments: [ obj(tx, args.bank), obj(tx, args.lendingMarket), obj(tx, args.clock) ], }) }

export interface UpdateBtokenMetadataArgs { metaA: TransactionObjectInput; metaBtoken: TransactionObjectInput; treasuryBtoken: TransactionObjectInput }

export function updateBtokenMetadata( tx: Transaction, typeArgs: [string, string], args: UpdateBtokenMetadataArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::update_btoken_metadata`, typeArguments: typeArgs, arguments: [ obj(tx, args.metaA), obj(tx, args.metaBtoken), obj(tx, args.treasuryBtoken) ], }) }

export function utilisationBufferBpsUnchecked( tx: Transaction, typeArgs: [string, string, string], bank: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::bank::utilisation_buffer_bps_unchecked`, typeArguments: typeArgs, arguments: [ obj(tx, bank) ], }) }
