module steamm_setup::usdc {
    use sui::url::Url;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};
    
    public struct USDC has drop {}
    
    fun init(otw: USDC, ctx: &mut TxContext) {
        let (treasury_cap, meta) = coin::create_currency<USDC>(otw, 9, b"USDC", b"USDC", b"Test USDC", option::none<Url>(), ctx);
        
        transfer::public_transfer<TreasuryCap<USDC>>(treasury_cap, ctx.sender());
        transfer::public_transfer<CoinMetadata<USDC>>(meta, ctx.sender());
    }
}

