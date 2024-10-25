#[allow(lint(share_owned))]
module oracle::oracle_wrapper {
    use sui::{
        bag::{Self, Bag},
    };
    use sui::{
        clock::Clock,
        transfer::share_object,
    };

    public use fun oracle::oracle_wrapper::price_base as OraclePrice.base;
    public use fun oracle::oracle_wrapper::price_exponent as OraclePrice.exponent;
    public use fun oracle::oracle_wrapper::price_has_negative_exponent as OraclePrice.has_negative_exponent;

    // ===== Constants =====

    const CURRENT_VERSION: u16 = 1;

    // ===== Errors =====

    const EIncorrectVersion: u64 = 0;
    const EPriceStale: u64 = 1;
    const EPriceOutsideConfidence: u64 = 2;

    // ===== Structs =====

    public struct OracleKey<phantom CoinType> has store, copy, drop {}

    public struct OracleRegistry has key, store {
        id: UID,
        version: u16,
        oracles: Bag,
    }

    public struct Admin has key {
        id: UID,
    }

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
    
    public struct OraclePrice<phantom CoinType> has drop {
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
        confidence: u64,
        timestamp_s: u64,
    }

    // ===== Init function =====

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

    // ===== Admin function =====

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

    // ===== Package function =====

    public(package) fun new_price<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
        confidence: u64,
        timestamp_s: u64,
    ): OraclePrice<CoinType> {
        OraclePrice {
            base,
            exponent,
            has_negative_exponent,
            confidence,
            timestamp_s,
        }
        
    }

    public(package) fun set_oracle_type<CoinType>(
        oracle: &mut OracleInfo<CoinType>,
        oracle_type: u8,
    ) { oracle.oracle_type = oracle_type }

    public(package) fun fields_mut<CoinType>(oracle: &mut OracleInfo<CoinType>): &mut Bag { &mut oracle.fields }

    // ===== Getter function =====

    public fun oracle_type<CoinType>(oracle: &OracleInfo<CoinType>): u8 { oracle.oracle_type }
    public fun fields<CoinType>(oracle: &OracleInfo<CoinType>): &Bag { &oracle.fields }
    public fun price_base<CoinType>(price: &OraclePrice<CoinType>): u64 { price.base }
    public fun price_exponent<CoinType>(price: &OraclePrice<CoinType>): u64 { price.exponent }
    public fun price_has_negative_exponent<CoinType>(price: &OraclePrice<CoinType>): bool { price.has_negative_exponent }
    public fun confidence<CoinType>(price: &OraclePrice<CoinType>): u64 { price.confidence }
    public fun timestamp_seconds<CoinType>(price: &OraclePrice<CoinType>): u64 { price.timestamp_s }

    public fun check_price<CoinType>(
        price: &OraclePrice<CoinType>,
        max_confidence_bps: u64,
        max_staleness_seconds: u64,
        clock: &Clock,
    ) { 
        // confidence check
        // max_absolute_confidence = price_mag * max_confidence_bps / 10_000;
        // asserts that conf <= max_absolute_confidence
        assert!(
            price.confidence * 10_000 <= price.base * max_confidence_bps, EPriceOutsideConfidence
        );

        // check current sui time against pythnet publish time. there can be some issues that arise because the
        // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
        let cur_time_s = clock.timestamp_ms() / 1000;

        // print(&(cur_time_s <= price.timestamp_s));
        // print(&(cur_time_s - price.timestamp_s <= max_staleness_seconds));
        assert!(
            cur_time_s <= price.timestamp_s || cur_time_s - price.timestamp_s <= max_staleness_seconds, EPriceStale
        );
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
        test_scenario::{Self, ctx},
        test_utils::destroy,
        clock,
    };


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
            base: oracle_price.base,
            exponent: oracle_price.exponent,
            has_negative_exponent: oracle_price.has_negative_exponent,
            confidence: oracle_price.confidence,
            timestamp_s: oracle_price.timestamp_s,
        }
    }
    
    #[test_only]
    public fun new_oracle_price_for_testing<CoinType>(
        base: u64,
        exponent: u64,
        has_negative_exponent: bool,
        confidence: u64,
        timestamp_s: u64,
    ): OraclePrice<CoinType> {
        OraclePrice<CoinType> {
            base,
            exponent,
            has_negative_exponent,
            confidence,
            timestamp_s,
        }
    }
    
    #[test_only]
    public fun init_for_testing(
        ctx: &mut TxContext,
    ) {
        init(ctx);
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

    #[test]
    fun test_check_price_at_max_confidence() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let price = new_oracle_price_for_testing<TestCoin>(
            550, // base
            1, // exponent
            true, // has_negative_exponent
            11, // confidence
            current_ts, // timestamp_s
        );

        price.check_price(
            200, // 5 / 54 = 9.25% confidence = 925 bps
            30, // 30 seconds
            &clock,
        );

        destroy(price);
        destroy(clock);
        destroy(scenario);
    }

    #[test]
    fun test_check_price_below_max_confidence() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let mut confidence = 10;

        while (confidence > 0) {
            let price = new_oracle_price_for_testing<TestCoin>(
                550, // base
                1, // exponent
                true, // has_negative_exponent
                confidence, // confidence
                current_ts, // timestamp_s
            );

            price.check_price(
                200, // 5 / 54 = 9.25% confidence = 925 bps
                30, // 30 seconds
                &clock,
            );

            confidence = confidence - 1;
        };

        destroy(clock);
        destroy(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EPriceOutsideConfidence)]
    fun test_fail_check_price_above_max_confidence() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let price = new_oracle_price_for_testing<TestCoin>(
            550, // base
            1, // exponent
            true, // has_negative_exponent
            11 + 1, // confidence
            current_ts, // timestamp_s
        );

        price.check_price(
            200, // 5 / 54 = 9.25% confidence = 925 bps
            30, // 30 seconds
            &clock,
        );

        destroy(price);
        destroy(clock);
        destroy(scenario);
    }

    #[test]
    fun test_check_price_at_max_staleness() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let price = new_oracle_price_for_testing<TestCoin>(
            550, // base
            1, // exponent
            true, // has_negative_exponent
            0, // confidence
            current_ts, // timestamp_s
        );

        clock.increment_for_testing(1 * 1_000);

        price.check_price(
            200, // 5 / 54 = 9.25% confidence = 925 bps
            1, // 1 second
            &clock,
        );

        destroy(price);
        destroy(clock);
        destroy(scenario);
    }
    
    #[test]
    fun test_check_price_at_below_staleness() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let price = new_oracle_price_for_testing<TestCoin>(
            550, // base
            1, // exponent
            true, // has_negative_exponent
            0, // confidence
            current_ts, // timestamp_s
        );

        clock.increment_for_testing(1 * 1_000);

        price.check_price(
            200, // 5 / 54 = 9.25% confidence = 925 bps
            2, // 2 seconds
            &clock,
        );

        destroy(price);
        destroy(clock);
        destroy(scenario);
    }
    
    #[test]
    fun test_check_price_at_no_staleness() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let price = new_oracle_price_for_testing<TestCoin>(
            550, // base
            1, // exponent
            true, // has_negative_exponent
            0, // confidence
            current_ts, // timestamp_s
        );

        price.check_price(
            200, // 5 / 54 = 9.25% confidence = 925 bps
            0, // 0 seconds
            &clock,
        );

        destroy(price);
        destroy(clock);
        destroy(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EPriceStale)]
    fun test_fail_check_price_above_max_staleness() {
        let mut scenario = test_scenario::begin(@0x0);
        test_scenario::next_tx(&mut scenario, @0x0);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        let current_ts = clock.timestamp_ms();

        let price = new_oracle_price_for_testing<TestCoin>(
            550, // base
            1, // exponent
            true, // has_negative_exponent
            0, // confidence
            current_ts, // timestamp_s
        );

        clock.increment_for_testing(3 * 1_000);

        price.check_price(
            200, // 5 / 54 = 9.25% confidence = 925 bps
            2, // 2 seconds
            &clock,
        );

        destroy(price);
        destroy(clock);
        destroy(scenario);
    }
}
