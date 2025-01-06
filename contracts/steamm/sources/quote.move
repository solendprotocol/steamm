/// Module for informative structs which provide the input/outputs of a given quotation.
module steamm::quote {
    use suilend::decimal::{Self, Decimal};

    public use fun steamm::pool::as_intent as SwapQuote.as_intent;
    public use fun steamm::pool::swap_inner as SwapQuote.swap_inner;
    public use fun redemption_fee_a as RedeemQuote.fees_a;
    public use fun redemption_fee_b as RedeemQuote.fees_b;

    public struct SwapQuote has store, drop {
        amount_in: u64,
        amount_out: u64,
        output_fees: SwapFee,
        a2b: bool,
    }

    public struct SwapFee has store, drop, copy {
        protocol_fees: u64,
        pool_fees: u64,
    }

    public struct DepositQuote has store, drop {
        initial_deposit: bool,
        deposit_a: u64,
        deposit_b: u64,
        mint_lp: u64,
    }
    
    public struct RedeemQuote has store, drop {
        withdraw_a: u64,
        withdraw_b: u64,
        fees_a: u64,
        fees_b: u64,
        burn_lp: u64
    }

    // ===== Package Methods =====

    public(package) fun quote(
        amount_in: u64,
        amount_out: u64,
        protocol_fees: u64,
        pool_fees: u64,
        a2b: bool,
    ): SwapQuote {
        SwapQuote {
            amount_in,
            amount_out,
            output_fees: SwapFee {
                protocol_fees,
                pool_fees,
            },
            a2b,
        }
    }
    
    public(package) fun deposit_quote(
        initial_deposit: bool,
        deposit_a: u64,
        deposit_b: u64,
        mint_lp: u64,
    ): DepositQuote {
        DepositQuote {
            initial_deposit,
            deposit_a,
            deposit_b,
            mint_lp,
        }
    }
    
    public(package) fun redeem_quote(
        withdraw_a: u64,
        withdraw_b: u64,
        fees_a: u64,
        fees_b: u64,
        burn_lp: u64
    ): RedeemQuote {
        RedeemQuote {
            withdraw_a,
            withdraw_b,
            fees_a,
            fees_b,
            burn_lp,
        }
    }

    public(package) fun add_extra_fees(
        quote: &mut SwapQuote,
        protocol_fees: u64,
        pool_fees: u64
    ) {
        quote.output_fees.protocol_fees = quote.output_fees.protocol_fees + protocol_fees;
        quote.output_fees.pool_fees = quote.output_fees.pool_fees + pool_fees;
    }
    

    // ===== Public View Methods =====

    public fun protocol_fees(fee: &SwapFee): u64 { fee.protocol_fees }
    public fun pool_fees(fee: &SwapFee): u64 { fee.pool_fees }

    public fun amount_in(quote: &SwapQuote): u64 { quote.amount_in }
    public fun amount_out(quote: &SwapQuote): u64 { quote.amount_out }
    public fun a2b(quote: &SwapQuote): bool { quote.a2b }
    
    public fun amount_out_net(quote: &SwapQuote): u64 {
        quote.amount_out - quote.output_fees.protocol_fees - quote.output_fees.pool_fees
    }
   
    public fun amount_out_net_of_protocol_fees(quote: &SwapQuote): u64 {
        quote.amount_out - quote.output_fees.protocol_fees
    }
    
    public fun amount_out_net_of_pool_fees(quote: &SwapQuote): u64 {
        quote.amount_out - quote.output_fees.pool_fees
    }
    
    public fun output_fee_rate(quote: &SwapQuote): Decimal {
        let total_fees = decimal::from(
            quote.output_fees().pool_fees() + quote.output_fees().protocol_fees()
        );

        total_fees.div(decimal::from(quote.amount_out()))
    }
    public fun output_fees(quote: &SwapQuote): &SwapFee { &quote.output_fees }
    
    public fun initial_deposit(quote: &DepositQuote): bool { quote.initial_deposit }
    public fun deposit_a(quote: &DepositQuote): u64 { quote.deposit_a }
    public fun deposit_b(quote: &DepositQuote): u64 { quote.deposit_b }
    public fun mint_lp(quote: &DepositQuote): u64 { quote.mint_lp }
    
    public fun withdraw_a(quote: &RedeemQuote): u64 { quote.withdraw_a }
    public fun withdraw_b(quote: &RedeemQuote): u64 { quote.withdraw_b }
    public fun redemption_fee_a(quote: &RedeemQuote): u64 { quote.fees_a }
    public fun redemption_fee_b(quote: &RedeemQuote): u64 { quote.fees_b }
    public fun burn_lp(quote: &RedeemQuote): u64 { quote.burn_lp }


    #[test_only]
    public(package) fun quote_for_testing(
        amount_in: u64,
        amount_out: u64,
        protocol_fees: u64,
        pool_fees: u64,
        a2b: bool,
    ): SwapQuote {
        SwapQuote {
            amount_in,
            amount_out,
            // input_fees,
            output_fees: SwapFee {
                protocol_fees: protocol_fees,
                pool_fees: pool_fees,
            },
            a2b,
        }
    }
}
