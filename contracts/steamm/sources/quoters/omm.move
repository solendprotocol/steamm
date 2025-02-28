/// Oracle AMM Hook implementation. This quoter can only be initialized with btoken types.
module steamm::omm {
    use oracles::oracles::{OracleRegistry, OraclePriceUpdate};
    use oracles::oracle_decimal::{OracleDecimal};
    use steamm::math::safe_mul_div;
    use steamm::pool::{Self, Pool, SwapResult, assert_liquidity};
    use steamm::quote::SwapQuote;
    use steamm::registry::Registry;
    use steamm::version::{Self, Version};
    use sui::clock::Clock;
    use sui::coin::{Coin, TreasuryCap, CoinMetadata};
    use suilend::decimal::{Decimal, Self};
    use suilend::lending_market::LendingMarket;
    use std::type_name::{TypeName, Self};
    use steamm::bank::Bank;
    // ===== Constants =====
    const CURRENT_VERSION: u16 = 1;

    // ===== Errors =====
    const EInvalidBankType: u64 = 0;
    const EInvalidOracleIndex: u64 = 1;
    const EInvalidOracleRegistry: u64 = 2;

    /// Oracle AMM specific state. We do not store the invariant,
    /// instead we compute it at runtime.
    public struct OracleQuoter has store {
        version: Version,

        // oracle params
        oracle_registry_id: ID,
        oracle_index_a: u64,
        oracle_index_b: u64,

        // coin info
        decimals_a: u8,
        decimals_b: u8,
    }

    // ===== Public Methods =====
    public fun new<P, A, B, B_A, B_B, LpType: drop>(
        registry: &mut Registry,
        lending_market: &LendingMarket<P>,
        meta_a: &CoinMetadata<A>,
        meta_b: &CoinMetadata<B>,
        meta_b_a: &CoinMetadata<B_A>,
        meta_b_b: &CoinMetadata<B_B>,
        meta_lp: &mut CoinMetadata<LpType>,
        lp_treasury: TreasuryCap<LpType>,
        oracle_registry: &OracleRegistry,
        oracle_index_a: u64,
        oracle_index_b: u64,
        swap_fee_bps: u64,
        ctx: &mut TxContext,
    ): Pool<B_A, B_B, OracleQuoter, LpType> {
        // ensure that this quoter can only be initialized with btoken types
        let bank_data_a = registry.get_bank_data<A>(object::id(lending_market));
        assert!(type_name::get<B_A>() == bank_data_a.btoken_type(), EInvalidBankType);

        let bank_data_b = registry.get_bank_data<B>(object::id(lending_market));
        assert!(type_name::get<B_B>() == bank_data_b.btoken_type(), EInvalidBankType);

        let quoter = OracleQuoter {
            version: version::new(CURRENT_VERSION),
            oracle_registry_id: object::id(oracle_registry),
            oracle_index_a,
            oracle_index_b,
            decimals_a: meta_a.get_decimals(),
            decimals_b: meta_b.get_decimals(),
        };

        pool::new<B_A, B_B, OracleQuoter, LpType>(
            registry,
            swap_fee_bps,
            quoter,
            meta_b_a,
            meta_b_b,
            meta_lp,
            lp_treasury,
            ctx,
        )
    }

    public fun swap<P, A, B, B_A, B_B, LpType: drop>(
        pool: &mut Pool<B_A, B_B, OracleQuoter, LpType>,
        bank_a: &Bank<P, A, B_A>,
        bank_b: &Bank<P, B, B_B>,
        lending_market: &LendingMarket<P>,
        coin_a: &mut Coin<B_A>,
        coin_b: &mut Coin<B_B>,
        oracle_price_update_a: OraclePriceUpdate,
        oracle_price_update_b: OraclePriceUpdate,
        a2b: bool,
        amount_in: u64,
        min_amount_out: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SwapResult {
        pool.quoter_mut().version.assert_version_and_upgrade(CURRENT_VERSION);

        assert!(oracle_price_update_a.oracle_registry_id() == pool.quoter().oracle_registry_id, EInvalidOracleRegistry);
        assert!(oracle_price_update_a.oracle_index() == pool.quoter().oracle_index_a, EInvalidOracleIndex);

        assert!(oracle_price_update_b.oracle_registry_id() == pool.quoter().oracle_registry_id, EInvalidOracleRegistry);
        assert!(oracle_price_update_b.oracle_index() == pool.quoter().oracle_index_b, EInvalidOracleIndex);
        let quote = quote_swap(
            pool, 
            bank_a,
            bank_b,
            lending_market,
            amount_in, 
            oracle_price_update_a,
            oracle_price_update_b,
            clock,
            a2b,
        );

        std::debug::print(&quote);

        let response = pool.swap(
            coin_a,
            coin_b,
            quote,
            min_amount_out,
            ctx,
        );

        response
    }

    public(package) fun quote_swap<P, A, B, B_A, B_B, LpType: drop>(
        pool: &Pool<B_A, B_B, OracleQuoter, LpType>,
        bank_a: &Bank<P, A, B_A>,
        bank_b: &Bank<P, B, B_B>,
        lending_market: &LendingMarket<P>,
        amount_in: u64,
        oracle_price_update_a: OraclePriceUpdate,
        oracle_price_update_b: OraclePriceUpdate,
        clock: &Clock,
        a2b: bool,
    ): SwapQuote {
        let quoter = pool.quoter();

        let decimals_a = quoter.decimals_a;
        let decimals_b = quoter.decimals_b; 

        let price_a = oracle_decimal_to_decimal(oracle_price_update_a.price());
        let price_b = oracle_decimal_to_decimal(oracle_price_update_b.price());

        let (total_funds_a, total_btoken_supply_a) = bank_a.get_btoken_ratio(lending_market, clock);
        let (total_funds_b, total_btoken_supply_b) = bank_b.get_btoken_ratio(lending_market, clock);


        let amount_out: u64 = if (a2b) {
            // 1. convert from btoken_a to regular token_a
            let a_in = decimal::from(amount_in)
                .mul(total_funds_a)
                .div(total_btoken_supply_a);

            // 2. convert to dollar value
            let dollar_value = a_in
                .div(decimal::from(10u64.pow(decimals_a as u8)))
                .mul(price_a);

            // 3. convert to b
            let b_out = dollar_value
                .div(price_b)
                .mul(decimal::from(10u64.pow(decimals_b as u8)));

            // 4. convert to btoken_b
            let b_b_out = b_out
                .mul(total_btoken_supply_b)
                .div(total_funds_b)
                .floor();

            b_b_out
        } else {
            // 1. convert from btoken_b to regular token_b
            let b_in = decimal::from(amount_in)
                .mul(total_funds_b)
                .div(total_btoken_supply_b);

            // 2. convert to dollar value
            let dollar_value = b_in
                .div(decimal::from(10u64.pow(decimals_b as u8)))
                .mul(price_b);

            // 3. convert to a
            let a_out = dollar_value
                .div(price_a)
                .mul(decimal::from(10u64.pow(decimals_a as u8)));

            // 4. convert to btoken_a
            let b_a_out = a_out
                .mul(total_btoken_supply_a)
                .div(total_funds_a)
                .floor();

            b_a_out
        };

        pool.get_quote(amount_in, amount_out, a2b)
    }

    fun oracle_decimal_to_decimal(price: OracleDecimal): Decimal {
        if (price.is_expo_negative()) {
            decimal::from(price.base() as u64).div(decimal::from(10u64.pow(price.expo() as u8)))
        } else {
            decimal::from(price.base() as u64).mul(decimal::from(10u64.pow(price.expo() as u8)))
        }
    }
}
