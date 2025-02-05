module steamm_setup::sui {
    use sui::url::Url;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};

    public struct SUI has drop {}
    
    fun init(otw: SUI, ctx: &mut TxContext) {
        let (treasury_cap, meta) = coin::create_currency<SUI>(otw, 9, b"SUI", b"SUI", b"Test SUI", option::none<Url>(), ctx);
        
        transfer::public_transfer<TreasuryCap<SUI>>(treasury_cap, ctx.sender());
        transfer::public_transfer<CoinMetadata<SUI>>(meta, ctx.sender());
    }
}