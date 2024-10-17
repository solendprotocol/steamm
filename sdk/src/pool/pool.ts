import { SuiClient } from "@mysten/sui/client";
import { Transaction, TransactionArgument } from "@mysten/sui/transactions";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui/dist/cjs/utils";
import {
  CollectProtocolFeesArgs,
  CollectRedemptionFeesArgs,
  MigrateArgs,
  MigrateAsGlobalAdminArgs,
  PoolDepositLiquidityArgs,
  PoolExecuteSwapArgs,
  PoolIntentSwapArgs,
  PoolNewArgs,
  PoolPrepareBankForPendingWithdrawArgs,
  PoolQuoteRedeemArgs,
  PoolQuoteSwap,
  PoolRedeemLiquidityArgs,
  PoolSetPoolSwapFeesArgs,
  PoolSetRedemptionFeesArgs,
  QuoteDepositArgs,
} from "./poolArgs";
import {
  PoolFunctions,
  PoolObj,
  BankObj,
  LendingMarketObj,
  phantom,
  PhantomReified,
  PhantomTypeArgument,
  TypeArgument,
  StructClass,
  ToTypeArgument,
  Reified,
} from "..";
import { Bank } from "../bank/bank";

export abstract class Pool<
  A extends PhantomTypeArgument,
  B extends PhantomTypeArgument,
  Hook extends PhantomTypeArgument,
  State extends TypeArgument,
  P extends PhantomTypeArgument
> {
  public pool: PoolObj<A, B, Hook, State>;
  public bankA: Bank<P, A>;
  public bankB: Bank<P, B>;
  public lendingMarket: LendingMarketObj<P>;

  constructor(
    pool: PoolObj<A, B, Hook, State>,
    bankA: Bank<P, A>,
    bankB: Bank<P, B>,
    lendingMarket: LendingMarketObj<P>
  ) {
    this.pool = pool;
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
      PoolObj<A, B, HookType, ToTypeArgument<State>>,
      BankObj<P, A>,
      BankObj<P, B>,
      LendingMarketObj<P>
    ]
  > {
    const poolTypeArgs: [
      PhantomReified<A>,
      PhantomReified<B>,
      PhantomReified<HookType>,
      State
    ] = [phantom(aType), phantom(bType), phantom(hookType), state];

    const pool = await PoolObj.fetch<
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

    const bankA = await BankObj.fetch(client, bankATypeArgs, bankAId);
    const bankB = await BankObj.fetch(client, bankBTypeArgs, bankBId);

    const lendingMarket = await LendingMarketObj.fetch(
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
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.bank.id),
      bankB: tx.object(this.bankB.bank.id),
      coinA: args.coinA,
      coinB: args.coinB,
      maxA: args.maxA,
      maxB: args.maxB,
      minA: args.minA,
      minB: args.minB,
    };

    const [lpCoin, depositResult] = PoolFunctions.depositLiquidity(
      tx,
      this.typeArgsWithP(),
      callArgs
    );
    return [lpCoin, depositResult];
  }

  public redeemLiquidity(
    args: PoolRedeemLiquidityArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.bank.id),
      bankB: tx.object(this.bankB.bank.id),
      lpTokens: args.lpTokens,
      minA: args.minA,
      minB: args.minB,
    };

    const [coinA, coinB, redeemResult] = PoolFunctions.redeemLiquidity(
      tx,
      this.typeArgsWithP(),
      callArgs
    );
    return [coinA, coinB, redeemResult];
  }

  public quoteDeposit(
    args: QuoteDepositArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      pool: tx.object(this.pool.id),
      idealA: args.idealA,
      idealB: args.idealB,
    };

    const quote = PoolFunctions.quoteDeposit(tx, this.typeArgs(), callArgs);
    return quote;
  }

  public quoteRedeem(
    args: PoolQuoteRedeemArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      pool: tx.object(this.pool.id),
      lpTokens: args.lpTokens,
    };

    const quote = PoolFunctions.quoteRedeem(tx, this.typeArgs(), callArgs);
    return quote;
  }

  public prepareBankForPendingWithdraw(
    args: PoolPrepareBankForPendingWithdrawArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.bank.id),
      bankB: tx.object(this.bankB.bank.id),
      lendingMarket: tx.object(this.lendingMarket.id),
      intent: args.intent,
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    PoolFunctions.prepareBankForPendingWithdraw(
      tx,
      this.typeArgsWithP(),
      callArgs
    );
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

    PoolFunctions.setPoolSwapFees(tx, this.typeArgs(), callArgs);
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

    PoolFunctions.setRedemptionFees(tx, this.typeArgs(), callArgs);
  }

  public collectRedemptionFees(
    args: CollectRedemptionFeesArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      cap: args.poolCap,
    };

    const [coinA, coinB] = PoolFunctions.collectRedemptionFees(
      tx,
      this.typeArgs(),
      callArgs
    );

    return [coinA, coinB];
  }

  public collectProtocolFees(
    args: CollectProtocolFeesArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      globalAdmin: args.globalAdmin,
    };

    const [coinA, coinB] = PoolFunctions.collectProtocolFees(
      tx,
      this.typeArgs(),
      callArgs
    );

    return [coinA, coinB];
  }

  public migrate(
    args: MigrateArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      cap: args.poolCap,
    };

    const [coinA, coinB] = PoolFunctions.migrate(tx, this.typeArgs(), callArgs);

    return [coinA, coinB];
  }

  public migrateAsGlobalAdmin(
    args: MigrateAsGlobalAdminArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      admin: args.globalAdmin,
    };

    const [coinA, coinB] = PoolFunctions.migrateAsGlobalAdmin(
      tx,
      this.typeArgs(),
      callArgs
    );

    return [coinA, coinB];
  }

  public typeArgsWithP(): [string, string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    const [typeP, _] = this.bankA.bank.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`, `${typeP}`];
  }

  public typeArgs(): [string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`];
  }

  // Getter functions

  public viewTotalFunds(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalFunds(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewTotalFundsA(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalFundsA(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewTotalFundsB(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalFundsB(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewProtocolFees(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.protocolFees(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewPoolFeeConfig(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.poolFeeConfig(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewLpSupplyVal(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.lpSupplyVal(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewTradingData(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.tradingData(
      tx,
      this.typeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewInner(tx: Transaction = new Transaction()): TransactionArgument {
    return PoolFunctions.inner(tx, this.typeArgs(), tx.object(this.pool.id));
  }

  public viewTotalSwapAInAmount(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalSwapAInAmount(tx, tradeData);
  }

  public viewTotalSwapBOutAmount(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalSwapBOutAmount(tx, tradeData);
  }

  public viewTotalSwapAOutAmount(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalSwapAOutAmount(tx, tradeData);
  }

  public viewTotalSwapBInAmount(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.totalSwapBInAmount(tx, tradeData);
  }

  public viewProtocolFeesA(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.protocolFeesA(tx, tradeData);
  }

  public viewProtocolFeesB(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.protocolFeesB(tx, tradeData);
  }

  public viewPoolFeesA(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.poolFeesA(tx, tradeData);
  }

  public viewPoolFeesB(
    tradeData: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.poolFeesB(tx, tradeData);
  }

  public viewMinimumLiquidity(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.minimumLiquidity(tx);
  }

  public viewIntentQuote(
    intent: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.intentQuote(tx, this.typeArgs(), intent);
  }

  public viewSwapResultUser(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultUser(tx, swapResult);
  }

  public viewSwapResultPoolId(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultPoolId(tx, swapResult);
  }

  public viewSwapResultAmountIn(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultAmountIn(tx, swapResult);
  }

  public viewSwapResultAmountOut(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultAmountOut(tx, swapResult);
  }

  public viewSwapResultProtocolFees(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultProtocolFees(tx, swapResult);
  }

  public viewSwapResultPoolFees(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultPoolFees(tx, swapResult);
  }

  public viewSwapResultA2b(
    swapResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.swapResultA2b(tx, swapResult);
  }

  public viewDepositResultUser(
    depositResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.depositResultUser(tx, depositResult);
  }

  public viewDepositResultPoolId(
    depositResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.depositResultPoolId(tx, depositResult);
  }

  public viewDepositResultDepositA(
    depositResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.depositResultDepositA(tx, depositResult);
  }

  public viewDepositResultDepositB(
    depositResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.depositResultDepositB(tx, depositResult);
  }

  public viewDepositResultMintLp(
    depositResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.depositResultMintLp(tx, depositResult);
  }

  public viewRedeemResultUser(
    redeemResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.redeemResultUser(tx, redeemResult);
  }

  public viewRedeemResultPoolId(
    redeemResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.redeemResultPoolId(tx, redeemResult);
  }

  public viewRedeemResultWithdrawA(
    redeemResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.redeemResultWithdrawA(tx, redeemResult);
  }

  public viewRedeemResultWithdrawB(
    redeemResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.redeemResultWithdrawB(tx, redeemResult);
  }

  public viewRedeemResultBurnLp(
    redeemResult: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.redeemResultBurnLp(tx, redeemResult);
  }
}
