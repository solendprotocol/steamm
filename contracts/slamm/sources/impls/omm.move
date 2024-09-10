/// Oracle AMM Hook implementation
module slamm::omm {
    use sui::coin::Coin;
    use sui::clock::Clock;
    use slamm::{
        global_admin::GlobalAdmin,
        registry::{Registry},
        math::safe_mul_div_up,
        quote::SwapQuote,
        bank::Bank,
        cpmm,
        pool::{Self, Pool, PoolCap, SwapResult, Intent},
        version::{Self, Version},
    };
    use suilend::{
        decimal::{Self, Decimal},
    };
    use slamm::oracle_wrapper::OraclePrice;

    // ===== Constants =====

    const CURRENT_VERSION: u16 = 1;
    const BPS: u64 = 10_000;
    // 500 bos => 5%, which is equal to (1-5%) = 95% confidence interval
    const MAX_CONFIDENCE_BPS: u64 = 500;
    const MAX_STALENESS_SECONDS: u64 = 60;

    // ===== Errors =====

    const EPriceInfoIsZero: u64 = 4;

    /// Hook type for the Oracle AMM implementation. Serves as both
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

    /// Oracle AMM specific state. We do not store the invariant,
    /// instead we compute it at runtime.
    public struct State has store {
        version: Version,
        // Reference price from which we compute the absolute price deviation
        reference_price: Decimal,
        // Exponential Moving-Average of the absolute price deviation (instant vol)
        ema: Ema,
        // Indicates the last time the price and vol references have been updated
        last_update_ms: u64,
        // Indicates the period (time delta) in which the references do not get
        // updated
        filter_period: u64,
        // Period followin the filter period, from which the references do get updated.
        // Indicates the period in which we apply a discount to the accumulated
        // vol. Beyond the discount period the accumulated vol gets resetted.
        decay_period: u64,
        // Factor applied to the fee calculation to scale the fee value.
        fee_control: Decimal,
    }

    /// Object containing the Exponential Moving-Average information.
    /// In the current implementation this object stores the information
    /// pertaining to the instant volatility.
    public struct Ema has store {
        // Reference value of the instant volatility, which gets periodically
        // updated.
        reference_val: Decimal,
        // Volatility accumulated
        accumulator: Decimal,
        // Discount factor applied to the volatility accumulator during the
        // decay period
        reduction_factor: Decimal,
        // Maximum value for the accumulator
        max_accumulator: Decimal,
    }

    // ===== Public Methods =====

    /// Initializes and returns a new AMM Pool along with its associated PoolCap.
    /// The pool is initialized with zero balances for both coin types `A` and `B`,
    /// specified protocol fees, and the provided swap fee. The pool's LP supply
    /// object is initialized at zero supply and the pool is added to the `registry`.
    /// 
    /// Such the initial parameters such as:
    /// 
    /// - Filter period in miliseconds
    /// - Decay period in miliseconds: cumulative over the filter period
    /// - Fee control factor in basis points
    /// - Reduction factor in basis points
    /// - Max accumulated vol in basis points
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
        swap_fee_bps: u64,
        price_a: OraclePrice<A>,
        price_b: OraclePrice<B>,
        filter_period: u64,
        decay_period: u64,
        fee_control_bps: u64,
        reduction_factor_bps: u64,
        max_vol_accumulated_bps: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Pool<A, B, Hook<W>, State>, PoolCap<A, B, Hook<W>, State>) {
        price_a.check_price(MAX_CONFIDENCE_BPS, MAX_STALENESS_SECONDS, clock);
        price_b.check_price(MAX_CONFIDENCE_BPS, MAX_STALENESS_SECONDS, clock);

        let reference_price = new_instant_price_oracle(&price_a, &price_b);
        
        let inner = State {
            version: version::new(CURRENT_VERSION),
            ema: Ema {
                reference_val: decimal::from(0),
                accumulator: decimal::from(0),
                reduction_factor: decimal::from(reduction_factor_bps).div(decimal::from(BPS)),
                max_accumulator: decimal::from(max_vol_accumulated_bps).div(decimal::from(BPS)),
            },
            reference_price,
            last_update_ms: clock.timestamp_ms(),
            filter_period,
            decay_period,
            fee_control: decimal::from(fee_control_bps).div(decimal::from(BPS)),
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
        price_a: OraclePrice<A>,
        price_b: OraclePrice<B>,
        amount_in: u64,
        a2b: bool,
        clock: &Clock,
    ): Intent<A, B, Hook<W>, State> {
        price_a.check_price(MAX_CONFIDENCE_BPS, MAX_STALENESS_SECONDS, clock);
        price_b.check_price(MAX_CONFIDENCE_BPS, MAX_STALENESS_SECONDS, clock);

        self.inner_mut().version.assert_version_and_upgrade(CURRENT_VERSION);

        let (quote, reference_price, reference_vol, vol_accumulator, last_update_ms) = quote_swap_impl(
            self, &price_a, &price_b, amount_in, a2b, clock
        );
        
        // Update parameters
        // print(&vol_accumulator);
        self.inner_mut().ema.accumulator = vol_accumulator;
        self.inner_mut().reference_price = reference_price;
        self.inner_mut().ema.reference_val = reference_vol;
        self.inner_mut().last_update_ms = last_update_ms;

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

        let k0 = cpmm::k(self);

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
        cpmm::assert_invariant_does_not_decrease(self, k0);

        response
    }

    public(package) fun quote_swap_impl<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        price_a: &OraclePrice<A>,
        price_b: &OraclePrice<B>,
        amount_in: u64,
        a2b: bool,
        clock: &Clock,
    ): (SwapQuote, Decimal, Decimal, Decimal, u64) {
        quote_swap_(self, price_a, price_b, amount_in, a2b, clock)
    }
    
    /// Computes a swap quote for a given input amount and direction
    /// taking into account fees, price updates, and volatility:
    /// 
    /// - We assert that the current price data is fresh by checking against `current_ms`.
    /// - Pull price and volatility updates based on the time elapsed since the last update.
    /// - Compute the swap quote based on the constant-product implementation
    /// - Compute base fees on the quote output
    /// - Computes accumulated volatility and with it the dynamic fees
    /// 
    /// This function does not mutate the pool with new reference updates so that
    /// it can be called by the swap_intent function as well as the read-only quote swap.
    ///
    /// # Returns
    /// A tuple containing:
    /// - Swap quote
    /// - Reference price
    /// - Reference volatility
    /// - Accumulated volatility
    /// - Time of last reference update (in ms)
    fun quote_swap_<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        price_a: &OraclePrice<A>,
        price_b: &OraclePrice<B>,
        amount_in: u64,
        a2b: bool,
        clock: &Clock,
    ): (SwapQuote, Decimal, Decimal, Decimal, u64) {
        let (reserve_a, reserve_b) = self.total_funds();

        // Update price and vol reference depending on timespan ellapsed
        let (reference_price, reference_vol, last_update_ms) = get_updated_references(
            self,
            price_a,
            price_b,
            clock,
        );

        let amount_out = cpmm::quote_swap_impl(
            reserve_a,
            reserve_b,
            amount_in,
            a2b,
        );

        let mut quote = self.get_quote(amount_in, amount_out, a2b);

        let new_instant_price_internal = new_instant_price_internal(self, &quote);
        let new_instant_price_oracle = new_instant_price_oracle(
            price_a,
            price_b,
        );

        let vol_accumulator = self.inner().new_volatility_accumulator(
            reference_price,
            reference_vol,
            new_instant_price_internal,
            new_instant_price_oracle
        );

        let variable_fee = vol_accumulator.pow(2).mul(self.inner().fee_control).div(decimal::from(100));

        let total_variable_fee = decimal::from(quote.amount_out()).mul(variable_fee).ceil();
        let (protocol_fee_num, protocol_fee_denom) = self.protocol_fees().fee_ratio();

        let protocol_fees = safe_mul_div_up(total_variable_fee, protocol_fee_num, protocol_fee_denom);
        let pool_fees = total_variable_fee - protocol_fees;

        quote.add_extra_fees(protocol_fees, pool_fees);

        (quote, reference_price, reference_vol, vol_accumulator, last_update_ms)
    }
    
    public fun compute_variable_fee_rate(
        vol_accumulator: Decimal,
        fee_control: Decimal,
    ): Decimal {
        vol_accumulator.pow(2).mul(fee_control).div(decimal::from(100))
    }
    
    public fun quote_swap<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        price_a: &OraclePrice<A>,
        price_b: &OraclePrice<B>,
        amount_in: u64,
        a2b: bool,
        clock: &Clock,
    ): SwapQuote {

        let (quote, _, _, _, _) = quote_swap_impl(self, price_a, price_b, amount_in, a2b, clock);

        quote
    }

    public fun new_instant_price_internal<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        quote: &SwapQuote
    ): Decimal {
        let (a, b) = if (quote.a2b()) {
            (
                self.total_funds_a() + quote.amount_in(),
                self.total_funds_b() - quote.amount_out_net_of_protocol_fees()
            )
        } else {
            (
                self.total_funds_a() - quote.amount_out_net_of_protocol_fees(),
                self.total_funds_b() + quote.amount_in(),
            )
        };

        decimal::from(a).div(decimal::from(b))
    }
    
    public fun instant_price_internal<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
    ): Decimal {
        decimal::from(self.total_funds_a()).div(decimal::from(self.total_funds_b()))
    }
    
    
    public(package) fun new_instant_price_oracle<A, B>(
        oracle_price_a: &OraclePrice<A>,
        oracle_price_b: &OraclePrice<B>,
    ): Decimal {
        let price_a = parse_price_to_decimal(oracle_price_a);
        let price_b = parse_price_to_decimal(oracle_price_b);

        assert!(price_a.gt(decimal::from(0)), EPriceInfoIsZero);
        assert!(price_b.gt(decimal::from(0)), EPriceInfoIsZero);
        
        get_oracle_price(
            price_a,
            price_b,
        )
    }

    fun parse_price_to_decimal<CoinType>(price: &OraclePrice<CoinType>): Decimal {
        // we don't support negative prices
        let price_mag = price.base();
        let exponent = price.exponent();
        let price_has_negative_exponent = price.price_has_negative_exponent();

        if (price_has_negative_exponent) {
            decimal::div(
                decimal::from(price_mag),
                decimal::from(
                    10_u64.pow(exponent as u8)
                )
            )
        }
        else {
            decimal::mul(
                decimal::from(price_mag),
                decimal::from(
                    10_u64.pow(exponent as u8)
                )
            )
        }
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

    // ===== Getter Functions =====

    public fun ema(self: &State): &Ema { &self.ema }
    public fun reference_val(self: &Ema): Decimal { self.reference_val }
    public fun accumulator(self: &Ema): Decimal { self.accumulator }
    public fun reduction_factor(self: &Ema): Decimal { self.reduction_factor }
    public fun max_accumulator(self: &Ema): Decimal { self.max_accumulator }
    public fun reference_price(self: &State): Decimal { self.reference_price }
    public fun last_update_ms(self: &State): u64 { self.last_update_ms }
    public fun filter_period(self: &State): u64 { self.filter_period }
    public fun decay_period(self: &State): u64 { self.decay_period }
    public fun fee_control(self: &State): Decimal { self.fee_control }
    public fun max_confidence_bps(): u64 { MAX_CONFIDENCE_BPS }
    public fun max_staleness_seconds(): u64 { MAX_STALENESS_SECONDS }
    
    // ===== Private Functions =====

    /// Returns the reference price, reference volatility, and last update timestamp
    /// based on the elapsed time since the last update. These can either be updated
    /// values or carryover depending on the time elapsed.
    ///
    /// We first compute the time elapsed since the last update.
    /// 
    /// - Within the Filter Period:
    ///     The reference values remain unchanged from their previous state.
    /// - Within the Decay Periods:
    ///     Sets reference vol by appltyin a reduction factor to the
    ///     accumulated volatility and updates the reference price using
    ///     the latest oracle data. 
    /// - Beyond Decay Period:
    ///     Reference volatility is reset to zero, and the reference price
    ///     is updated using the latest oracle data.
    /// 
    /// # Returns
    /// A tuple containing:
    /// - Reference price
    /// - Reference volatilite
    /// - Last update in miliseconds
    fun get_updated_references<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        price_a: &OraclePrice<A>,
        price_b: &OraclePrice<B>,
        clock: &Clock,
    ): (Decimal, Decimal, u64) {
        let state = self.inner();
        let current_ms = clock.timestamp_ms();
        let time_elapsed = current_ms - state.last_update_ms;

        if (time_elapsed >= state.filter_period && time_elapsed <= state.decay_period) {
            let reduction_factor = self.inner().ema.reduction_factor;
            let vol_accumulated = self.inner().ema.accumulator;

            let reference_val = vol_accumulated.mul(reduction_factor);
            let reference_price = new_instant_price_oracle(price_a, price_b);
            return (reference_price, reference_val, current_ms)
        };

        if (time_elapsed > state.decay_period) {
            let reference_val = decimal::from(0);
            let reference_price = new_instant_price_oracle(price_a, price_b);
            return (reference_price, reference_val, current_ms)
        };

        // Ths is kept here to make it more readable
        // if (time_elapsed < state.filter_period)
        return (self.inner().reference_price, self.inner().ema.reference_val, state.last_update_ms)
    }

    /// Computes a new volatility accumulator based on the reference price,
    /// reference volatility, and two new price estimates (one based on the constant
    /// product formula and another based on the the oracle feed)
    /// 
    /// Computes the difference between the new prices and the reference price to
    /// determine the absolute rate of change in price.
    /// It then updates the volatility accumulator by adding the maximum price
    /// difference rate to the reference volatility.
    ///
    /// # Returns
    /// - The updated volatility accumulator value
    fun new_volatility_accumulator(
        self: &State,
        reference_price: Decimal,
        reference_vol: Decimal,
        new_price_internal: Decimal,
        new_price_oracle: Decimal,
    ): Decimal {
        let vol_acc = new_volatility_accumulator_(
            reference_price,
            reference_vol,
            new_price_internal,
            new_price_oracle,
        );

        if (vol_acc.lt(self.ema.max_accumulator)) { vol_acc } else { self.ema.max_accumulator }
    }
    
    fun new_volatility_accumulator_(
        reference_price: Decimal,
        reference_vol: Decimal,
        new_price_internal: Decimal,
        new_price_oracle: Decimal,
    ): Decimal {
        let price_diff_rate = decimal::max(
            compute_price_diff_rate(reference_price, new_price_internal),
            compute_price_diff_rate(reference_price, new_price_oracle)
        );

        reference_vol.add(price_diff_rate)
    }
    
    fun compute_price_diff_rate(
        reference_price: Decimal,
        new_price: Decimal,
    ): Decimal {
        let average_price = reference_price.add(new_price).div(decimal::from(2));

        if (new_price.ge(reference_price)) {
            new_price.sub(reference_price).div(average_price)
        } else {
            reference_price.sub(new_price).div(average_price)
        }
    }

    #[allow(unused_function)]
    fun get_oracle_output_amount(
        amount_in: u64,
        input_price: Decimal,
        output_price: Decimal
    ): u64 {
        decimal::from(amount_in).mul(input_price).div(output_price).floor()
    }
    
    fun get_oracle_price(
        price_a: Decimal,
        price_b: Decimal
    ): Decimal {
        price_a.div(price_b)
    }

    // ===== Test-only functions =====


    #[test_only]
    public(package) fun quote_swap_for_testing<A, B, W: drop>(
        self: &Pool<A, B, Hook<W>, State>,
        price_a: &OraclePrice<A>,
        price_b: &OraclePrice<B>,
        amount_in: u64,
        a2b: bool,
        clock: &Clock,
    ): (SwapQuote, Decimal, Decimal, Decimal, u64) {
        quote_swap_(
            self,
            price_a,
            price_b,
            amount_in,
            a2b,
            clock,
        )

    }
    
    #[test_only]
    use sui::test_utils::assert_eq;

    #[test]
    fun test_vol_accumulator() {
        assert_eq(
            compute_price_diff_rate(
                decimal::from(4), decimal::from(2)
            ),
            decimal::from_scaled_val(666666666666666666) // 66%..
        );

        let vol_acc = new_volatility_accumulator_(
            decimal::from(4),
            decimal::from_percent(20), // reference_vol = 20%
            decimal::from(2),
            decimal::from(3),
        );

        assert_eq(vol_acc, decimal::from_scaled_val(866666666666666666)); // 20% + 66%

        assert_eq(
            compute_price_diff_rate(
                decimal::from(4), decimal::from(3)
            ),
            decimal::from_scaled_val(285714285714285714) // 28.57%..
        );
        
        let vol_acc = new_volatility_accumulator_(
            decimal::from(4),
            decimal::from_percent(20), // reference_vol = 20%
            decimal::from(4),
            decimal::from(3),
        );

        assert_eq(vol_acc, decimal::from_scaled_val(485714285714285714));
    }
    
    #[test]
    fun test_get_oracle_price() {
        let price = get_oracle_price(
            decimal::from(110),
            decimal::from(2),
        );

        assert_eq(price, decimal::from(55));
        
        let price = get_oracle_price(
            decimal::from(2),
            decimal::from(110),
        );

        assert_eq(price, decimal::from_scaled_val(18181818181818181_u256)); // 0.0181...
    }
    
    #[test]
    fun test_compute_price_diff() {

        // Relative Deviation = (1.50 - 1) / 1.25 = 40%
        assert_eq(
            compute_price_diff_rate(
                decimal::from(1), decimal::from(15).div(decimal::from(10))
            ),
            decimal::from_scaled_val(400000000000000000) // 40%..
        );
        
        // Relative Deviation = (0.667 - 1) / 0.833 = 40%
        // Where 0.667 = 1 / 1.5, in other words the inverse price
        assert_eq(
            compute_price_diff_rate(
                decimal::from(1), decimal::from(1).div(
                    decimal::from(15).div(decimal::from(10)
                ))
            ),
            decimal::from_scaled_val(400000000000000000) // 40%..
        );
    }
    
    #[test]
    fun test_compute_variable_fee_rate() {

        assert_eq(
            compute_variable_fee_rate(
                decimal::from_percent(90), decimal::from(1)
            ),
            decimal::from_scaled_val(8100000000000000) // 0.0081..
        );
    }
}
