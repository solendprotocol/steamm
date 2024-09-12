import {PUBLISHED_AT} from "..";
import {obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface NewArgs { feeNumerator: bigint | TransactionArgument; feeDenominator: bigint | TransactionArgument; minFee: bigint | TransactionArgument }

export function new_( tx: Transaction, typeArgs: [string, string], args: NewArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::new`, typeArguments: typeArgs, arguments: [ pure(tx, args.feeNumerator, `u64`), pure(tx, args.feeDenominator, `u64`), pure(tx, args.minFee, `u64`) ], }) }

export function config( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::config`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export interface NewConfigArgs { feeNumerator: bigint | TransactionArgument; feeDenominator: bigint | TransactionArgument; minFee: bigint | TransactionArgument }

export function newConfig( tx: Transaction, args: NewConfigArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::new_config`, arguments: [ pure(tx, args.feeNumerator, `u64`), pure(tx, args.feeDenominator, `u64`), pure(tx, args.minFee, `u64`) ], }) }

export function withdraw( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::withdraw`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export function balances( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::balances`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export function balancesMut( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::balances_mut`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export function feeA( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::fee_a`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export function feeB( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::fee_b`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export function feeDenominator( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::fee_denominator`, arguments: [ obj(tx, self) ], }) }

export function feeNumerator( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::fee_numerator`, arguments: [ obj(tx, self) ], }) }

export function feeRatio( tx: Transaction, typeArgs: [string, string], self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::fee_ratio`, typeArguments: typeArgs, arguments: [ obj(tx, self) ], }) }

export function feeRatio_( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::fee_ratio_`, arguments: [ obj(tx, self) ], }) }

export function minFee( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::min_fee`, arguments: [ obj(tx, self) ], }) }

export interface SetConfigArgs { self: TransactionObjectInput; feeNumerator: bigint | TransactionArgument; feeDenominator: bigint | TransactionArgument; minFee: bigint | TransactionArgument }

export function setConfig( tx: Transaction, typeArgs: [string, string], args: SetConfigArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::fees::set_config`, typeArguments: typeArgs, arguments: [ obj(tx, args.self), pure(tx, args.feeNumerator, `u64`), pure(tx, args.feeDenominator, `u64`), pure(tx, args.minFee, `u64`) ], }) }
