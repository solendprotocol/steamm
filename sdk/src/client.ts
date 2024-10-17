import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
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

export abstract class PoolClient<
  A extends PhantomTypeArgument,
  B extends PhantomTypeArgument,
  Hook extends PhantomTypeArgument,
  State extends TypeArgument,
  P extends PhantomTypeArgument
> {
  public client: SuiClient;
  public pool: Pool<A, B, Hook, State>;
  public bankA: Bank<P, A>;
  public bankB: Bank<P, B>;
  public lendingMarket: LendingMarket<P>;

  constructor(
    pool: Pool<A, B, Hook, State>,
    client: SuiClient,
    bankA: Bank<P, A>,
    bankB: Bank<P, B>,
    lendingMarket: LendingMarket<P>
  ) {
    this.pool = pool;
    this.client = client;
    this.bankA = bankA;
    this.bankB = bankB;
    this.lendingMarket = lendingMarket;
  }

  // Abstract methods
  abstract newPool(args: PoolNewArgs): Transaction;
  abstract intentSwap(args: PoolIntentSwapArgs, tx: Transaction): void;
  abstract executeSwap(args: PoolExecuteSwapArgs, tx: Transaction): void;
  abstract quoteSwap(args: PoolQuoteSwap, tx: Transaction): void;

  protected static async fetchState<
    A extends PhantomTypeArgument,
    B extends PhantomTypeArgument,
    P extends PhantomTypeArgument,
    HookType extends PhantomTypeArgument,
    StateType extends StructClass,
    StateFields,
    State extends Reified<StateType, StateFields>
  >(
    aType: A,
    bType: B,
    hookType: HookType,
    state: State,
    pType: P,
    poolId: string,
    bankAId: string,
    bankBId: string,
    lendingMarketId: string,
    client: SuiClient
  ): Promise<
    [
      Pool<A, B, HookType, ToTypeArgument<State>>,
      Bank<P, A>,
      Bank<P, B>,
      LendingMarket<P>
    ]
  > {
    const poolTypeArgs: [
      PhantomReified<A>,
      PhantomReified<B>,
      PhantomReified<HookType>,
      State
    ] = [phantom(aType), phantom(bType), phantom(hookType), state];

    const pool = await Pool.fetch<
      PhantomReified<A>,
      PhantomReified<B>,
      PhantomReified<HookType>,
      State
    >(client, poolTypeArgs, poolId);

    const bankATypeArgs: [PhantomReified<P>, PhantomReified<A>] = [
      phantom(pType),
      phantom(aType),
    ];

    const bankBTypeArgs: [PhantomReified<P>, PhantomReified<B>] = [
      phantom(pType),
      phantom(bType),
    ];

    const bankA = await Bank.fetch(client, bankATypeArgs, bankAId);
    const bankB = await Bank.fetch(client, bankBTypeArgs, bankBId);

    const lendingMarket = await LendingMarket.fetch(
      client,
      phantom(pType),
      lendingMarketId
    );

    return [pool, bankA, bankB, lendingMarket];
  }

  // Module Methods

  public depositLiquidity(
    args: PoolDepositLiquidityArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.id),
      bankB: tx.object(this.bankB.id),
      coinA: args.coinA,
      coinB: args.coinB,
      maxA: args.maxA,
      maxB: args.maxB,
      minA: args.minA,
      minB: args.minB,
    };

    depositLiquidity(tx, this.typeArgsWithP(), callArgs);
  }

  public redeemLiquidity(
    args: PoolRedeemLiquidityArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.id),
      bankB: tx.object(this.bankB.id),
      lpTokens: args.lpTokens,
      minA: args.minA,
      minB: args.minB,
    };

    redeemLiquidity(tx, this.typeArgsWithP(), callArgs);
  }

  public quoteDeposit(
    args: PoolRedeemLiquidityArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.id),
      bankB: tx.object(this.bankB.id),
      lpTokens: args.lpTokens,
      minA: args.minA,
      minB: args.minB,
    };

    redeemLiquidity(tx, this.typeArgsWithP(), callArgs);
  }

  public quoteRedeem(
    args: PoolQuoteRedeemArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      lpTokens: args.lpTokens,
    };

    quoteRedeem(tx, this.typeArgs(), callArgs);
  }

  public prepareBankForPendingWithdraw(
    args: PoolPrepareBankForPendingWithdrawArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.id),
      bankB: tx.object(this.bankB.id),
      lendingMarket: tx.object(this.lendingMarket.id),
      intent: args.intent,
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    prepareBankForPendingWithdraw(tx, this.typeArgsWithP(), callArgs);
  }

  public setPoolSwapFees(
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

  public setRedemptionFees(
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
    const [typeP, _] = this.bankA.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`, `${typeP}`];
  }

  public typeArgs(): [string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`];
  }

  public static createBank(
    pType: string,
    tType: string,
    registryID: string,
    tx: Transaction = new Transaction()
  ) {
    const registry = tx.object(registryID);

    createBankAndShare(tx, [pType, tType], registry);
  }
}
