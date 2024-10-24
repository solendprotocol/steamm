import { SuiClient } from "@mysten/sui/client";
import { Transaction, TransactionArgument } from "@mysten/sui/transactions";
import {
  PhantomTypeArgument,
  ToTypeArgument,
  PhantomToTypeStr,
} from "../_codegen/_generated/_framework/reified";
import {
  CpExecuteSwapArgs,
  CpIntentSwapArgs,
  CpNewArgs,
  CpPoolQuoteSwap,
  CpSwapArgs,
  SwapQuote,
} from "./constantProductArgs";
import { PKG_V1 } from "../_codegen/_generated/slamm";
import {
  Hook,
  State,
  StateFields,
  StateReified,
} from "../_codegen/_generated/slamm/cpmm/structs";
import { GenericHookType, ObjectIds, PoolTypes } from "../utils";
import { Pool } from "../pool/pool";
import { ConstantProductFunctions, LendingMarketObj, PoolObj } from "..";
import { Bank } from "../bank/bank";
import { MigrateArgs, MigrateAsGlobalAdminArgs } from "../pool/poolArgs";

export type HookType<W extends PhantomTypeArgument> = GenericHookType<Hook<W>>;
export type StateType = ToTypeArgument<StateReified>;

export class ConstantProductPool<
  A extends PhantomTypeArgument,
  B extends PhantomTypeArgument,
  W extends PhantomTypeArgument,
  P extends PhantomTypeArgument
> extends Pool<A, B, HookType<W>, StateType, P> {
  public hook: Hook<W>;

  constructor(
    pool: PoolObj<A, B, HookType<W>, State>,
    bankA: Bank<P, A>,
    bankB: Bank<P, B>,
    lendingMarket: LendingMarketObj<P>,
    hook: Hook<W>
  ) {
    super(pool, bankA, bankB, lendingMarket);
    this.hook = hook;
  }

  public async fetch(
    poolTypes: PoolTypes<A, B, Hook<W>, W, State, P>,
    objectIds: ObjectIds,
    client: SuiClient
  ): Promise<ConstantProductPool<A, B, W, P>> {
    const { aType, bType, hookType, wit, pType } = poolTypes;
    const { poolId, bankAId, bankBId, lendingMarketId } = objectIds;

    const hookTypeName: HookType<W> = `${PKG_V1}::cpmm::Hook<${
      wit as PhantomToTypeStr<W>
    }>`;

    const state = State.reified();

    const [pool, bankAObj, bankBObj, lendingMarketObj] = await Pool.fetchState<
      A,
      B,
      P,
      HookType<W>,
      State,
      StateFields,
      StateReified
    >(
      aType,
      bType,
      hookTypeName,
      state,
      pType,
      poolId,
      bankAId,
      bankBId,
      lendingMarketId,
      client
    );

    const bankA = new Bank(bankAObj, lendingMarketObj);
    const bankB = new Bank(bankBObj, lendingMarketObj);

    return new ConstantProductPool(
      pool,
      bankA,
      bankB,
      lendingMarketObj,
      hookType
    );
  }

  public newPool(args: CpNewArgs): Transaction {
    const tx = new Transaction();

    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.bank.id),
      bankB: tx.object(this.bankB.bank.id),
      witness: args.witness,
      registry: args.registry,
      swapFeeBps: args.swapFeeBps,
      inner: args.inner,
      offset: args.offset,
    };

    const pool =
      callArgs.offset === (0 || tx.pure.u64(0))
        ? ConstantProductFunctions.newWithOffset(
            tx,
            this.rawTypeArgs(),
            callArgs
          )
        : ConstantProductFunctions.new_(tx, this.rawTypeArgs(), callArgs);

    tx.shareObject(pool, this.poolType());

    return tx;
  }

  public swap(args: CpSwapArgs, tx: Transaction = new Transaction()) {
    const intent = this.intentSwap(args, tx);
    this.executeSwap({ ...args, intent }, tx);
  }

  public intentSwap(
    args: CpIntentSwapArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      pool: tx.object(this.pool.id),
      amountIn: args.amountIn,
      a2B: args.a2b,
    };

    const intent = ConstantProductFunctions.intentSwap(
      tx,
      this.rawTypeArgs(),
      callArgs
    );
    return intent;
  }

  public executeSwap(
    args: CpExecuteSwapArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      pool: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.bank.id),
      bankB: tx.object(this.bankB.bank.id),
      intent: args.intent,
      coinA: args.coinA,
      coinB: args.coinB,
      minAmountOut: args.minAmountOut,
    };

    ConstantProductFunctions.executeSwap(tx, this.rawTypeArgsWithP(), callArgs);
  }

  public async computeSwapQuote(
    provider: SuiClient,
    sender: string,
    args: CpPoolQuoteSwap
  ): Promise<SwapQuote> {
    const txb = new Transaction();
    const quote = this.quoteSwap(args, txb);
    txb.moveCall({
      target: `0x2::event::emit`,
      typeArguments: [`${PKG_V1}::slamm::quote::SwapQuote`], // TODO: pkg should not be hardcoded
      arguments: [quote],
    });

    const result = await provider.devInspectTransactionBlock({
      transactionBlock: txb,
      sender,
    });

    if (result.error) {
      throw new Error(result.error);
    }
    const swapQuoteEvent = result.events.find(
      (event) => event.type === `${PKG_V1}::slamm::quote::SwapQuote` // TODO: pkg should not be hardcoded
    );

    if (!swapQuoteEvent || !swapQuoteEvent.parsedJson) {
      throw new Error("SwapQuote event not found");
    }

    return swapQuoteEvent.parsedJson as SwapQuote;
  }

  public quoteSwap(
    args: CpPoolQuoteSwap,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      pool: tx.object(this.pool.id),
      amountIn: args.amountIn,
      a2B: args.a2b,
    };

    const quote = ConstantProductFunctions.quoteSwap(
      tx,
      this.rawTypeArgs(),
      callArgs
    );
    return quote;
  }

  public poolType(): [string] {
    return [`${this.pool.$fullTypeName}`];
  }

  public rawTypeArgs(): [string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    const [typeW] = this.hook.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeW}`];
  }

  public rawTypeArgsWithP(): [string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    const [typeW] = this.hook.$typeArgs;
    const [typeP, _] = this.bankA.bank.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeW}`, `${typeP}`];
  }

  public rawTypeWithGenericHookArgs(): [string, string, string, string] {
    const [typeA, typeB, typeHook, typeState] = this.pool.$typeArgs;
    const [typeW] = this.hook.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeHook}`, `${typeState}`];
  }

  // Getter functions

  public viewOffset(tx: Transaction = new Transaction()): TransactionArgument {
    return ConstantProductFunctions.offset(
      tx,
      this.rawTypeArgs(),
      tx.object(this.pool.id)
    );
  }

  public viewK(
    offset: TransactionArgument,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return ConstantProductFunctions.k(tx, this.rawTypeWithGenericHookArgs(), {
      pool: tx.object(this.pool.id),
      offset: tx.object(offset),
    });
  }

  public migrateHook(
    args: MigrateArgs,
    tx: Transaction = new Transaction()
  ): [TransactionArgument, TransactionArgument] {
    const callArgs = {
      pool: tx.object(this.pool.id),
      cap: args.poolCap,
    };

    const [coinA, coinB] = ConstantProductFunctions.migrate(
      tx,
      this.rawTypeArgs(),
      callArgs
    );

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

    const [coinA, coinB] = ConstantProductFunctions.migrateAsGlobalAdmin(
      tx,
      this.rawTypeArgs(),
      callArgs
    );

    return [coinA, coinB];
  }
}
