module steamm_setup::lp_usdc_sui {
    use sui::url::Url;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};
    
    public struct LP_USDC_SUI has drop {}
    
    fun init(otw: LP_USDC_SUI, ctx: &mut TxContext) {

        let (v0, v1) = coin::create_currency<LP_USDC_SUI>(
            otw,
            9,
            b"steammLP bUSDC-bSUI",
            b"Steamm LP Token bUSDC-bSUI",
            b"Steamm LP Token",
            option::none<Url>(),
            ctx
        );
        
        transfer::public_transfer<TreasuryCap<LP_USDC_SUI>>(v0, ctx.sender());
        transfer::public_transfer<CoinMetadata<LP_USDC_SUI>>(v1, ctx.sender());
    }
}

