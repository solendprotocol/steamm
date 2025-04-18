#[test_only]
module steamm::omm_tests_2;

use oracles::oracles::{Self, OracleRegistry};
use steamm::b_test_sui::B_TEST_SUI;
use steamm::b_test_usdc::B_TEST_USDC;
use steamm::bank::{Bank};
use steamm::lp_sui_usdc::LP_SUI_USDC;
use steamm::dummy_omm::{Self, OracleQuoter as NaiveOracleQuoter};
use steamm::omm::{Self, OracleQuoter};
use steamm::pool::{Pool};
use steamm::test_utils::{base_setup_2};
use sui::clock::{Self};
use sui::coin;
use sui::test_scenario::{Self, Scenario};
use sui::test_utils::{destroy, assert_eq};
use suilend::lending_market::{LendingMarket};
use suilend::lending_market_tests::{LENDING_MARKET};
use suilend::mock_pyth::{Self, PriceState};
use suilend::test_sui::{TEST_SUI};
use suilend::test_usdc::{TEST_USDC};
use steamm::test_utils::{e9, e6};
use steamm::fixed_point64::{Self as fp64};

fun setup(
    fee_bps: u64,
    scenario: &mut Scenario,
): (
    Pool<B_TEST_SUI, B_TEST_USDC, NaiveOracleQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, OracleQuoter, LP_SUI_USDC>,
    OracleRegistry,
    PriceState,
    LendingMarket<LENDING_MARKET>,
    Bank<LENDING_MARKET, TEST_SUI, B_TEST_SUI>,
    Bank<LENDING_MARKET, TEST_USDC, B_TEST_USDC>,
) {
    let (
        bank_usdc,
        bank_sui,
        lending_market,
        lend_cap,
        price_state,
        bag,
        clock,
        mut registry,
        meta_b_usdc,
        meta_b_sui,
        meta_usdc,
        meta_sui,
        mut meta_lp_sui_usdc,
        treasury_cap_lp,
    ) = base_setup_2(option::none(), scenario);

    let (mut oracle_registry, admin_cap) = oracles::new_oracle_registry_for_testing(
        oracles::new_oracle_registry_config(
            60,
            10,
            60,
            10,
            scenario.ctx(),
        ),
        scenario.ctx(),
    );

    oracle_registry.add_pyth_oracle(
        &admin_cap,
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        scenario.ctx(),
    );

    oracle_registry.add_pyth_oracle(
        &admin_cap,
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        scenario.ctx(),
    );

    let pool = dummy_omm::new<
        LENDING_MARKET,
        TEST_SUI,
        TEST_USDC,
        B_TEST_SUI,
        B_TEST_USDC,
        LP_SUI_USDC,
    >(
        &mut registry,
        &lending_market,
        &meta_sui,
        &meta_usdc,
        &meta_b_sui,
        &meta_b_usdc,
        &mut meta_lp_sui_usdc,
        treasury_cap_lp,
        &oracle_registry,
        1,
        0,
        fee_bps,
        scenario.ctx(),
    );

    let treasury_cap_lp = coin::create_treasury_cap_for_testing(scenario.ctx());
    
    let dyn_pool = omm::new<
        LENDING_MARKET,
        TEST_SUI,
        TEST_USDC,
        B_TEST_SUI,
        B_TEST_USDC,
        LP_SUI_USDC,
    >(
        &mut registry,
        &lending_market,
        &meta_sui,
        &meta_usdc,
        &meta_b_sui,
        &meta_b_usdc,
        &mut meta_lp_sui_usdc,
        treasury_cap_lp,
        &oracle_registry,
        1,
        0,
        fee_bps,
        scenario.ctx(),
    );

    sui::test_utils::destroy(admin_cap);
    sui::test_utils::destroy(meta_lp_sui_usdc);
    sui::test_utils::destroy(meta_b_usdc);
    sui::test_utils::destroy(meta_b_sui);
    sui::test_utils::destroy(meta_usdc);
    sui::test_utils::destroy(meta_sui);
    sui::test_utils::destroy(registry);
    sui::test_utils::destroy(lend_cap);
    sui::test_utils::destroy(clock);
    sui::test_utils::destroy(bag);

    (pool, dyn_pool, oracle_registry, price_state, lending_market, bank_sui, bank_usdc)
}

/// Checks that the dynamic fee quotation is less than the naive oracle implementation
/// It should ALWAYS give a worst price than the given oracle price
#[test]
fun test_dmm_positive_slippage_x2y() {
    let mut scenario = test_scenario::begin(@0x26);

    let (mut pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );
    let clock = clock::create_for_testing(scenario.ctx());

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(2_000 * 1_000_000_000, scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(2_000 * 1_000_000, scenario.ctx());

    let (lp_coins, _) = pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        1_000 * 1_000_000_000,
        1_000 * 1_000_000,
        scenario.ctx(),
    );
    
    let (lp_coins_2, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        1_000 * 1_000_000_000,
        1_000 * 1_000_000,
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(1 * 1_000_000_000, scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(0, scenario.ctx());

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );

    price_state.update_price<TEST_SUI>(3, 0, &clock);
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let swap_result = dummy_omm::swap(
        &mut pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        1 * 1_000_000_000, // 10 SUI
        0,
        &clock,
        scenario.ctx(),
    );

    assert_eq(swap_result.amount_out() + swap_result.protocol_fees() + swap_result.pool_fees(), 3_000_000); // 3 USDC

    destroy(coin_sui);
    destroy(coin_usdc);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(1 * 1_000_000_000, scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(0, scenario.ctx());

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );

    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let swap_result_2 = omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        1 * 1_000_000_000, // 10 USDC
        0,
        &clock,
        scenario.ctx(),
    );

    assert!(swap_result.amount_out() > swap_result_2.amount_out(), 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(pool);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(lp_coins_2);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);

    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_a2b_consecutive_price_decrease_amp_1() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e9(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.lt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e9(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        amount_in,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        0,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (_, reserve_usdc) = dyn_pool.balance_amounts();

    assert!(reserve_usdc > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_b2a_consecutive_price_increase_amp_1() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e6(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.gt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e6(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        0,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        amount_in,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        false, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (reserve_sui, _) = dyn_pool.balance_amounts();

    assert!(reserve_sui > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_a2b_consecutive_price_decrease_amp_10() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e9(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.lt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e9(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        amount_in,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        0,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (_, reserve_usdc) = dyn_pool.balance_amounts();

    assert!(reserve_usdc > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_b2a_consecutive_price_increase_amp_10() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e6(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.gt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e6(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        0,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        amount_in,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        false, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (reserve_sui, _) = dyn_pool.balance_amounts();

    assert!(reserve_sui > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_a2b_consecutive_price_decrease_amp_100() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e9(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.lt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e9(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        amount_in,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        0,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (_, reserve_usdc) = dyn_pool.balance_amounts();

    assert!(reserve_usdc > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_b2a_consecutive_price_increase_amp_100() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e6(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.gt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e6(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        0,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        amount_in,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        false, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (reserve_sui, _) = dyn_pool.balance_amounts();

    assert!(reserve_sui > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_a2b_consecutive_price_decrease_amp_1000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e9(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.lt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e9(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        amount_in,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        0,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (_, reserve_usdc) = dyn_pool.balance_amounts();

    assert!(reserve_usdc > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_b2a_consecutive_price_increase_amp_1000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e6(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.gt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e6(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        0,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        amount_in,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        false, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (reserve_sui, _) = dyn_pool.balance_amounts();

    assert!(reserve_sui > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_a2b_consecutive_price_decrease_amp_8000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e9(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.lt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e9(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        amount_in,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        0,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        true, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (_, reserve_usdc) = dyn_pool.balance_amounts();

    assert!(reserve_usdc > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

/// Checks that the dynamic fee quotation progressively gives a worse quote
/// as the trade size, and therefore imbalance, increases
#[test]
fun test_b2a_consecutive_price_increase_amp_8000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        &mut scenario,
    );

    destroy(pool);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(e6(100_000), scenario.ctx());

    let (lp_coins, _) = dyn_pool.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1_000;
    let mut amount_in = e6(1_000);
    let mut delta_out = 18_446_744_073_709_551_615; // Max value for u64
    let mut price = fp64::from(3 as u128);

    while (trades > 0) {
        let oracle_price_update_usdc = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            0,
            &clock,
        );

        let oracle_price_update_sui = oracle_registry.get_pyth_price(
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            1,
            &clock,
        );

        let quote_result = omm::quote_swap(
            &dyn_pool,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );

        let new_delta_out = quote_result.amount_out() + quote_result.output_fees().protocol_fees() + quote_result.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));

        let new_price = dy.div(dx);

        if (delta_out == 0) {
            assert!(new_delta_out == 0);
        } else {
            assert!(new_price.gt(price), 0);
        };
        
        delta_out = new_delta_out;
        price = new_price;

        amount_in = amount_in + e6(1_000);
        trades = trades - 1;
    };

    let oracle_price_update_usdc = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_USDC>(&price_state),
        0,
        &clock,
    );
    let oracle_price_update_sui = oracle_registry.get_pyth_price(
        mock_pyth::get_price_obj<TEST_SUI>(&price_state),
        1,
        &clock,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(
        0,
        scenario.ctx(),
    );
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(
        amount_in,
        scenario.ctx(),
    );

    omm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        false, // a2b
        amount_in,
        0,
        &clock,
        scenario.ctx(),
    );
    let (reserve_sui, _) = dyn_pool.balance_amounts();

    assert!(reserve_sui > 0, 0);

    destroy(coin_sui);
    destroy(coin_usdc);
    destroy(dyn_pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}
