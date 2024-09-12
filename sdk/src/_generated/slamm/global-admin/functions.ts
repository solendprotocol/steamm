import {PUBLISHED_AT} from "..";
import {Transaction} from "@mysten/sui/transactions";

export function init( tx: Transaction, ) { return tx.moveCall({ target: `${PUBLISHED_AT}::global_admin::init`, arguments: [ ], }) }
