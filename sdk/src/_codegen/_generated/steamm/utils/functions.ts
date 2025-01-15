import {PUBLISHED_AT} from "..";
import {Transaction} from "@mysten/sui/transactions";

export function getTypeReflection( tx: Transaction, typeArg: string, ) { return tx.moveCall({ target: `${PUBLISHED_AT}::utils::get_type_reflection`, typeArguments: [typeArg], arguments: [ ], }) }
