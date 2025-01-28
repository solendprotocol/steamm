#[allow(lint(self_transfer))]
module steamm::script_v1;

use sui::coin::{Self, Coin};
use sui::clock::Clock;
use steamm::bank::Bank;
use steamm::pool::Pool;
use steamm::cpmm::CpQuoter;
use suilend::lending_market::{LendingMarket};
use steamm::quote::{SwapQuote, DepositQuote};

public fun deposit_liquidity<P, A, B, BTokenA, BTokenB, Quoter: store, LpType: drop>(
    pool: &mut Pool<BTokenA, BTokenB, Quoter, LpType>,
    bank_a: &mut Bank<P, A, BTokenA>,
    bank_b: &mut Bank<P, B, BTokenB>,
    lending_market: &mut LendingMarket<P>,
    coin_a: &mut Coin<A>,
    coin_b: &mut Coin<B>,
    max_a: u64,
    max_b: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<LpType> {
    let mut btoken_a = bank_a.mint_btokens(lending_market, coin_a, max_a, clock, ctx);
    let mut btoken_b = bank_b.mint_btokens(lending_market, coin_b, max_b, clock, ctx);

    let max_ba = btoken_a.value();
    let max_bb = btoken_b.value();

    let (lp_coin, _) = pool.deposit_liquidity(&mut btoken_a, &mut btoken_b, max_ba, max_bb, ctx);

    let coin_a_ = bank_a.burn_btokens(lending_market, &mut btoken_a, max_a, clock, ctx);
    let coin_b_ = bank_b.burn_btokens(lending_market, &mut btoken_b, max_b, clock, ctx);

    destroy_or_transfer(btoken_a, btoken_b, ctx);

    coin_a.join(coin_a_);
    coin_b.join(coin_b_);

    lp_coin
}

public fun redeem_liquidity<P, A, B, BTokenA, BTokenB, Quoter: store, LpType: drop>(
    pool: &mut Pool<BTokenA, BTokenB, Quoter, LpType>,
    bank_a: &mut Bank<P, A, BTokenA>,
    bank_b: &mut Bank<P, B, BTokenB>,
    lending_market: &mut LendingMarket<P>,
    lp_tokens: Coin<LpType>,
    min_a: u64,
    min_b: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<A>, Coin<B>) {
    let (mut btoken_a, mut btoken_b, _) = pool.redeem_liquidity(lp_tokens, min_a, min_b, ctx);

    let (btoken_a_amount, btoken_b_amount) = (btoken_a.value(), btoken_b.value());

    let coin_a = bank_a.burn_btokens(lending_market, &mut btoken_a, btoken_a_amount, clock, ctx);
    let coin_b = bank_b.burn_btokens(lending_market, &mut btoken_b, btoken_b_amount, clock, ctx);

    destroy_or_transfer(btoken_a, btoken_b, ctx);

    (coin_a, coin_b)
}

public fun cpmm_swap<P, A, B, BTokenA, BTokenB, LpType: drop>(
    pool: &mut Pool<BTokenA, BTokenB, CpQuoter, LpType>,
    bank_a: &mut Bank<P, A, BTokenA>,
    bank_b: &mut Bank<P, B, BTokenB>,
    lending_market: &mut LendingMarket<P>,
    coin_a: &mut Coin<A>,
    coin_b: &mut Coin<B>,
    a2b: bool,
    amount_in: u64,
    min_amount_out: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let (mut btoken_a, mut btoken_b) = if (a2b) {
        (
            bank_a.mint_btokens(lending_market, coin_a, amount_in, clock, ctx),
            coin::zero(ctx)
        )
    } else {
        (
            coin::zero(ctx),
            bank_b.mint_btokens(lending_market, coin_b, amount_in, clock, ctx)
        )
    };

    pool.cpmm_swap(&mut btoken_a, &mut btoken_b, a2b, amount_in, min_amount_out, ctx);

    let btoken_a_amount = btoken_a.value();
    let btoken_b_amount = btoken_b.value();

    let coin_a_ = bank_a.burn_btokens(lending_market, &mut btoken_a, btoken_a_amount, clock, ctx);
    let coin_b_ = bank_b.burn_btokens(lending_market, &mut btoken_b, btoken_b_amount, clock, ctx);

    coin_a.join(coin_a_);
    coin_b.join(coin_b_);

    destroy_or_transfer(btoken_a, btoken_b, ctx);
}

public fun quote_cpmm_swap<P, A, B, BTokenA, BTokenB, LpType: drop>(
    pool: &Pool<BTokenA, BTokenB, CpQuoter, LpType>,
    bank_a: &Bank<P, A, BTokenA>,
    bank_b: &Bank<P, B, BTokenB>,
    lending_market: &mut LendingMarket<P>,
    amount_in: u64,
    a2b: bool,
    clock: &Clock,
): SwapQuote {
    bank_a.compound_interest_if_any(lending_market, clock);
    bank_b.compound_interest_if_any(lending_market, clock);

    let amount_in_ = if (a2b) {
        bank_a.to_btokens(lending_market, amount_in, clock).floor()
    } else {
        bank_b.to_btokens(lending_market, amount_in, clock).floor()
    };

    pool.cpmm_quote_swap(amount_in_, a2b)
}

public fun quote_deposit<P, A, B, BTokenA, BTokenB, Quoter: store, LpType: drop>(
    pool: &Pool<BTokenA, BTokenB, Quoter, LpType>,
    bank_a: &Bank<P, A, BTokenA>,
    bank_b: &Bank<P, B, BTokenB>,
    lending_market: &mut LendingMarket<P>,
    max_a: u64,
    max_b: u64,
    clock: &Clock,
): DepositQuote {
    bank_a.compound_interest_if_any(lending_market, clock);
    bank_b.compound_interest_if_any(lending_market, clock);

    let btoken_amount_a = bank_a.to_btokens(lending_market, max_a, clock).floor();
    let btoken_amount_b = bank_b.to_btokens(lending_market, max_b, clock).floor();

    pool.quote_deposit(btoken_amount_a, btoken_amount_b)
}

fun destroy_or_transfer<BTokenA, BTokenB>(
    btoken_a: Coin<BTokenA>,
    btoken_b: Coin<BTokenB>,
    ctx: &TxContext,
) {
    if (btoken_a.value() > 0) {
        transfer::public_transfer(btoken_a, ctx.sender());
    } else {
        btoken_a.destroy_zero();
    };
    
    if (btoken_b.value() > 0) {
        transfer::public_transfer(btoken_b, ctx.sender());
    } else {
        btoken_b.destroy_zero();
    };
}
