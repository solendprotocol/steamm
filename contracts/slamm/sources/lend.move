module slamm::lend {
    use std::type_name::{Self, TypeName};
    use sui::bag::Bag;
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance, Supply};
    use slamm::global_admin::GlobalAdmin;
    use suilend::lending_market::{Self, LendingMarket};
    use suilend::reserve::{CToken};

    // TODO
    const SYNC_TIME: u64 = 1;

    public struct LendingConfig has key {
        id: UID,
        lending_market: ID,
        p_type: TypeName,
        // Calls that rely on this type reflection are either
        // sporadic or not sensitive to performance. Type reflections here helps
        // reducing the interface so we can act generically over coin types A and B
        coin_type: TypeName,
        liquidity_ratio_bps: u16,
    }

    public struct LendingRequirements has store {
        config_id: ID,
        liquidity_ratio_bps: u16,
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
        ctx: &mut TxContext,
        ): LendingConfig {
        LendingConfig {
            id: object::new(ctx),
            lending_market: object::id(lending_market),
            p_type: type_name::get<P>(),
            coin_type: type_name::get<T>(),
            liquidity_ratio_bps,
        }
    }

    public(package) fun new_requirements(
        config: &LendingConfig,
        clock: &Clock,
    ): LendingRequirements {
        LendingRequirements {
            config_id: object::id(config),
            liquidity_ratio_bps: config.liquidity_ratio_bps,
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

        // <CToken<P, T>>
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
        assert!(clock.timestamp_ms() >= requirements.next_update.0, 0);
        requirements.liquidity_ratio_bps = config.liquidity_ratio_bps;

        requirements.next_update = Timestamp(requirements.next_update.0 + SYNC_TIME);
    }
    
    public fun config_id(
        self: &LendingRequirements,
    ): ID {
        self.config_id
    }
    
    public fun has_sufficient_liquidity(
        config: &LendingConfig,
        liquid_reserve: u64,
        iliquid_reserve: u64,
    ): bool {
        liquidity_ratio(liquid_reserve, iliquid_reserve) >= config.liquidity_ratio_bps
    }

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
