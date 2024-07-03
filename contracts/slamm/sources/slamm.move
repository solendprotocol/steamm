module slamm::pool {
    use std::option::none;
    use sui::tx_context::sender;
    use sui::clock::Clock;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance, Supply};
    use slamm::events::emit_event;
    use slamm::registry::{Registry};
    use slamm::math::{safe_mul_div_u64};
    use slamm::global_admin::GlobalAdmin;
    use slamm::fees::{Self, Fees, FeeData};
    use slamm::quote::{SwapQuote, DepositQuote, RedeemQuote};
    use slamm::lend::{Self, Lending, LendingConfig, LendingAction};
    use suilend::lending_market::LendingMarket;
    
    public use fun slamm::cpmm::deposit_liquidity as Pool.cpmm_deposit;
    public use fun slamm::cpmm::redeem_liquidity as Pool.cpmm_redeem;
    public use fun slamm::cpmm::swap as Pool.cpmm_swap;
    public use fun slamm::cpmm::quote_swap as Pool.cpmm_quote_swap;
    public use fun slamm::cpmm::quote_deposit as Pool.cpmm_quote_deposit;
    public use fun slamm::cpmm::quote_redeem as Pool.cpmm_quote_redeem;
    public use fun slamm::cpmm::k as Pool.cpmm_k;

    // Consts
    const SWAP_FEE_NUMERATOR: u64 = 200;
    const SWAP_FEE_DENOMINATOR: u64 = 10_000;

    // Error codes
    const EFeeAbove100Percent: u64 = 0;
    const ESwapExceedsSlippage: u64 = 1;
    const EOutputAExceedsLiquidity: u64 = 2;
    const EOutputBExceedsLiquidity: u64 = 3;
    const EPoolGuarded: u64 = 4;
    const EPoolUnguarded: u64 = 5;
    const ELpBurnAmountMismatch: u64 = 6; // Should not occur
    const ELendingAlreadyOnForA: u64 = 7;
    const ELendingAlreadyOnForB: u64 = 8;
    const ELendingOffForA: u64 = 9;
    const ELendingOffForB: u64 = 10;
    const EPoolIdMistmatch: u64 = 11;

    /// Marker type for the LP coins of a pool. There can only be one
    /// pool per type, albeit given the permissionless aspect of the pool
    /// creation, we allow for pool creators to export their own types. The creator's
    /// type is not explicitly expressed in the generic types of this struct,
    /// instead the hooks types in our implementations follow the `Hook<phantom W>`
    /// schema. This has the advantage that we do not require an extra generic
    /// type on the `LP` as well as on the `Pool`
    public struct LP<phantom A, phantom B, phantom Hook: drop> has copy, drop {}

    public struct PoolCap<phantom A, phantom B, phantom Hook: drop> {
        id: UID,
        pool_id: ID,
    }

    public struct Pool<phantom A, phantom B, phantom Hook: drop, State: store> has key, store {
        id: UID,
        inner: State,
        reserve_a: Balance<A>,
        reserve_b: Balance<B>,
        lp_supply: Supply<LP<A, B, Hook>>,
        protocol_fees: Fees<A, B>,
        pool_fees: FeeData,
        trading_data: TradingData,
        lending_a: Option<Lending>,
        lending_b: Option<Lending>,
        lock_guard: bool,
    }

    public struct TradingData has store {
        // swap a2b
        swap_a_in_amount: u128,
        swap_b_out_amount: u128,
        // swap b2a
        swap_a_out_amount: u128,
        swap_b_in_amount: u128,
    }

    public struct Intent<Quote, phantom A, phantom B, phantom Hook> {
        pool_id: ID,
        quote: Quote,
        lending_a: LendingAction,
        lending_b: LendingAction,
    }

    // ===== Public Methods =====

    public(package) fun new<A, B, Hook: drop, State: store>(
        _witness: Hook,
        registry: &mut Registry,
        swap_fee_bps: u64,
        inner: State,
        ctx: &mut TxContext,
    ): (Pool<A, B, Hook, State>, PoolCap<A, B, Hook>) {
        assert!(swap_fee_bps < SWAP_FEE_DENOMINATOR, EFeeAbove100Percent);

        let lp_supply = balance::create_supply(LP<A, B, Hook>{});

        let pool = Pool {
            id: object::new(ctx),
            inner,
            reserve_a: balance::zero(),
            reserve_b: balance::zero(),
            protocol_fees: fees::new(SWAP_FEE_NUMERATOR, SWAP_FEE_DENOMINATOR),
            pool_fees: fees::new_(swap_fee_bps, SWAP_FEE_DENOMINATOR),
            lp_supply,
            trading_data: TradingData {
                swap_a_in_amount: 0,
                swap_b_out_amount: 0,
                swap_a_out_amount: 0,
                swap_b_in_amount: 0,
            },
            lending_a: none(),
            lending_b: none(),
            lock_guard: false,
        };

        registry.add_amm(&pool);

        // Create pool cap
        let pool_cap = PoolCap {
            id: object::new(ctx),
            pool_id: pool.id.uid_to_inner(),
        };


        // Emit event
        emit_event(
            NewPoolResult {
                creator: sender(ctx),
                pool_id: object::id(&pool),
            }
        );

        (pool, pool_cap)
    }

    
    public fun swap<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
        _witness: Hook,
        coin_a: &mut Coin<A>,
        coin_b: &mut Coin<B>,
        swap_intent: Intent<SwapQuote, A, B, Hook>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): SwapResult {
        let quote = swap_intent.quote();
        let amount_in = quote.amount_in();
        let amount_out = quote.amount_out();
        let a2b = quote.a2b();

        assert!(quote.amount_out() > min_amount_out, ESwapExceedsSlippage);
        
        let (protocol_fee_num, protocol_fee_denom) = self.protocol_fees.fee_ratio();
        let (admin_fee_num, admin_fee_denom) = self.pool_fees.fee_ratio();
        
        let protocol_fees = safe_mul_div_u64(amount_in, protocol_fee_num, protocol_fee_denom);
        let pool_fees = safe_mul_div_u64(amount_in, admin_fee_num, admin_fee_denom);

        if (a2b) {
            self.assert_liquidity_requirements(
                amount_in - protocol_fees,
                amount_out,
                true,
                false,
            );

            assert!(amount_out < self.reserve_b.value(), EOutputBExceedsLiquidity);
            let mut balance_in = coin_a.balance_mut().split(amount_in);

            // Transfers protocol fees in
            self.protocol_fees.deposit_a(balance_in.split(protocol_fees));
            
            // Account pool fees in
            self.pool_fees.increment_fee_a(pool_fees);

            // Transfers amount in
            self.reserve_a.join(balance_in);
        
            // Transfers amount out
            coin_b.balance_mut().join(self.reserve_b.split(amount_out));
        } else {
            self.assert_liquidity_requirements(
                amount_out,
                amount_in - protocol_fees,
                false,
                true,
            );

            assert!(amount_out < self.reserve_a.value(), EOutputAExceedsLiquidity);
            let mut balance_in = coin_b.balance_mut().split(amount_in);

            // Transfers protocol fees in
            self.protocol_fees.deposit_b(balance_in.split(protocol_fees));
            
            // Account pool fees in
            self.pool_fees.increment_fee_b(pool_fees);

            // Transfers amount in
            self.reserve_b.join(balance_in);
        
            // Transfers amount out
            coin_a.balance_mut().join(self.reserve_a.split(amount_out));
        };

        // Emit event
        let result = SwapResult {
            user: sender(ctx),
            pool_id: object::id(self),
            amount_in,
            amount_out,
            protocol_fees,
            pool_fees,
            a2b,
        };

        emit_event(result);

        self.consume(swap_intent);

        result
    }

    public fun deposit_liquidity<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
        _witness: Hook,
        balance_a: &mut Balance<A>,
        balance_b: &mut Balance<B>,
        deposit_intent: Intent<DepositQuote, A, B, Hook>,
        ctx:  &mut TxContext,
    ): (Coin<LP<A, B, Hook>>, DepositResult) {
        let quote = deposit_intent.quote();

        let deposit_a = balance_a.split(quote.deposit_a());
        let deposit_b = balance_b.split(quote.deposit_b());

        self.assert_liquidity_requirements(
            deposit_a.value(),
            deposit_b.value(),
            true,
            true,
        );
        
        // 1. Add liquidity to pool
        self.reserve_a.join(deposit_a);
        self.reserve_b.join(deposit_b);

        // 2. Mint LP Tokens
        let lp_coins = coin::from_balance(
            self.lp_supply.increase_supply(quote.mint_lp()),
            ctx
        );

        // 4. Emit event
        let result = DepositResult {
            user: sender(ctx),
            pool_id: object::id(self),
            deposit_a: quote.deposit_a(),
            deposit_b: quote.deposit_b(),
            mint_lp: quote.mint_lp(),
        };
        
        emit_event(result);
        self.consume(deposit_intent);

        (lp_coins, result)
    }
    
    public fun redeem_liquidity<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
        _witness: Hook,
        redeem_intent: Intent<RedeemQuote, A, B, Hook>,
        lp_tokens: Coin<LP<A, B, Hook>>,
        ctx:  &mut TxContext,
    ): (Coin<A>, Coin<B>, RedeemResult) {
        let quote = redeem_intent.quote();
        assert!(quote.burn_lp() == lp_tokens.value(), ELpBurnAmountMismatch);

        self.assert_liquidity_requirements(
            quote.withdraw_a(),
            quote.withdraw_b(),
            false,
            false,
        );

        let lp_burn = lp_tokens.value();

        // 1. Burn LP Tokens
        self.lp_supply.decrease_supply(
            lp_tokens.into_balance()
        );

        // 2. Prepare tokens to send
        let base_tokens = coin::from_balance(
            self.reserve_a.split(quote.withdraw_a()),
            ctx,
        );
        let quote_tokens = coin::from_balance(
            self.reserve_b.split(quote.withdraw_b()),
            ctx,
        );

        // 3. Emit events
        let result = RedeemResult {
            user: sender(ctx),
            pool_id: object::id(self),
            withdraw_a: quote.withdraw_a(),
            withdraw_b: quote.withdraw_b(),
            burn_lp: lp_burn,
        };

        emit_event(result);
        self.consume(redeem_intent);

        (base_tokens, quote_tokens, result)
    }

    public fun net_amount_in<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>, amount_in: u64): (u64, u64, u64) {
        let (protocol_fee_num, protocol_fee_denom) = self.protocol_fees.fee_ratio();
        let (pool_fee_num, pool_fee_denom) = self.pool_fees.fee_ratio();
        
        let protocol_fees = safe_mul_div_u64(amount_in, protocol_fee_num, protocol_fee_denom);
        let pool_fees = safe_mul_div_u64(amount_in, pool_fee_num, pool_fee_denom);
        let net_amount_in = amount_in - protocol_fees - pool_fees;

        (net_amount_in, protocol_fees, pool_fees)
    }

    // ===== Public Lending functions =====

    public fun init_lending<A, B, Hook: drop, State: store, P>(
        self: &mut Pool<A, B, Hook, State>,
        _: &PoolCap<A, B, Hook>,
        config: &LendingConfig,
        is_a: bool,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        config.assert_p_type<P>();

        if (is_a) {
            assert!(self.lending_a.is_none(), ELendingAlreadyOnForA);
            config.assert_coin_type<A>();

            self.lending_a.fill(
                lend::new<P, A>(config, clock, ctx)
            );

        } else {
            assert!(self.lending_b.is_none(), ELendingAlreadyOnForB);
            config.assert_coin_type<B>();

            self.lending_a.fill(
                lend::new<P, B>(config, clock, ctx)
            );
        }
    }

    public fun set_lending_requirements<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
        config: &LendingConfig,
        is_a: bool,
        clock: &Clock,
    ) {
        if (is_a) {
            assert!(self.lending_a.is_some(), ELendingOffForA);
            
            let lending_a = self.lending_a.borrow_mut();
            lending_a.sync_liquidity_ratio(config, clock);


        } else {
            assert!(self.lending_b.is_some(), ELendingOffForB);
            
            let lending_b = self.lending_b.borrow_mut();
            lending_b.sync_liquidity_ratio(config, clock);
        }
    }

    public fun rebalance_lending<A, B, Hook: drop, State: store, P, IntentOp>(
        self: &mut Pool<A, B, Hook, State>,
        amm_intent: &Intent<IntentOp, A, B, Hook>,
        lending_market: &mut LendingMarket<P>, 
        reserve_array_index: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        lend::rebalance_lending(
            &mut self.reserve_a,
            &mut self.reserve_b,
            &mut self.lending_a,
            &mut self.lending_b,
            &amm_intent.lending_a,
            &amm_intent.lending_b,
            lending_market,
            reserve_array_index,
            clock,
            ctx,
        );
    }

    
    // ===== View & Getters =====
    
    public fun full_reserves<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>): (u64, u64) {
        let reserve_a = if (self.lending_a.is_some()) {
            self.reserve_a.value() + self.lending_a.borrow().lent()
        } else {
            self.reserve_a.value()
        };

        let reserve_b = if (self.lending_b.is_some()) {
            self.reserve_b.value() + self.lending_b.borrow().lent()
        } else {
            self.reserve_b.value()
        };
        
        (reserve_a, reserve_b)
    }
    
    public fun fractional_reserves<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>): (u64, u64) {        
        (self.reserve_a.value(), self.reserve_b.value())
    }
    
    public fun protocol_fees<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>): &Fees<A, B> {
        &self.protocol_fees
    }
    
    public fun pool_fees<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>): &FeeData {
        &self.pool_fees
    }
    
    public fun lp_supply_val<A, B, Hook: drop, State: store>(self: &Pool<A, B, Hook, State>): u64 {
        self.lp_supply.supply_value()
    }

    // ===== Intent functions =====

    public(package) fun as_intent<A, B, Hook: drop, State: store, Quote>(
        quote: Quote,
        pool: &mut Pool<A, B, Hook, State>,
        lending_a: LendingAction,
        lending_b: LendingAction,
        _: Hook,
    ): Intent<Quote, A, B, Hook> {
        pool.guard();
        
        Intent {
            pool_id: object::id(pool),
            quote: quote,
            lending_a,
            lending_b,
        }
    }
    
    public(package) fun as_intent_swap<A, B, Hook: drop, State: store>(
        quote: SwapQuote,
        pool: &mut Pool<A, B, Hook, State>,
        lending_a: LendingAction,
        lending_b: LendingAction,
        hook: Hook,
    ): Intent<SwapQuote, A, B, Hook> {
        as_intent(
            quote,
            pool,
            lending_a,
            lending_b,
            hook,
        )
    }
    
    public(package) fun as_intent_deposit<A, B, Hook: drop, State: store>(
        quote: DepositQuote,
        pool: &mut Pool<A, B, Hook, State>,
        lending_a: LendingAction,
        lending_b: LendingAction,
        hook: Hook,
    ): Intent<DepositQuote, A, B, Hook> {
        as_intent(
            quote,
            pool,
            lending_a,
            lending_b,
            hook,
        )
    }
    
    public(package) fun as_intent_redeem<A, B, Hook: drop, State: store>(
        quote: RedeemQuote,
        pool: &mut Pool<A, B, Hook, State>,
        lending_a: LendingAction,
        lending_b: LendingAction,
        hook: Hook,
    ): Intent<RedeemQuote, A, B, Hook> {
        as_intent(
            quote,
            pool,
            lending_a,
            lending_b,
            hook,
        )
    }
    
    fun consume<A, B, Hook: drop, State: store, Quote: drop>(
        pool: &mut Pool<A, B, Hook, State>,
        intent: Intent<Quote, A, B, Hook>,
    ) {
        pool.unguard();
        assert!(object::id(pool) == intent.pool_id, EPoolIdMistmatch);

        let Intent { pool_id: _, quote: _, lending_a: _, lending_b: _ } = intent;

    }

    public fun quote<Op, A, B, Hook>(self: &Intent<Op, A, B, Hook>): &Op { &self.quote }
    public fun lending_a<Op, A, B, Hook>(self: &Intent<Op, A, B, Hook>): &LendingAction { &self.lending_a }
    public fun lending_b<Op, A, B, Hook>(self: &Intent<Op, A, B, Hook>): &LendingAction { &self.lending_b }


    // ===== Package functions =====

    fun assert_unguarded<A, B, Hook: drop, State: store>(
        pool: &Pool<A, B, Hook, State>,
    ) {
        assert!(pool.lock_guard == false, EPoolGuarded);
    }
    
    fun assert_guarded<A, B, Hook: drop, State: store>(
        pool: &Pool<A, B, Hook, State>,
    ) {
        assert!(pool.lock_guard == true, EPoolUnguarded);
    }
    
    public(package) fun guard<A, B, Hook: drop, State: store>(
        pool: &mut Pool<A, B, Hook, State>,
    ) {
        pool.assert_unguarded();
        pool.lock_guard = true
    }
    
    public(package) fun unguard<A, B, Hook: drop, State: store>(
        pool: &mut Pool<A, B, Hook, State>,
    ) {
        pool.assert_guarded();
        pool.lock_guard = false
    }
    
    public(package) fun inner<A, B, Hook: drop, State: store>(
        pool: &Pool<A, B, Hook, State>,
    ): &State {
        &pool.inner
    }
    
    public(package) fun inner_mut<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
    ): &mut State {
        &mut self.inner
    }

    // ===== Admin endpoints =====

    public fun collect_protol_fees<A, B, Hook: drop, State: store>(
        _global_admin: &GlobalAdmin,
        self: &mut Pool<A, B, Hook, State>,
        ctx: &mut TxContext,
    ): (Coin<A>, Coin<B>) {

        let (fees_a, fees_b) = self.protocol_fees.withdraw();

        (
            coin::from_balance(fees_a, ctx),
            coin::from_balance(fees_b, ctx)
        )
    }

    fun assert_liquidity_requirements<A, B, Hook: drop, State: store>(
        self: &Pool<A, B, Hook, State>,
        amount_a: u64,
        amont_b: u64,
        a_in: bool,
        b_in: bool,
    ) {
        if (self.lending_a.is_some()) {
                let lent = self.lending_a.borrow().lent();
                self.lending_a.borrow().assert_liquidity_requirements(
                    self.reserve_a.value(),
                    amount_a,
                    a_in,
                    lent
                );
            };

            if (self.lending_b.is_some()) {
                let lent = self.lending_b.borrow().lent();
                self.lending_b.borrow().assert_liquidity_requirements(
                    self.reserve_b.value(),
                    amont_b,
                    b_in,
                    lent
                );
            };
    }
    
    public fun compute_lending_actions<A, B, Hook: drop, State: store>(
        self: &Pool<A, B, Hook, State>,
        amount_a: u64,
        amont_b: u64,
        a_in: bool,
        b_in: bool,
    ): (LendingAction, LendingAction) {
        let lending_action_a = if (self.lending_a.is_some()) {
                let lent = self.lending_a.borrow().lent();
                self.lending_a.borrow().compute_lending_action(
                    self.reserve_a.value(),
                    amount_a,
                    a_in,
                    lent
                )
            } else { lend::no_op() };

        let lending_action_b = if (self.lending_b.is_some()) {
                let lent = self.lending_b.borrow().lent();
                self.lending_b.borrow().compute_lending_action(
                    self.reserve_b.value(),
                    amont_b,
                    b_in,
                    lent
                )
            } else { lend::no_op() };

        (lending_action_a, lending_action_b)
    }
    
    // ===== Results/Events =====

    public struct NewPoolResult has copy, drop, store {
        creator: address,
        pool_id: ID,
    }
    
    public struct SwapResult has copy, drop, store {
        user: address,
        pool_id: ID,
        amount_in: u64,
        amount_out: u64,
        protocol_fees: u64,
        pool_fees: u64,
        a2b: bool,
    }
    
    public struct DepositResult has copy, drop, store {
        user: address,
        pool_id: ID,
        deposit_a: u64,
        deposit_b: u64,
        mint_lp: u64,
    }
    
    public struct RedeemResult has copy, drop, store {
        user: address,
        pool_id: ID,
        withdraw_a: u64,
        withdraw_b: u64,
        burn_lp: u64,
    }

    public use fun swap_result_user as SwapResult.user;
    public use fun swap_result_pool_id as SwapResult.pool_id;
    public use fun swap_result_amount_in as SwapResult.amount_in;
    public use fun swap_result_amount_out as SwapResult.amount_out;
    public use fun swap_result_net_amount_in as SwapResult.net_amount_in;
    public use fun swap_result_protocol_fees as SwapResult.protocol_fees;
    public use fun swap_result_pool_fees as SwapResult.pool_fees;
    public use fun swap_result_a2b as SwapResult.a2b;

    public use fun deposit_result_user as DepositResult.user;
    public use fun deposit_result_pool_id as DepositResult.pool_id;
    public use fun deposit_result_deposit_a as DepositResult.deposit_a;
    public use fun deposit_result_deposit_b as DepositResult.deposit_b;
    public use fun deposit_result_mint_lp as DepositResult.mint_lp;

    public use fun redeem_result_user as RedeemResult.user;
    public use fun redeem_result_pool_id as RedeemResult.pool_id;
    public use fun redeem_result_withdraw_a as RedeemResult.withdraw_a;
    public use fun redeem_result_withdraw_b as RedeemResult.withdraw_b;
    public use fun redeem_result_burn_lp as RedeemResult.burn_lp;

    public fun swap_result_user(self: &SwapResult): address { self.user }
    public fun swap_result_pool_id(self: &SwapResult): ID { self.pool_id }
    public fun swap_result_amount_in(self: &SwapResult): u64 { self.amount_in }
    public fun swap_result_amount_out(self: &SwapResult): u64 { self.amount_out }
    public fun swap_result_net_amount_in(self: &SwapResult): u64 { self.amount_in - self.protocol_fees - self.pool_fees}
    public fun swap_result_protocol_fees(self: &SwapResult): u64 { self.protocol_fees }
    public fun swap_result_pool_fees(self: &SwapResult): u64 { self.pool_fees }
    public fun swap_result_a2b(self: &SwapResult): bool { self.a2b }

    public fun deposit_result_user(self: &DepositResult): address { self.user }
    public fun deposit_result_pool_id(self: &DepositResult): ID { self.pool_id }
    public fun deposit_result_deposit_a(self: &DepositResult): u64 { self.deposit_a }
    public fun deposit_result_deposit_b(self: &DepositResult): u64 { self.deposit_b }
    public fun deposit_result_mint_lp(self: &DepositResult): u64 { self.mint_lp }

    public fun redeem_result_user(self: &RedeemResult): address { self.user }
    public fun redeem_result_pool_id(self: &RedeemResult): ID { self.pool_id }
    public fun redeem_result_withdraw_a(self: &RedeemResult): u64 { self.withdraw_a }
    public fun redeem_result_withdraw_b(self: &RedeemResult): u64 { self.withdraw_a }
    public fun redeem_result_burn_lp(self: &RedeemResult): u64 { self.burn_lp }

    // ===== Test-Only =====

    #[test_only]
    public(package) fun reserve_a_mut_for_testing<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
    ): &mut Balance<A> {
        &mut self.reserve_a
    }
    
    #[test_only]
    public(package) fun reserve_b_mut_for_testing<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
    ): &mut Balance<A> {
        &mut self.reserve_a
    }
    
    #[test_only]
    public(package) fun lp_supply_mut_for_testing<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
    ): &mut Supply<LP<A, B, Hook>> {
        &mut self.lp_supply
    }
    
    #[test_only]
    public(package) fun protocol_fees_mut_for_testing<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
    ): &mut Fees<A, B> {
        &mut self.protocol_fees
    }
    
    #[test_only]
    public(package) fun pool_fees_mut_for_testing<A, B, Hook: drop, State: store>(
        self: &mut Pool<A, B, Hook, State>,
    ): &mut FeeData {
        &mut self.pool_fees
    }
}
