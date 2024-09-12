import {
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";

export interface PoolNewArgs {
  witness: TransactionObjectInput;
  registry: TransactionObjectInput;
  swapFeeBps: bigint | TransactionArgument;
  inner: TransactionObjectInput;
}

export interface PoolIntentSwapArgs {
  amountIn: bigint | TransactionArgument;
  a2b: boolean | TransactionArgument;
}

export interface PoolExecuteSwapArgs {
  intent: TransactionObjectInput;
  coinA: TransactionObjectInput;
  coinB: TransactionObjectInput;
  minAmountOut: bigint | TransactionArgument;
}

export interface PoolQuoteSwap {
  amountIn: bigint | TransactionArgument;
  a2b: boolean | TransactionArgument;
}

export interface PoolDepositLiquidityArgs {
  coinA: TransactionObjectInput;
  coinB: TransactionObjectInput;
  maxA: bigint | TransactionArgument;
  maxB: bigint | TransactionArgument;
  minA: bigint | TransactionArgument;
  minB: bigint | TransactionArgument;
}

export interface PoolRedeemLiquidityArgs {
  lpTokens: TransactionObjectInput;
  minA: bigint | TransactionArgument;
  minB: bigint | TransactionArgument;
}

export interface PoolPrepareBankForPendingWithdrawArgs {
  intent: TransactionObjectInput;
}

export interface PoolQuoteRedeemArgs {
  lpTokens: bigint | TransactionArgument;
}

export interface PoolNeedsLendingActionOnSwapArgs {
  quote: TransactionObjectInput;
}

export interface PoolSetPoolSwapFeesArgs {
  poolCap: TransactionObjectInput;
  swapFeeBps: bigint | TransactionArgument;
}
export interface PoolSetRedemptionFeesArgs {
  poolCap: TransactionObjectInput;
  redemptionFeeBps: bigint | TransactionArgument;
}
