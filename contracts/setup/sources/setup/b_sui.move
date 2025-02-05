module steamm_setup::b_sui {
    use sui::url::Url;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};

    public struct B_SUI has drop {}
    
    fun init(otw: B_SUI, ctx: &mut TxContext) {
        let (treasury_cap, coin_meta) = coin::create_currency<B_SUI>(
            otw,
            9,
            b"bSUI",
            b"bToken SUI",
            b"Steamm bToken",
            option::none<Url>(),
            ctx
        );
        
        transfer::public_transfer<TreasuryCap<B_SUI>>(treasury_cap, ctx.sender());
        transfer::public_transfer<CoinMetadata<B_SUI>>(coin_meta, ctx.sender());
    }
}

