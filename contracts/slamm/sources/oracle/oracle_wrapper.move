module slamm::oracle_wrapper {
    use std::option::{none, some};
    use sui::{
        bag::{Self, Bag},
    };
    use sui::clock::{Self, Clock};
    use pyth::{
        i64,
        price::{Price as PythPrice},
        price_info::{Self, PriceInfoObject},
    };
    use suilend::{
        decimal::{Self, Decimal},
    };

    // ===== Constants =====
    const EIncorrectVersion: u64 = 0;
    const EInvalidPrice: u64 = 1;
    const EPriceIdentifierMismatch: u64 = 2;
    const EPriceStale: u64 = 3;

    // min confidence ratio of X means that the confidence interval must be less than (100/x)% of the price
    const MIN_CONFIDENCE_RATIO: u64 = 10;
    const MAX_STALENESS_SECONDS: u64 = 60;

    const CURRENT_VERSION: u16 = 1;
    const PRICE_STALENESS_THRESHOLD_S: u64 = 15;

    // ===== Errors =====

    public struct OracleKey<phantom CoinType> has store, copy, drop {}
    
    public struct PythKey has store, copy, drop {}

    public struct OracleRegistry has key, store {
        id: UID,
        version: u16,
        oracles: Bag,
    }

    public struct Admin has key {
        id: UID,
    }

    public struct PriceId has store, copy, drop {
        bytes: vector<u8>,
    }

    // price is computed by base * 10^(exponent)
    // this struct does not have the store ability. 
    // invariant: Price objects are never stale.
    public struct Price<phantom CoinType> has store, copy, drop {
        price: u256
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
    
    public struct PythData<phantom CoinType> has store {
        price_identifier: PriceId,
        price: Option<Price<CoinType>>,
        // Added option here assuming some feeds might not offer
        // smoothed price
        smoothed_price: Option<Price<CoinType>>,
        price_last_update_timestamp_s: u64,
    }

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
    public fun set_pyth_oracle_for_cointype<CoinType>(
        _: &Admin,
        registry: &mut OracleRegistry,
        price_info_obj: &PriceInfoObject,
        clock: &Clock,
        ctx: &mut TxContext,
    ): OracleInfo<CoinType> {
        let (mut price, smoothed_price) = get_pyth_price(price_info_obj, clock);
        let price_info = price_info_obj.get_price_info_from_price_info_object();
        let price_feed = price_info.get_price_feed();
        let price_identifier = price_feed.get_price_identifier().get_bytes();

        // Create Price Info object
        let oracle_uid = object::new(ctx);
        let oracle_id = oracle_uid.uid_to_inner();

        let pyth_data = PythData<CoinType> {
            price_identifier: PriceId { bytes: price_identifier },
            price: if (price.is_none()) { none() } else { some(Price { price: price.extract() })},
            smoothed_price: some(Price { price: smoothed_price}),
            price_last_update_timestamp_s: clock::timestamp_ms(clock) / 1000,
        };

        let mut fields = bag::new(ctx);
        fields.add(PythKey {}, pyth_data);

        let price_info = OracleInfo<CoinType> {
            id: oracle_uid,
            version: CURRENT_VERSION,
            oracle_type: 1,
            fields,
        };

        // Add oracle ID to registry
        registry.oracles.add(
            OracleKey<CoinType> {},
            oracle_id
        );

        price_info
    }

    // errors if the PriceInfoObject is stale/invalid.
    public fun get_updated_price<CoinType>(
        oracle_info: &mut OracleInfo<CoinType>,
        price_info: &PriceInfoObject,
        clock: &Clock,
    ): Option<u256> {
        let price_info_ = price_info.get_price_info_from_price_info_object();
        let (mut price, smoothed_price) = get_pyth_price(price_info, clock);
        let price_feed = price_info_.get_price_feed();
        let price_identifier = price_feed.get_price_identifier().get_bytes();

        let pyth_data: &mut PythData<CoinType> = oracle_info.fields.borrow_mut(PythKey {});

        assert!(price_identifier == pyth_data.price_identifier.bytes, EPriceIdentifierMismatch);
        assert!(option::is_some(&price), EInvalidPrice);

        pyth_data.price = if (price.is_none()) { none() } else { some(Price { price: price.extract() })};
        pyth_data.smoothed_price = some(Price { price: smoothed_price});
        pyth_data.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;

        // TODO: refactor, to make the update optional..
        oracle_info.assert_liveness(clock);

        let pyth_data: &PythData<CoinType> = oracle_info.fields.borrow(PythKey {});

        if (pyth_data.price.is_some()) {
            some(pyth_data.price.borrow().price)
        } else {
            none()
        }
    }

    public fun get_smoothed_price<CoinType>(
        oracle_info: &OracleInfo<CoinType>,
        clock: &Clock,
    ): Option<u256> {
        oracle_info.assert_liveness(clock);

        let pyth_data: &PythData<CoinType> = oracle_info.fields.borrow(PythKey {});

        if (pyth_data.smoothed_price.is_some()) {
            some(pyth_data.smoothed_price.borrow().price)
        } else {
            none()
        }
    }

    public fun get_price_with_fallback<CoinType>(
        oracle_info: &OracleInfo<CoinType>,
        clock: &Clock,
    ): u256 {
        oracle_info.assert_liveness(clock);

        let mut price = oracle_info.get_price_unchecked();

        if (price.is_none()) {
            let mut smooth_price = oracle_info.get_smoothed_price_unchecked();
            assert!(smooth_price.is_some(), 0);
            return smooth_price.extract()
        } else {
            return price.extract()
        }
    }

    public fun assert_liveness<CoinType>(
        oracle_info: &OracleInfo<CoinType>,
        clock: &Clock,
    ) {
        let cur_time_s = clock.timestamp_ms() / 1000;

        let pyth_data: &PythData<CoinType> = oracle_info.fields.borrow(PythKey {});

        assert!(
            cur_time_s - pyth_data.price_last_update_timestamp_s <= PRICE_STALENESS_THRESHOLD_S, 
            EPriceStale
        );
    }

    fun get_price_unchecked<CoinType>(
        oracle_info: &OracleInfo<CoinType>,
    ): Option<u256> {
        let pyth_data: &PythData<CoinType> = oracle_info.fields.borrow(PythKey {});

        if (pyth_data.price.is_some()) {
            some(pyth_data.price.borrow().price)
        } else {
            none()
        }
    }

    fun get_smoothed_price_unchecked<CoinType>(
        oracle_info: &OracleInfo<CoinType>,
    ): Option<u256> {
        let pyth_data: &PythData<CoinType> = oracle_info.fields.borrow(PythKey {});

        if (pyth_data.smoothed_price.is_some()) {
            some(pyth_data.smoothed_price.borrow().price)
        } else {
            none()
        }
    }

    /// parse the pyth price info object to get a price and identifier. This function returns an None if the
    /// price is invalid due to confidence interval checks or staleness checks. It returns None instead of aborting
    /// so the caller can handle invalid prices gracefully by eg falling back to a different oracle
    /// return type: (spot price, ema price, price identifier)
    fun get_pyth_price(price_info_obj: &PriceInfoObject, clock: &Clock): (Option<u256>, u256) {
        let price_info = price_info_obj.get_price_info_from_price_info_object();
        let price_feed = price_info.get_price_feed();

        let ema_price = parse_price_to_decimal(price_feed.get_ema_price());

        let price = price_feed.get_price();
        let price_mag = i64::get_magnitude_if_positive(&price.get_price());
        let conf = price.get_conf();

        // confidence interval check
        // we want to make sure conf / price <= x%
        // -> conf * (100 / x )<= price
        if (conf * MIN_CONFIDENCE_RATIO > price_mag) {
            return (option::none(), ema_price.to_scaled_val())
        };

        // check current sui time against pythnet publish time. there can be some issues that arise because the
        // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        if (cur_time_s > price.get_timestamp() && // this is technically possible!
            cur_time_s - price.get_timestamp() > MAX_STALENESS_SECONDS) {
            return (option::none(), ema_price.to_scaled_val())
        };

        let spot_price = parse_price_to_decimal(price);
        (option::some(spot_price.to_scaled_val()), ema_price.to_scaled_val())
    }

    fun parse_price_to_decimal(price: PythPrice): Decimal {
        // we don't support negative prices
        let price_mag = i64::get_magnitude_if_positive(&price.get_price());
        let expo = price.get_expo();

        if (i64::get_is_negative(&expo)) {
            decimal::div(
                decimal::from(price_mag),
                decimal::from(
                    10_u64.pow(i64::get_magnitude_if_negative(&expo) as u8)
                )
            )
        }
        else {
            decimal::mul(
                decimal::from(price_mag),
                decimal::from(
                    10_u64.pow(i64::get_magnitude_if_positive(&expo) as u8)
                )
            )
        }
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
    public fun new_pyth_oracle_for_testing<CoinType>(
        price_identifier: vector<u8>,
        mut price: Option<u256>,
        mut smoothed_price: Option<u256>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): OracleInfo<CoinType> {
        let pyth_data = PythData<CoinType> {
            price_identifier: PriceId { bytes: price_identifier },
            price: if (price.is_none()) { none() } else { some(Price { price: price.extract() })},
            smoothed_price: if (smoothed_price.is_some()) { some(Price { price: smoothed_price.extract() }) } else { none() },
            price_last_update_timestamp_s: clock::timestamp_ms(clock) / 1000,
        };

        let mut fields = bag::new(ctx);
        fields.add(PythKey {}, pyth_data);

        OracleInfo<CoinType> {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            oracle_type: 1,
            fields,
        }
    }

    #[test_only]
    public fun set_oracle_price_for_testing<CoinType>(
        self: &mut OracleInfo<CoinType>,
        price: u256,
        clock: &Clock,
    ) {
        let pyth_data: &mut PythData<CoinType> = self.fields.borrow_mut(PythKey {});

        pyth_data.price.swap_or_fill(Price { price });
        pyth_data.price_last_update_timestamp_s = clock.timestamp_ms() / 1_000;
    }
    
    #[test_only]
    public fun set_oracle_ts_for_testing<CoinType>(
        self: &mut OracleInfo<CoinType>,
        clock: &Clock,
    ) {
        let pyth_data: &mut PythData<CoinType> = self.fields.borrow_mut(PythKey {});
        pyth_data.price_last_update_timestamp_s = clock.timestamp_ms() / 1_000;
    }
    
    #[test_only]
    public fun set_oracle_for_testing<CoinType>(
        self: &mut OracleInfo<CoinType>,
        mut price: Option<u256>,
        mut smoothed_price: Option<u256>,
        clock: &Clock,
    ) {
        let pyth_data: &mut PythData<CoinType> = self.fields.borrow_mut(PythKey {});

        pyth_data.price = if (price.is_some()) { some(Price { price: price.extract() }) } else { none() };
        pyth_data.smoothed_price = if (smoothed_price.is_some()) { some(Price { price: smoothed_price.extract() }) } else { none() };
        pyth_data.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;
    }

    #[test_only]
    use sui::{
        test_scenario::{Self, Scenario, ctx},
        test_utils::{assert_eq, destroy},
    };
    
    #[test_only]
    use pyth::{price, price_identifier::{Self, PriceIdentifier}, price_feed};
    
    #[test_only]
    fun create_price_obj(
        current_ts: u64,
        price: u64,
        exponent: u64,
        id: u8,
        scenario: &mut Scenario,
    ): (PriceIdentifier, PriceInfoObject) {
        let price = price::new(
            i64::from_u64(price),
            0,
            i64::from_u64(exponent),
            current_ts
        );

        let mut v = vector::empty<u8>();
        vector::push_back(&mut v, id);

        let mut i = 1;
        while (i < 32) {
            vector::push_back(&mut v, 0);
            i = i + 1;
        };

        let price_id = price_identifier::from_byte_vec(v);

        let price_feed = price_feed::new(
            price_id,
            price,
            price,
        );
        
        let price_info = price_info::new_price_info(
            current_ts,
            current_ts,
            price_feed
        );

        let price_info_obj = price_info::new_price_info_object_for_testing(
            price_info,
            ctx(scenario),
        );

        (price_id, price_info_obj)
    }

    #[test_only]
    public struct TestCoin has drop {}

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
    fun test_new_pyth_oracle_for_cointype() {
        let mut scenario = test_scenario::begin(@0x0);
        init(ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, @0x0);

        let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
        let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

        let clock = clock::create_for_testing(ctx(&mut scenario));

        let current_ts = clock.timestamp_ms();

        let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

        let oracle = set_pyth_oracle_for_cointype<TestCoin>(
            &admin,
            &mut registry,
            &price_info_obj,
            &clock,
            ctx(&mut scenario),
        );

        let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

        assert_eq(
            decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
            1
        );

        assert_eq(
            decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
            1
        );

        assert_eq(
            pyth_data.price_last_update_timestamp_s,
            current_ts / 1000
        );

        assert_eq(
            registry.oracles.contains(OracleKey<TestCoin> {}),
            true,
        );

        destroy(registry);
        destroy(admin);
        destroy(clock);
        destroy(oracle);
        destroy(price_info_obj);
        destroy(scenario);
    }
    
    // #[test]
    // fun test_set_pyth_oracle_for_cointype() {
    //     let mut scenario = test_scenario::begin(@0x0);
    //     init(ctx(&mut scenario));

    //     test_scenario::next_tx(&mut scenario, @0x0);

    //     let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
    //     let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

    //     let mut clock = clock::create_for_testing(ctx(&mut scenario));

    //     let current_ts = clock.timestamp_ms();

    //     let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

    //     let mut oracle = set_pyth_oracle_for_cointype<TestCoin>(
    //         &admin,
    //         &mut registry,
    //         &price_info_obj,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
    //         1
    //     );

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
    //         1
    //     );

    //     assert_eq(
    //         pyth_data.price_last_update_timestamp_s,
    //         current_ts / 1000
    //     );

    //     clock.set_for_testing(current_ts + 1000);
    //     let current_ts = clock.timestamp_ms();

    //     let (_, price_info_obj_2) = create_price_obj(current_ts, 1, 1, 1, &mut scenario);

    //     update_pyth_price_for_cointype(&mut oracle, &price_info_obj_2, &clock);

    //     let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
    //         10
    //     );
        
    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
    //         10
    //     );

    //     assert_eq(
    //         pyth_data.price_last_update_timestamp_s,
    //         current_ts / 1000
    //     );

    //     destroy(registry);
    //     destroy(admin);
    //     destroy(clock);
    //     destroy(oracle);
    //     destroy(price_info_obj);
    //     destroy(price_info_obj_2);
    //     destroy(scenario);
    // }
    
    // #[test]
    // #[expected_failure(abort_code = EPriceIdentifierMismatch)]
    // fun test_fail_price_id() {
    //     let mut scenario = test_scenario::begin(@0x0);
    //     init(ctx(&mut scenario));

    //     test_scenario::next_tx(&mut scenario, @0x0);

    //     let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
    //     let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

    //     let mut clock = clock::create_for_testing(ctx(&mut scenario));

    //     let current_ts = clock.timestamp_ms();

    //     let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

    //     let mut oracle = set_pyth_oracle_for_cointype<TestCoin>(
    //         &admin,
    //         &mut registry,
    //         &price_info_obj,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
    //         1
    //     );

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
    //         1
    //     );

    //     assert_eq(
    //         pyth_data.price_last_update_timestamp_s,
    //         current_ts / 1000
    //     );

    //     clock.set_for_testing(current_ts + 1000);
    //     let current_ts = clock.timestamp_ms();

    //     let (_, price_info_obj_2) = create_price_obj(current_ts, 1, 1, 2, &mut scenario);

    //     update_pyth_price_for_cointype(&mut oracle, &price_info_obj_2, &clock);

    //     destroy(registry);
    //     destroy(admin);
    //     destroy(clock);
    //     destroy(oracle);
    //     destroy(price_info_obj);
    //     destroy(price_info_obj_2);
    //     destroy(scenario);
    // }
    
    // #[test]
    // #[expected_failure(abort_code = EPriceStale)]
    // fun test_fail_liveness_price() {
    //     let mut scenario = test_scenario::begin(@0x0);
    //     init(ctx(&mut scenario));

    //     test_scenario::next_tx(&mut scenario, @0x0);

    //     let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
    //     let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

    //     let mut clock = clock::create_for_testing(ctx(&mut scenario));

    //     let current_ts = clock.timestamp_ms();

    //     let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

    //     let oracle = set_pyth_oracle_for_cointype<TestCoin>(
    //         &admin,
    //         &mut registry,
    //         &price_info_obj,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
    //         1
    //     );

    //     assert_eq(
    //         decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
    //         1
    //     );

    //     assert_eq(
    //         pyth_data.price_last_update_timestamp_s,
    //         current_ts / 1000
    //     );

    //     clock.set_for_testing(current_ts + 1000 * (PRICE_STALENESS_THRESHOLD_S + 1));

    //     let price = oracle.get_price(&clock);

    //     destroy(registry);
    //     destroy(admin);
    //     destroy(clock);
    //     destroy(oracle);
    //     destroy(price_info_obj);
    //     destroy(price);
    //     destroy(scenario);
    // }
    
    #[test]
    #[expected_failure(abort_code = EPriceStale)]
    fun test_fail_liveness_smoothed_price() {
        let mut scenario = test_scenario::begin(@0x0);
        init(ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, @0x0);

        let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
        let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let current_ts = clock.timestamp_ms();

        let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

        let oracle = set_pyth_oracle_for_cointype<TestCoin>(
            &admin,
            &mut registry,
            &price_info_obj,
            &clock,
            ctx(&mut scenario),
        );

        let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

        assert_eq(
            decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
            1
        );

        assert_eq(
            decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
            1
        );

        assert_eq(
            pyth_data.price_last_update_timestamp_s,
            current_ts / 1000
        );

        clock.set_for_testing(current_ts + 1000 * (PRICE_STALENESS_THRESHOLD_S + 1));

        let price = oracle.get_smoothed_price(&clock);

        destroy(registry);
        destroy(admin);
        destroy(clock);
        destroy(oracle);
        destroy(price_info_obj);
        destroy(price);
        destroy(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code = EPriceStale)]
    fun test_fail_liveness_price_with_fallback() {
        let mut scenario = test_scenario::begin(@0x0);
        init(ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, @0x0);

        let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
        let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let current_ts = clock.timestamp_ms();

        let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

        let oracle = set_pyth_oracle_for_cointype<TestCoin>(
            &admin,
            &mut registry,
            &price_info_obj,
            &clock,
            ctx(&mut scenario),
        );

        let pyth_data: &PythData<TestCoin> = oracle.fields.borrow(PythKey {});

        assert_eq(
            decimal::from_scaled_val(pyth_data.price.borrow().price).floor(),
            1
        );

        assert_eq(
            decimal::from_scaled_val(pyth_data.smoothed_price.borrow().price).floor(),
            1
        );

        assert_eq(
            pyth_data.price_last_update_timestamp_s,
            current_ts / 1000
        );

        clock.set_for_testing(current_ts + 1000 * (PRICE_STALENESS_THRESHOLD_S + 1));

        let price = oracle.get_price_with_fallback(&clock);

        destroy(registry);
        destroy(admin);
        destroy(clock);
        destroy(oracle);
        destroy(price_info_obj);
        destroy(price);
        destroy(scenario);
    }
}
