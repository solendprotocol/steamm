module 0x233f0e47651aaa1aa9884b3f099f1fe5532b99a7a988654c38f7220dcd44eb34::usdc {
    struct USDC has drop {
        dummy_field: bool,
    }
    
    fun init(arg0: USDC, arg1: &mut 0x2::tx_context::TxContext) {
        let (v0, v1) = 0x2::coin::create_currency<USDC>(arg0, 9, b"USDC", b"USDC", b"Test USDC", 0x1::option::none<0x2::url::Url>(), arg1);
        0x2::transfer::public_transfer<0x2::coin::TreasuryCap<USDC>>(v0, 0x2::tx_context::sender(arg1));
        0x2::transfer::public_transfer<0x2::coin::CoinMetadata<USDC>>(v1, 0x2::tx_context::sender(arg1));
    }
    
    // decompiled from Move bytecode v6
}

