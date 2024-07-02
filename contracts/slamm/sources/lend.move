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
    
    public(package) fun deposit_c_tokens<P, T>(
        fields: &mut Bag,
        c_tokens: Balance<CToken<P, T>>
    ) {
        let c_balance: &mut Balance<CToken<P, T>> = fields.borrow_mut(LendingReserveKey<T> {});
        c_balance.join(c_tokens);
    }
    
    public(package) fun withdraw_c_tokens<P, T>(
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

    public fun liquidity_ratio(
        liquid_reserve: u64,
        iliquid_reserve: u64,
    ): u16 {
        ((liquid_reserve * 10_000) / (liquid_reserve + iliquid_reserve)) as u16
    }
}
