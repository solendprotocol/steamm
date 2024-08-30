module slamm::oracle_wrapper {
    use std::option::{none, some};
    use sui::{
        bag::{Self, Bag},
    };
    use sui::clock::{Self, Clock};
    use pyth::{
        i64,
        price::{Price as PythPrice},
        price_info::{PriceInfoObject},
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
    const PRICE_STALENESS_THRESHOLD_S: u64 = 0;

    // ===== Errors =====

    public struct OracleKey<phantom Source, phantom CoinType> has store, copy, drop {}

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
    public struct Price<phantom Source, phantom CoinType> has store, copy, drop {
        price: u256
    }

    /// Price info object with data sourced from oracle
    /// Price info has key so it can be queried as a standalone object, therefore
    /// avoiding centralising all price feeds into one object with dynamic fields.
    /// We keep track of all the price info object in the OracleRegistry
    public struct OracleInfo<phantom Source, phantom CoinType> has key, store {
        id: UID,
        version: u16,
        price_identifier: PriceId,
        price: Option<Price<Source, CoinType>>,
        // Added option here assuming some feeds might not offer
        // smoothed price
        smoothed_price: Option<Price<Source, CoinType>>,
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
    ): OracleInfo<PriceInfoObject, CoinType> {
        let (mut price, smoothed_price) = get_pyth_price(price_info_obj, clock);
        let price_info = price_info_obj.get_price_info_from_price_info_object();
        let price_feed = price_info.get_price_feed();
        let price_identifier = price_feed.get_price_identifier().get_bytes();

        // Create Price Info object
        let oracle_uid = object::new(ctx);
        let oracle_id = oracle_uid.uid_to_inner();

        let price_info = OracleInfo<PriceInfoObject, CoinType> {
            id: oracle_uid,
            version: CURRENT_VERSION,
            price_identifier: PriceId { bytes: price_identifier },
            price: if (price.is_none()) { none() } else { some(Price { price: price.extract() })},
            smoothed_price: some(Price { price: smoothed_price}),
            price_last_update_timestamp_s: clock::timestamp_ms(clock) / 1000,
        };

        // Add oracle ID to registry
        registry.oracles.add(
            OracleKey<PriceInfoObject, CoinType> {},
            oracle_id
        );

        price_info
    }

    // errors if the PriceInfoObject is stale/invalid.
    public fun update_pyth_price_for_cointype<CoinType>(
        oracle_info: &mut OracleInfo<PriceInfoObject, CoinType>,
        price_info: &PriceInfoObject,
        clock: &Clock,
    ) {
        let price_info_ = price_info.get_price_info_from_price_info_object();
        let (mut price, smoothed_price) = get_pyth_price(price_info, clock);
        let price_feed = price_info_.get_price_feed();
        let price_identifier = price_feed.get_price_identifier().get_bytes();

        assert!(price_identifier == oracle_info.price_identifier.bytes, EPriceIdentifierMismatch);
        assert!(option::is_some(&price), EInvalidPrice);

        oracle_info.price = if (price.is_none()) { none() } else { some(Price { price: price.extract() })};
        oracle_info.smoothed_price = some(Price { price: smoothed_price});
        oracle_info.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;
    }
    
    public fun get_price<CoinType>(
        oracle_info: &OracleInfo<PriceInfoObject, CoinType>,
        clock: &Clock,
    ): Option<u256> {
        oracle_info.assert_liveness(clock);

        if (oracle_info.price.is_some()) {
            some(oracle_info.price.borrow().price)
        } else {
            none()
        }
    }

    public fun get_smoothed_price<CoinType>(
        oracle_info: &OracleInfo<PriceInfoObject, CoinType>,
        clock: &Clock,
    ): Option<u256> {
        oracle_info.assert_liveness(clock);

        if (oracle_info.smoothed_price.is_some()) {
            some(oracle_info.smoothed_price.borrow().price)
        } else {
            none()
        }
    }

    public fun get_price_with_fallback<CoinType>(
        oracle_info: &OracleInfo<PriceInfoObject, CoinType>,
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
        oracle_info: &OracleInfo<PriceInfoObject, CoinType>,
        clock: &Clock,
    ) {
        let cur_time_s = clock.timestamp_ms() / 1000;

        assert!(
            cur_time_s - oracle_info.price_last_update_timestamp_s <= PRICE_STALENESS_THRESHOLD_S, 
            EPriceStale
        );
    }

    fun get_price_unchecked<CoinType>(
        oracle_info: &OracleInfo<PriceInfoObject, CoinType>,
    ): Option<u256> {
        if (oracle_info.price.is_some()) {
            some(oracle_info.price.borrow().price)
        } else {
            none()
        }
    }

    fun get_smoothed_price_unchecked<CoinType>(
        oracle_info: &OracleInfo<PriceInfoObject, CoinType>,
    ): Option<u256> {
        if (oracle_info.smoothed_price.is_some()) {
            some(oracle_info.smoothed_price.borrow().price)
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

    #[test_only]
    public fun set_oracle_price_for_testing<Source, CointType>(
        self: &mut OracleInfo<Source, CointType>,
        price: u256,
        clock: &Clock,
    ) {
        self.price.swap_or_fill(Price { price });
        self.price_last_update_timestamp_s = clock.timestamp_ms() / 1_000;
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
    
    public fun upgrade_oracle<Source, CoinType>(
        _: &Admin,
        self: &mut OracleInfo<Source, CoinType>,
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


    // ===== Private Functions =====

    // fun update_price<CoinType>(
    //     self: &mut OracleInfo<PriceInfoObject, CoinType>,
    //     price_info: &PriceInfoObject,
    //     clock: &Clock,
    // ) {
    //     let price_feed = price_info.get_price_info_from_price_info_object().get_price_feed();
    //     let price_identifier = price_feed.get_price_identifier().get_bytes();

    //     let (mut price, smoothed_price) = get_pyth_price(price_info, clock);
    //     assert!(option::is_some(&price), EInvalidPrice);
    //     assert!(price_identifier == self.price_identifier.bytes, EPriceIdentifierMismatch);

    //     if (price.is_none()) {
    //         self.price = none();
    //     } else {
    //         self.price.swap_or_fill(
    //             Price { price: price.extract() }
    //         );
    //     };
        
    //     self.smoothed_price.swap_or_fill(Price { price: smoothed_price });
    //     self.price_last_update_timestamp_s = clock::timestamp_ms(clock) / 1000;
    // }

    // #[allow(unused_function)]
    // fun get_oracle_output_amount(
    //     amount_in: u64,
    //     input_price: Decimal,
    //     output_price: Decimal
    // ): u64 {
    //     decimal::from(amount_in).mul(input_price).div(output_price).floor()
    // }
    
    // fun get_oracle_price(
    //     price_a: Decimal,
    //     price_b: Decimal
    // ): Decimal {
    //     price_a.div(price_b)
    // }
}
