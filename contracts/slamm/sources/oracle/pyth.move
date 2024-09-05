module slamm::pyth {
    use sui::{ 
        clock::{Self, Clock}
    };
    use pyth::{
        i64,
        price_info::{Self, PriceInfoObject},
        price::{Price as PythPrice},
    };
    use slamm::oracle_wrapper::{Self, Admin, OracleInfo, OraclePrice, new_oracle_price};

    const EAlreadyInitialised: u64 = 0;
    const EPriceStale: u64 = 1;
    const EPriceOutsideConfidence: u64 = 2;
    const EPriceIdentifierMismatch: u64 = 3;

    public struct PythKey has store, copy, drop {}

    public struct PythData<phantom CoinType> has store {
        price_identifier: PriceId,
    }

    public struct PriceId has store, copy, drop {
        bytes: vector<u8>,
    }

    // Admin gated to ensure that CoinType does not mismatch the PriceInfoObject
    public fun set_pyth_oracle_for_cointype<CoinType>(
        _: &Admin,
        oracle: &mut OracleInfo<CoinType>,
        price_info_obj: &PriceInfoObject,
    ) {
        assert!(oracle.oracle_type() == 0, EAlreadyInitialised);
        
        let price_info = price_info_obj.get_price_info_from_price_info_object();
        let price_feed = price_info.get_price_feed();
        let price_identifier = price_feed.get_price_identifier().get_bytes();

        let pyth_data = PythData<CoinType> {
            price_identifier: PriceId { bytes: price_identifier },
        };

        oracle.set_oracle_type(1);
        oracle.fields_mut().add(PythKey {}, pyth_data);
    }

    // errors if the PriceInfoObject is stale/invalid.
    public fun get_updated_price<CoinType>(
        oracle_info: &mut OracleInfo<CoinType>,
        price_info_obj: &PriceInfoObject,
        // min confidence ratio of X means that the confidence interval must be less than (100/x)% of the price
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
        clock: &Clock,
    ): OraclePrice<CoinType> {
        let price_info_ = price_info_obj.get_price_info_from_price_info_object();
        let price_feed = price_info_.get_price_feed();
        let price_identifier = price_feed.get_price_identifier().get_bytes();
        let pyth_data: &mut PythData<CoinType> = oracle_info.fields_mut().borrow_mut(PythKey {});
        
        assert!(price_identifier == pyth_data.price_identifier.bytes, EPriceIdentifierMismatch);

        let price_obj = price_feed.get_price();
        
        get_price<CoinType>(price_obj, min_confidence_interval_bps, max_staleness_seconds, clock)
    }

    fun get_price<CoinType>(
        pyth_price: PythPrice,
        min_confidence_interval_bps: u64,
        max_staleness_seconds: u64,
        clock: &Clock
    ): OraclePrice<CoinType> {
        let price_mag = i64::get_magnitude_if_positive(&pyth_price.get_price());
        let conf = pyth_price.get_conf();

        // confidence interval check
        // we want to make sure conf / price <= x%
        // -> conf * (100 / x )<= price
        assert!(conf * min_confidence_interval_bps <= price_mag, EPriceOutsideConfidence);

        // check current sui time against pythnet publish time. there can be some issues that arise because the
        // timestamps are from different sources and may get out of sync, but that's why we have a fallback oracle
        let cur_time_s = clock::timestamp_ms(clock) / 1000;
        assert!(
            cur_time_s <= pyth_price.get_timestamp() || cur_time_s - pyth_price.get_timestamp() <= max_staleness_seconds, EPriceStale
        );

        let price_exponent_is_negative = pyth_price.get_expo().get_is_negative();

        let price = new_oracle_price(
            pyth_price.get_price().get_magnitude_if_positive(),
            if (price_exponent_is_negative) {
                pyth_price.get_expo().get_magnitude_if_negative()
            } else {
                pyth_price.get_expo().get_magnitude_if_positive()
            },
            price_exponent_is_negative,
            min_confidence_interval_bps,
            max_staleness_seconds,
        );

        price
    }

    // ===== Test-only Functions =====

    #[test_only]
    use sui::{
        test_scenario::{Self, Scenario, ctx},
        test_utils::{assert_eq, destroy},
        bag,
    };

    #[test_only]
    use pyth::{price, price_identifier::{Self, PriceIdentifier}, price_feed};

    #[test_only]
    public fun new_pyth_oracle_for_testing<CoinType>(
        price_identifier: vector<u8>,
        ctx: &mut TxContext,
    ): OracleInfo<CoinType> {
        let pyth_data = PythData<CoinType> {
            price_identifier: PriceId { bytes: price_identifier },
        };

        let mut oracle = oracle_wrapper::new_oracle_for_testing<CoinType>(1, ctx);
        oracle.fields_mut().add(PythKey {}, pyth_data);

        oracle
    }

    #[test_only]
    public fun create_price_obj(
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

    // #[test]
    // fun test_new_pyth_oracle_for_cointype() {
    //     let mut scenario = test_scenario::begin(@0x0);
    //     init(ctx(&mut scenario));

    //     test_scenario::next_tx(&mut scenario, @0x0);

    //     let mut registry = test_scenario::take_shared<OracleRegistry>(&scenario);
    //     let admin = test_scenario::take_from_address<Admin>(&scenario, @0x0);

    //     let clock = clock::create_for_testing(ctx(&mut scenario));

    //     let current_ts = clock.timestamp_ms();

    //     let (_, price_info_obj) = create_price_obj(current_ts, 1, 0, 1, &mut scenario);

    //     let oracle = set_pyth_oracle_for_cointype<TestCoin>(
    //         &admin,
    //         &mut registry,
    //         &price_info_obj,
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

    //     assert_eq(
    //         registry.oracles.contains(OracleKey<TestCoin> {}),
    //         true,
    //     );

    //     destroy(registry);
    //     destroy(admin);
    //     destroy(clock);
    //     destroy(oracle);
    //     destroy(price_info_obj);
    //     destroy(scenario);
    // }
    
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
    
    // #[test]
    // #[expected_failure(abort_code = EPriceStale)]
    // fun test_fail_liveness_smoothed_price() {
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

    //     let price = oracle.get_smoothed_price(&clock);

    //     destroy(registry);
    //     destroy(admin);
    //     destroy(clock);
    //     destroy(oracle);
    //     destroy(price_info_obj);
    //     destroy(price);
    //     destroy(scenario);
    // }
    
    // #[test]
    // #[expected_failure(abort_code = EPriceStale)]
    // fun test_fail_liveness_price_with_fallback() {
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

    //     let price = oracle.get_price_with_fallback(&clock);

    //     destroy(registry);
    //     destroy(admin);
    //     destroy(clock);
    //     destroy(oracle);
    //     destroy(price_info_obj);
    //     destroy(price);
    //     destroy(scenario);
    // }
}
