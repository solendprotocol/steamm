#[test_only]
module steamm::omm_tests;

use oracles::oracles::{Self, OracleRegistry, OraclePriceUpdate};
use steamm::b_test_sui::B_TEST_SUI;
use steamm::b_test_usdc::B_TEST_USDC;
use steamm::bank::{Self, Bank};
use steamm::cpmm::CpQuoter;
use steamm::lp_usdc_sui::LP_USDC_SUI;
use steamm::omm::{Self, OracleQuoter};
use steamm::pool::{Self, Pool, minimum_liquidity};
use steamm::test_utils::{test_setup_cpmm, reserve_args, e9, setup_currencies, base_setup};
use sui::clock::{Self, Clock};
use sui::coin;
use sui::test_scenario::{Self, Scenario, ctx};
use sui::test_utils::{destroy, assert_eq};
use suilend::lending_market::{LendingMarketOwnerCap, LendingMarket};
use suilend::lending_market_tests::{LENDING_MARKET, setup as suilend_setup};
use suilend::mock_pyth::{Self, PriceState};
use suilend::test_sui::{Self, TEST_SUI};
use suilend::test_usdc::{Self, TEST_USDC};

fun setup(
    fee_bps: u64,
    scenario: &mut Scenario,
): (
    Pool<B_TEST_USDC, B_TEST_SUI, OracleQuoter, LP_USDC_SUI>,
    OracleRegistry,
    PriceState,
    LendingMarket<LENDING_MARKET>,
    Bank<LENDING_MARKET, TEST_USDC, B_TEST_USDC>,
    Bank<LENDING_MARKET, TEST_SUI, B_TEST_SUI>,
) {
    let (
        bank_a,
        bank_b,
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
        mut meta_lp_usdc_sui,
        treasury_cap_lp,
    ) = base_setup(option::none(), scenario);

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

    let pool = omm::new<
        LENDING_MARKET,
        TEST_USDC,
        TEST_SUI,
        B_TEST_USDC,
        B_TEST_SUI,
        LP_USDC_SUI,
    >(
        &mut registry,
        &lending_market,
        &meta_usdc,
        &meta_sui,
        &meta_b_usdc,
        &meta_b_sui,
        &mut meta_lp_usdc_sui,
        treasury_cap_lp,
        &oracle_registry,
        0,
        1,
        fee_bps,
        scenario.ctx(),
    );

    sui::test_utils::destroy(admin_cap);
    sui::test_utils::destroy(meta_lp_usdc_sui);
    sui::test_utils::destroy(meta_b_usdc);
    sui::test_utils::destroy(meta_b_sui);
    sui::test_utils::destroy(meta_usdc);
    sui::test_utils::destroy(meta_sui);
    sui::test_utils::destroy(registry);
    sui::test_utils::destroy(lend_cap);
    sui::test_utils::destroy(clock);
    sui::test_utils::destroy(bag);

    (pool, oracle_registry, price_state, lending_market, bank_a, bank_b)
}

#[test]
fun test_omm_basic() {
    let mut scenario = test_scenario::begin(@0x26);

    let (mut pool, oracle_registry, mut price_state, lending_market, bank_a, bank_b) = setup(
        100,
        &mut scenario,
    );
    let clock = clock::create_for_testing(scenario.ctx());

    let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(1_000 * 1_000_000, scenario.ctx());
    let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(20 * 1_000_000_000, scenario.ctx());

    let (lp_coins, _) = pool.deposit_liquidity(
        &mut coin_a,
        &mut coin_b,
        1_000 * 1_000_000,
        20 * 1_000_000_000,
        scenario.ctx(),
    );

    destroy(coin_a);
    destroy(coin_b);

    let mut coin_a = coin::mint_for_testing<B_TEST_USDC>(6 * 1_000_000, scenario.ctx());
    let mut coin_b = coin::mint_for_testing<B_TEST_SUI>(0, scenario.ctx());

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

    let swap_result = omm::swap(
        &mut pool,
        &bank_a,
        &bank_b,
        &lending_market,
        &mut coin_a,
        &mut coin_b,
        oracle_price_update_usdc,
        oracle_price_update_sui,
        true, // a2b
        6 * 1_000_000,
        0,
        &clock,
        scenario.ctx(),
    );

    std::debug::print(&swap_result);

    destroy(coin_a);
    destroy(coin_b);
    destroy(pool);
    destroy(lp_coins);
    destroy(oracle_registry);
    destroy(clock);
    destroy(price_state);
    destroy(lending_market);
    destroy(bank_a);
    destroy(bank_b);

    test_scenario::end(scenario);
}