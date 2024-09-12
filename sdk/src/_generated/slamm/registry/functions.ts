import {PUBLISHED_AT} from "..";
import {GenericArg, generic, obj} from "../../_framework/util";
import {Transaction, TransactionObjectInput} from "@mysten/sui/transactions";

export function init( tx: Transaction, ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::init`, arguments: [ ], }) }

export function assertVersion( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::assert_version`, arguments: [ obj(tx, self) ], }) }

export function assertVersionAndUpgrade( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::assert_version_and_upgrade`, arguments: [ obj(tx, self) ], }) }

export function migrate_( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::migrate_`, arguments: [ obj(tx, self) ], }) }

export interface AddAmmArgs { registry: TransactionObjectInput; pool: GenericArg }

export function addAmm( tx: Transaction, typeArg: string, args: AddAmmArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::add_amm`, typeArguments: [typeArg], arguments: [ obj(tx, args.registry), generic(tx, `${typeArg}`, args.pool) ], }) }

export interface AddBankArgs { registry: TransactionObjectInput; bank: GenericArg }

export function addBank( tx: Transaction, typeArg: string, args: AddBankArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::add_bank`, typeArguments: [typeArg], arguments: [ obj(tx, args.registry), generic(tx, `${typeArg}`, args.bank) ], }) }

export interface MigrateAsGlobalAdminArgs { self: TransactionObjectInput; admin: TransactionObjectInput }

export function migrateAsGlobalAdmin( tx: Transaction, args: MigrateAsGlobalAdminArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::registry::migrate_as_global_admin`, arguments: [ obj(tx, args.self), obj(tx, args.admin) ], }) }
