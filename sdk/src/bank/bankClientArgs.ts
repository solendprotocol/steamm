import {
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";

export interface InitLendingArgs {
  globalAdmin: TransactionObjectInput;
  targetUtilisationBps: number | TransactionArgument;
  utilisationBufferBps: number | TransactionArgument;
}

export interface CTokenAmountArgs {
  amount: bigint | TransactionArgument;
}

export interface SetUtilisationBpsArgs {
  globalAdmin: TransactionObjectInput;
  targetUtilisationBps: number | TransactionArgument;
  utilisationBufferBps: number | TransactionArgument;
}

export interface MigrateAsGlobalAdminArgs {
  admin: TransactionObjectInput;
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
