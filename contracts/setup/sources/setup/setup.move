#[allow(lint(share_owned, self_transfer))]
module steamm_setup::setup {
    use sui::coin::{CoinMetadata, TreasuryCap};
    use suilend::lending_market_registry::{create_lending_market, Registry as SuilendRegistry};
    use steamm::registry::Registry;
    use steamm::cpmm;
    use steamm_setup::{
        lp_usdc_sui::LP_USDC_SUI,
        usdc::USDC,
        sui::SUI,
        b_usdc::B_USDC,
        b_sui::B_SUI,
    };

    public struct LENDING_MARKET has drop {}
    
    public fun setup(
        suilend_registry: &mut SuilendRegistry,
        steamm_registry: &mut Registry,
        meta_lp: &mut CoinMetadata<LP_USDC_SUI>,
        treasury_lp: TreasuryCap<LP_USDC_SUI>,
        meta_usdc: &CoinMetadata<USDC>,
        meta_sui: &CoinMetadata<SUI>,
        meta_b_usdc: &mut CoinMetadata<B_USDC>,
        meta_b_sui: &mut CoinMetadata<B_SUI>,
        treasury_b_usdc: TreasuryCap<B_USDC>,
        treasury_b_sui: TreasuryCap<B_SUI>,
        ctx: &mut TxContext
    ) {
        let (owner_cap, lending_market) = create_lending_market<LENDING_MARKET>(suilend_registry, ctx);

        let pool = cpmm::new<B_USDC, B_SUI, LP_USDC_SUI>(
            steamm_registry,
            100,
            0,
            meta_b_usdc,
            meta_b_sui,
            meta_lp,
            treasury_lp,
            ctx
        );

        steamm::bank::create_bank_and_share(steamm_registry, meta_usdc, meta_b_usdc, treasury_b_usdc, &lending_market, ctx);
        steamm::bank::create_bank_and_share(steamm_registry, meta_sui, meta_b_sui, treasury_b_sui, &lending_market, ctx);
        
        transfer::public_share_object(lending_market);
        transfer::public_share_object(pool);
        transfer::public_transfer(owner_cap, ctx.sender());
    }
}

