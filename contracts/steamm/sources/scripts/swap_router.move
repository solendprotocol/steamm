#[allow(lint(self_transfer))]
module steamm::swap_router;

use sui::coin::{Self, Coin};
use sui::clock::Clock;
use steamm::events::emit_event;
use steamm::bank::Bank;
use suilend::lending_market::{LendingMarket};

public struct MultiRouteSwapQuote has store, copy, drop {
    amount_in: u64,
    amount_out: u64,
}

public fun one_hop_btokens<P, X, Y, BX, H1, BY>(
    bank_x: &mut Bank<P, X, BX>,
    bank_y: &mut Bank<P, Y, BY>,
    lending_market: &mut LendingMarket<P>,
    coin_x: &mut Coin<X>,
    coin_y: &mut Coin<Y>,
    x2y: bool,
    amount_in: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<BX>, Coin<H1>, Coin<BY>) {
    if (x2y) {
        (
            bank_x.mint_btokens(lending_market, coin_x, amount_in, clock, ctx),
            coin::zero(ctx),
            coin::zero(ctx),
        )
    } else {
        (
            coin::zero(ctx),
            coin::zero(ctx),
            bank_y.mint_btokens(lending_market, coin_y, amount_in, clock, ctx)
        )
    }
}

public fun two_hop_btokens<P, X, Y, BX, H1, H2, BY>(
    bank_x: &mut Bank<P, X, BX>,
    bank_y: &mut Bank<P, Y, BY>,
    lending_market: &mut LendingMarket<P>,
    coin_x: &mut Coin<X>,
    coin_y: &mut Coin<Y>,
    x2y: bool,
    amount_in: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<BX>, Coin<H1>, Coin<H2>, Coin<BY>) {
    if (x2y) {
        (
            bank_x.mint_btokens(lending_market, coin_x, amount_in, clock, ctx),
            coin::zero(ctx),
            coin::zero(ctx),
            coin::zero(ctx),
        )
    } else {
        (
            coin::zero(ctx),
            coin::zero(ctx),
            coin::zero(ctx),
            bank_y.mint_btokens(lending_market, coin_y, amount_in, clock, ctx)
        )
    }
}

public fun collect_btoken_dust<P, X, C, BTokenX, BTokenY>(
    bank_x: &mut Bank<P, X, BTokenX>,
    bank_y: &mut Bank<P, C, BTokenY>,
    coin_x: &mut Coin<X>,
    coin_y: &mut Coin<C>,
    lending_market: &mut LendingMarket<P>,
    btoken_a: &mut Coin<BTokenX>,
    btoken_c: &mut Coin<BTokenY>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let remaining_value_ba = btoken_a.value();
    let remaining_value_bc = btoken_c.value();

    if (remaining_value_ba > 0) {
        let coin_x_ = bank_x.burn_btokens(lending_market, btoken_a, remaining_value_ba, clock, ctx);
        coin_x.join(coin_x_);
    };
    if (remaining_value_bc > 0) {
        let coin_y_ = bank_y.burn_btokens(lending_market, btoken_c, remaining_value_bc, clock, ctx);
        coin_y.join(coin_y_);
    };
}

public fun get_amount_in_for_quote<P, X, Y, BTokenX, BTokenY>(
    bank_x: &mut Bank<P, X, BTokenX>,
    bank_y: &mut Bank<P, Y, BTokenY>,
    lending_market: &mut LendingMarket<P>,
    x2y: bool,
    amount_in: u64,
    clock: &Clock,
): u64 {
    bank_x.compound_interest_if_any(lending_market, clock);
    bank_y.compound_interest_if_any(lending_market, clock);

    let amount_in_ = if (x2y) {
        bank_x.to_btokens(lending_market, amount_in, clock).floor()
    } else {
        bank_y.to_btokens(lending_market, amount_in, clock).floor()
    };

    amount_in_
}

public fun to_multi_swap_route<P, X, Y, BTokenX, BTokenY>(
    bank_x: &mut Bank<P, X, BTokenX>,
    bank_y: &mut Bank<P, Y, BTokenY>,
    lending_market: &mut LendingMarket<P>,
    x2y: bool,
    amount_in: u64,
    amount_out: u64,
    clock: &Clock,
): MultiRouteSwapQuote {
    bank_x.compound_interest_if_any(lending_market, clock);
    bank_y.compound_interest_if_any(lending_market, clock);

    let (amount_in, amount_out) = if (x2y) {
        (
            bank_x.from_btokens(lending_market, amount_in, clock).floor(),
            bank_y.from_btokens(lending_market, amount_out, clock).floor(),
        )
    } else {
        (
            bank_y.from_btokens(lending_market, amount_in, clock).floor(),
            bank_x.from_btokens(lending_market, amount_out, clock).floor(),
        )
    };

    let quote = MultiRouteSwapQuote { amount_in, amount_out };

    emit_event(quote);

    quote
}
