module steamm_setup::b_usdc {
    use sui::url::Url;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};

    public struct B_USDC has drop {}
    
    fun init(otw: B_USDC, ctx: &mut TxContext) {
        let (treasury_cap, meta) = coin::create_currency<B_USDC>(
            otw,
            9,
            b"bUSDC",
            b"bToken USDC",
            b"Steamm bToken",
            option::none<Url>(),
            ctx
        );
        
        transfer::public_transfer<TreasuryCap<B_USDC>>(treasury_cap, ctx.sender());
        transfer::public_transfer<CoinMetadata<B_USDC>>(meta, ctx.sender());
    }
}