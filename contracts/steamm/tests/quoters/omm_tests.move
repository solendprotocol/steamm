#[test_only]
module steamm::omm_tests {
    use oracles::oracles::{Self, OracleRegistry, OraclePriceUpdate};
    use steamm::cpmm::CpQuoter;
    use steamm::global_admin;
    use steamm::lp_usdc_sui::LP_USDC_SUI;
    use steamm::omm::{Self, OracleQuoter};
    use steamm::pool::{Self, Pool, minimum_liquidity};
    use steamm::registry;
    use steamm::test_utils::{test_setup_cpmm, reserve_args, e9, setup_currencies};
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
    ): (Pool<TEST_USDC, TEST_SUI, OracleQuoter, LP_USDC_SUI>, OracleRegistry, PriceState) {
        let mut registry = registry::init_for_testing(scenario.ctx());

        let (
            meta_usdc,
            meta_sui,
            mut meta_lp_usdc_sui,
            meta_b_usdc,
            meta_b_sui,
            treasury_cap_lp,
            treasury_cap_b_usdc,
            treasury_cap_b_sui,
        ) = setup_currencies(scenario);

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

        let mut price_state = mock_pyth::init_state(scenario.ctx());
        mock_pyth::register<TEST_USDC>(&mut price_state, scenario.ctx());
        mock_pyth::register<TEST_SUI>(&mut price_state, scenario.ctx());

        let oracle_index_a = oracle_registry.add_pyth_oracle(
            &admin_cap,
            mock_pyth::get_price_obj<TEST_USDC>(&price_state),
            scenario.ctx(),
        );

        let oracle_index_b = oracle_registry.add_pyth_oracle(
            &admin_cap,
            mock_pyth::get_price_obj<TEST_SUI>(&price_state),
            scenario.ctx(),
        );

        let pool = omm::new<TEST_USDC, TEST_SUI, LP_USDC_SUI>(
            &mut registry,
            fee_bps,
            &meta_usdc,
            &meta_sui,
            &mut meta_lp_usdc_sui,
            treasury_cap_lp,
            &oracle_registry,
            oracle_index_a,
            oracle_index_b,
            scenario.ctx(),
        );

        sui::test_utils::destroy(admin_cap);
        sui::test_utils::destroy(meta_usdc);
        sui::test_utils::destroy(meta_sui);
        sui::test_utils::destroy(meta_lp_usdc_sui);
        sui::test_utils::destroy(meta_b_usdc);
        sui::test_utils::destroy(meta_b_sui);
        sui::test_utils::destroy(treasury_cap_b_usdc);
        sui::test_utils::destroy(treasury_cap_b_sui);
        sui::test_utils::destroy(registry);

        (pool, oracle_registry, price_state)
    }

    #[test]
    fun test_omm_basic() {
        let mut scenario = test_scenario::begin(@0x26);

        let (mut pool, oracle_registry, mut price_state) = setup(100, &mut scenario);
        let clock = clock::create_for_testing(scenario.ctx());

        let mut coin_a = coin::mint_for_testing<TEST_USDC>(1_000 * 1_000_000, scenario.ctx());
        let mut coin_b = coin::mint_for_testing<TEST_SUI>(20 * 1_000_000_000, scenario.ctx());

        let (lp_coins, _) = pool.deposit_liquidity(
            &mut coin_a,
            &mut coin_b,
            1_000 * 1_000_000,
            20 * 1_000_000_000,
            scenario.ctx(),
        );

        destroy(coin_a);
        destroy(coin_b);

        let mut coin_a = coin::mint_for_testing<TEST_USDC>(6 * 1_000_000, scenario.ctx());
        let mut coin_b = coin::mint_for_testing<TEST_SUI>(0, scenario.ctx());

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

        test_scenario::end(scenario);
    }
}
