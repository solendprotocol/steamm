module steamm::registry;

use std::type_name::{Self, TypeName};
use steamm::bank::Bank;
use steamm::pool::Pool;
use steamm::version::{Self, Version};
use sui::bag::{Self, Bag};
use sui::table::{Self, Table};

const CURRENT_VERSION: u16 = 1;

public struct Registry has key, store {
    id: UID,
    version: Version,
    pool_ids: Table<ID, Null>,
    btoken_ids: Table<ID, Null>,
}

public struct Null has copy, drop, store {}

fun init(ctx: &mut TxContext) {
    let registry = Registry {
        id: object::new(ctx),
        version: version::new(CURRENT_VERSION),
        pool_ids: table::new(ctx),
        btoken_ids: table::new(ctx),
    };

    transfer::public_share_object(registry);
}

public(package) fun add_pool_to_registry(
    self: &mut Registry,
    pool_id: ID,
) {
    self.version.assert_version_and_upgrade(CURRENT_VERSION);
    self.pool_ids.add(pool_id, Null {});
}

public(package) fun add_bank_to_registry(
    self: &mut Registry,
    bank_id: ID,
) {
    self.version.assert_version_and_upgrade(CURRENT_VERSION);
    self.btoken_ids.add(bank_id, Null {});
}

#[test_only]
public fun create_for_testing(ctx: &mut TxContext): Registry {
    let registry = Registry {
        id: object::new(ctx),
        version: version::new(CURRENT_VERSION),
        pool_ids: table::new(ctx),
        btoken_ids: table::new(ctx),
    };

    registry
}
