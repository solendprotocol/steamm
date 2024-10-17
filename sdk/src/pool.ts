import { SuiClient } from "@mysten/sui/client";
import {
  Transaction,
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";
import { Pool } from "./codegen/_generated/slamm/pool/structs";
import {
  PhantomTypeArgument,
  TypeArgument,
  phantom,
  StructClass,
  Reified,
  PhantomReified,
  ToTypeArgument,
} from "./codegen/_generated/_framework/reified";
import { Bank } from "./codegen/_generated/slamm/bank/structs";
import {
  depositLiquidity,
  needsLendingActionOnSwap,
  prepareBankForPendingWithdraw,
  quoteRedeem,
  redeemLiquidity,
  setPoolSwapFees,
  setRedemptionFees,
} from "./codegen/_generated/slamm/pool/functions";
import { LendingMarket } from "./codegen/_generated/_dependencies/source/0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf/lending-market/structs";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui/dist/cjs/utils";
import {
  PoolDepositLiquidityArgs,
  PoolExecuteSwapArgs,
  PoolIntentSwapArgs,
  PoolNeedsLendingActionOnSwapArgs,
  PoolNewArgs,
  PoolPrepareBankForPendingWithdrawArgs,
  PoolQuoteRedeemArgs,
  PoolQuoteSwap,
  PoolRedeemLiquidityArgs,
  PoolSetPoolSwapFeesArgs,
  PoolSetRedemptionFeesArgs,
} from "./clientArgs";
import { createBankAndShare } from "./codegen/_generated/slamm/bank/functions";
