#[test_only]
module steamm::script_tests;

use steamm::script_v1;
use suilend::test_sui::TEST_SUI;
use suilend::test_usdc::TEST_USDC;
use steamm::b_test_sui::B_TEST_SUI;
use steamm::b_test_usdc::B_TEST_USDC;
use steamm::cpmm::CpQuoter;
use steamm::global_admin;
use steamm::lp_usdc_sui::LP_USDC_SUI;
use steamm::pool::{Self, Pool, minimum_liquidity};
use steamm::test_utils::{test_setup_cpmm, reserve_args, e9};
use sui::clock::Clock;
use sui::coin;
use sui::test_scenario::{Self, Scenario, ctx};
use sui::test_utils::{destroy, assert_eq};
use suilend::lending_market::{LendingMarketOwnerCap, LendingMarket};
use suilend::lending_market_tests::{LENDING_MARKET, setup as suilend_setup};

const ADMIN: address = @0x10;
const POOL_CREATOR: address = @0x11;

#[test]
fun script_deposit() {
    let mut scenario = test_scenario::begin(ADMIN);

    // Create amm bank
    let global_admin = global_admin::init_for_testing(ctx(&mut scenario));
    let (
        mut pool,
        mut bank_a,
        mut bank_b,
        mut lending_market,
        lend_cap,
        prices,
        bag,
        clock,
    ) = test_setup_cpmm(100, 0, &mut scenario);

    bank_a.mock_min_token_block_size(10);
    bank_b.mock_min_token_block_size(10);

    bank_a.init_lending(
        &global_admin,
        &mut lending_market,
        8_000, // utilisation_bps
        1_000, // utilisation_bps
        ctx(&mut scenario),
    );

    // Init Pool
    test_scenario::next_tx(&mut scenario, POOL_CREATOR);

    // Deposit funds in AMM Pool
    let mut coin_a = coin::mint_for_testing<TEST_USDC>(500_000, scenario.ctx());
    let mut coin_b = coin::mint_for_testing<TEST_SUI>(500_000, scenario.ctx());
    
    let quote = script_v1::quote_deposit(
        &pool,
        &bank_a,
        &bank_b,
        &mut lending_market,
        500_000,
        500_000,
        &clock,
    );

    let lp_token = script_v1::deposit_liquidity(
        &mut pool,
        &mut bank_a,
        &mut bank_b,
        &mut lending_market,
        &mut coin_a,
        &mut coin_b,
        500_000,
        500_000,
        &clock,
        scenario.ctx()
    );

    assert_eq(quote.deposit_a(), 500_000);
    assert_eq(quote.deposit_b(), 500_000);
    assert_eq(coin_a.value(), 0);
    assert_eq(coin_b.value(), 0);

    destroy(coin_a);
    destroy(coin_b);
    destroy(lp_token);
    destroy(bank_a);
    destroy(bank_b);
    destroy(pool);
    destroy(global_admin);
    destroy(lending_market);
    destroy(lend_cap);
    destroy(prices);
    destroy(bag);
    destroy(clock);
    test_scenario::end(scenario);
}

#[test]
fun script_redeem() {
    let mut scenario = test_scenario::begin(ADMIN);

    // Create amm bank
    let global_admin = global_admin::init_for_testing(ctx(&mut scenario));
    let (
        mut pool,
        mut bank_a,
        mut bank_b,
        mut lending_market,
        lend_cap,
        prices,
        bag,
        clock,
    ) = test_setup_cpmm(100, 0, &mut scenario);

    bank_a.mock_min_token_block_size(10);
    bank_b.mock_min_token_block_size(10);

    bank_a.init_lending(
        &global_admin,
        &mut lending_market,
        8_000, // utilisation_bps
        1_000, // utilisation_bps
        ctx(&mut scenario),
    );

    // Init Pool
    test_scenario::next_tx(&mut scenario, POOL_CREATOR);

    // Deposit funds in AMM Pool
    let mut coin_a = coin::mint_for_testing<TEST_USDC>(500_000, scenario.ctx());
    let mut coin_b = coin::mint_for_testing<TEST_SUI>(500_000, scenario.ctx());

    let lp_token = script_v1::deposit_liquidity(
        &mut pool,
        &mut bank_a,
        &mut bank_b,
        &mut lending_market,
        &mut coin_a,
        &mut coin_b,
        500_000,
        500_000,
        &clock,
        scenario.ctx()
    );

    destroy(coin_a);
    destroy(coin_b);

    let quote = script_v1::quote_redeem(
        &pool,
        &bank_a,
        &bank_b,
        &mut lending_market,
        lp_token.value(),
        &clock
    );

    let (coin_a, coin_b) = script_v1::redeem_liquidity(
        &mut pool,
        &mut bank_a,
        &mut bank_b,
        &mut lending_market,
        lp_token,
        0,
        0,
        &clock,
        scenario.ctx()
    );

    assert_eq(quote.withdraw_a(), 500_000 - 1000);
    assert_eq(quote.withdraw_b(), 500_000 - 1000);
    assert_eq(coin_a.value(), quote.withdraw_a());
    assert_eq(coin_b.value(), quote.withdraw_b());

    destroy(coin_a);
    destroy(coin_b);
    destroy(bank_a);
    destroy(bank_b);
    destroy(pool);
    destroy(global_admin);
    destroy(lending_market);
    destroy(lend_cap);
    destroy(prices);
    destroy(bag);
    destroy(clock);
    test_scenario::end(scenario);
}

#[test]
fun script_swap() {
    let mut scenario = test_scenario::begin(ADMIN);

    // Create amm bank
    let global_admin = global_admin::init_for_testing(ctx(&mut scenario));
    let (
        mut pool,
        mut bank_a,
        mut bank_b,
        mut lending_market,
        lend_cap,
        prices,
        bag,
        clock,
    ) = test_setup_cpmm(100, 0, &mut scenario);

    bank_a.mock_min_token_block_size(10);
    bank_b.mock_min_token_block_size(10);

    bank_a.init_lending(
        &global_admin,
        &mut lending_market,
        8_000, // utilisation_bps
        1_000, // utilisation_bps
        ctx(&mut scenario),
    );

    // Init Pool
    test_scenario::next_tx(&mut scenario, POOL_CREATOR);

    // Deposit funds in AMM Pool
    let mut coin_a = coin::mint_for_testing<TEST_USDC>(500_000, scenario.ctx());
    let mut coin_b = coin::mint_for_testing<TEST_SUI>(500_000, scenario.ctx());

    let lp_token = script_v1::deposit_liquidity(
        &mut pool,
        &mut bank_a,
        &mut bank_b,
        &mut lending_market,
        &mut coin_a,
        &mut coin_b,
        500_000,
        500_000,
        &clock,
        scenario.ctx()
    );

    destroy(coin_a);
    destroy(coin_b);

    let quote = script_v1::quote_cpmm_swap(
        &pool,
        &bank_a,
        &bank_b,
        &mut lending_market,
        true,
        10_000,
        &clock
    );

    let mut coin_a = coin::mint_for_testing<TEST_USDC>(10_000, scenario.ctx());
    let mut coin_b = coin::zero<TEST_SUI>(scenario.ctx());

    script_v1::cpmm_swap(
        &mut pool,
        &mut bank_a,
        &mut bank_b,
        &mut lending_market,
        &mut coin_a,
        &mut coin_b,
        true,
        10_000,
        quote.amount_out(),
        &clock,
        scenario.ctx()
    );

    assert_eq(quote.amount_in(), 10_000);
    assert_eq(quote.amount_out(), coin_b.value());

    destroy(coin_a);
    destroy(coin_b);
    destroy(lp_token);
    destroy(bank_a);
    destroy(bank_b);
    destroy(pool);
    destroy(global_admin);
    destroy(lending_market);
    destroy(lend_cap);
    destroy(prices);
    destroy(bag);
    destroy(clock);
    test_scenario::end(scenario);
}