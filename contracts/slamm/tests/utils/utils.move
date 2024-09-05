#[test_only]
module slamm::test_utils {
    use slamm::cpmm::{Self, State as CpmmState, Hook as CpmmHook};
    use slamm::registry;
    use slamm::omm::{Self, Hook as OmmHook, State as OmmState, min_confidence_interval, max_staleness_seconds};
    use slamm::bank::{Self, Bank};
    use slamm::pool::{Pool};
    use slamm::oracle_wrapper::OracleInfo;
    use sui::test_utils::destroy;
    use sui::clock::Clock;
    use sui::test_scenario::{Self, ctx, Scenario};
    use sui::sui::SUI;
    use sui::bag::{Self, Bag};
    use std::type_name;
    use suilend::test_usdc::{TEST_USDC};
    use suilend::test_sui::{TEST_SUI};
    use suilend::lending_market::{Self, LENDING_MARKET};
    use suilend::reserve_config;
    use slamm::oracle_wrapper::{Self, OraclePrice, Price};
    use slamm::pyth::{Self as pyth_wrapper};

    public fun e9(amt: u64): u64 {
        1_000_000_000 * amt
    }

    public struct PoolWit has drop {}
    public struct COIN has drop {}

    #[test_only]
    public fun reserve_args(scenario: &mut Scenario): Bag {
        let mut bag = bag::new(test_scenario::ctx(scenario));
        bag::add(
            &mut bag, 
            type_name::get<TEST_USDC>(), 
            lending_market::new_args(100 * 1_000_000, reserve_config::default_reserve_config()),
        );
            
        bag::add(
            &mut bag, 
            type_name::get<TEST_SUI>(), 
            lending_market::new_args(100 * 1_000_000, reserve_config::default_reserve_config()),
        );

        bag
    }
    
    #[test_only]
    public fun reserve_args_2(scenario: &mut Scenario): Bag {
        let mut bag = bag::new(test_scenario::ctx(scenario));

        let reserve_args = {
            let config = reserve_config::default_reserve_config();
            let mut builder = reserve_config::from(&config, test_scenario::ctx(scenario));
            reserve_config::set_open_ltv_pct(&mut builder, 50);
            reserve_config::set_close_ltv_pct(&mut builder, 50);
            reserve_config::set_max_close_ltv_pct(&mut builder, 50);
            sui::test_utils::destroy(config);
            let config = reserve_config::build(builder, test_scenario::ctx(scenario));

            lending_market::new_args(100 * 1_000_000, config)
        };

        bag::add(
            &mut bag, 
            type_name::get<TEST_USDC>(), 
            reserve_args,
        );

        let reserve_args = {
            let config = reserve_config::default_reserve_config();
            lending_market::new_args(100 * 1_000_000_000, config)
        };

        bag::add(
            &mut bag, 
            type_name::get<TEST_SUI>(), 
            reserve_args,
        );

        bag
    }
    
    #[test_only]
    public fun new_for_testing(
        reserve_a: u64,
        reserve_b: u64,
        lp_supply: u64,
        swap_fee_bps: u64,
    ): (Pool<SUI, COIN, CpmmHook<PoolWit>, CpmmState>, Bank<LENDING_MARKET, SUI>, Bank<LENDING_MARKET, COIN>) {
        let mut scenario = test_scenario::begin(@0x0);
        let ctx = ctx(&mut scenario);

        let mut registry = registry::init_for_testing(ctx);

        let (mut pool, pool_cap) = cpmm::new<SUI, COIN, PoolWit>(
            PoolWit {},
            &mut registry,
            swap_fee_bps,
            ctx,
        );

        let mut bank_a = bank::create_bank<LENDING_MARKET, SUI>(&mut registry, ctx);
        let mut bank_b = bank::create_bank<LENDING_MARKET, COIN>(&mut registry, ctx);

        pool.mut_reserve_a(&mut bank_a, reserve_a, true);
        pool.mut_reserve_b(&mut bank_b, reserve_b, true);
        let lp = pool.lp_supply_mut_for_testing().increase_supply(lp_supply);

        destroy(registry);
        destroy(pool_cap);
        destroy(lp);

        test_scenario::end(scenario);

        (pool, bank_a, bank_b)
    }

    #[test_only]
    public fun set_clock_time(
        clock: &mut Clock,
    ) {
        clock.set_for_testing(1704067200000); //2024-01-01 00:00:00
    }
    
    #[test_only]
    public fun get_oracle<CoinType>(
        idx: u8,
        ctx: &mut TxContext,
    ): OracleInfo<CoinType> {
        let mut v = vector::empty<u8>();
        vector::push_back(&mut v, idx);

        let mut i = 1;
        while (i < 32) {
            vector::push_back(&mut v, 0);
            i = i + 1;
        };

        // pyth_wrapper::new_pyth_oracle_for_testing<CoinType>(v, some(price as u256), none(), clock, ctx)
        pyth_wrapper::new_pyth_oracle_for_testing<CoinType>(v, ctx)
    }
    
    #[test_only]
    public fun new_oracle_price<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
    ): OraclePrice<CoinType> {
        oracle_wrapper::new_oracle_price_for_testing<CoinType>(base, exponent, has_negative_exponent, min_confidence_interval(), max_staleness_seconds())
    }
    
    // #[test_only]
    // public fun zero_price_info<CoinType>(
    //     idx: u8,
    //     clock: &Clock,
    //     ctx: &mut TxContext,
    // ): OracleInfo<PriceInfoObject, CoinType> {
    //     let mut v = vector::empty<u8>();
    //     vector::push_back(&mut v, idx);

    //     let mut i = 1;
    //     while (i < 32) {
    //         vector::push_back(&mut v, 0);
    //         i = i + 1;
    //     };

    //     oracle_wrapper::new_oracle_for_testing<PriceInfoObject, CoinType>(v, some(0 as u256), none(), clock, ctx)
    // }

    public fun set_oracle_price_as_internal_for_testing<A, B, W: drop>(
        pool: &mut Pool<A, B, OmmHook<W>, OmmState>,
    ): (OraclePrice<A>, OraclePrice<B>) {
        let a = pool.total_funds_a();
        let b = pool.total_funds_b();
        
        let price_info_a = new_oracle_price<A>(a, 0, false);
        let price_info_b = new_oracle_price<B>(b, 0, false);
        
        (price_info_a, price_info_b)
    }
    
    public fun update_pool_oracle_price_ahead_of_trade<A, B, W: drop>(
        pool: &mut Pool<A, B, OmmHook<W>, OmmState>,
        oracle_a: Price<A>,
        oracle_b: Price<B>,
        amount_in: u64,
        a2b: bool,
        clock_bump_seconds: u64,
        clock: &mut Clock,
    ): (OraclePrice<A>, OraclePrice<B>) {
        bump_clock_seconds(clock, clock_bump_seconds);
        
        let (quote, _, _, _, _) = omm::quote_swap_for_testing(
            pool,
            &oracle_a,
            &oracle_b,
            amount_in,
            a2b, // a2b,
            clock,
        );

        // Set back clock to initial time
        let a = if (a2b) {pool.total_funds_a() + quote.amount_in()} else {pool.total_funds_a() - quote.amount_out()};
        let b = if (a2b) {pool.total_funds_b() - quote.amount_out()} else {pool.total_funds_b() + quote.amount_in()};

        let price_info_a = new_oracle_price<A>(a, 0, false);
        let price_info_b = new_oracle_price<B>(b, 0, false);
        
        (price_info_a, price_info_b)
    }
    
    public fun bump_clock_seconds(
        clock: &mut Clock,
        clock_bump_seconds: u64,
    ) {
        let clock_time = clock.timestamp_ms();
        clock.set_for_testing(clock_time + (clock_bump_seconds * 1_000));
    }
}
