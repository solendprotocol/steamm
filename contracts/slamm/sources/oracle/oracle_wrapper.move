#[allow(lint(share_owned))]
module slamm::oracle_wrapper {
    use sui::{
        bag::{Self, Bag},
    };
    use sui::{
        transfer::share_object,
    };

    // ===== Constants =====
    const EIncorrectVersion: u64 = 0;
    const EInvalidStaleness: u64 = 1;
    const EInvalidConfidenceInterval: u64 = 2;

    const CURRENT_VERSION: u16 = 1;

    // ===== Errors =====

    public struct OracleKey<phantom CoinType> has store, copy, drop {}

    public struct OracleRegistry has key, store {
        id: UID,
        version: u16,
        oracles: Bag,
    }

    public struct Admin has key {
        id: UID,
    }
    
    public struct OraclePrice<phantom CoinType> {
        price: Price<CoinType>,
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
    }
    
    public struct Price<phantom CoinType> has drop {
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
    }

    public use fun slamm::oracle_wrapper::price_base as Price.base;
    public use fun slamm::oracle_wrapper::price_exponent as Price.exponent;
    public use fun slamm::oracle_wrapper::price_has_negative_exponent as Price.has_negative_exponent;

    /// Price info object with data sourced from oracle
    /// Price info has key so it can be queried as a standalone object, therefore
    /// avoiding centralising all price feeds into one object with dynamic fields.
    /// We keep track of all the price info object in the OracleRegistry
    public struct OracleInfo<phantom CoinType> has key, store {
        id: UID,
        version: u16,
        oracle_type: u8,
        fields: Bag,
    }

    public fun oracle_type<CoinType>(oracle: &OracleInfo<CoinType>): u8 { oracle.oracle_type }
    public(package) fun fields_mut<CoinType>(oracle: &mut OracleInfo<CoinType>): &mut Bag { &mut oracle.fields }
    
    public(package) fun new_oracle_price<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
    ): OraclePrice<CoinType> {
        OraclePrice {
            price: Price {
                base,
                exponent,
                has_negative_exponent,
            },
            min_confidence_interval_bps,
            max_staleness_seconds,
        }
        
    }
    
    public(package) fun new_price<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
    ): Price<CoinType> {
        Price {
            base,
            exponent,
            has_negative_exponent,
        }
    }

    public(package) fun set_oracle_type<CoinType>(
        oracle: &mut OracleInfo<CoinType>,
        oracle_type: u8,
    ) { oracle.oracle_type = oracle_type }
    
    public fun price_base<CoinType>(price: &Price<CoinType>): u64 { price.base }
    public fun price_exponent<CoinType>(price: &Price<CoinType>): u64 { price.exponent }
    public fun price_has_negative_exponent<CoinType>(price: &Price<CoinType>): bool { price.has_negative_exponent }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            Admin{
                id: object::new(ctx)
            },
            tx_context::sender(ctx)
        );

        let registry = OracleRegistry {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            oracles: bag::new(ctx),
        };

        transfer::share_object(registry);
    }

    // Admin gated to ensure that CoinType does not mismatch the PriceInfoObject
    public fun new_oracle_for_cointype<CoinType>(
        _: &Admin,
        registry: &mut OracleRegistry,
        ctx: &mut TxContext,
    ): OracleInfo<CoinType> {
        let oracle_uid = object::new(ctx);
        let oracle_id = oracle_uid.uid_to_inner();

        let fields = bag::new(ctx);

        let price_info = OracleInfo<CoinType> {
            id: oracle_uid,
            version: CURRENT_VERSION,
            oracle_type: 0, // Uninitialised
            fields,
        };

        // Add oracle ID to registry
        registry.oracles.add(
            OracleKey<CoinType> {},
            oracle_id
        );

        price_info
    }
  
    public fun init_oracle_for_cointype<CoinType>(
        admin: &Admin,
        registry: &mut OracleRegistry,
        ctx: &mut TxContext,
    ) {
        let oracle = new_oracle_for_cointype<CoinType>(admin, registry, ctx);

        share_object(oracle);
    }

    public fun get_price<CoinType>(
        oracle_price: OraclePrice<CoinType>,
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
    ): Price<CoinType> {
        assert!(
            oracle_price.max_staleness_seconds == max_staleness_seconds, EInvalidStaleness
        );
        
        assert!(
            oracle_price.min_confidence_interval_bps == min_confidence_interval_bps, EInvalidConfidenceInterval
        );
        
        let OraclePrice<CoinType> { price, min_confidence_interval_bps: _, max_staleness_seconds: _ } = oracle_price;

        price
    }
    
    public fun get_price_ref<CoinType>(
        oracle_price: &OraclePrice<CoinType>,
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
    ): &Price<CoinType> {
        assert!(
            oracle_price.max_staleness_seconds == max_staleness_seconds, EInvalidStaleness
        );
        
        assert!(
            oracle_price.min_confidence_interval_bps == min_confidence_interval_bps, EInvalidConfidenceInterval
        );

        &oracle_price.price
    }

    // ===== Versioning Functions =====

    public fun upgrade_registry(
        _: &Admin,
        self: &mut OracleRegistry,
        current_version: u16,
    ) {
        assert!(self.version < current_version, EIncorrectVersion);
        self.version = current_version;
    }
    
    public fun upgrade_oracle<CoinType>(
        _: &Admin,
        self: &mut OracleInfo<CoinType>,
        current_version: u16,
    ) {
        assert!(self.version < current_version, EIncorrectVersion);
        self.version = current_version;
    }

    public(package) fun assert_version(
        version: &u16,
        current_version: u16,
    ) {
        assert!(version == current_version, EIncorrectVersion);
    }

    public(package) fun assert_version_and_upgrade(
        version: &mut u16,
    ) {
        if (*version < CURRENT_VERSION) {
            *version = CURRENT_VERSION;
        };
        assert_version(version, CURRENT_VERSION);
    }

    // ===== Test-only Functions =====

    #[test_only]
    use sui::{
        test_scenario::{Self, Scenario, ctx},
        test_utils::{assert_eq, destroy},
    };
    
    #[test_only]
    use pyth::{price, price_identifier::{Self, PriceIdentifier}, price_feed};

    #[test_only]
    public struct TestCoin has drop {}

    #[test_only]
    public fun new_oracle_for_testing<CoinType>(
        oracle_type: u8,
        ctx: &mut TxContext,
    ): OracleInfo<CoinType> {
        let fields = bag::new(ctx);

        OracleInfo<CoinType> {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            oracle_type,
            fields,
        }
    }
    
    #[test_only]
    public fun clone_for_testing<CoinType>(
        oracle_price: &OraclePrice<CoinType>,
    ): OraclePrice<CoinType> {
        OraclePrice<CoinType> {
            price: Price {
                base: oracle_price.price.base,
                exponent: oracle_price.price.exponent,
                has_negative_exponent: oracle_price.price.has_negative_exponent,
            },
            min_confidence_interval_bps: oracle_price.min_confidence_interval_bps,
            max_staleness_seconds: oracle_price.max_staleness_seconds,
        }
    }
    
    #[test_only]
    public fun clone_price_for_testing<CoinType>(
        price: &Price<CoinType>,
    ): Price<CoinType> {
        Price {
            base: price.base,
            exponent: price.exponent,
            has_negative_exponent: price.has_negative_exponent,
        }
    }
    
    #[test_only]
    public fun new_oracle_price_for_testing<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
    ): OraclePrice<CoinType> {
        OraclePrice<CoinType> {
            price: Price { base, exponent, has_negative_exponent },
            min_confidence_interval_bps,
            max_staleness_seconds,
        }
    }
    
    #[test_only]
    public fun new_price_for_testing<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
    ): Price<CoinType> {
        Price { base, exponent, has_negative_exponent }
    }

    #[test]
    fun test_init_oracle_registry() {
        let mut scenario = test_scenario::begin(@0x0);
        init(ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, @0x0);

        let registry = test_scenario::take_shared<OracleRegistry>(&scenario);
        let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

        destroy(registry);
        destroy(admin);
        destroy(scenario);
    }
}
