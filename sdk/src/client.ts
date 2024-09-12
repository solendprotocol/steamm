import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Pool } from "./_generated/slamm/pool/structs";
import { TypeArgument } from "./_generated/_framework/reified";
import { Bank } from "./_generated/slamm/bank/structs";
import {
  depositLiquidity,
  needsLendingActionOnSwap,
  prepareBankForPendingWithdraw,
  quoteRedeem,
  redeemLiquidity,
  setPoolSwapFees,
  setRedemptionFees,
} from "./_generated/slamm/pool/functions";
import { LendingMarket } from "./_generated/_dependencies/source/0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf/lending-market/structs";
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

export abstract class PoolClient<
  A extends string,
  B extends string,
  Hook extends string,
  State extends TypeArgument,
  P extends string
> {
  public client: SuiClient;
  public pool: Pool<A, B, Hook, State>;
  public bankClientA: Bank<P, A>;
  public bankClientB: Bank<P, B>;
  public lendingMarket: LendingMarket<P>;
  public pkg: string;

  constructor(
    pkg: string,
    pool: Pool<A, B, Hook, State>,
    client: SuiClient,
    bankClientA: Bank<P, A>,
    bankClientB: Bank<P, B>,
    lendingMarket: LendingMarket<P>
  ) {
    this.pool = pool;
    this.pkg = pkg;
    this.client = client;
    this.bankClientA = bankClientA;
    this.bankClientB = bankClientB;
    this.lendingMarket = lendingMarket;
  }

  // Abstract methods

  abstract new(args: PoolNewArgs): Promise<void>;
  abstract intentSwap(args: PoolIntentSwapArgs): Promise<void>;
  abstract executeSwap(args: PoolExecuteSwapArgs): Promise<void>;
  abstract quoteSwap(args: PoolQuoteSwap): Promise<void>;

  // Methods

  public async depositLiquidity(
    args: PoolDepositLiquidityArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankClientA.id),
      bankB: tx.object(this.bankClientB.id),
      coinA: args.coinA,
      coinB: args.coinB,
      maxA: args.maxA,
      maxB: args.maxB,
      minA: args.minA,
      minB: args.minB,
    };

    depositLiquidity(tx, this.typeArgsWithP(), callArgs);
  }

  public async redeemLiquidity(
    args: PoolRedeemLiquidityArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankClientA.id),
      bankB: tx.object(this.bankClientB.id),
      lpTokens: args.lpTokens,
      minA: args.minA,
      minB: args.minB,
    };

    redeemLiquidity(tx, this.typeArgsWithP(), callArgs);
  }

  public async quoteDeposit(
    args: PoolRedeemLiquidityArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankClientA.id),
      bankB: tx.object(this.bankClientB.id),
      lpTokens: args.lpTokens,
      minA: args.minA,
      minB: args.minB,
    };

    redeemLiquidity(tx, this.typeArgsWithP(), callArgs);
  }

  public async quoteRedeem(
    args: PoolQuoteRedeemArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      lpTokens: args.lpTokens,
    };

    quoteRedeem(tx, this.typeArgs(), callArgs);
  }
  public async prepareBankForPendingWithdraw(
    args: PoolPrepareBankForPendingWithdrawArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankClientA.id),
      bankB: tx.object(this.bankClientB.id),
      lendingMarket: tx.object(this.lendingMarket.id),
      intent: args.intent,
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    prepareBankForPendingWithdraw(tx, this.typeArgsWithP(), callArgs);
  }
  public async needsLendingActionOnSwap(
    args: PoolNeedsLendingActionOnSwapArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankClientA.id),
      bankB: tx.object(this.bankClientB.id),
      quote: args.quote,
    };

    needsLendingActionOnSwap(tx, this.typeArgsWithP(), callArgs);
  }
  public async setPoolSwapFees(
    args: PoolSetPoolSwapFeesArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      poolCap: args.poolCap,
      swapFeeBps: args.swapFeeBps,
    };

    setPoolSwapFees(tx, this.typeArgs(), callArgs);
  }
  public async setRedemptionFees(
    args: PoolSetRedemptionFeesArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      poolCap: args.poolCap,
      redemptionFeeBps: args.redemptionFeeBps,
    };

    setRedemptionFees(tx, this.typeArgs(), callArgs);
  }

  public typeArgsWithP(): [string, string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    const [typeP, _] = this.bankClientA.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`, `${typeP}`];
  }

  public typeArgs(): [string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`];
  }
}
