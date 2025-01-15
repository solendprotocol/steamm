import {
  Transaction,
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";
import { SteammSDK } from "../sdk";
import { IModule } from "../interfaces/IModule";
import { DepositQuote, RedeemQuote } from "../base/pool/poolTypes";
import { SuiTypeName } from "../utils";
import { SuiAddressType } from "../utils";
import { BankInfo, PoolInfo } from "../types";
import { Bank, Pool } from "../base";

/**
 * Helper class to help interact with pools.
 */
export class PoolModule implements IModule {
  protected _sdk: SteammSDK;

  constructor(sdk: SteammSDK) {
    this._sdk = sdk;
  }

  get sdk() {
    return this._sdk;
  }

  public async depositLiquidity(
    args: PoolDepositLiquidityArgs,
    tx: Transaction
  ) {
    const pools = await this._sdk.getPools();
    const bankList = await this._sdk.getBankList();

    const poolInfo = pools.find((pool) => pool.poolId === args.pool)!;
    const bankInfoA = bankList[args.coinTypeA];
    const bankInfoB = bankList[args.coinTypeB];

    const pool = this.getPool(poolInfo);
    const bankA = this.getBank(bankInfoA);
    const bankB = this.getBank(bankInfoB);

    const bTokenA = bankA.mintBTokens(
      {
        coins: tx.object(args.coinObjA),
        coinAmount: args.maxA,
      },
      tx
    );

    const bTokenB = bankB.mintBTokens(
      {
        coins: tx.object(args.coinObjB),
        coinAmount: args.maxB,
      },
      tx
    );

    const maxbA = tx.moveCall({
      target: `0x2::coin::value`,
      typeArguments: [args.coinTypeA],
      arguments: [tx.object(args.coinObjA)],
    });
    const maxbB = tx.moveCall({
      target: `0x2::coin::value`,
      typeArguments: [args.coinTypeB],
      arguments: [tx.object(args.coinObjB)],
    });

    const [lpCoin, _depositResult] = pool.depositLiquidity(
      {
        coinA: bTokenA,
        coinB: bTokenB,
        maxA: maxbA,
        maxB: maxbB,
      },
      tx
    );

    // TODO: flash mint repay or burn?
    tx.transferObjects([bTokenA, bTokenB, lpCoin], this._sdk.senderAddress);
  }

  public async redeemLiquidity(args: PoolRedeemLiquidityArgs, tx: Transaction) {
    const pools = await this._sdk.getPools();
    const bankList = await this._sdk.getBankList();

    const poolInfo = pools.find((pool) => pool.poolId === args.pool)!;
    const bankInfoA = bankList[args.coinTypeA];
    const bankInfoB = bankList[args.coinTypeB];

    const pool = this.getPool(poolInfo);
    const bankA = this.getBank(bankInfoA);
    const bankB = this.getBank(bankInfoB);

    const [bTokenA, bTokenB, _redeemResult] = pool.redeemLiquidity(
      {
        lpCoinObj: tx.object(args.lpCoinObj),
        minA: args.minA,
        minB: args.minB,
      },
      tx
    );

    const bTokenAAmount = tx.moveCall({
      target: `0x2::coin::value`,
      typeArguments: [bankInfoA.btokenType],
      arguments: [bTokenA],
    });
    const bTokenBAmount = tx.moveCall({
      target: `0x2::coin::value`,
      typeArguments: [bankInfoB.btokenType],
      arguments: [bTokenB],
    });

    const coinA = bankA.burnBTokens(
      {
        btokens: bTokenA,
        btokenAmount: bTokenAAmount,
      },
      tx
    );

    const coinB = bankB.burnBTokens(
      {
        btokens: bTokenB,
        btokenAmount: bTokenBAmount,
      },
      tx
    );

    // TODO: destroy or transfer btokens
    tx.transferObjects(
      [coinA, coinB, bTokenA, bTokenB],
      this._sdk.senderAddress
    );
  }

  public async swap(args: PoolSwapArgs, tx: Transaction) {
    const pools = await this._sdk.getPools();
    const bankList = await this._sdk.getBankList();

    const poolInfo = pools.find((pool) => pool.poolId === args.pool)!;
    const bankInfoA = bankList[args.coinTypeA];
    const bankInfoB = bankList[args.coinTypeB];

    const pool = this.getPool(poolInfo);
    const bankA = this.getBank(bankInfoA);
    const bankB = this.getBank(bankInfoB);

    const bTokenA = args.a2b
      ? bankA.mintBTokens(
          {
            coins: tx.object(args.coinAObj),
            coinAmount: args.amountIn,
          },
          tx
        )
      : tx.moveCall({
          target: `0x2::coin::zero`,
          typeArguments: [bankInfoA.btokenType],
        });

    const bTokenB = !args.a2b
      ? bankB.mintBTokens(
          {
            coins: tx.object(args.coinBObj),
            coinAmount: args.amountIn,
          },
          tx
        )
      : tx.moveCall({
          target: `0x2::coin::zero`,
          typeArguments: [bankInfoA.btokenType],
        });

    const _swapResult = pool.swap(
      {
        coinA: tx.object(bTokenA),
        coinB: tx.object(bTokenB),
        a2b: args.a2b,
        amountIn: args.amountIn,
        // TODO: Min amount out should be translated from native coin T to bT
        minAmountOut: args.minAmountOut,
      },
      tx
    );

    const bTokenAAmount = tx.moveCall({
      target: `0x2::coin::value`,
      typeArguments: [bankInfoA.btokenType],
      arguments: [bTokenA],
    });
    const bTokenBAmount = tx.moveCall({
      target: `0x2::coin::value`,
      typeArguments: [bankInfoB.btokenType],
      arguments: [bTokenB],
    });

    const coinA = bankA.burnBTokens(
      {
        btokens: bTokenA,
        btokenAmount: bTokenAAmount,
      },
      tx
    );

    const coinB = bankB.burnBTokens(
      {
        btokens: bTokenB,
        btokenAmount: bTokenBAmount,
      },
      tx
    );

    // TODO: destroy or transfer btokens
    tx.transferObjects(
      [coinA, coinB, bTokenA, bTokenB],
      this._sdk.senderAddress
    );
  }

  public async quoteDeposit(args: QuoteDepositArgs): Promise<DepositQuote> {
    const tx = new Transaction();
    const pools = await this._sdk.getPools();
    const poolInfo = pools.find((pool) => pool.poolId === args.pool)!;

    const pool = this.getPool(poolInfo);
    const quote = pool.quoteDeposit(
      {
        maxA: args.maxA,
        maxB: args.maxB,
      },
      tx
    );

    return await this.getQuoteResult<DepositQuote>(tx, quote);
  }

  public async quoteRedeem(args: PoolQuoteRedeemArgs): Promise<RedeemQuote> {
    const tx = new Transaction();
    const pools = await this._sdk.getPools();
    const poolInfo = pools.find((pool) => pool.poolId === args.pool)!;

    const pool = this.getPool(poolInfo);
    const quote = pool.quoteRedeem(
      {
        lpTokens: args.lpTokens,
      },
      tx
    );

    return await this.getQuoteResult<RedeemQuote>(tx, quote);
  }

  private async getQuoteResult<T>(
    tx: Transaction,
    quote: TransactionArgument
  ): Promise<T> {
    const pkgAddy = this._sdk._sdkOptions.steamm_config.package_id;

    tx.moveCall({
      target: `0x2::event::emit`,
      typeArguments: [`${pkgAddy}::quote::DepositQuote`],
      arguments: [quote],
    });

    const inspectResults =
      await this._sdk._rpcModule.devInspectTransactionBlock({
        sender: this._sdk.senderAddress,
        transactionBlock: tx,
      });

    if (inspectResults.error) {
      throw new Error("DevInspect Failed");
    }

    const quoteResult = inspectResults.events[0].parsedJson as T;
    return quoteResult;
  }

  private getPool(poolInfo: PoolInfo): Pool {
    return new Pool(this._sdk.sdkOptions.steamm_config.package_id, poolInfo);
  }

  private getBank(bankInfo: BankInfo): Bank {
    return new Bank(this._sdk.sdkOptions.steamm_config.package_id, bankInfo);
  }

  // TODO
  // public setPoolSwapFees(
  //   args: PoolSetPoolSwapFeesArgs,
  //   tx: Transaction = new Transaction()
  // ) {
  //   const callArgs = {
  //     pool: tx.object(this.pool.id),
  //     poolCap: args.poolCap,
  //     swapFeeBps: args.swapFeeBps,
  //   };

  //   PoolFunctions.setPoolSwapFees(tx, this.typeArgs(), callArgs);
  // }

  // public setRedemptionFees(
  //   args: PoolSetRedemptionFeesArgs,
  //   tx: Transaction = new Transaction()
  // ) {
  //   const callArgs = {
  //     pool: tx.object(this.pool.id),
  //     poolCap: args.poolCap,
  //     redemptionFeeBps: args.redemptionFeeBps,
  //   };

  //   PoolFunctions.setRedemptionFees(tx, this.typeArgs(), callArgs);
  // }

  // public collectRedemptionFees(
  //   args: CollectRedemptionFeesArgs,
  //   tx: Transaction = new Transaction()
  // ): [TransactionArgument, TransactionArgument] {
  //   const callArgs = {
  //     pool: tx.object(this.pool.id),
  //     cap: args.poolCap,
  //   };

  //   const [coinA, coinB] = PoolFunctions.collectRedemptionFees(
  //     tx,
  //     this.typeArgs(),
  //     callArgs
  //   );

  //   return [coinA, coinB];
  // }

  // public collectProtocolFees(
  //   args: CollectProtocolFeesArgs,
  //   tx: Transaction = new Transaction()
  // ): [TransactionArgument, TransactionArgument] {
  //   const callArgs = {
  //     pool: tx.object(this.pool.id),
  //     globalAdmin: args.globalAdmin,
  //   };

  //   const [coinA, coinB] = PoolFunctions.collectProtocolFees(
  //     tx,
  //     this.typeArgs(),
  //     callArgs
  //   );

  //   return [coinA, coinB];
  // }

  // public migrate(
  //   args: MigratePoolArgs,
  //   tx: Transaction = new Transaction()
  // ): [TransactionArgument, TransactionArgument] {
  //   const callArgs = {
  //     pool: tx.object(this.pool.id),
  //     cap: args.poolCap,
  //   };

  //   const [coinA, coinB] = PoolFunctions.migrate(tx, this.typeArgs(), callArgs);

  //   return [coinA, coinB];
  // }
}

export interface PoolDepositLiquidityArgs {
  pool: SuiAddressType;
  coinTypeA: SuiTypeName;
  coinTypeB: SuiTypeName;
  coinObjA: SuiAddressType;
  coinObjB: SuiAddressType;
  maxA: bigint;
  maxB: bigint;
}

export interface PoolRedeemLiquidityArgs {
  pool: SuiAddressType;
  coinTypeA: SuiTypeName;
  coinTypeB: SuiTypeName;
  lpCoinObj: SuiAddressType;
  minA: bigint;
  minB: bigint;
}

export interface PoolSwapArgs {
  pool: SuiAddressType;
  coinTypeA: SuiTypeName;
  coinTypeB: SuiTypeName;
  coinAObj: TransactionObjectInput;
  coinBObj: TransactionObjectInput;
  a2b: boolean;
  amountIn: bigint;
  minAmountOut: bigint;
}

export interface QuoteDepositArgs {
  pool: SuiAddressType;
  maxA: bigint;
  maxB: bigint;
}

export interface PoolQuoteRedeemArgs {
  pool: SuiAddressType;
  lpTokens: bigint;
}
