module slamm::lend {
    use std::option::none;
    use std::type_name::{Self, TypeName};
    use sui::bag::{Self, Bag};
    use sui::coin::{Self, Coin};
    use sui::clock::{Clock};
    use sui::balance::{Self, Balance};
    use slamm::global_admin::GlobalAdmin;
    use slamm::quote::Intent;
    use suilend::lending_market::{LendingMarket};
    use suilend::reserve::{CToken};

    // TODO
    const SYNC_TIME: u64 = 1;

    public struct Lending has store {
        lent: u64,
        requirements: LendingRequirements,
        fields: Bag,
    }

    public enum LendingAction has copy, store, drop {
        Lend(u64),
        Ok,
        Recall(u64),
    }

    public struct LendingConfig has key {
        id: UID,
        lending_market: ID,
        p_type: TypeName,
        // Calls that rely on this type reflection are either
        // sporadic or not sensitive to performance. Type reflections here helps
        // reducing the interface so we can act generically over coin types A and B
        coin_type: TypeName,
        liquidity_ratio_bps: u16,
        liquidity_buffer_bps: u16,
    }

    public struct LendingRequirements has store {
        config_id: ID,
        liquidity_ratio_bps: u16,
        liquidity_buffer_bps: u16,
        next_update: Timestamp,
    }

    public struct Timestamp has copy, drop, store (u64)

    public struct LendingReserveKey<phantom T> has copy, store, drop {}

    public struct LendingReserve<phantom P, phantom T> has store {
        c_tokens: Balance<CToken<P, T>>
    }

    public fun lent(self: &Lending): u64 { self.lent }
    
    public(package) fun no_op(): LendingAction { LendingAction::Ok }

    public fun new<P, T>(
        config: &LendingConfig,
        clock: &Clock,
        ctx: &mut TxContext,
        ): Lending {
        let mut lending = Lending {
            lent: 0,
            requirements: config.new_requirements(clock),
            fields: bag::new(ctx),
        };

        lending.add_c_token_field<P, T>();

        lending
    }

    public fun init_lending_config<P, T>(
        _: &GlobalAdmin,
        lending_market: &LendingMarket<P>,
        liquidity_ratio_bps: u16,
        liquidity_buffer_bps: u16,
        ctx: &mut TxContext,
        ): LendingConfig {
        LendingConfig {
            id: object::new(ctx),
            lending_market: object::id(lending_market),
            p_type: type_name::get<P>(),
            coin_type: type_name::get<T>(),
            liquidity_ratio_bps,
            liquidity_buffer_bps,
        }
    }

    public(package) fun rebalance_lending<A, B, Hook: drop, P, IntentOp>(
        reserve_a: &mut Balance<A>,
        reserve_b: &mut Balance<B>,
        lending_a: &mut Option<Lending>,
        lending_b: &mut Option<Lending>,
        amm_intent: &Intent<IntentOp, A, B, Hook>,
        lending_market: &mut LendingMarket<P>, 
        reserve_array_index: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        if (lending_a.is_some()) {
            match (amm_intent.lending_a()) {
                LendingAction::Lend(amount) => {
                    let balance_to_lend = reserve_a.split(*amount);

                    let c_tokens = lending_market.deposit_liquidity_and_mint_ctokens<P, A>(
                        reserve_array_index,
                        clock,
                        coin::from_balance(balance_to_lend, ctx),
                        ctx,
                    );

                    lending_a.borrow_mut().lent = lending_a.borrow().lent + *amount;
                    deposit_c_tokens(lending_a.borrow_mut(), c_tokens.into_balance());
                },
                LendingAction::Ok => {},
                LendingAction::Recall(amount) => {
                    let ctokens: Coin<CToken<P, A>> = coin::from_balance(withdraw_c_tokens(lending_a.borrow_mut(), *amount), ctx);

                    let coin_a = lending_market.redeem_ctokens_and_withdraw_liquidity(
                        reserve_array_index,
                        clock,
                        ctokens,
                        none(), // rate_limiter_exemption
                        ctx,
                    );

                    lending_a.borrow_mut().lent = lending_a.borrow().lent - *amount;

                    reserve_a.join(coin_a.into_balance());
                },
            };
        };
        
        if (lending_b.is_some()) {
            match (amm_intent.lending_b()) {
                LendingAction::Lend(amount) => {
                    let balance_to_lend = reserve_b.split(*amount);
            
                let c_tokens = lending_market.deposit_liquidity_and_mint_ctokens<P, B>(
                    reserve_array_index,
                    clock,
                    coin::from_balance(balance_to_lend, ctx),
                    ctx,
                );

                lending_b.borrow_mut().lent = lending_b.borrow().lent + *amount;
                deposit_c_tokens(lending_b.borrow_mut(), c_tokens.into_balance());
                },
                LendingAction::Ok => {},
                LendingAction::Recall(amount) => {
                    let ctokens: Coin<CToken<P, B>> = coin::from_balance(withdraw_c_tokens(lending_b.borrow_mut(), *amount), ctx);

                    let coin_b = lending_market.redeem_ctokens_and_withdraw_liquidity(
                        reserve_array_index,
                        clock,
                        ctokens,
                        none(), // rate_limiter_exemption
                        ctx,
                    );

                lending_b.borrow_mut().lent = lending_a.borrow().lent - *amount;
                reserve_b.join(coin_b.into_balance());
                },
            };
        };
    }

    public(package) fun new_requirements(
        config: &LendingConfig,
        clock: &Clock,
    ): LendingRequirements {
        LendingRequirements {
            config_id: object::id(config),
            liquidity_ratio_bps: config.liquidity_ratio_bps,
            liquidity_buffer_bps: config.liquidity_buffer_bps,
            next_update: Timestamp(clock.timestamp_ms() + SYNC_TIME),
        }
    }
    
    public(package) fun assert_coin_type<T>(
        config: &LendingConfig,
    ) {
        assert!(type_name::get<T>() == config.coin_type, 0);
    }
    
    public(package) fun assert_p_type<P>(
        config: &LendingConfig,
    ) {
        assert!(type_name::get<P>() == config.coin_type, 0);
    }

    public(package) fun add_c_token_field<P, T>(
        lending: &mut Lending,
    ) {
        lending.fields.add(LendingReserveKey<T> {}, LendingReserve<P, T> { c_tokens: balance::zero() })
    }
    
    public(package) fun deposit_c_tokens<P, T>(
        lending: &mut Lending,
        c_tokens: Balance<CToken<P, T>>
    ) {
        let c_balance: &mut Balance<CToken<P, T>> = lending.fields.borrow_mut(LendingReserveKey<T> {});
        c_balance.join(c_tokens);
    }
    
    public(package) fun withdraw_c_tokens<P, T>(
        lending: &mut Lending,
        c_tokens: u64,
    ): Balance<CToken<P, T>> {
        let c_balance: &mut Balance<CToken<P, T>> = lending.fields.borrow_mut(LendingReserveKey<T> {});
        c_balance.split(c_tokens)
    }
    
    public fun add_c_token_field_<P, T>(
        fields: &mut Bag,
    ) {
        fields.add(LendingReserveKey<T> {}, LendingReserve<P, T> { c_tokens: balance::zero() })
    }
    
    public fun deposit_c_tokens_<P, T>(
        fields: &mut Bag,
        c_tokens: Balance<CToken<P, T>>
    ) {
        let c_balance: &mut Balance<CToken<P, T>> = fields.borrow_mut(LendingReserveKey<T> {});
        c_balance.join(c_tokens);
    }
    
    public fun withdraw_c_tokens_<P, T>(
        fields: &mut Bag,
        c_tokens: u64,
    ): Balance<CToken<P, T>> {
        let c_balance: &mut Balance<CToken<P, T>> = fields.borrow_mut(LendingReserveKey<T> {});
        c_balance.split(c_tokens)
    }

    public fun liquidity_ratio_bps(
        config: &LendingConfig,
    ): u16 {
        config.liquidity_ratio_bps
    }
    
    public(package) fun sync_liquidity_ratio(
        lending: &mut Lending,
        config: &LendingConfig,
        clock: &Clock,
    ) {
        assert!(lending.requirements.config_id == object::id(config), 0);
        assert!(clock.timestamp_ms() >= lending.requirements.next_update.0, 0);
        lending.requirements.liquidity_ratio_bps = config.liquidity_ratio_bps;
        lending.requirements.liquidity_buffer_bps = config.liquidity_buffer_bps;

        lending.requirements.next_update = Timestamp(lending.requirements.next_update.0 + SYNC_TIME);
    }
    
    public fun config_id(
        self: &LendingRequirements,
    ): ID {
        self.config_id
    }

    public fun compute_lending_action(
        self: &Lending,
        reserve: u64,
        amount: u64,
        is_input: bool,
        lent: u64,
    ): LendingAction {
        compute_lending_action_(
            reserve,
            amount,
            is_input,
            lent,
            self.requirements.liquidity_ratio_bps as u64,
            self.requirements.liquidity_buffer_bps as u64,
        )
    }
    
    public fun compute_lending_action_(
        reserve: u64,
        amount: u64,
        is_input: bool,
        lent: u64,
        liquidity_ratio_bps: u64,
        liquidity_buffer_bps: u64,
    ): LendingAction {
        if (is_input) {
            let liquidity_ratio = liquidity_ratio(reserve + amount, lent) as u64;

            if (liquidity_ratio > liquidity_ratio_bps + liquidity_buffer_bps) {
                return LendingAction::Lend(compute_lend(
                    reserve,
                        amount,
                        lent,
                        liquidity_ratio_bps,
                        liquidity_buffer_bps,
                ))
            } else {
                LendingAction::Ok
            }


        } else {
            assert!(reserve + lent > amount, 0);

            if (amount > reserve) {
                return LendingAction::Recall(compute_recall(
                    reserve,
                    amount,
                    lent,
                    liquidity_ratio_bps,
                    liquidity_buffer_bps,
                ))
            };

            let liquidity_ratio = liquidity_ratio(reserve - amount, lent) as u64;

            if (liquidity_ratio < liquidity_ratio_bps - liquidity_buffer_bps) {
                return LendingAction::Recall(compute_recall(
                    reserve,
                        amount,
                        lent,
                        liquidity_ratio_bps,
                        liquidity_buffer_bps,
                ))
            } else {
                LendingAction::Ok
            }
        }
    }
    
    public fun assert_liquidity_requirements(
        self: &Lending,
        reserve: u64,
        amount: u64,
        is_input: bool,
        lent: u64,
    ) {
        if (is_input) {
            let liquidity_ratio = liquidity_ratio(reserve + amount, lent) as u64;
            assert!(liquidity_ratio <= (self.requirements.liquidity_ratio_bps + self.requirements.liquidity_buffer_bps) as u64, 0);
        } else {
            assert!(reserve + lent > amount, 0);
            assert!(reserve > amount, 0);

            let liquidity_ratio = liquidity_ratio(reserve - amount, lent) as u64;

            assert!(liquidity_ratio >= (self.requirements.liquidity_ratio_bps - self.requirements.liquidity_buffer_bps) as u64, 0);
        }
    }

    fun compute_recall(
        reserve: u64,
        output: u64,
        lent: u64,
        liquidity_ratio_bps: u64,
        liquidity_buffer_bps: u64
    ): u64 {
        (
            (liquidity_ratio_bps + liquidity_buffer_bps) * (reserve + lent - output) + (output * 10_000) - (reserve * 10_000)
        ) / 10_000
    }
    
    fun compute_lend(
        reserve: u64,
        input: u64,
        lent: u64,
        liquidity_ratio_bps: u64,
        liquidity_buffer_bps: u64
    ): u64 {
        (reserve + input) - ((liquidity_ratio_bps + liquidity_buffer_bps) * (reserve + input + lent) / 10_000) 
    }

    public fun liquidity_ratio(
        liquid_reserve: u64,
        iliquid_reserve: u64,
    ): u16 {
        ((liquid_reserve * 10_000) / (liquid_reserve + iliquid_reserve)) as u16
    }
}
