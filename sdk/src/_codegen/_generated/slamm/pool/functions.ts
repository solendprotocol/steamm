import {PUBLISHED_AT} from "..";
import {GenericArg, generic, obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface SwapArgs { pool: TransactionObjectInput; witness: GenericArg; bankA: TransactionObjectInput; bankB: TransactionObjectInput; coinA: TransactionObjectInput; coinB: TransactionObjectInput; intent: TransactionObjectInput; minAmountOut: bigint | TransactionArgument }

export function swap( tx: Transaction, typeArgs: [string, string, string, string, string], args: SwapArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), generic(tx, `${typeArgs[2]}`, args.witness), obj(tx, args.bankA), obj(tx, args.bankB), obj(tx, args.coinA), obj(tx, args.coinB), obj(tx, args.intent), pure(tx, args.minAmountOut, `u64`) ], }) }

export interface NewArgs { witness: GenericArg; registry: TransactionObjectInput; swapFeeBps: bigint | TransactionArgument; inner: GenericArg }

export function new_( tx: Transaction, typeArgs: [string, string, string, string], args: NewArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::new`, typeArguments: typeArgs, arguments: [ generic(tx, `${typeArgs[2]}`, args.witness), obj(tx, args.registry), pure(tx, args.swapFeeBps, `u64`), generic(tx, `${typeArgs[3]}`, args.inner) ], }) }

export interface DepositArgs { funds: TransactionObjectInput; bank: TransactionObjectInput; balance: TransactionObjectInput }

export function deposit( tx: Transaction, typeArgs: [string, string], args: DepositArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit`, typeArguments: typeArgs, arguments: [ obj(tx, args.funds), obj(tx, args.bank), obj(tx, args.balance) ], }) }

export interface WithdrawArgs { funds: TransactionObjectInput; bank: TransactionObjectInput; amount: bigint | TransactionArgument }

export function withdraw( tx: Transaction, typeArgs: [string, string], args: WithdrawArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::withdraw`, typeArguments: typeArgs, arguments: [ obj(tx, args.funds), obj(tx, args.bank), pure(tx, args.amount, `u64`) ], }) }

export interface MigrateArgs { pool: TransactionObjectInput; cap: TransactionObjectInput }

export function migrate( tx: Transaction, typeArgs: [string, string, string, string], args: MigrateArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::migrate`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.cap) ], }) }

export interface MigrateAsGlobalAdminArgs { pool: TransactionObjectInput; admin: TransactionObjectInput }

export function migrateAsGlobalAdmin( tx: Transaction, typeArgs: [string, string, string, string], args: MigrateAsGlobalAdminArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::migrate_as_global_admin`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.admin) ], }) }

export function totalFunds( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_funds`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function protocolFees( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::protocol_fees`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export interface AssertLpSupplyReserveRatioArgs { initialReserveA: bigint | TransactionArgument; initialLpSupply: bigint | TransactionArgument; finalReserveA: bigint | TransactionArgument; finalLpSupply: bigint | TransactionArgument }

export function assertLpSupplyReserveRatio( tx: Transaction, args: AssertLpSupplyReserveRatioArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::assert_lp_supply_reserve_ratio`, arguments: [ pure(tx, args.initialReserveA, `u64`), pure(tx, args.initialLpSupply, `u64`), pure(tx, args.finalReserveA, `u64`), pure(tx, args.finalLpSupply, `u64`) ], }) }

export interface QuoteDepositArgs { pool: TransactionObjectInput; idealA: bigint | TransactionArgument; idealB: bigint | TransactionArgument }

export function quoteDeposit( tx: Transaction, typeArgs: [string, string, string, string], args: QuoteDepositArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::quote_deposit`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.idealA, `u64`), pure(tx, args.idealB, `u64`) ], }) }

export interface QuoteRedeemArgs { pool: TransactionObjectInput; lpTokens: bigint | TransactionArgument }

export function quoteRedeem( tx: Transaction, typeArgs: [string, string, string, string], args: QuoteRedeemArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::quote_redeem`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.lpTokens, `u64`) ], }) }

export interface AsIntentArgs { quote: TransactionObjectInput; pool: TransactionObjectInput }

export function asIntent( tx: Transaction, typeArgs: [string, string, string, string], args: AsIntentArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::as_intent`, typeArguments: typeArgs, arguments: [ obj(tx, args.quote), obj(tx, args.pool) ], }) }

export function assertGuarded( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::assert_guarded`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export interface AssertLiquidityArgs { reserveOut: bigint | TransactionArgument; amountOut: bigint | TransactionArgument }

export function assertLiquidity( tx: Transaction, args: AssertLiquidityArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::assert_liquidity`, arguments: [ pure(tx, args.reserveOut, `u64`), pure(tx, args.amountOut, `u64`) ], }) }

export function assertUnguarded( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::assert_unguarded`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export interface CollectProtocolFeesArgs { pool: TransactionObjectInput; globalAdmin: TransactionObjectInput }

export function collectProtocolFees( tx: Transaction, typeArgs: [string, string, string, string], args: CollectProtocolFeesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::collect_protocol_fees`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.globalAdmin) ], }) }

export interface CollectRedemptionFeesArgs { pool: TransactionObjectInput; cap: TransactionObjectInput }

export function collectRedemptionFees( tx: Transaction, typeArgs: [string, string, string, string], args: CollectRedemptionFeesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::collect_redemption_fees`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.cap) ], }) }

export interface ComputeRedemptionFees_Args { pool: TransactionObjectInput; amountA: bigint | TransactionArgument; amountB: bigint | TransactionArgument }

export function computeRedemptionFees_( tx: Transaction, typeArgs: [string, string, string, string], args: ComputeRedemptionFees_Args ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::compute_redemption_fees_`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.amountA, `u64`), pure(tx, args.amountB, `u64`) ], }) }

export interface ComputeSwapFees_Args { pool: TransactionObjectInput; amount: bigint | TransactionArgument }

export function computeSwapFees_( tx: Transaction, typeArgs: [string, string, string, string], args: ComputeSwapFees_Args ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::compute_swap_fees_`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.amount, `u64`) ], }) }

export interface ConsumeArgs { pool: TransactionObjectInput; intent: TransactionObjectInput }

export function consume( tx: Transaction, typeArgs: [string, string, string, string], args: ConsumeArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::consume`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.intent) ], }) }

export interface DepositLiquidityArgs { pool: TransactionObjectInput; bankA: TransactionObjectInput; bankB: TransactionObjectInput; coinA: TransactionObjectInput; coinB: TransactionObjectInput; maxA: bigint | TransactionArgument; maxB: bigint | TransactionArgument; minA: bigint | TransactionArgument; minB: bigint | TransactionArgument }

export function depositLiquidity( tx: Transaction, typeArgs: [string, string, string, string, string], args: DepositLiquidityArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit_liquidity`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.bankA), obj(tx, args.bankB), obj(tx, args.coinA), obj(tx, args.coinB), pure(tx, args.maxA, `u64`), pure(tx, args.maxB, `u64`), pure(tx, args.minA, `u64`), pure(tx, args.minB, `u64`) ], }) }

export function depositResultDepositA( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit_result_deposit_a`, arguments: [ obj(tx, result) ], }) }

export function depositResultDepositB( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit_result_deposit_b`, arguments: [ obj(tx, result) ], }) }

export function depositResultMintLp( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit_result_mint_lp`, arguments: [ obj(tx, result) ], }) }

export function depositResultPoolId( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit_result_pool_id`, arguments: [ obj(tx, result) ], }) }

export function depositResultUser( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::deposit_result_user`, arguments: [ obj(tx, result) ], }) }

export interface GetQuoteArgs { pool: TransactionObjectInput; amountIn: bigint | TransactionArgument; amountOut: bigint | TransactionArgument; a2B: boolean | TransactionArgument }

export function getQuote( tx: Transaction, typeArgs: [string, string, string, string], args: GetQuoteArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::get_quote`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.amountIn, `u64`), pure(tx, args.amountOut, `u64`), pure(tx, args.a2B, `bool`) ], }) }

export function guard( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::guard`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function inner( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::inner`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function innerMut( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::inner_mut`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function intentQuote( tx: Transaction, typeArgs: [string, string, string, string], intent: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::intent_quote`, typeArguments: typeArgs, arguments: [ obj(tx, intent) ], }) }

export function lpSupplyVal( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::lp_supply_val`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function minimumLiquidity( tx: Transaction, ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::minimum_liquidity`, arguments: [ ], }) }

export function poolFeeConfig( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::pool_fee_config`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function poolFeesA( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::pool_fees_a`, arguments: [ obj(tx, tradeData) ], }) }

export function poolFeesB( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::pool_fees_b`, arguments: [ obj(tx, tradeData) ], }) }

export interface PrepareBankForPendingWithdrawArgs { bankA: TransactionObjectInput; bankB: TransactionObjectInput; lendingMarket: TransactionObjectInput; intent: TransactionObjectInput; clock: TransactionObjectInput }

export function prepareBankForPendingWithdraw( tx: Transaction, typeArgs: [string, string, string, string, string], args: PrepareBankForPendingWithdrawArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::prepare_bank_for_pending_withdraw`, typeArguments: typeArgs, arguments: [ obj(tx, args.bankA), obj(tx, args.bankB), obj(tx, args.lendingMarket), obj(tx, args.intent), obj(tx, args.clock) ], }) }

export function protocolFeesA( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::protocol_fees_a`, arguments: [ obj(tx, tradeData) ], }) }

export function protocolFeesB( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::protocol_fees_b`, arguments: [ obj(tx, tradeData) ], }) }

export interface QuoteDepositImplArgs { pool: TransactionObjectInput; idealA: bigint | TransactionArgument; idealB: bigint | TransactionArgument; minA: bigint | TransactionArgument; minB: bigint | TransactionArgument }

export function quoteDepositImpl( tx: Transaction, typeArgs: [string, string, string, string], args: QuoteDepositImplArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::quote_deposit_impl`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.idealA, `u64`), pure(tx, args.idealB, `u64`), pure(tx, args.minA, `u64`), pure(tx, args.minB, `u64`) ], }) }

export interface QuoteRedeemImplArgs { pool: TransactionObjectInput; lpTokens: bigint | TransactionArgument; minA: bigint | TransactionArgument; minB: bigint | TransactionArgument }

export function quoteRedeemImpl( tx: Transaction, typeArgs: [string, string, string, string], args: QuoteRedeemImplArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::quote_redeem_impl`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), pure(tx, args.lpTokens, `u64`), pure(tx, args.minA, `u64`), pure(tx, args.minB, `u64`) ], }) }

export interface RedeemLiquidityArgs { pool: TransactionObjectInput; bankA: TransactionObjectInput; bankB: TransactionObjectInput; lpTokens: TransactionObjectInput; minA: bigint | TransactionArgument; minB: bigint | TransactionArgument }

export function redeemLiquidity( tx: Transaction, typeArgs: [string, string, string, string, string], args: RedeemLiquidityArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::redeem_liquidity`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.bankA), obj(tx, args.bankB), obj(tx, args.lpTokens), pure(tx, args.minA, `u64`), pure(tx, args.minB, `u64`) ], }) }

export function redeemResultBurnLp( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::redeem_result_burn_lp`, arguments: [ obj(tx, result) ], }) }

export function redeemResultPoolId( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::redeem_result_pool_id`, arguments: [ obj(tx, result) ], }) }

export function redeemResultUser( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::redeem_result_user`, arguments: [ obj(tx, result) ], }) }

export function redeemResultWithdrawA( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::redeem_result_withdraw_a`, arguments: [ obj(tx, result) ], }) }

export function redeemResultWithdrawB( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::redeem_result_withdraw_b`, arguments: [ obj(tx, result) ], }) }

export interface SetPoolSwapFeesArgs { pool: TransactionObjectInput; poolCap: TransactionObjectInput; swapFeeBps: bigint | TransactionArgument }

export function setPoolSwapFees( tx: Transaction, typeArgs: [string, string, string, string], args: SetPoolSwapFeesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::set_pool_swap_fees`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.poolCap), pure(tx, args.swapFeeBps, `u64`) ], }) }

export interface SetRedemptionFeesArgs { pool: TransactionObjectInput; poolCap: TransactionObjectInput; redemptionFeeBps: bigint | TransactionArgument }

export function setRedemptionFees( tx: Transaction, typeArgs: [string, string, string, string], args: SetRedemptionFeesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::set_redemption_fees`, typeArguments: typeArgs, arguments: [ obj(tx, args.pool), obj(tx, args.poolCap), pure(tx, args.redemptionFeeBps, `u64`) ], }) }

export interface SwapInnerArgs { quote: TransactionObjectInput; bankIn: TransactionObjectInput; reserveIn: TransactionObjectInput; coinIn: TransactionObjectInput; lifetimeInAmount: bigint | TransactionArgument; protocolFeeBalance: TransactionObjectInput; bankOut: TransactionObjectInput; reserveOut: TransactionObjectInput; coinOut: TransactionObjectInput; lifetimeOutAmount: bigint | TransactionArgument; lifetimeProtocolFee: bigint | TransactionArgument; lifetimePoolFee: bigint | TransactionArgument }

export function swapInner( tx: Transaction, typeArgs: [string, string, string], args: SwapInnerArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_inner`, typeArguments: typeArgs, arguments: [ obj(tx, args.quote), obj(tx, args.bankIn), obj(tx, args.reserveIn), obj(tx, args.coinIn), pure(tx, args.lifetimeInAmount, `u128`), obj(tx, args.protocolFeeBalance), obj(tx, args.bankOut), obj(tx, args.reserveOut), obj(tx, args.coinOut), pure(tx, args.lifetimeOutAmount, `u128`), pure(tx, args.lifetimeProtocolFee, `u64`), pure(tx, args.lifetimePoolFee, `u64`) ], }) }

export function swapResultA2b( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_a2b`, arguments: [ obj(tx, result) ], }) }

export function swapResultAmountIn( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_amount_in`, arguments: [ obj(tx, result) ], }) }

export function swapResultAmountOut( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_amount_out`, arguments: [ obj(tx, result) ], }) }

export function swapResultPoolFees( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_pool_fees`, arguments: [ obj(tx, result) ], }) }

export function swapResultPoolId( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_pool_id`, arguments: [ obj(tx, result) ], }) }

export function swapResultProtocolFees( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_protocol_fees`, arguments: [ obj(tx, result) ], }) }

export function swapResultUser( tx: Transaction, result: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::swap_result_user`, arguments: [ obj(tx, result) ], }) }

export function totalFundsA( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_funds_a`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function totalFundsB( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_funds_b`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function totalSwapAInAmount( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_swap_a_in_amount`, arguments: [ obj(tx, tradeData) ], }) }

export function totalSwapAOutAmount( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_swap_a_out_amount`, arguments: [ obj(tx, tradeData) ], }) }

export function totalSwapBInAmount( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_swap_b_in_amount`, arguments: [ obj(tx, tradeData) ], }) }

export function totalSwapBOutAmount( tx: Transaction, tradeData: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::total_swap_b_out_amount`, arguments: [ obj(tx, tradeData) ], }) }

export function tradingData( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::trading_data`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }

export function unguard( tx: Transaction, typeArgs: [string, string, string, string], pool: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::pool::unguard`, typeArguments: typeArgs, arguments: [ obj(tx, pool) ], }) }
