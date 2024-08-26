/// Fixed Range Constant-Sum AMM Hook implementation
module slamm::smm {
    use std::debug::print;
    use sui::coin::Coin;
    use slamm::{
        global_admin::GlobalAdmin,
        registry::{Registry},
        quote::SwapQuote,
        bank::Bank,
        pool::{Self, Pool, PoolCap, SwapResult, Intent},
        version::{Self, Version},
        math::safe_mul_div_up,
    };
    use suilend::decimal::{Self, Decimal};

    // ===== Constants =====

    const CURRENT_VERSION: u16 = 1;
    const BPS_DENOMINATOR: u64 = 10_000;


    // ===== Errors =====

    const EInvariantViolation: u64 = 1;
    const EFeeAbove100Percent: u64 = 2;
    const EMaxFeeMustBeBiggerThenMinFee: u64 = 3;

    /// Hook type for the constant-sum AMM implementation. Serves as both
    /// the hook's witness (authentication) as well as it wraps around the pool
    /// creator's witness.
    /// 
    /// This has the advantage that we do not require an extra generic
    /// type on the `Pool` object.
    /// 
    /// Other hook implementations can decide to leverage this property and
    /// provide pathways for the inner witness contract to add further logic,
    /// therefore making the hook extendable.
    public struct Hook<phantom W> has drop {}

    /// Constant-Sum AMM specific state. We do not store the invariant,
    /// instead we compute it at runtime.
    public struct State has store {
        min_fee_bps: u64,
        max_fee_bps: u64,
        version: Version,
    }

    // ===== Public Methods =====

    /// Initializes and returns a new AMM Pool along with its associated PoolCap.
    /// The pool is initialized with zero balances for both coin types `A` and `B`,
    /// specified protocol fees, and the provided swap fee. The pool's LP supply
    /// object is initialized at zero supply and the pool is added to the `registry`.
    /// 
    /// It sets uo the upper and lower reserve ratio which depermines the boundaries
    /// which the AMM offers a quote or not.
    ///
    /// # Returns
    ///
    /// A tuple containing:
    /// - `Pool<A, B, Hook, State>`: The created AMM pool object.
    /// - `PoolCap<A, B, Hook>`: The associated pool capability object.
    ///
    /// # Panics
    ///
    /// This function will panic if `swap_fee_bps` is greater than or equal to
    /// `SWAP_FEE_DENOMINATOR`
    public fun new<A, B, W: drop>(
        _witness: W,
        registry: &mut Registry,
        min_fee_bps: u64,
        max_fee_bps: u64,
        swap_fee_bps: u64,
        ctx: &mut TxContext,
    ): (Pool<A, B, Hook<W>, State>, PoolCap<A, B, Hook<W>, State>) {
        assert!(max_fee_bps <= BPS_DENOMINATOR, EFeeAbove100Percent);
        assert!(min_fee_bps < max_fee_bps, EMaxFeeMustBeBiggerThenMinFee);

        let inner = State {
            version: version::new(CURRENT_VERSION),
            min_fee_bps,
            max_fee_bps,
        };

        let (pool, pool_cap) = pool::new<A, B, Hook<W>, State>(
            Hook<W> {},
            registry,
            swap_fee_bps,
            inner,
            ctx,
        );

        (pool, pool_cap)
    }

    public fun intent_swap<A, B, W: drop>(
        self: &mut Pool<A, B, Hook<W>, State>,
        amount_in: u64,
        a2b: bool,
    ): Intent<A, B, Hook<W>, State> {
        self.inner_mut().version.assert_version_and_upgrade(CURRENT_VERSION);
        let quote = quote_swap(self, amount_in, a2b);

        quote.as_intent(self)
    }

    public fun execute_swap<A, B, W: drop, P>(
        self: &mut Pool<A, B, Hook<W>, State>,
        bank_a: &mut Bank<P, A>,
        bank_b: &mut Bank<P, B>,
        intent: Intent<A, B, Hook<W>, State>,
        coin_a: &mut Coin<A>,
        coin_b: &mut Coin<B>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): SwapResult {
        self.inner_mut().version.assert_version_and_upgrade(CURRENT_VERSION);

        let k0 = k(self);

        let response = self.swap(
            Hook<W> {},
            bank_a,
            bank_b,
            coin_a,
            coin_b,
            intent,
            min_amount_out,
            ctx,
        );

        // Recompute invariant
        assert_invariant_does_not_decrease(self, k0);

        response
    }

    public fun quote_swap<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        amount_in: u64,
        a2b: bool,
    ): SwapQuote {
        let initial_reserve_ratio = reserve_ratio(self);
        let amount_out = amount_in;

        let final_funds_a = if (a2b) {
            self.total_funds_a() + amount_in
        } else {
            self.total_funds_a() - amount_out
        };
        
        let final_funds_b = if (a2b) {
            self.total_funds_b() - amount_out
        } else {
            self.total_funds_b() + amount_in
        };

        let final_reserve_ratio = reserve_ratio_(final_funds_a, final_funds_b);

        let variable_fee_bps = compute_fee(
            initial_reserve_ratio,
            final_reserve_ratio,
            self.inner().min_fee_bps,
            self.inner().max_fee_bps,
        );

        let total_variable_fee = variable_fee_bps * amount_out / 10_000;

        
        print(&@0x111);
        print(&variable_fee_bps);
        print(&amount_out);
        print(&total_variable_fee);
        print(&@0x222);

        let (protocol_fee_num, protocol_fee_denom) = self.protocol_fees().fee_ratio();
        let protocol_fees = safe_mul_div_up(total_variable_fee, protocol_fee_num, protocol_fee_denom);
        let pool_fees = total_variable_fee - protocol_fees;

        let mut quote = self.get_quote(amount_in, amount_out, a2b);
        quote.add_extra_fees(protocol_fees, pool_fees);

        quote
    }

    public fun compute_fee(
        initial_reserve_ratio: Decimal,
        final_reserve_ratio: Decimal,
        min_fee_bps: u64,
        max_fee_bps: u64,
    ): u64 {
        let zero = decimal::from(0);
        let one = decimal::from(1);
        let two = decimal::from(2);
        let half = decimal::from_percent(50);

        let is_bigger = final_reserve_ratio.gt(initial_reserve_ratio);
        let is_both_side = initial_reserve_ratio.ge(half) && final_reserve_ratio.gt(half)
            || initial_reserve_ratio.le(half) && final_reserve_ratio.lt(half);
        
        let mut reserve_delta = zero;
        
        {
            if (is_bigger && is_both_side) {
                reserve_delta = final_reserve_ratio.sub(initial_reserve_ratio);
            };

            if (is_bigger && !is_both_side) {
                reserve_delta = final_reserve_ratio.sub(half);
            };

            if (!is_bigger && !is_both_side) {
                reserve_delta = half.sub(final_reserve_ratio);
            };
        };

        reserve_delta = reserve_delta.min(half);

        // scale reserve delta
        {
            if (final_reserve_ratio.eq(one) || final_reserve_ratio.eq(zero)) {
                reserve_delta = half;
            };

            if (final_reserve_ratio.lt(half)) {
                reserve_delta = reserve_delta.mul(
                    one.div(final_reserve_ratio).mul(two)
                ).min(half)
            } else {
                reserve_delta = reserve_delta.mul(
                    one.div(one.sub(final_reserve_ratio)).mul(two)
                ).min(half)
            };
        };

        let min_fee = decimal::from(min_fee_bps);
        let max_fee = decimal::from(max_fee_bps);

        max_fee.sub(min_fee).div(half).mul(reserve_delta).add(min_fee).ceil()
    }
    
    // ===== Assert Functions =====

    public fun reserve_ratio<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
    ): Decimal {
        reserve_ratio_(
            self.total_funds_a(),
            self.total_funds_b(),
        )
    }
    
    fun reserve_ratio_(
        total_funds_a: u64,
        total_funds_b: u64
    ): Decimal {
        let a = decimal::from(total_funds_a);
        let b = decimal::from(total_funds_b);
        a.div(a.add(b))
    }

    // ===== View Functions =====
    
    public fun k<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>): u128 {
        let (reserve_a, reserve_b) = self.total_funds();
        ((reserve_a as u128) + (reserve_b as u128))
    }

    // ===== Versioning =====
    
    entry fun migrate<A, B, W>(
        self: &mut Pool<A, B, Hook<W>, State>,
        _cap: &PoolCap<A, B, Hook<W>, State>,
    ) {
        migrate_(self);
    }
    
    entry fun migrate_as_global_admin<A, B, W>(
        self: &mut Pool<A, B, Hook<W>, State>,
        _admin: &GlobalAdmin,
    ) {
        migrate_(self);
    }

    fun migrate_<A, B, W>(
        self: &mut Pool<A, B, Hook<W>, State>,
    ) {
        self.inner_mut().version.migrate_(CURRENT_VERSION);
    }
    
    public(package) fun assert_invariant_does_not_decrease<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>, k0: u128) {
        let k1 = k(self);
        assert!(k1 >= k0, EInvariantViolation);
    }

    // #[test_only]
    // use sui::test_utils::assert_eq;

    // #[test]
    // fun test_compute_fee_balanced() {
    //     // When the reserve rati33333o is perfectly balanced at 0.5
    //     let initial_reserve_ratio = decimal::from_percent(50);
    //     let final_reserve_ratio = decimal::from_percent(50);

    //     // The fee should be equal to MIN_FEE because the abs_reserve_delta is 0
    //     assert_eq(compute_fee(initial_reserve_ratio, final_reserve_ratio), MIN_FEE);
    // }

    // #[test]
    // fun test_compute_fee_max_delta() {
    //     // When the initial and final reserve ratios are both 0 (or near 0)
    //     let initial_reserve_ratio = decimal::from_percent(0);
    //     let final_reserve_ratio = decimal::from_percent(0);

    //     // The fee should be MAX_FEE because the abs_reserve_delta is 0.5
    //     assert_eq(compute_fee(initial_reserve_ratio, final_reserve_ratio), MAX_FEE);
    // }

    // #[test]
    // fun test_compute_fee_mid_range() {
    //     // When the reserve ratio is somewhere between 0 and 0.5
    //     let initial_reserve_ratio = decimal::from_percent(25);
    //     let final_reserve_ratio = decimal::from_percent(25);

    //     // The fee should be halfway between MIN_FEE and MAX_FEE
    //     let expected_fee = decimal::from(MIN_FEE).add(decimal::from(MAX_FEE).sub(decimal::from(MIN_FEE)).div(decimal::from(2))).ceil();
    //     assert_eq(compute_fee(initial_reserve_ratio, final_reserve_ratio), expected_fee);
    // }
}
