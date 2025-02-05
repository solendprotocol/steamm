module steamm::sui {
    use sui::url::Url;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};

    public struct SUI has drop {}
    
    fun init(otw: SUI, arg1: &mut 0x2::tx_context::TxContext) {
        let (v0, v1) = 0x2::coin::create_currency<SUI>(otw, 9, b"SUI", b"SUI", b"Test SUI", 0x1::option::none<0x2::url::Url>(), arg1);
        0x2::transfer::public_transfer<0x2::coin::TreasuryCap<SUI>>(v0, 0x2::tx_context::sender(arg1));
        0x2::transfer::public_transfer<0x2::coin::CoinMetadata<SUI>>(v1, 0x2::tx_context::sender(arg1));
    }
}