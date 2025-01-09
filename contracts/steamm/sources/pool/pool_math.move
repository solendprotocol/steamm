/// Module containing package math functions for pool operations
/// such as deposits, redeems, and swaps
module steamm::pool_math;

use std::u128::sqrt;
use std::u64::min;
use steamm::math::{safe_mul_div, safe_mul_div_up};

// ===== Errors =====

// When the deposit max parameter ratio is invalid
const EDepositRatioInvalid: u64 = 3;
// The amount of coin A reedemed is below the minimum set
const ERedeemSlippageAExceeded: u64 = 4;
// The amount of coin B reedemed is below the minimum set
const ERedeemSlippageBExceeded: u64 = 5;
// Assert that the reserve to lp supply ratio updates
// in favor of of the pool. This error should not occur
const ELpSupplyToReserveRatioViolation: u64 = 6;
// When depositing the max deposit params cannot be zero
const EDepositMaxAParamCantBeZero: u64 = 7;
// The deposit ratio computed leads to a coin A deposit of zero
const EDepositRatioLeadsToZeroA: u64 = 8;

// ===== Package functions =====

/// Calculates the amount of tokens A and B to deposit and LP tokens to mint
/// @param reserve_a Current reserve of token A in the pool
/// @param reserve_b Current reserve of token B in the pool
/// @param lp_supply Total supply of LP tokens
/// @param max_a Maximum amount of token A user is willing to deposit
/// @param max_b Maximum amount of token B user is willing to deposit
/// 
/// @return (delta_a, delta_b, delta_lp) Tuple of token amounts to deposit and LP tokens to mint
public(package) fun quote_deposit(
    reserve_a: u64,
    reserve_b: u64,
    lp_supply: u64,
    max_a: u64,
    max_b: u64,
): (u64, u64, u64) {
    let (delta_a, delta_b) = tokens_to_deposit(
        reserve_a,
        reserve_b,
        max_a,
        max_b,
    );

    // Compute new LP Tokens
    let delta_lp = lp_tokens_to_mint(
        reserve_a,
        reserve_b,
        lp_supply,
        delta_a,
        delta_b,
    );

    (delta_a, delta_b, delta_lp)
}

/// Calculates the amount of tokens A and B to be redeemed for a given amount of LP tokens
/// @param reserve_a Current reserve of token A in the pool
/// @param reserve_b Current reserve of token B in the pool
/// @param lp_supply Total supply of LP tokens
/// @param lp_tokens Amount of LP tokens to redeem
/// @param min_a Minimum amount of token A user is willing to receive
/// @param min_b Minimum amount of token B user is willing to receive
/// 
/// @return (withdraw_a, withdraw_b) Tuple of token amounts to be redeemed
public(package) fun quote_redeem(
    reserve_a: u64,
    reserve_b: u64,
    lp_supply: u64,
    lp_tokens: u64,
    min_a: u64,
    min_b: u64,
): (u64, u64) {
    // Compute the amount of tokens the user is allowed to
    // receive for each reserve, via the lp ratio
    let withdraw_a = safe_mul_div(reserve_a, lp_tokens, lp_supply);
    let withdraw_b = safe_mul_div(reserve_b, lp_tokens, lp_supply);

    // Assert slippage
    assert!(withdraw_a >= min_a, ERedeemSlippageAExceeded);
    assert!(withdraw_b >= min_b, ERedeemSlippageBExceeded);

    (withdraw_a, withdraw_b)
}

/// Asserts that the ratio between LP supply and reserves remains favorable for the pool
/// @param initial_reserve_a Initial reserve of token A in the pool
/// @param initial_lp_supply Initial total supply of LP tokens
/// @param final_reserve_a Final reserve of token A in the pool
/// @param final_lp_supply Final total supply of LP tokens
public(package) fun assert_lp_supply_reserve_ratio(
    initial_reserve_a: u64,
    initial_lp_supply: u64,
    final_reserve_a: u64,
    final_lp_supply: u64,
) {
    assert!(
        (final_reserve_a as u128) * (initial_lp_supply as u128) >=
            (initial_reserve_a as u128) * (final_lp_supply as u128),
        ELpSupplyToReserveRatioViolation,
    );
}

// ===== Private functions =====

/// Calculates the optimal deposit amounts for both tokens while maintaining the pool ratio
/// @param reserve_a Current reserve of token A in the pool
/// @param reserve_b Current reserve of token B in the pool
/// @param max_a Maximum amount of token A user is willing to deposit
/// @param max_b Maximum amount of token B user is willing to deposit
/// 
/// @return (amount_a, amount_b) Tuple of optimal deposit amounts for tokens A and B
fun tokens_to_deposit(reserve_a: u64, reserve_b: u64, max_a: u64, max_b: u64): (u64, u64) {
    assert!(max_a > 0, EDepositMaxAParamCantBeZero);

    if (reserve_a == 0 && reserve_b == 0) {
        (max_a, max_b)
    } else {
        let b_star = safe_mul_div_up(max_a, reserve_b, reserve_a);
        if (b_star <= max_b) { (max_a, b_star) } else {
            let a_star = safe_mul_div_up(max_b, reserve_a, reserve_b);
            assert!(a_star > 0, EDepositRatioLeadsToZeroA);
            assert!(a_star <= max_a, EDepositRatioInvalid);
            (a_star, max_b)
        }
    }
}

/// Calculates the amount of LP tokens to mint for a given deposit
/// @param reserve_a Current reserve of token A in the pool
/// @param reserve_b Current reserve of token B in the pool
/// @param lp_supply Current total supply of LP tokens
/// @param amount_a Amount of token A being deposited
/// @param amount_b Amount of token B being deposited
/// 
/// @return Amount of LP tokens to mint
fun lp_tokens_to_mint(
    reserve_a: u64,
    reserve_b: u64,
    lp_supply: u64,
    amount_a: u64,
    amount_b: u64,
): u64 {
    if (lp_supply == 0) {
        if (amount_b == 0) {
            return amount_a
        };

        (sqrt((amount_a as u128) * (amount_b as u128)) as u64)
    } else {
        if (reserve_b == 0) {
            safe_mul_div(amount_a, lp_supply, reserve_a)
        } else {
            min(
                safe_mul_div(amount_a, lp_supply, reserve_a),
                safe_mul_div(amount_b, lp_supply, reserve_b),
            )
        }
    }
}

// ===== Test-Only =====

#[test_only]
public(package) fun quote_deposit_test(
    reserve_a: u64,
    reserve_b: u64,
    lp_supply: u64,
    max_a: u64,
    max_b: u64,
): (u64, u64, u64) {
    quote_deposit(
        reserve_a,
        reserve_b,
        lp_supply,
        max_a,
        max_b,
    )
}

#[test_only]
public(package) fun quote_redeem_test(
    reserve_a: u64,
    reserve_b: u64,
    lp_supply: u64,
    lp_tokens: u64,
    min_a: u64,
    min_b: u64,
): (u64, u64) {
    quote_redeem(
        reserve_a,
        reserve_b,
        lp_supply,
        lp_tokens,
        min_a,
        min_b,
    )
}

// ===== Tests =====

#[test]
fun test_assert_lp_supply_reserve_ratio_ok() {
    // Perfect ratio
    assert_lp_supply_reserve_ratio(
        10, // initial_reserve_a
        10, // initial_lp_supply
        100, // final_reserve_a
        100, // final_lp_supply
    );

    // Ratio gets better in favor of the pool
    assert_lp_supply_reserve_ratio(
        10, // initial_reserve_a
        10, // initial_lp_supply
        100, // final_reserve_a
        99, // final_lp_supply
    );
}

// Note: This error cannot occur unless there is a bug in the contract.
// It provides an extra layer of security
#[test]
#[expected_failure(abort_code = ELpSupplyToReserveRatioViolation)]
fun test_assert_lp_supply_reserve_ratio_not_ok() {
    // Ratio gets worse in favor of the pool
    assert_lp_supply_reserve_ratio(
        10, // initial_reserve_a
        10, // initial_lp_supply
        100, // final_reserve_a
        101, // final_lp_supply
    );
}
