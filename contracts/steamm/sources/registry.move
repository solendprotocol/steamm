/// Top level object that tracks all AMM pools.
/// Ensures that there is only one AMM pool of each type.
module steamm::registry;

use std::type_name::TypeName;
use sui::vec_set::{Self, VecSet};
use steamm::global_admin::GlobalAdmin;
use steamm::version::{Self, Version};
use steamm::events::emit_event;
use sui::bag::{Self, Bag};

// ===== Constants =====

const CURRENT_VERSION: u16 = 1;

public struct BankKey has copy, store, drop { lending_market_id: ID, coin_type: TypeName }
public struct PoolKey has copy, store, drop { coin_type_a: TypeName, coin_type_b: TypeName }

// ===== Errors =====

const EDuplicatedBankType: u64 = 1;

public struct Registry has key {
    id: UID,
    version: Version,
    banks: Bag,
    pools: Bag,
}

public struct BankData has store {
    bank_id: ID,
    btoken_type: TypeName,
    lending_market_type: TypeName,
}

public struct PoolData has copy, drop, store {
    pool_id: ID,
    quoter_type: TypeName,
    swap_fee_bps: u64,
    lp_token_type: TypeName,
}


fun init(ctx: &mut TxContext) {
    let registry = Registry {
        id: object::new(ctx),
        version: version::new(CURRENT_VERSION),
        banks: bag::new(ctx),
        pools: bag::new(ctx),
    };

    transfer::share_object(registry);
}

public(package) fun register_pool(
    registry: &mut Registry,
    pool_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    lp_token_type: TypeName,
    swap_fee_bps: u64,
    quoter_type: TypeName,
) {
    registry.version.assert_version_and_upgrade(CURRENT_VERSION);

    let event = NewPoolResult {
        pool_id,
        coin_type_a,
        coin_type_b,
        lp_token_type,
        swap_fee_bps,
        quoter_type,
    };

    let key = PoolKey {
        coin_type_a,
        coin_type_b,
    };

    if (!registry.pools.contains(key)) {
        registry.pools.add(key, vec_set::empty<PoolData>());
    };

    let pools: &mut VecSet<PoolData> = registry.pools.borrow_mut(key);
    
    pools.insert(PoolData {
        pool_id,
        quoter_type,
        swap_fee_bps,
        lp_token_type,
    });

    emit_event(event);
}

public(package) fun register_bank(
    registry: &mut Registry,
    bank_id: ID,
    coin_type: TypeName,
    btoken_type: TypeName,
    lending_market_id: ID,
    lending_market_type: TypeName,
) {
    registry.version.assert_version_and_upgrade(CURRENT_VERSION);

    let event = NewBankEvent {
        bank_id,
        coin_type,
        btoken_type,
        lending_market_id,
        lending_market_type,
    };

    let key = BankKey {
        lending_market_id: lending_market_id,
        coin_type: coin_type,
    };

    assert!(!registry.banks.contains(key), EDuplicatedBankType);

    registry.banks.add(key, BankData {
        bank_id,
        btoken_type,
        lending_market_type,
    });

    emit_event(event);
}

// ===== Events =====

public struct NewPoolResult has copy, drop, store {
    pool_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    quoter_type: TypeName,
    swap_fee_bps: u64,
    lp_token_type: TypeName,
}

public struct NewBankEvent has copy, drop, store {
    bank_id: ID,
    coin_type: TypeName,
    btoken_type: TypeName,
    lending_market_id: ID,
    lending_market_type: TypeName,
}

// ===== Versioning =====

entry fun migrate(registry: &mut Registry, _admin: &GlobalAdmin) {
    registry.version.migrate_(CURRENT_VERSION);
}

// ===== Tests =====

#[test_only]
public fun init_for_testing(ctx: &mut TxContext): Registry {
    let registry = Registry {
        id: object::new(ctx),
        version: version::new(CURRENT_VERSION),
        pools: bag::new(ctx),
        banks: bag::new(ctx),
    };

    registry
}
