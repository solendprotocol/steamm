#[test_only]
module steamm_scripts::router;

use std::debug::print;
use steamm_scripts::pool_script;
use sui::coin;
use sui::clock;
use std::u128::sqrt;
use steamm::bank;
use steamm::b_test_sui::B_TEST_SUI;
use steamm::b_test_usdc::B_TEST_USDC;
use steamm::cpmm::CpQuoter;
use steamm::lp_usdc_sui::LP_USDC_SUI;
use steamm::math as steamm_math;
use steamm::pool::{Self, Pool};
use steamm::cpmm;
use steamm::pool_math::{Self, quote_deposit_test, quote_redeem_test};
use steamm::test_utils;
use sui::test_scenario::{Self, Scenario};
use sui::test_utils::{destroy, assert_eq};
use suilend::lending_market_tests::{Self, LENDING_MARKET, setup as suilend_setup};

public struct A has drop {}
public struct B has drop {}
public struct C has drop {}

public struct B_A has drop {}
public struct B_B has drop {}
public struct B_C has drop {}
public struct LP_AB has drop {}
public struct LP_BC has drop {}


#[test]
fun test_initial_deposit() {
    let mut scenario = test_scenario::begin(@0x10);

    let (clock, owner_cap, mut lending_market, prices, type_to_index) = test_utils::setup_lending_market(option::some(test_utils::reserve_args(&mut scenario)), &mut scenario);

    let mut bank_a = bank::new_for_testing<LENDING_MARKET, A, B_A>(scenario.ctx());
    let mut bank_b = bank::new_for_testing<LENDING_MARKET, B, B_B>(scenario.ctx());
    let mut bank_c = bank::new_for_testing<LENDING_MARKET, C, B_C>(scenario.ctx());

    let mut pool_ab = pool::new_for_testing<B_A, B_B, CpQuoter, LP_AB>(
        100,
        cpmm::new_for_testing(0),
        scenario.ctx(),
    );
    
    let mut pool_bc = pool::new_for_testing<B_B, B_C, CpQuoter, LP_BC>(
        100,
        cpmm::new_for_testing(0),
        scenario.ctx(),
    );

    let mut coin_a = coin::mint_for_testing<A>(10000000, scenario.ctx());
    let mut coin_b = coin::mint_for_testing<B>(10000000, scenario.ctx());

    let lp_coins = pool_script::deposit_liquidity(
        &mut pool_ab,
        &mut bank_a,
        &mut bank_b,
        &mut lending_market,
        &mut coin_a,
        &mut coin_b,
        10000000,
        10000000,
        &clock,
        scenario.ctx(),
    );

    destroy(coin_a);
    destroy(coin_b);
    destroy(lp_coins);
    
    let mut coin_b = coin::mint_for_testing<B>(10000000, scenario.ctx());
    let mut coin_c = coin::mint_for_testing<C>(10000000, scenario.ctx());

    let lp_coins = pool_script::deposit_liquidity(
        &mut pool_bc,
        &mut bank_b,
        &mut bank_c,
        &mut lending_market,
        &mut coin_b,
        &mut coin_c,
        10000000,
        10000000,
        &clock,
        scenario.ctx(),
    );

    destroy(coin_b);
    destroy(coin_c);
    destroy(lp_coins);

    //
    bank_a.compound_interest_if_any(&mut lending_market, &clock);
    bank_b.compound_interest_if_any(&mut lending_market, &clock);

    let btoken_amount = bank_a.to_btokens(&lending_market, 50000, &clock);

    let quote1 = pool_script::quote_cpmm_swap(
        &pool_ab,
        &bank_a,
        &bank_b,
        &mut lending_market,
        true, // a2b
        btoken_amount,
        &clock,
    );

    print(&quote1);

    let quote2 = pool_script::quote_cpmm_swap(
        &pool_bc,
        &bank_b,
        &bank_c,
        &mut lending_market,
        true, // a2b
        quote1.amount_out(),
        &clock,
    );

    print(&quote2);


    destroy(clock);
    destroy(owner_cap);
    destroy(lending_market);
    destroy(prices);
    destroy(type_to_index);
    destroy(pool_ab);
    destroy(pool_bc);
    destroy(bank_a);
    destroy(bank_b);
    destroy(bank_c);
    destroy(scenario);
}
