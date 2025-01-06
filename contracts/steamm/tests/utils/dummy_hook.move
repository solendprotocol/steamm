#[test_only]
module steamm::dummy_hook {
    use sui::coin::Coin;
    use steamm::registry::{Registry};
    use steamm::quote::SwapQuote;
    use steamm::bank::{BToken};
    use steamm::pool::{Self, Pool, PoolCap, SwapResult, Intent};

    public struct DummyQuoter<phantom W> has store {}

    // ===== Public Methods =====

    public fun new_no_fees<A, B, W: drop, P>(
        _witness: W,
        registry: &mut Registry,
        swap_fee_bps: u64,
        ctx: &mut TxContext,
    ): (Pool<A, B, DummyQuoter<W>, P>, PoolCap<A, B, DummyQuoter<W>, P>) {
        let quoter = DummyQuoter {};

        let (mut pool, pool_cap) = pool::new<A, B, DummyQuoter<W>, P>(
            registry,
            swap_fee_bps,
            quoter,
            ctx,
        );

        pool.no_protocol_fees_for_testing();
        pool.no_redemption_fees_for_testing();

        (pool, pool_cap)
    }
    
    public fun new<A, B, W: drop, P>(
        _witness: W,
        registry: &mut Registry,
        swap_fee_bps: u64,
        ctx: &mut TxContext,
    ): (Pool<A, B, DummyQuoter<W>, P>, PoolCap<A, B, DummyQuoter<W>, P>) {
        let quoter = DummyQuoter {};

        let (pool, pool_cap) = pool::new<A, B, DummyQuoter<W>, P>(
            registry,
            swap_fee_bps,
            quoter,
            ctx,
        );

        (pool, pool_cap)
    }

    public fun swap<A, B, W: drop, P>(
        pool: &mut Pool<A, B, DummyQuoter<W>, P>,
        coin_a: &mut Coin<BToken<P, A>>,
        coin_b: &mut Coin<BToken<P, B>>,
        amount_in: u64,
        min_amount_out: u64,
        a2b: bool,
        ctx: &mut TxContext,
    ): SwapResult {
        let intent = intent_swap(
            pool,
            amount_in,
            a2b,
        );

        let result = execute_swap(
            pool,
            intent,
            coin_a,
            coin_b,
            min_amount_out,
            ctx
        );

        result
    }

    public fun intent_swap<A, B, W: drop, P>(
        pool: &mut Pool<A, B, DummyQuoter<W>, P>,
        amount_in: u64,
        a2b: bool,
    ): Intent<A, B, DummyQuoter<W>, P> {
        let quote = quote_swap(pool, amount_in, a2b);

        quote.as_intent(pool)
    }

    public fun execute_swap<A, B, W: drop, P>(
        self: &mut Pool<A, B, DummyQuoter<W>, P>,
        intent: Intent<A, B, DummyQuoter<W>, P>,
        coin_a: &mut Coin<BToken<P, A>>,
        coin_b: &mut Coin<BToken<P, B>>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): SwapResult {
        let response = self.swap(
            coin_a,
            coin_b,
            intent,
            min_amount_out,
            ctx,
        );

        response
    }

    public fun quote_swap<A, B, W: drop, P>(
        pool: &Pool<A, B, DummyQuoter<W>, P>,
        amount_in: u64,
        a2b: bool,
    ): SwapQuote {
        let amount_out = amount_in;

        pool.get_quote(amount_in, amount_out, a2b)
    }
}
