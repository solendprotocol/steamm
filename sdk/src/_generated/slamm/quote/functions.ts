import {PUBLISHED_AT} from "..";
import {obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface QuoteArgs { amountIn: bigint | TransactionArgument; amountOut: bigint | TransactionArgument; protocolFees: bigint | TransactionArgument; poolFees: bigint | TransactionArgument; a2B: boolean | TransactionArgument }

export function quote( tx: Transaction, args: QuoteArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::quote`, arguments: [ pure(tx, args.amountIn, `u64`), pure(tx, args.amountOut, `u64`), pure(tx, args.protocolFees, `u64`), pure(tx, args.poolFees, `u64`), pure(tx, args.a2B, `bool`) ], }) }

export function a2b( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::a2b`, arguments: [ obj(tx, self) ], }) }

export interface AddExtraFeesArgs { self: TransactionObjectInput; protocolFees: bigint | TransactionArgument; poolFees: bigint | TransactionArgument }

export function addExtraFees( tx: Transaction, args: AddExtraFeesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::add_extra_fees`, arguments: [ obj(tx, args.self), pure(tx, args.protocolFees, `u64`), pure(tx, args.poolFees, `u64`) ], }) }

export function protocolFees( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::protocol_fees`, arguments: [ obj(tx, self) ], }) }

export function poolFees( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::pool_fees`, arguments: [ obj(tx, self) ], }) }

export function amountIn( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::amount_in`, arguments: [ obj(tx, self) ], }) }

export function amountOut( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::amount_out`, arguments: [ obj(tx, self) ], }) }

export function amountOutNet( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::amount_out_net`, arguments: [ obj(tx, self) ], }) }

export function amountOutNetOfPoolFees( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::amount_out_net_of_pool_fees`, arguments: [ obj(tx, self) ], }) }

export function amountOutNetOfProtocolFees( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::amount_out_net_of_protocol_fees`, arguments: [ obj(tx, self) ], }) }

export function burnLp( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::burn_lp`, arguments: [ obj(tx, self) ], }) }

export function depositA( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::deposit_a`, arguments: [ obj(tx, self) ], }) }

export function depositB( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::deposit_b`, arguments: [ obj(tx, self) ], }) }

export interface DepositQuoteArgs { initialDeposit: boolean | TransactionArgument; depositA: bigint | TransactionArgument; depositB: bigint | TransactionArgument; mintLp: bigint | TransactionArgument }

export function depositQuote( tx: Transaction, args: DepositQuoteArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::deposit_quote`, arguments: [ pure(tx, args.initialDeposit, `bool`), pure(tx, args.depositA, `u64`), pure(tx, args.depositB, `u64`), pure(tx, args.mintLp, `u64`) ], }) }

export function initialDeposit( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::initial_deposit`, arguments: [ obj(tx, self) ], }) }

export function mintLp( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::mint_lp`, arguments: [ obj(tx, self) ], }) }

export function outputFeeRate( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::output_fee_rate`, arguments: [ obj(tx, self) ], }) }

export function outputFees( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::output_fees`, arguments: [ obj(tx, self) ], }) }

export interface RedeemQuoteArgs { withdrawA: bigint | TransactionArgument; withdrawB: bigint | TransactionArgument; feesA: bigint | TransactionArgument; feesB: bigint | TransactionArgument; burnLp: bigint | TransactionArgument }

export function redeemQuote( tx: Transaction, args: RedeemQuoteArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::redeem_quote`, arguments: [ pure(tx, args.withdrawA, `u64`), pure(tx, args.withdrawB, `u64`), pure(tx, args.feesA, `u64`), pure(tx, args.feesB, `u64`), pure(tx, args.burnLp, `u64`) ], }) }

export function withdrawA( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::withdraw_a`, arguments: [ obj(tx, self) ], }) }

export function withdrawB( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::withdraw_b`, arguments: [ obj(tx, self) ], }) }

export function redemptionFeeA( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::redemption_fee_a`, arguments: [ obj(tx, self) ], }) }

export function redemptionFeeB( tx: Transaction, self: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::quote::redemption_fee_b`, arguments: [ obj(tx, self) ], }) }
