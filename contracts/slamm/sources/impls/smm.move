/// Stable-Swap AMM Hook implementation
module slamm::smm {
    use slamm::global_admin::GlobalAdmin;
    use slamm::registry::{Registry};
    use slamm::pool::{Self, Pool, PoolCap};
    use slamm::version::{Self, Version};
    use suilend::decimal::{Self, Decimal};

    // ===== Constants =====

    const CURRENT_VERSION: u16 = 1;

    // The method should converge within few iterations, due to the fact
    // we are approximating positive root from a well positioned first
    // initial guess.
    // We use the same max that was used in the old AMM version.
    //
    // This is one of two bounding conditions for the newtons method. The other is
    // the admissible error. We're pretty much guaranteed that the admissible error
    // bounding condition is going to be the breaking point for the newton's method
    // loop. We use this constant as a sanity check. We don't lower the constant to
    // be more in line with the admissible error, because we want to have only one
    // condition to reason about. It's better to know that the method will always
    // break on surpassing the admissible error, than to reason about whether it
    // was max iterations or the error.
    const MAX_ITERATIONS: u32 = 32;

    // ===== Errors =====

    const EInvalidRoot: u64 = 1;
    const EMathOverflow: u64 = 2;
    const EInavlidAmplifier: u64 = 3;

    /// Hook type for the Stable-Swap AMM implementation. Serves as both
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

    /// Stable-Swap AMM specific state. We do not store the invariant,
    /// instead we compute it at runtime.
    public struct State has store {
        version: Version,
        k: u128,
        amplifier: u64,
    }

    public struct StableCurveInvariant has copy, store, drop {
        // number of reserves
        exponent: u64,
        // initial guess for Newton's Method
        initial_guess: Decimal,
        // scale down exponent
        scl_down_coef: Decimal,
        // amplifier * n - 1
        first_order_coeff: Decimal,
        // amplifier * n * sum
        polynomial_third_term: Decimal,
    }

    public struct ScaleDownOutput has copy, store, drop {
        scale_down: Decimal,
        exponent: u32,
    }

    // ===== Public Methods =====

    public fun new<A, B, W: drop>(
        _witness: W,
        registry: &mut Registry,
        swap_fee_bps: u64,
        amplifier: u64,
        ctx: &mut TxContext,
    ): (Pool<A, B, Hook<W>, State>, PoolCap<A, B, Hook<W>>) {
        let inner = State {
            version: version::new(CURRENT_VERSION),
            amplifier,
            k: 0_u128,
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

    // public fun swap<A, B, W: drop>(
    //     self: &mut Pool<A, B, Hook<W>, State>,
    //     bank_a: &mut Bank<A>,
    //     bank_b: &mut Bank<B>,
    //     coin_a: &mut Coin<A>,
    //     coin_b: &mut Coin<B>,
    //     amount_in: u64,
    //     min_amount_out: u64,
    //     a2b: bool,
    //     clock: &Clock,
    //     ctx: &mut TxContext,
    // ): SwapResult {
    //     // TODO
    // }
    
    // public fun intent_swap<A, B, W: drop>(
    //     self: &mut Pool<A, B, Hook<W>, State>,
    //     amount_in: u64,
    //     a2b: bool,
    //     clock: &Clock,
    // ): Intent<A, B, Hook<W>> {
    //     // TODO
    // }

    // public fun execute_swap<A, B, W: drop>(
    //     self: &mut Pool<A, B, Hook<W>, State>,
    //     bank_a: &mut Bank<A>,
    //     bank_b: &mut Bank<B>,
    //     intent: Intent<A, B, Hook<W>>,
    //     coin_a: &mut Coin<A>,
    //     coin_b: &mut Coin<B>,
    //     min_amount_out: u64,
    //     ctx: &mut TxContext,
    // ): SwapResult {
    //     // TODO
    // }

    // public fun quote_swap_<A, B, W: drop>(
    //     self: &Pool<A, B, Hook<W>, State>,
    //     amount_in: u64,
    //     a2b: bool,
    // ): SwapQuote {
    //     // TODO
    // }
    
    // public fun quote_swap<A, B, W: drop>(
    //     self: &Pool<A, B, Hook<W>, State>,
    //     amount_in: u64,
    //     a2b: bool,
    // ): SwapQuote {
    //     // TODO
    // }

    // ===== Versioning =====
    
    entry fun migrate<A, B, W>(
        self: &mut Pool<A, B, Hook<W>, State>,
        _cap: &PoolCap<A, B, Hook<W>>,
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

    
    // ===== Private Functions =====

    fun compute(
        amp: u64,
        reserve_a: u64,
        reserve_b: u64,
    ): Decimal {
        // if amplifier is zero, then the invariant of the curve is just the product
        // of tokens
        if (amp == 0) {
            abort(EInavlidAmplifier)
        };

        // we proved that the invariant D value is bounded above by the sum of
        // tokens reserve amounts. For this reason, the value of D should be
        // able to be represented by a Decimal type, whenever each single token
        // reserve is also represented by Decimal (which should always be the case)
        new_invariant(amp, reserve_a, reserve_b).compute_()
    }

    fun new_invariant(
        amp: u64,
        reserve_a: u64,
        reserve_b: u64,
    ): StableCurveInvariant {
        let amp = decimal::from(amp);

        let sum = decimal::from(reserve_a + reserve_b); // our initial guess for Newton's method

        let scl_down_sum = scale_down_value(sum);
        let initial_guess = scl_down_sum.scale_down;
        let scl_down_exp = scl_down_sum.exponent;

        let scl_down_coef =
            decimal::from(1000_u64).pow(scl_down_exp as u64);

        let product = decimal::from(reserve_a).div(scl_down_coef).mul(
            decimal::from(reserve_b).div(scl_down_coef)
        );

        // we don't allow trades in which the product is infinitesimally close
        // to zero, as this means extreme imbalance on a stable swap pool
        if (product.lt(decimal::from_scaled_val(1_000_000_u256))) {
            abort(EMathOverflow)
        };

        let exponent = 2; // number of reserves
        let base: Decimal = decimal::from(exponent); // todo: double check..
        let n: Decimal = base.pow(exponent);
        let n_n_scaled_product = n.mul(product);
        let first_order_coeff = amp
            .mul(n)
            .sub(decimal::from(1))
            .mul(n_n_scaled_product);

        let polynomial_third_term = amp
            .mul(n)
            .mul(sum)
            .mul(n_n_scaled_product)
            .div(scl_down_coef);

        StableCurveInvariant {
            first_order_coeff,
            exponent,
            initial_guess,
            scl_down_coef,
            polynomial_third_term,
        }
    }

    fun scale_down_value(mut val: Decimal): ScaleDownOutput {
        let mut n = 0u32;
        let bound = decimal::from(1000u64);

        while (val.gt(bound)) {
            val = val.div(decimal::from(1000u64));
            n = n + 1u32;
        };

        ScaleDownOutput {
            scale_down: val,
            exponent: n,
        }
    }



    fun compute_(self: &StableCurveInvariant): Decimal {
        // acts as a threshold for the difference between successive
        // approximations
        let admissible_error: Decimal =
            decimal::from(1u64).div(decimal::from(2u64));

        // our initial guess is the scaled down sum of token reserve balances
        let mut prev_val = self.initial_guess;

        // current iteration of Newton-Raphson method
        let mut new_val = prev_val;

        let iterations = MAX_ITERATIONS;
        let solved = false;

        while (iterations > 0 || solved == false) {
            prev_val = new_val;
            new_val = self.newton_method_single_iteration(prev_val);
            // We proved by algebraic manipulations that given a first initial
            // guess coinciding with the sum of token reserve
            // balances, then sum(x_i) >= positive_zero where
            // positive_zero is the positive zero of the stable swap
            // polynomial. Moreover, the method is decreasing on
            // each iteration. Therefore, in order to check that the method
            // converges, we only need to check that (prev_iter - next_iter) <=
            // adm_err. Given this assumption, it is impossible that prev_val <
            // new_val and the only case where equality holds is when
            // prev_val is a precise root of the polynomial.
            // Notice also that if x is a root of the stable polynomial,
            // applying Newton method to it will result in getting x again,
            // and the reciprocal statement holds true, so it is an equivalence.
            // Thus, the following checks are sufficient to guarantee
            // full logic coverage.
            if (prev_val.le(new_val)) {
                let is_val_root_stable_poly = self
                    .get_stable_swap_polynomial(prev_val)
                    == decimal::from(0);

                if (is_val_root_stable_poly) {
                    return prev_val.mul(self.scl_down_coef);
                } else {
                    // in this case, prev_val is not a root of the polynomial,
                    // and therefore having prev_val <=
                    // new_val would violate our
                    // mathematical assumptions
                    abort(EInvalidRoot)
                }
            };

            // assuming that prev_val >= new_val, we just need to check that
            // prev_val - new_val <= adm_error
            if (prev_val.sub(new_val).le(admissible_error)) {
                break;
            }
        };

        new_val.mul(self.scl_down_coef)
    }

    fun newton_method_single_iteration(
        self: &StableCurveInvariant,
        initial_guess: Decimal,
    ): Decimal {
        let stable_swap_poly =
            self.get_stable_swap_polynomial(initial_guess);
        let derivative_stable_swap_poly =
            self.get_derivate_stable_swap_polynomial(initial_guess);

        initial_guess
            .sub(stable_swap_poly.div(derivative_stable_swap_poly))
    }

    fun get_stable_swap_polynomial(self: &StableCurveInvariant, val: Decimal): Decimal {
        // D^(n+1) + D(An^n -1)\prod_i x_i n^n + A(n^n)^2\sum_i x_i \prod_i x_i
        let first_term = val.pow(self.exponent + 1);

        let second_term = val.mul(self.first_order_coeff);

        first_term.add(second_term).sub(self.polynomial_third_term)
    }

    fun get_derivate_stable_swap_polynomial(
        self: &StableCurveInvariant,
        val: Decimal,
    ): Decimal {
        let first_term = decimal::from(self.exponent).add(decimal::from(1)).mul(val.pow(self.exponent));
        let second_term = self.first_order_coeff;

        first_term.add(second_term)
    }
}
