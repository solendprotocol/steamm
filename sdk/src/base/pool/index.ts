import {
  Transaction,
  TransactionArgument,
  TransactionResult,
} from "@mysten/sui/transactions";
import {
  CollectProtocolFeesArgs,
  CollectRedemptionFeesArgs,
  MigrateArgs,
  PoolDepositLiquidityArgs,
  PoolQuoteRedeemArgs,
  PoolRedeemLiquidityArgs,
  PoolSetPoolSwapFeesArgs,
  PoolSetRedemptionFeesArgs,
  PoolSwapArgs,
  QuoteDepositArgs,
} from "./poolArgs";
import { PoolFunctions } from "../..";
import { PoolInfo } from "../../types";
import { Quoter } from "../quoters/quoter";
import { ConstantProductQuoter } from "../quoters/constantQuoter";

export * from "./poolArgs";
export * from "./poolTypes";

export class Pool {
  public packageId: string;
  public poolInfo: PoolInfo;
  public quoter: Quoter;

  constructor(packageId: string, poolInfo: PoolInfo) {
    this.poolInfo = poolInfo;
    this.packageId = packageId;

    this.quoter = this.createQuoter(packageId, poolInfo);
  }

  private createQuoter(packageId: string, poolInfo: PoolInfo): Quoter {
    switch (poolInfo.quoterType) {
      case `${packageId}::cpmm::CpQuoter`:
        return new ConstantProductQuoter(packageId, poolInfo);
      default:
        throw new Error(`Unsupported quoter type: ${poolInfo.quoterType}`);
    }
  }

  public swap(args: PoolSwapArgs, tx: Transaction): TransactionResult {
    return this.quoter.swap(args, tx);
  }

  public quoteSwap(args: PoolSwapArgs, tx: Transaction): TransactionArgument {
    return this.quoter.swap(args, tx);
  }

  public depositLiquidity(
    args: PoolDepositLiquidityArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      coinA: args.coinA,
      coinB: args.coinB,
      maxA: args.maxA,
      maxB: args.maxB,
    };

    const [lpCoin, depositResult] = PoolFunctions.depositLiquidity(
      tx,
      this.poolTypes(),
      callArgs
    );
    return [lpCoin, depositResult];
  }

  public redeemLiquidity(
    args: PoolRedeemLiquidityArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      lpTokens: args.lpCoinObj,
      minA: args.minA,
      minB: args.minB,
    };

    const [coinA, coinB, redeemResult] = PoolFunctions.redeemLiquidity(
      tx,
      this.poolTypes(),
      callArgs
    );
    return [coinA, coinB, redeemResult];
  }

  public quoteDeposit(
    args: QuoteDepositArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      maxA: args.maxA,
      maxB: args.maxB,
    };

    const quote = PoolFunctions.quoteDeposit(tx, this.poolTypes(), callArgs);
    return quote;
  }

  public quoteRedeem(
    args: PoolQuoteRedeemArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      lpTokens: args.lpTokens,
    };

    const quote = PoolFunctions.quoteRedeem(tx, this.poolTypes(), callArgs);
    return quote;
  }

  public setPoolSwapFees(
    args: PoolSetPoolSwapFeesArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      poolCap: args.poolCap,
      swapFeeBps: args.swapFeeBps,
    };

    PoolFunctions.setPoolSwapFees(tx, this.poolTypes(), callArgs);
  }

  public setRedemptionFees(
    args: PoolSetRedemptionFeesArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      poolCap: args.poolCap,
      redemptionFeeBps: args.redemptionFeeBps,
    };

    PoolFunctions.setRedemptionFees(tx, this.poolTypes(), callArgs);
  }

  public collectRedemptionFees(
    args: CollectRedemptionFeesArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      cap: args.poolCap,
    };

    const [coinA, coinB] = PoolFunctions.collectRedemptionFees(
      tx,
      this.poolTypes(),
      callArgs
    );

    return [coinA, coinB];
  }

  public collectProtocolFees(
    args: CollectProtocolFeesArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      globalAdmin: args.globalAdmin,
    };

    const [coinA, coinB] = PoolFunctions.collectProtocolFees(
      tx,
      this.poolTypes(),
      callArgs
    );

    return [coinA, coinB];
  }

  public migrate(
    args: MigrateArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.poolInfo.poolId),
      admin: args.adminCap,
    };

    const [coinA, coinB] = PoolFunctions.migratePool(
      tx,
      this.poolTypes(),
      callArgs
    );

    return [coinA, coinB];
  }

  public poolTypes(): [string, string, string, string] {
    return [
      this.poolInfo.coinTypeA,
      this.poolInfo.coinTypeB,
      this.poolInfo.quoterType,
      this.poolInfo.lpTokenType,
    ];
  }

  // Getter functions

  public viewBalanceAmounts(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.balanceAmounts(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewBalanceAmountA(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.balanceAmountA(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewBalanceAmountB(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.balanceAmountB(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewProtocolFees(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.protocolFees(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewPoolFeeConfig(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.poolFeeConfig(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewLpSupplyVal(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.lpSupplyVal(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewTradingData(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return PoolFunctions.tradingData(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
  }

  public viewQuoter(tx: Transaction = new Transaction()): TransactionArgument {
    return PoolFunctions.quoter(
      tx,
      this.poolTypes(),
      tx.object(this.poolInfo.poolId)
    );
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
