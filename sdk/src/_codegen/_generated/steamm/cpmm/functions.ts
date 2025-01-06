import {PUBLISHED_AT} from "..";
import {GenericArg, generic, obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export function migrate_( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::migrate_`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export interface NewArgs { witness: GenericArg; registry: TransactionObjectInput; swapFeeBps: bigint | TransactionArgument }

export function new_( tx: Transaction, typeArgs: [string, string, string, string], args: NewArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::new`, typeArguments: typeArgs, arguments: [ generic(tx, `${typeArgs[2]}`, args.witness), obj(tx, args.registry), pure(tx, args.swapFeeBps, `u64`) ], }) }

export interface KArgs { pool: TransactionObjectInput; offset: bigint | TransactionArgument }

export function k( tx: Transaction, typeArgs: [string, string, string, string], args: KArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::k`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.offset, `u64`) ], }) }

export interface MigrateArgs { pool: TransactionObjectInput; cap: TransactionObjectInput }

export function migrate( tx: Transaction, typeArgs: [string, string, string, string], args: MigrateArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::migrate`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.cap) ], }) }

export interface MigrateAsGlobalAdminArgs { pool: TransactionObjectInput; admin: TransactionObjectInput }

export function migrateAsGlobalAdmin( tx: Transaction, typeArgs: [string, string, string, string], args: MigrateAsGlobalAdminArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::migrate_as_global_admin`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.admin) ], }) }

export interface CheckInvarianceArgs { pool: TransactionObjectInput; k0: bigint | TransactionArgument; offset: bigint | TransactionArgument }

export function checkInvariance( tx: Transaction, typeArgs: [string, string, string, string], args: CheckInvarianceArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::check_invariance`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.k0, `u128`), pure(tx, args.offset, `u64`) ], }) }

export function offset( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::offset`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export interface ExecuteSwapArgs { pool: TransactionObjectInput; intent: TransactionObjectInput; coinA: TransactionObjectInput; coinB: TransactionObjectInput; minAmountOut: bigint | TransactionArgument }

export function executeSwap( tx: Transaction, typeArgs: [string, string, string, string], args: ExecuteSwapArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::execute_swap`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.intent), obj(tx, args.coinA), obj(tx, args.coinB), pure(tx, args.minAmountOut, `u64`) ], }) }

export interface IntentSwapArgs { pool: TransactionObjectInput; amountIn: bigint | TransactionArgument; a2B: boolean | TransactionArgument }

export function intentSwap( tx: Transaction, typeArgs: [string, string, string, string], args: IntentSwapArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::intent_swap`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.amountIn, `u64`), pure(tx, args.a2B, `bool`) ], }) }

export function maxAmountInOnA2b( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::max_amount_in_on_a2b`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export interface NewWithOffsetArgs { witness: GenericArg; registry: TransactionObjectInput; swapFeeBps: bigint | TransactionArgument; offset: bigint | TransactionArgument }

export function newWithOffset( tx: Transaction, typeArgs: [string, string, string, string], args: NewWithOffsetArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::new_with_offset`, typeArguments: typeArgs, arguments: [ generic(tx, `${typeArgs[2]}`, args.witness), obj(tx, args.registry), pure(tx, args.swapFeeBps, `u64`), pure(tx, args.offset, `u64`) ], }) }

export interface QuoteSwapArgs { pool: TransactionObjectInput; amountIn: bigint | TransactionArgument; a2B: boolean | TransactionArgument }

export function quoteSwap( tx: Transaction, typeArgs: [string, string, string, string], args: QuoteSwapArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::quote_swap`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.amountIn, `u64`), pure(tx, args.a2B, `bool`) ], }) }

export interface QuoteSwap_Args { amountIn: bigint | TransactionArgument; reserveIn: bigint | TransactionArgument; reserveOut: bigint | TransactionArgument; offset: bigint | TransactionArgument; a2B: boolean | TransactionArgument }

export function quoteSwap_( tx: Transaction, args: QuoteSwap_Args ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::quote_swap_`, arguments: [ pure(tx, args.amountIn, `u64`), pure(tx, args.reserveIn, `u64`), pure(tx, args.reserveOut, `u64`), pure(tx, args.offset, `u64`), pure(tx, args.a2B, `bool`) ], }) }

export interface QuoteSwapImplArgs { reserveA: bigint | TransactionArgument; reserveB: bigint | TransactionArgument; amountIn: bigint | TransactionArgument; offset: bigint | TransactionArgument; a2B: boolean | TransactionArgument }

export function quoteSwapImpl( tx: Transaction, args: QuoteSwapImplArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::cpmm::quote_swap_impl`, arguments: [ pure(tx, args.reserveA, `u64`), pure(tx, args.reserveB, `u64`), pure(tx, args.amountIn, `u64`), pure(tx, args.offset, `u64`), pure(tx, args.a2B, `bool`) ], }) }
