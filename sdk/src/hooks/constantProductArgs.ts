import {
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";
import {
  PoolExecuteSwapArgs,
  PoolIntentSwapArgs,
  PoolNewArgs,
  PoolQuoteSwap,
} from "../pool/poolArgs";

export type CpNewArgs = PoolNewArgs & {
  offset: bigint | TransactionArgument;
};

export type CpIntentSwapArgs = PoolIntentSwapArgs & {};
export type CpExecuteSwapArgs = PoolExecuteSwapArgs & {};
export type CpPoolQuoteSwap = PoolQuoteSwap & {};
export type CpSwapArgs = CpIntentSwapArgs & Omit<CpExecuteSwapArgs, "intent">;

export interface SwapQuote {
  amountIn: bigint;
  amountOut: bigint;
  outputFees: SwapFee;
  a2b: boolean;
}

export interface SwapFee {
  protocolFees: bigint;
  poolFees: bigint;
}
