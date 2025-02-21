/// Oracle AMM Hook implementation
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

    // use oracles::

    // ===== Constants =====

    const CURRENT_VERSION: u16 = 1;
    const PRICE_STALENESS_THRESHOLD_S: u64 = 0;
    const BPS: u64 = 10_000;

    // ===== Errors =====

    const EPriceIdentifierMismatch: u64 = 1;
    const EInvalidPrice: u64 = 2;
    const EPriceStale: u64 = 3;
    const EPriceInfoIsZero: u64 = 4;

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

    public fun new<A, B, LpType: drop>(
        registry: &mut Registry,
        swap_fee_bps: u64,
        meta_a: &CoinMetadata<A>,
        meta_b: &CoinMetadata<B>,
        meta_lp: &mut CoinMetadata<LpType>,
        lp_treasury: TreasuryCap<LpType>,
        oracle_registry: &OracleRegistry,
        oracle_index_a: u64,
        oracle_index_b: u64,
        ctx: &mut TxContext,
    ): Pool<A, B, OracleQuoter, LpType> {
        let quoter = OracleQuoter {
            version: version::new(CURRENT_VERSION),
            oracle_registry_id: object::id(oracle_registry),
            oracle_index_a,
            oracle_index_b,
            decimals_a: meta_a.get_decimals(),
            decimals_b: meta_b.get_decimals(),
        };

        pool::new<A, B, OracleQuoter, LpType>(
            registry,
            swap_fee_bps,
            quoter,
            meta_a,
            meta_b,
            meta_lp,
            lp_treasury,
            ctx,
        )
    }

    public fun swap<A, B, LpType: drop>(
        pool: &mut Pool<A, B, OracleQuoter, LpType>,
        coin_a: &mut Coin<A>,
        coin_b: &mut Coin<B>,
        oracle_price_update_a: OraclePriceUpdate,
        oracle_price_update_b: OraclePriceUpdate,
        a2b: bool,
        amount_in: u64,
        min_amount_out: u64,
        _clock: &Clock,
        ctx: &mut TxContext,
    ): SwapResult {
        pool.quoter_mut().version.assert_version_and_upgrade(CURRENT_VERSION);

        let quote = quote_swap(
            pool, 
            amount_in, 
            oracle_price_update_a,
            oracle_price_update_b,
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

    public(package) fun quote_swap<A, B, LpType: drop>(
        pool: &Pool<A, B, OracleQuoter, LpType>,
        amount_in: u64,
        oracle_price_update_a: OraclePriceUpdate,
        oracle_price_update_b: OraclePriceUpdate,
        a2b: bool,
    ): SwapQuote {
        let quoter = pool.quoter();

        let decimals_a = quoter.decimals_a;
        let decimals_b = quoter.decimals_b; 

        let price_a = oracle_decimal_to_decimal(oracle_price_update_a.price());
        let price_b = oracle_decimal_to_decimal(oracle_price_update_b.price());


        let amount_out: u64 = if (a2b) {
            decimal::from(amount_in)
                .div(decimal::from(10u64.pow(decimals_a as u8)))
                .mul(price_a)
                .div(price_b)
                .mul(decimal::from(10u64.pow(decimals_b as u8)))
                .floor()
        } else {
            decimal::from(amount_in)
                .div(decimal::from(10u64.pow(decimals_b as u8)))
                .mul(price_b)
                .div(price_a)
                .mul(decimal::from(10u64.pow(decimals_a as u8)))
                .floor()
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
