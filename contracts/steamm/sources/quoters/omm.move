/// Oracle AMM Hook implementation. This quoter can only be initialized with btoken types.
module steamm::omm;
use oracles::oracles::{OracleRegistry, OraclePriceUpdate};
use steamm::pool::{Self, Pool, SwapResult};
use steamm::quote::SwapQuote;
use steamm::registry::Registry;
use steamm::version::{Self, Version};
use sui::clock::Clock;
use sui::coin::{Coin, TreasuryCap, CoinMetadata};
use suilend::decimal::{Decimal, Self};
use suilend::lending_market::LendingMarket;
use std::type_name::{Self};
use steamm::bank::Bank;
use steamm::events::emit_event;
use steamm::quoter_math;
use steamm::utils::oracle_decimal_to_decimal;

// ===== Constants =====

const AMPLIFIER: u64 = 2;

const CURRENT_VERSION: u16 = 1;

// ===== Errors =====
const EInvalidBankType: u64 = 0;
const EInvalidOracleIndex: u64 = 1;
const EInvalidOracleRegistry: u64 = 2;

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

    let pool = pool::new<B_A, B_B, OracleQuoter, LpType>(
        registry,
        swap_fee_bps,
        quoter,
        meta_b_a,
        meta_b_b,
        meta_lp,
        lp_treasury,
        ctx,
    );

    let result = NewOracleQuoter {
        pool_id: object::id(&pool),
        oracle_registry_id: object::id(oracle_registry),
        oracle_index_a,
        oracle_index_b,
        
    };

    emit_event(result);

    return pool
}

public fun swap<P, A, B, B_A, B_B, LpType: drop>(
    pool: &mut Pool<B_A, B_B, OracleQuoter, LpType>,
    bank_a: &Bank<P, A, B_A>,
    bank_b: &Bank<P, B, B_B>,
    lending_market: &LendingMarket<P>,
    oracle_price_update_a: OraclePriceUpdate,
    oracle_price_update_b: OraclePriceUpdate,
    coin_a: &mut Coin<B_A>,
    coin_b: &mut Coin<B_B>,
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
        oracle_price_update_a,
        oracle_price_update_b,
        amount_in, 
        a2b,
        clock,
    );

    let response = pool.swap(
        coin_a,
        coin_b,
        quote,
        min_amount_out,
        ctx,
    );

    response
}

public fun quote_swap<P, A, B, B_A, B_B, LpType: drop>(
    pool: &Pool<B_A, B_B, OracleQuoter, LpType>,
    bank_a: &Bank<P, A, B_A>,
    bank_b: &Bank<P, B, B_B>,
    lending_market: &LendingMarket<P>,
    oracle_price_update_a: OraclePriceUpdate,
    oracle_price_update_b: OraclePriceUpdate,
    amount_in: u64,
    a2b: bool,
    clock: &Clock,
): SwapQuote {
    let quoter = pool.quoter();

    let decimals_a = quoter.decimals_a;
    let decimals_b = quoter.decimals_b; 

    let price_a = oracle_decimal_to_decimal(oracle_price_update_a.price());
    let price_b = oracle_decimal_to_decimal(oracle_price_update_b.price());

    let (bank_total_funds_a, total_btoken_supply_a) = bank_a.get_btoken_ratio(lending_market, clock);
    let btoken_ratio_a = bank_total_funds_a.div(total_btoken_supply_a);

    let (bank_total_funds_b, total_btoken_supply_b) = bank_b.get_btoken_ratio(lending_market, clock);
    let btoken_ratio_b = bank_total_funds_b.div(total_btoken_supply_b);


    let amount_out_underlying = if (a2b) {
        let underlying_amount_in = decimal::from(amount_in).mul(btoken_ratio_a);
        let underlying_reserve_in = decimal::from(pool.balance_amount_a()).mul(btoken_ratio_a);
        let underlying_reserve_out = decimal::from(pool.balance_amount_b()).mul(btoken_ratio_b);

        // quote_swap_impl uses the underlying values instead of btoken values
        quote_swap_impl(
            underlying_amount_in,
            underlying_reserve_in,
            underlying_reserve_out,
            decimals_a,
            decimals_b,
            price_a,
            price_b,
            AMPLIFIER,
            a2b,
        )
    } else {
        let underlying_amount_in = decimal::from(amount_in).mul(btoken_ratio_b);
        let underlying_reserve_in = decimal::from(pool.balance_amount_b()).mul(btoken_ratio_b);
        let underlying_reserve_out = decimal::from(pool.balance_amount_a()).mul(btoken_ratio_a);

        // quote_swap_impl uses the underlying values instead of btoken values
        quote_swap_impl(
            underlying_amount_in,
            underlying_reserve_in,
            underlying_reserve_out,
            decimals_b,
            decimals_a,
            price_b,
            price_a,
            AMPLIFIER,
            a2b,
        )
    };

    let mut amount_out = if (a2b) {
        decimal::from(amount_out_underlying).div(btoken_ratio_b).floor()
    } else {
        decimal::from(amount_out_underlying).div(btoken_ratio_a).floor()
    };

    amount_out = if (a2b) {
        if (amount_out >= pool.balance_amount_b()) {
            0
        } else {
            amount_out
        }
    } else {
        if (amount_out >= pool.balance_amount_a()) {
            0
        } else {
            amount_out
        }
    };

    pool.get_quote(amount_in, amount_out, a2b)
}

fun quote_swap_impl(
    // Amount in (underlying)
    amount_in: Decimal,
    // Reserve in (underlying)
    reserve_in: Decimal,
    // Reserve out (underlying)
    reserve_out: Decimal,
    decimals_in: u8,
    decimals_out: u8,
    // Price In (underlying)
    price_in: Decimal,
    // Price Out (underlying)
    price_out: Decimal,
    amplifier: u64,
    a2b: bool,
): u64 {
    // quoter_math::swap uses the underlying values instead of btoken values
    if (a2b) {
        quoter_math::swap(
            amount_in, // input_a
            reserve_in, // reserve_a
            reserve_out, // reserve_b
            price_in, // price_a
            price_out, // price_b
            decimals_in as u64, // decimals_a
            decimals_out as u64, // decimals_b
            amplifier,
            true, // a2b
        )
    } else {
        quoter_math::swap(
            amount_in, // input_b
            reserve_out, // reserve_a
            reserve_in, // reserve_b
            price_out, // price_a
            price_in, // price_b
            decimals_out as u64, // decimals_a
            decimals_in as u64, // decimals_b
            amplifier,
            false, // a2b
        )
    }
}

// ===== Events =====

public struct NewOracleQuoter has copy, drop, store {
    pool_id: ID,
    oracle_registry_id: ID,
    oracle_index_a: u64,
    oracle_index_b: u64,
}
