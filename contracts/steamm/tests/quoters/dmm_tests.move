#[test_only]
module steamm::dmm_tests;

use std::debug::print;
use oracles::oracles::{Self, OracleRegistry};
use steamm::b_test_sui::B_TEST_SUI;
use steamm::b_test_usdc::B_TEST_USDC;
use steamm::bank::{Bank};
use steamm::lp_sui_usdc::LP_SUI_USDC;
use steamm::dummy_omm::{Self, OracleQuoter};
use steamm::stable::{Self as dmm, StableQuoter as DynQuoter};
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
use sui::random;

fun setup(
    fee_bps: u64,
    amplifier: u64,
    scenario: &mut Scenario,
): (
    Pool<B_TEST_SUI, B_TEST_USDC, OracleQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, DynQuoter, LP_SUI_USDC>,
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
    
    let dyn_pool = dmm::new<
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
        amplifier,
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

fun setup_all(
    fee_bps: u64,
    scenario: &mut Scenario,
): (
    Pool<B_TEST_SUI, B_TEST_USDC, OracleQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, DynQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, DynQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, DynQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, DynQuoter, LP_SUI_USDC>,
    Pool<B_TEST_SUI, B_TEST_USDC, DynQuoter, LP_SUI_USDC>,
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
    
    let dyn_pool1 = dmm::new<
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
        1,
        fee_bps,
        scenario.ctx(),
    );
    
    let treasury_cap_lp = coin::create_treasury_cap_for_testing(scenario.ctx());
    
    let dyn_pool10 = dmm::new<
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
        10,
        fee_bps,
        scenario.ctx(),
    );
    
    let treasury_cap_lp = coin::create_treasury_cap_for_testing(scenario.ctx());
    
    let dyn_pool100 = dmm::new<
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
        100,
        fee_bps,
        scenario.ctx(),
    );
    
    let treasury_cap_lp = coin::create_treasury_cap_for_testing(scenario.ctx());
    
    let dyn_pool1000 = dmm::new<
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
        1000,
        fee_bps,
        scenario.ctx(),
    );
    
    let treasury_cap_lp = coin::create_treasury_cap_for_testing(scenario.ctx());
    
    let dyn_pool8000 = dmm::new<
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
        8000,
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

    (pool, dyn_pool1, dyn_pool10, dyn_pool100, dyn_pool1000, dyn_pool8000, oracle_registry, price_state, lending_market, bank_sui, bank_usdc)
}

#[test]
fun test_dmm_positive_slippage_y2x() {
    let mut scenario = test_scenario::begin(@0x26);

    let (mut pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        1,
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

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(0, scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(10 * 1_000_000, scenario.ctx());

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
        false, // a2b
        10 * 1_000_000, // 10 USDC
        0,
        &clock,
        scenario.ctx(),
    );

    assert!(swap_result.amount_out() + swap_result.protocol_fees() + swap_result.pool_fees() == 3_333_333_333); // 3.3333 sui

    destroy(coin_sui);
    destroy(coin_usdc);

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(0, scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(10 * 1_000_000, scenario.ctx());

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

    let swap_result_2 = dmm::swap(
        &mut dyn_pool,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        &mut coin_sui,
        &mut coin_usdc,
        false, // a2b
        10 * 1_000_000, // 10 USDC
        0,
        &clock,
        scenario.ctx(),
    );

    assert!(swap_result.amount_out() > swap_result_2.amount_out(), 0);
    assert_eq(swap_result_2.amount_out() + swap_result_2.protocol_fees() + swap_result_2.pool_fees(), 3_327_783_945);

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

#[test]
fun test_dmm_positive_slippage_x2y() {
    let mut scenario = test_scenario::begin(@0x26);

    let (mut pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        1,
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

    let swap_result_2 = dmm::swap(
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
    assert_eq(swap_result_2.amount_out() + swap_result_2.protocol_fees() + swap_result_2.pool_fees(), 2_995_504); // 2.9955 USDC

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

#[test]
fun test_a2b_consecutive_price_decrease_amp_1() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        1,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_b2a_consecutive_price_increase_amp_1() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        1,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_a2b_consecutive_price_decrease_amp_10() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        10,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_b2a_consecutive_price_increase_amp_10() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        10,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_a2b_consecutive_price_decrease_amp_100() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_b2a_consecutive_price_increase_amp_100() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_a2b_consecutive_price_decrease_amp_1000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        1000,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_b2a_consecutive_price_increase_amp_1000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        1000,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_a2b_consecutive_price_decrease_amp_8000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        8000,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_b2a_consecutive_price_increase_amp_8000() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (pool, mut dyn_pool, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup(
        100,
        8000,
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

        let quote_result = dmm::quote_swap(
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

    dmm::swap(
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

#[test]
fun test_a2b_price_slippage_comparison() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (mut pool0, mut dyn_pool1, mut dyn_pool10, mut dyn_pool100, mut dyn_pool1000, mut dyn_pool8000, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup_all(
        100,
        &mut scenario,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(6 * e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(6 * e6(100_000), scenario.ctx());

    let (lp_coins, _) = pool0.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool1.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool10.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool100.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool1000.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool8000.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1000;
    let mut amount_in = e9(1_000);

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

    let res0 = dummy_omm::quote_swap(
        &pool0,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        amount_in,
        true, // a2b
        &clock,
    );

    let new_delta_out = res0.amount_out() + res0.output_fees().protocol_fees() + res0.output_fees().pool_fees();
    let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
    let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));
    let price0 = dy.div(dx);

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
        let res1 = dmm::quote_swap(
            &dyn_pool1,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );
        let new_delta_out = res1.amount_out() + res1.output_fees().protocol_fees() + res1.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));
        let price1 = dy.div(dx);
        
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
        let res10 = dmm::quote_swap(
            &dyn_pool10,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );
        let new_delta_out = res10.amount_out() + res10.output_fees().protocol_fees() + res10.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));
        let price10 = dy.div(dx);
        
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
        let res100 = dmm::quote_swap(
            &dyn_pool100,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );
        let new_delta_out = res100.amount_out() + res100.output_fees().protocol_fees() + res100.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));
        let price100 = dy.div(dx);
        
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
        let res1000 = dmm::quote_swap(
            &dyn_pool1000,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );
        let new_delta_out = res1000.amount_out() + res1000.output_fees().protocol_fees() + res1000.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));
        let price1000 = dy.div(dx);
        
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
        let res8000 = dmm::quote_swap(
            &dyn_pool8000,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            true, // a2b
            &clock,
        );
        let new_delta_out = res8000.amount_out() + res8000.output_fees().protocol_fees() + res8000.output_fees().pool_fees();
        let dx = fp64::from(amount_in as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(new_delta_out as u128).div(fp64::from(e6(1) as u128));
        let price8000 = dy.div(dx);

        assert!(price8000.lt(price0), 0);
        assert!(price1000.lte(price8000), 0);
        assert!(price100.lte(price1000), 0);
        assert!(price10.lte(price100), 0);
        assert!(price1.lte(price10), 0);

        amount_in = amount_in + e9(1_000);
        trades = trades - 1;
    };


    destroy(pool0);
    destroy(dyn_pool1);
    destroy(dyn_pool10);
    destroy(dyn_pool100);
    destroy(dyn_pool1000);
    destroy(dyn_pool8000);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}

#[test]
fun test_b2a_price_slippage_comparison() {
    let mut scenario = test_scenario::begin(@0x26);

    // Init Pool
    test_scenario::next_tx(&mut scenario, @0x26);
    let clock = clock::create_for_testing(scenario.ctx());
    let (mut pool0, mut dyn_pool1, mut dyn_pool10, mut dyn_pool100, mut dyn_pool1000, mut dyn_pool8000, oracle_registry, mut price_state, lending_market, bank_sui, bank_usdc) = setup_all(
        100,
        &mut scenario,
    );

    let mut coin_sui = coin::mint_for_testing<B_TEST_SUI>(6 * e9(100_000), scenario.ctx());
    let mut coin_usdc = coin::mint_for_testing<B_TEST_USDC>(6 * e6(100_000), scenario.ctx());

    let (lp_coins, _) = pool0.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool1.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool10.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool100.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool1000.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);
    
    let (lp_coins, _) = dyn_pool8000.deposit_liquidity(
        &mut coin_sui,
        &mut coin_usdc,
        e9(100_000),
        e6(100_000),
        scenario.ctx(),
    );
    destroy(lp_coins);

    destroy(coin_sui);
    destroy(coin_usdc);

    // Swap
    test_scenario::next_tx(&mut scenario, @0x26);

    price_state.update_price<TEST_USDC>(1, 0, &clock);
    price_state.update_price<TEST_SUI>(3, 0, &clock);

    let mut trades = 1000;
    let mut amount_in = e6(1_000);

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

    let res0 = dummy_omm::quote_swap(
        &pool0,
        &bank_sui,
        &bank_usdc,
        &lending_market,
        oracle_price_update_sui,
        oracle_price_update_usdc,
        amount_in,
        false, // a2b
        &clock,
    );

    let new_delta_out = res0.amount_out() + res0.output_fees().protocol_fees() + res0.output_fees().pool_fees();
    let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
    let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));
    let price0 = dy.div(dx);

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
        let res1 = dmm::quote_swap(
            &dyn_pool1,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );
        let new_delta_out = res1.amount_out() + res1.output_fees().protocol_fees() + res1.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));
        let price1 = dy.div(dx);
        
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
        let res10 = dmm::quote_swap(
            &dyn_pool10,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );
        let new_delta_out = res10.amount_out() + res10.output_fees().protocol_fees() + res10.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));
        let price10 = dy.div(dx);
        
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
        let res100 = dmm::quote_swap(
            &dyn_pool100,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );
        let new_delta_out = res100.amount_out() + res100.output_fees().protocol_fees() + res100.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));
        let price100 = dy.div(dx);
        
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
        let res1000 = dmm::quote_swap(
            &dyn_pool1000,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );
        let new_delta_out = res1000.amount_out() + res1000.output_fees().protocol_fees() + res1000.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));
        let price1000 = dy.div(dx);
        
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
        let res8000 = dmm::quote_swap(
            &dyn_pool8000,
            &bank_sui,
            &bank_usdc,
            &lending_market,
            oracle_price_update_sui,
            oracle_price_update_usdc,
            amount_in,
            false, // a2b
            &clock,
        );
        let new_delta_out = res8000.amount_out() + res8000.output_fees().protocol_fees() + res8000.output_fees().pool_fees();
        let dx = fp64::from(new_delta_out as u128).div(fp64::from(e9(1) as u128));
        let dy = fp64::from(amount_in as u128).div(fp64::from(e6(1) as u128));
        let price8000 = dy.div(dx);

        assert!(price8000.gt(price0), 0);
        assert!(price1000.gte(price8000), 0);
        assert!(price100.gte(price1000), 0);
        assert!(price10.gte(price100), 0);
        assert!(price1.gte(price10), 0);


        amount_in = amount_in + e6(1_000);
        trades = trades - 1;
    };


    destroy(pool0);
    destroy(dyn_pool1);
    destroy(dyn_pool10);
    destroy(dyn_pool100);
    destroy(dyn_pool1000);
    destroy(dyn_pool8000);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_sui);
    destroy(bank_usdc);
    test_scenario::end(scenario);
}


// #[test]
// #[expected_failure(abort_code = steamm::dummy_omm::EInvalidOracleIndex)]
// fun test_omm_fail_wrong_oracle() {
//     let mut scenario = test_scenario::begin(@0x26);

//     let (mut pool, oracle_registry, mut price_state, lending_market, bank_a, bank_b) = setup(
//         100,
//         &mut scenario,
//     );
//     let clock = clock::create_for_testing(scenario.ctx());

//     let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(1_000 * 1_000_000, scenario.ctx());
//     let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(20 * 1_000_000_000, scenario.ctx());

//     let (lp_coins, _) = pool.deposit_liquidity(
//         &mut coin_a,
//         &mut coin_b,
//         1_000 * 1_000_000,
//         20 * 1_000_000_000,
//         scenario.ctx(),
//     );

//     destroy(coin_a);
//     destroy(coin_b);

//     let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(6 * 1_000_000, scenario.ctx());
//     let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(0, scenario.ctx());

//     price_state.update_price<TEST_USDC>(1, 0, &clock);
//     let oracle_price_update_usdc = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_USDC>(&price_state),
//         0,
//         &clock,
//     );

//     price_state.update_price<TEST_SUI>(3, 0, &clock);
//     let oracle_price_update_sui = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_SUI>(&price_state),
//         1,
//         &clock,
//     );

//     // oracle updates are switched
//     let _swap_result = dummy_omm::swap(
//         &mut pool,
//         &bank_a,
//         &bank_b,
//         &lending_market,
//         oracle_price_update_sui,
//         oracle_price_update_usdc,
//         &mut coin_a,
//         &mut coin_b,
//         true, // a2b
//         6 * 1_000_000,
//         0,
//         &clock,
//         scenario.ctx(),
//     );

//     destroy(coin_a);
//     destroy(coin_b);
//     destroy(pool);
//     destroy(lp_coins);
//     destroy(oracle_registry);
//     destroy(clock);
//     destroy(price_state);
//     destroy(lending_market);
//     destroy(bank_a);
//     destroy(bank_b);

//     test_scenario::end(scenario);
// }

// #[test]
// #[expected_failure(abort_code = steamm::dummy_omm::EInvalidBankType)]
// fun test_omm_fail_not_a_btoken() {
//     let mut scenario = test_scenario::begin(@0x26);

//     let (
//         bank_a,
//         bank_b,
//         lending_market,
//         lend_cap,
//         price_state,
//         bag,
//         clock,
//         mut registry,
//         meta_b_usdc,
//         meta_b_sui,
//         meta_usdc,
//         meta_sui,
//         mut meta_lp_usdc_sui,
//         treasury_cap_lp,
//     ) = base_setup(option::none(), &mut scenario);

//     let (mut oracle_registry, admin_cap) = oracles::new_oracle_registry_for_testing(
//         oracles::new_oracle_registry_config(
//             60,
//             10,
//             60,
//             10,
//             scenario.ctx(),
//         ),
//         scenario.ctx(),
//     );

//     oracle_registry.add_pyth_oracle(
//         &admin_cap,
//         mock_pyth::get_price_obj<TEST_USDC>(&price_state),
//         scenario.ctx(),
//     );

//     oracle_registry.add_pyth_oracle(
//         &admin_cap,
//         mock_pyth::get_price_obj<TEST_SUI>(&price_state),
//         scenario.ctx(),
//     );

//     let pool = dummy_omm::new<
//         LENDING_MARKET,
//         TEST_USDC,
//         TEST_SUI,
//         TEST_USDC,
//         B_TEST_SUI,
//         LP_USDC_SUI,
//     >(
//         &mut registry,
//         &lending_market,
//         &meta_usdc,
//         &meta_sui,
//         &meta_usdc,
//         &meta_b_sui,
//         &mut meta_lp_usdc_sui,
//         treasury_cap_lp,
//         &oracle_registry,
//         0,
//         1,
//         100,
//         scenario.ctx(),
//     );

//     sui::test_utils::destroy(admin_cap);
//     sui::test_utils::destroy(meta_lp_usdc_sui);
//     sui::test_utils::destroy(meta_b_usdc);
//     sui::test_utils::destroy(meta_b_sui);
//     sui::test_utils::destroy(meta_usdc);
//     sui::test_utils::destroy(meta_sui);
//     sui::test_utils::destroy(registry);
//     sui::test_utils::destroy(lend_cap);
//     sui::test_utils::destroy(clock);
//     sui::test_utils::destroy(bag);
//     sui::test_utils::destroy(pool);
//     sui::test_utils::destroy(oracle_registry);
//     sui::test_utils::destroy(price_state);
//     sui::test_utils::destroy(lending_market);
//     sui::test_utils::destroy(bank_a);
//     sui::test_utils::destroy(bank_b);

//     test_scenario::end(scenario);
// }

// #[test]
// fun test_omm_quote_swap_insufficient_liquidity() {
//     let mut scenario = test_scenario::begin(@0x26);

//     let (mut pool, oracle_registry, mut price_state, lending_market, bank_a, bank_b) = setup(
//         100,
//         &mut scenario,
//     );
//     let clock = clock::create_for_testing(scenario.ctx());

//     // Add some initial liquidity to the pool
//     let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(100 * 1_000_000, scenario.ctx());
//     let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(10 * 1_000_000_000, scenario.ctx());

//     let (lp_coins, _) = pool.deposit_liquidity(
//         &mut coin_a,
//         &mut coin_b,
//         100 * 1_000,
//         100 * 1_000,
//         scenario.ctx(),
//     );

//     destroy(coin_a);
//     destroy(coin_b);

//     // Update oracle prices
//     price_state.update_price<TEST_USDC>(1, 0, &clock);
//     let oracle_price_update_usdc = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_USDC>(&price_state),
//         0,
//         &clock,
//     );

//     price_state.update_price<TEST_SUI>(3, 0, &clock);
//     let oracle_price_update_sui = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_SUI>(&price_state),
//         1,
//         &clock,
//     );

//     // Try to quote a swap with an amount much larger than pool liquidity
//     // Attempting to swap 1000 USDC when pool only has 100
//     let quote = dummy_omm::quote_swap(
//         &pool,
//         &bank_a,
//         &bank_b,
//         &lending_market,
//         oracle_price_update_usdc,
//         oracle_price_update_sui,
//         1000 * 1_000_000, // 1000 USDC, much larger than pool liquidity
//         true, // a2b (USDC to SUI)
//         &clock,
//     );

//     // Verify that amount_out is 0 due to insufficient liquidity
//     assert!(quote.amount_out() == 0, 0);
//     assert!(quote.output_fees().pool_fees() == 0, 0);
//     assert!(quote.output_fees().protocol_fees() == 0, 0);

//     price_state.update_price<TEST_USDC>(1, 0, &clock);
//     let oracle_price_update_usdc = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_USDC>(&price_state),
//         0,
//         &clock,
//     );

//     price_state.update_price<TEST_SUI>(3, 0, &clock);
//     let oracle_price_update_sui = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_SUI>(&price_state),
//         1,
//         &clock,
//     );

//     // Check the opposite direction as well - trying to swap more SUI than available
//     let quote = dummy_omm::quote_swap(
//         &pool,
//         &bank_a,
//         &bank_b,
//         &lending_market,
//         oracle_price_update_usdc,
//         oracle_price_update_sui,
//         100 * 1_000_000_000, // 100 SUI, much larger than pool liquidity
//         false, // b2a (SUI to USDC)
//         &clock,
//     );

//     // Verify that amount_out is 0 due to insufficient liquidity
//     assert!(quote.amount_out() == 0, 0);
//     assert!(quote.output_fees().pool_fees() == 0, 0);
//     assert!(quote.output_fees().protocol_fees() == 0, 0);

//     destroy(lp_coins);
//     destroy(pool);
//     destroy(oracle_registry);
//     destroy(clock);
//     destroy(price_state);
//     destroy(lending_market);
//     destroy(bank_a);
//     destroy(bank_b);

//     test_scenario::end(scenario);
// }

// #[test]
// #[expected_failure(abort_code = steamm::pool::ESwapOutputAmountIsZero)]
// fun test_omm_swap_insufficient_liquidity() {
//     let mut scenario = test_scenario::begin(@0x26);

//     let (mut pool, oracle_registry, mut price_state, lending_market, bank_a, bank_b) = setup(
//         100,
//         &mut scenario,
//     );
//     let clock = clock::create_for_testing(scenario.ctx());

//     // Add some initial liquidity to the pool - deliberately small amount
//     let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(100 * 1_000_000, scenario.ctx());
//     let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(10 * 1_000_000_000, scenario.ctx());

//     let (lp_coins, _) = pool.deposit_liquidity(
//         &mut coin_a,
//         &mut coin_b,
//         100 * 1_000_000,
//         10 * 1_000_000_000,
//         scenario.ctx(),
//     );

//     destroy(coin_a);
//     destroy(coin_b);

//     // Update oracle prices
//     price_state.update_price<TEST_USDC>(1, 0, &clock);
//     let oracle_price_update_usdc = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_USDC>(&price_state),
//         0,
//         &clock,
//     );

//     price_state.update_price<TEST_SUI>(3, 0, &clock);
//     let oracle_price_update_sui = oracle_registry.get_pyth_price(
//         mock_pyth::get_price_obj<TEST_SUI>(&price_state),
//         1,
//         &clock,
//     );

//     // Create coins for swapping - attempting to swap more than the pool has
//     let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(1000 * 1_000_000, scenario.ctx()); // 1000 USDC
//     let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(0, scenario.ctx());

//     // This should fail with EInsufficientLiquidity (or similar error)
//     // as we're trying to swap 1000 USDC when pool only has 100 USDC
//     let _swap_result = dummy_omm::swap(
//         &mut pool,
//         &bank_a,
//         &bank_b,
//         &lending_market,
//         oracle_price_update_usdc,
//         oracle_price_update_sui,
//         &mut coin_a,
//         &mut coin_b,
//         true, // a2b (USDC to SUI)
//         1000 * 1_000_000, // 1000 USDC, much larger than pool liquidity
//         0, // min amount out - doesn't matter as we expect failure
//         &clock,
//         scenario.ctx(),
//     );

//     destroy(coin_a);
//     destroy(coin_b);
//     destroy(lp_coins);
//     destroy(pool);
//     destroy(oracle_registry);
//     destroy(clock);
//     destroy(price_state);
//     destroy(lending_market);
//     destroy(bank_a);
//     destroy(bank_b);

//     test_scenario::end(scenario);
// }