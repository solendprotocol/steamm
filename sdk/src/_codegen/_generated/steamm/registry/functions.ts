import {PUBLISHED_AT} from "..";
import {GenericArg, generic, obj} from "../../_framework/util";
import {Transaction, TransactionObjectInput} from "@mysten/sui/transactions";

export function init( tx: Transaction, ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::init`, arguments: [ ], }) }

export interface MigrateArgs { registry: TransactionObjectInput; admin: TransactionObjectInput }

export function migrate( tx: Transaction, args: MigrateArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::migrate`, arguments: [ obj(tx, args.registry), obj(tx, args.admin) ], }) }

export interface AddAmmArgs { registry: TransactionObjectInput; pool: GenericArg }

export function addAmm( tx: Transaction, typeArg: string, args: AddAmmArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::add_amm`, typeArguments: [typeArg], arguments: [ obj(tx, args.registry), generic(tx, `${typeArg}`, args.pool) ], }) }

export interface AddBankArgs { registry: TransactionObjectInput; bank: GenericArg }

export function addBank( tx: Transaction, typeArgs: [string, string], args: AddBankArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::add_bank`, typeArguments: typeArgs, arguments: [ obj(tx, args.registry), generic(tx, `${typeArgs[0]}`, args.bank) ], }) }
