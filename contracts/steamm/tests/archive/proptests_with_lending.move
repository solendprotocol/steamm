#[test_only]
module steamm::proptests_with_lending_2;

use steamm::b_test_sui::B_TEST_SUI;
use steamm::b_test_usdc::B_TEST_USDC;
use steamm::test_utils::e9;
use sui::coin::{Self, Coin};
use sui::random;
use sui::test_scenario::{Self, Scenario, ctx};
use sui::test_utils::{destroy, assert_eq};

use suilend::test_sui::TEST_SUI;
use suilend::test_usdc::TEST_USDC;
use steamm::bank::Bank;
use steamm::cpmm::CpQuoter;
use steamm::lp_usdc_sui::LP_USDC_SUI;
use steamm::pool::Pool;
use steamm::test_utils::{test_setup_cpmm};
use sui::clock::Clock;
use suilend::lending_market::{LendingMarket};
use suilend::lending_market_tests::{LENDING_MARKET};

const ADMIN: address = @0x10;
const POOL_CREATOR: address = @0x11;
const TRADER: address = @0x13;

#[test_only]
public fun setup(
    fee: u64,
    offset: u64,
    scenario: &mut Scenario,
): (
    Pool<B_TEST_USDC, B_TEST_SUI, CpQuoter, LP_USDC_SUI>,
    Bank<LENDING_MARKET, TEST_USDC, B_TEST_USDC>,
    Bank<LENDING_MARKET, TEST_SUI, B_TEST_SUI>,
    LendingMarket<LENDING_MARKET>,
    Clock,
) {
    let is_no_fee = fee == 0;
    let fee = if (is_no_fee) { 100 } else { fee };

    let (mut pool, bank_a, bank_b, lending_market, lend_cap, prices, bag, clock) = test_setup_cpmm(
        fee,
        offset,
        scenario,
    );

    if (is_no_fee) {
        pool.no_protocol_fees_for_testing();
        pool.no_swap_fees_for_testing();
    };

    destroy(bag);
    destroy(lend_cap);
    destroy(prices);

    (pool, bank_a, bank_b, lending_market, clock)
}

#[test]
fun proptest_swap_with_lending_test_regression() {
    let mut scenario = test_scenario::begin(ADMIN);

    // Init Pool
    test_scenario::next_tx(&mut scenario, POOL_CREATOR);

    let (mut pool, mut bank_a, mut bank_b, mut lending_market, clock) = setup(
        100,
        0,
        &mut scenario,
    );
    
    let (mut pool_2, bank_a_2, bank_b_2, lending_market_2, clock_2) = setup(
        100,
        0,
        &mut scenario,
    );

    destroy(bank_a_2);
    destroy(bank_b_2);
    destroy(lending_market_2);
    destroy(clock_2);

    let ctx = ctx(&mut scenario);

    let mut coin_a = coin::mint_for_testing<TEST_USDC>(e9(200_000), ctx);
    let mut coin_b = coin::mint_for_testing<TEST_SUI>(e9(200_000), ctx);

    let mut btoken_a = bank_a.mint_btokens(&mut lending_market, &mut coin_a, e9(200_000), &clock, ctx);
    let mut btoken_b = bank_b.mint_btokens(&mut lending_market, &mut coin_b, e9(200_000), &clock, ctx);

    let (lp_coins, _) = pool.deposit_liquidity(
        &mut btoken_a,
        &mut btoken_b,
        e9(100_000),
        e9(100_000),
        ctx,
    );
    
    let (lp_coins_2, _) = pool_2.deposit_liquidity(
        &mut btoken_a,
        &mut btoken_b,
        e9(100_000),
        e9(100_000),
        ctx,
    );

    destroy(lp_coins_2);
    destroy(coin_a);
    destroy(coin_b);
    destroy(btoken_a);
    destroy(btoken_b);

    // Swap
    test_scenario::next_tx(&mut scenario, TRADER);

    let mut rng = random::new_generator_from_seed_for_testing(vector[0, 1, 2, 3]);

    let mut trades = 1_000;

    while (trades > 0) {
        test_scenario::next_tx(&mut scenario, TRADER);
        let ctx = ctx(&mut scenario);
        
        let amount_in = rng.generate_u64_in_range(1_000, 100_000_000);
        let a2b = if (rng.generate_u8_in_range(1_u8, 2_u8) == 1) { true } else { false };

        let mut coin_a = coin::mint_for_testing<TEST_USDC>(
            if (a2b) { amount_in * 2 } else { 0 },
            ctx,
        );
        let mut coin_b = coin::mint_for_testing<TEST_SUI>(
            if (a2b) { 0 } else { amount_in * 2 },
            ctx,
        );

        let (mut btoken_a, mut btoken_b): (Coin<B_TEST_USDC>, Coin<B_TEST_SUI>) = if (a2b) {(
            bank_a.mint_btokens(&mut lending_market, &mut coin_a, amount_in, &clock, ctx),
            coin::zero<B_TEST_SUI>(ctx)
        )} else {(
            coin::zero<B_TEST_USDC>(ctx),
            bank_b.mint_btokens(&mut lending_market, &mut coin_b, amount_in, &clock, ctx)
        )};

        let (mut btoken_a_2, mut btoken_b_2): (Coin<B_TEST_USDC>, Coin<B_TEST_SUI>) = if (a2b) {(
            bank_a.mint_btokens(&mut lending_market, &mut coin_a, amount_in, &clock, ctx),
            coin::zero<B_TEST_SUI>(ctx)
        )} else {(
            coin::zero<B_TEST_USDC>(ctx),
            bank_b.mint_btokens(&mut lending_market, &mut coin_b, amount_in, &clock, ctx)
        )};

        assert_eq(btoken_a.value(), btoken_a_2.value());
        assert_eq(btoken_b.value(), btoken_b_2.value());
        
        pool.cpmm_swap(
            &mut btoken_a,
            &mut btoken_b,
            a2b, // a2b
            amount_in,
            0,
            ctx,
        );

        pool_2.cpmm_swap(
            &mut btoken_a_2,
            &mut btoken_b_2,
            a2b, // a2b
            amount_in,
            0,
            ctx,
        );

        if (a2b) {
            let val = btoken_b.value();
            let res_b = bank_b.burn_btokens(&mut lending_market, &mut btoken_b, val, &clock, ctx);
            let val = btoken_b_2.value();
            let res_b2 = bank_b.burn_btokens(&mut lending_market, &mut btoken_b_2, val, &clock, ctx);
            assert_eq(res_b.value(), res_b2.value());
            destroy(res_b);
            destroy(res_b2);
        } else {
            let val = btoken_a.value();
            let res_a = bank_a.burn_btokens(&mut lending_market, &mut btoken_a, val, &clock, ctx);
            let val = btoken_a_2.value();
            let res_a2 = bank_a.burn_btokens(&mut lending_market, &mut btoken_a_2, val, &clock, ctx);
            assert_eq(res_a.value(), res_a2.value());
            destroy(res_a);
            destroy(res_a2);
        };
        
        destroy(coin_a);
        destroy(coin_b);
        destroy(btoken_a);
        destroy(btoken_b);
        destroy(btoken_a_2);
        destroy(btoken_b_2);

        trades = trades - 1;
    };

    destroy(pool);
    destroy(pool_2);
    destroy(lp_coins);
    destroy(clock);
    destroy(lending_market);
    destroy(bank_a);
    destroy(bank_b);
    test_scenario::end(scenario);
}
