#[test_only]
module steamm::test_registry;

use std::type_name::get;
use steamm::registry;
use sui::test_utils::{destroy};

public struct A has drop {}
public struct B has drop {}

public struct B_A has drop {}
public struct B_B has drop {}
public struct LpType has drop {}

public struct B_A2 has drop {}
public struct B_B2 has drop {}
public struct LpType2 has drop {}

public struct Quoter has drop {}
public struct Quoter2 has drop {}
public struct LendingMarket1 has drop {}
public struct LendingMarket2 has drop {}

#[test]
fun test_happy_registry_pool() {
    use sui::test_scenario::{Self};

    let owner = @0x26;
    let mut scenario = test_scenario::begin(owner);

    let mut registry = registry::init_for_testing(test_scenario::ctx(&mut scenario));

    let pool_id = object::id_from_address(scenario.ctx().fresh_object_address());

    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        100,
        get<Quoter>(),
    );

    let pool2_id = object::id_from_address(scenario.ctx().fresh_object_address());
    
    registry.register_pool(
        pool2_id,
        get<B_A2>(),
        get<B_B2>(),
        get<LpType2>(),
        100,
        get<Quoter>(),
    );

    destroy(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_happy_registry_bank() {
    use sui::test_scenario::{Self};

    let owner = @0x26;
    let mut scenario = test_scenario::begin(owner);

    let mut registry = registry::init_for_testing(test_scenario::ctx(&mut scenario));

    let bank_id = object::id_from_address(scenario.ctx().fresh_object_address());
    let lending_market_id = object::id_from_address(scenario.ctx().fresh_object_address());

    registry.register_bank(
        bank_id,
        get<A>(),
        get<B_A>(),
        lending_market_id,
        get<LendingMarket1>(),
    );

    let bank2_id = object::id_from_address(scenario.ctx().fresh_object_address());
    let lending_market2_id = object::id_from_address(scenario.ctx().fresh_object_address());
    
    registry.register_bank(
        bank2_id,
        get<A>(),
        get<B_A>(),
        lending_market2_id,
        get<LendingMarket2>(),
    );

    destroy(registry);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = registry::EDuplicatedPoolType)]
fun test_duplicated_registry_pool() {
    use sui::test_scenario::{Self};

    let owner = @0x26;
    let mut scenario = test_scenario::begin(owner);

    let mut registry = registry::init_for_testing(test_scenario::ctx(&mut scenario));

    let pool_id = object::id_from_address(scenario.ctx().fresh_object_address());

    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        100,
        get<Quoter>(),
    );

    scenario.next_tx(owner);
    
    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        100,
        get<Quoter>(),
    );

    destroy(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_registry_pool_ok_same_fee_different_quoter() {
    use sui::test_scenario::{Self};

    let owner = @0x26;
    let mut scenario = test_scenario::begin(owner);

    let mut registry = registry::init_for_testing(test_scenario::ctx(&mut scenario));

    let pool_id = object::id_from_address(scenario.ctx().fresh_object_address());

    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        100,
        get<Quoter>(),
    );

    scenario.next_tx(owner);
    
    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        100,
        get<Quoter2>(),
    );

    destroy(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_registry_pool_ok_different_fee_same_quoter() {
    use sui::test_scenario::{Self};

    let owner = @0x26;
    let mut scenario = test_scenario::begin(owner);

    let mut registry = registry::init_for_testing(test_scenario::ctx(&mut scenario));

    let pool_id = object::id_from_address(scenario.ctx().fresh_object_address());

    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        100,
        get<Quoter>(),
    );

    scenario.next_tx(owner);
    
    registry.register_pool(
        pool_id,
        get<B_A>(),
        get<B_B>(),
        get<LpType>(),
        200,
        get<Quoter>(),
    );

    destroy(registry);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = registry::EDuplicatedBankType)]
fun test_duplicated_registry_bank() {
    use sui::test_scenario::{Self};

    let owner = @0x26;
    let mut scenario = test_scenario::begin(owner);

    let mut registry = registry::init_for_testing(test_scenario::ctx(&mut scenario));

    let bank_id = object::id_from_address(scenario.ctx().fresh_object_address());
    let lending_market_id = object::id_from_address(scenario.ctx().fresh_object_address());

    registry.register_bank(
        bank_id,
        get<A>(),
        get<B_A>(),
        lending_market_id,
        get<LendingMarket1>(),
    );

    let bank2_id = object::id_from_address(scenario.ctx().fresh_object_address());
    
    registry.register_bank(
        bank2_id,
        get<A>(),
        get<B_A>(),
        lending_market_id,
        get<LendingMarket1>(),
    );

    destroy(registry);
    test_scenario::end(scenario);
}