module slamm::lend {
    use std::type_name::{Self, TypeName};
    use sui::bag::Bag;
    use sui::clock::{Clock};
    use sui::balance::{Self, Balance};
    use slamm::global_admin::GlobalAdmin;
    use suilend::lending_market::{LendingMarket};
    use suilend::reserve::{CToken};

    // TODO
    const SYNC_TIME: u64 = 1;

    public enum LendingAction {
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
        fields: &mut Bag,
    ) {
        fields.add(LendingReserveKey<T> {}, LendingReserve<P, T> { c_tokens: balance::zero() })
    }

    public fun liquidity_ratio_bps(
        config: &LendingConfig,
    ): u16 {
        config.liquidity_ratio_bps
    }
    
    public(package) fun sync_liquidity_ratio(
        requirements: &mut LendingRequirements,
        config: &LendingConfig,
        clock: &Clock,
    ) {
        assert!(requirements.config_id == object::id(config), 0);
        assert!(clock.timestamp_ms() >= requirements.next_update.0, 0);
        requirements.liquidity_ratio_bps = config.liquidity_ratio_bps;
        requirements.liquidity_buffer_bps = config.liquidity_buffer_bps;

        requirements.next_update = Timestamp(requirements.next_update.0 + SYNC_TIME);
    }
    
    public fun config_id(
        self: &LendingRequirements,
    ): ID {
        self.config_id
    }

    public fun compute_lending_action(
        self: &LendingRequirements,
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
            self.liquidity_ratio_bps as u64,
            self.liquidity_buffer_bps as u64,
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
        self: &LendingRequirements,
        reserve: u64,
        amount: u64,
        is_input: bool,
        lent: u64,
    ) {
        if (is_input) {
            let liquidity_ratio = liquidity_ratio(reserve + amount, lent) as u64;
            assert!(liquidity_ratio <= (self.liquidity_ratio_bps + self.liquidity_buffer_bps) as u64, 0);
        } else {
            assert!(reserve + lent > amount, 0);
            assert!(reserve > amount, 0);

            let liquidity_ratio = liquidity_ratio(reserve - amount, lent) as u64;

            assert!(liquidity_ratio >= (self.liquidity_ratio_bps - self.liquidity_buffer_bps) as u64, 0);
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
    
    // public fun has_sufficient_liquidity_output(
    //     config: &LendingConfig,
    //     output: u64,
    //     liquid_reserve: u64,
    //     iliquid_reserve: u64,
    // ): bool {
    //     if (output > liquid_reserve) {
    //         false
    //     } else {
    //         let post_trade_ratio = liquidity_ratio(liquid_reserve - output, iliquid_reserve);
    //         post_trade_ratio >= config.liquidity_ratio_bps - config.liquidity_buffer_bps
    //     }
    // }
    
    // public fun assert_sufficient_liquidity_after_(
    //     config: &LendingConfig,
    //     output: u64,
    //     liquid_reserve: u64,
    //     iliquid_reserve: u64,
    // ) {
    //     assert!(config.has_sufficient_liquidity(output, liquid_reserve, iliquid_reserve), 0);
    // }

    // public fun compute_liquidity_recall(
    //     reserve: u64,
    //     output: u64,
    //     lent: u64,
    //     liquidity_ratio_bps: u64,
    //     liquidity_buffer_bps: u64
    // ): (u64, bool) {
    //     let post_trade_ratio_bps = liquidity_ratio(reserve - output, lent) as u64;

    //     if (post_trade_ratio_bps < liquidity_ratio_bps) {
    //         let recall = (
    //             (liquidity_ratio_bps + liquidity_buffer_bps) * (reserve - output + lent) + (output * 10_000) - (reserve * 10_000)
    //             ) / 10_000;

    //         (recall, true)
    //     } else {
    //         (0, false)
    //     }
    // }

    public fun liquidity_ratio(
        liquid_reserve: u64,
        iliquid_reserve: u64,
    ): u16 {
        ((liquid_reserve * 10_000) / (liquid_reserve + iliquid_reserve)) as u16
    }

    // public fun deposit_liquidity_and_mint_ctokens<A, B, Hook: drop, State: store, P, T>(
    //     self: &mut Pool<A, B, Hook, State>,
    //     lending_market: &mut LendingMarket<P>, 
    //     reserve_array_index: u64,
    //     clock: &Clock,
    //     deposit: Coin<T>,
    //     ctx: &mut TxContext
    // ): Coin<CToken<P, T>> {
    //     let c_tokens = lending_market::deposit_liquidity_and_mint_ctokens(
    //         lending_market,
    //         reserve_array_index,
    //         clock,
    //         deposit,
    //         ctx,
    //     );
    // }

    // public fun redeem_ctokens_and_withdraw_liquidity<P, T>(
    //     lending_market: &mut LendingMarket<P>, 
    //     reserve_array_index: u64,
    //     clock: &Clock,
    //     ctokens: Coin<CToken<P, T>>,
    //     rate_limiter_exemption: Option<RateLimiterExemption<P, T>>,
    //     ctx: &mut TxContext
    // ): Coin<T> {
    //     let lending_market_id = object::id_address(lending_market);
    //     assert!(lending_market.version == CURRENT_VERSION, EIncorrectVersion);
    //     assert!(coin::value(&ctokens) > 0, ETooSmall);

    //     let ctoken_amount = coin::value(&ctokens);

    //     let reserve = vector::borrow_mut(&mut lending_market.reserves, reserve_array_index);
    //     assert!(reserve::coin_type(reserve) == type_name::get<T>(), EWrongType);

    //     reserve::compound_interest(reserve, clock);

    //     let exempt_from_rate_limiter = false;
    //     if (option::is_some(&rate_limiter_exemption)) {
    //         let exemption = option::borrow_mut(&mut rate_limiter_exemption);
    //         if (exemption.amount >= ctoken_amount) {
    //             exempt_from_rate_limiter = true;
    //         };
    //     };

    //     if (!exempt_from_rate_limiter) {
    //         rate_limiter::process_qty(
    //             &mut lending_market.rate_limiter, 
    //             clock::timestamp_ms(clock) / 1000,
    //             reserve::ctoken_market_value_upper_bound(reserve, ctoken_amount)
    //         );
    //     };

    //     let liquidity = reserve::redeem_ctokens<P, T>(
    //         reserve, 
    //         coin::into_balance(ctokens)
    //     );

    //     assert!(balance::value(&liquidity) > 0, ETooSmall);

    //     event::emit(RedeemEvent {
    //         lending_market_id,
    //         coin_type: type_name::get<T>(),
    //         reserve_id: object::id_address(reserve),
    //         ctoken_amount,
    //         liquidity_amount: balance::value(&liquidity),
    //     });

    //     coin::from_balance(liquidity, ctx)
    // }

}
