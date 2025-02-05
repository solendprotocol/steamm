module faucet::faucets {
    use sui::coin::TreasuryCap;
    use sui::transfer;
    use sui::object::new;

    struct Faucet<phantom T> has store, key {
        id: UID,
        treasury_cap: TreasuryCap<T>,
    }
    
    public fun new<T>(cap: TreasuryCap<T>, ctx: &mut TxContext) {
        let faucet = Faucet<T>{
            id           : new(ctx), 
            treasury_cap : cap,
        };
        transfer::public_share_object<Faucet<T>>(faucet);
    }
    
    public fun get_faucet<T>(faucet: &mut Faucet<T>) : &mut TreasuryCap<T> {
        &mut faucet.treasury_cap
    }
}

