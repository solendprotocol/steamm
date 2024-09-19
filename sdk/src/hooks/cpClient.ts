import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { Pool } from "./../_generated/slamm/pool/structs";
import {
  PhantomTypeArgument,
  ToTypeArgument,
  PhantomToTypeStr,
} from "./../_generated/_framework/reified";
import { Bank } from "./../_generated/slamm/bank/structs";
import { LendingMarket } from "./../_generated/_dependencies/source/0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf/lending-market/structs";
import { PoolClient } from "../client";
import {
  CpExecuteSwapArgs,
  CpIntentSwapArgs,
  CpNewArgs,
  CpPoolQuoteSwap,
} from "./cpArgs";
import {
  executeSwap,
  intentSwap,
  new_,
  newWithOffset,
  quoteSwap,
} from "../_generated/slamm/cpmm/functions";
import {
  Hook,
  State,
  StateFields,
  StateReified,
} from "../_generated/slamm/cpmm/structs";
import { PKG_V1 } from "../_generated/slamm";
import { GenericHookType, ObjectIds, PoolTypes } from "../utils";

export type HookType<W extends PhantomTypeArgument> = GenericHookType<Hook<W>>;
export type StateType = ToTypeArgument<StateReified>;

export class CpClient<
  A extends PhantomTypeArgument,
  B extends PhantomTypeArgument,
  W extends PhantomTypeArgument,
  P extends PhantomTypeArgument
> extends PoolClient<A, B, HookType<W>, StateType, P> {
  public hook: Hook<W>;

  constructor(
    pool: Pool<A, B, HookType<W>, State>,
    client: SuiClient,
    bankA: Bank<P, A>,
    bankB: Bank<P, B>,
    lendingMarket: LendingMarket<P>,
    hook: Hook<W>
  ) {
    super(pool, client, bankA, bankB, lendingMarket);
    this.hook = hook;
  }

  public async fetch(
    poolTypes: PoolTypes<A, B, Hook<W>, W, State, P>,
    objectIds: ObjectIds,
    client: SuiClient
  ): Promise<CpClient<A, B, W, P>> {
    const { aType, bType, hookType, wit, pType } = poolTypes;
    const { poolId, bankAId, bankBId, lendingMarketId } = objectIds;

    const hookTypeName: HookType<W> = `${PKG_V1}::cpmm::Hook<${
      wit as PhantomToTypeStr<W>
    }>`;

    const state = State.reified();

    const [pool, bankA, bankB, lendingMarket] = await PoolClient.fetchState<
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

    return new CpClient(pool, client, bankA, bankB, lendingMarket, hookType);
  }

  public newPool(args: CpNewArgs): Transaction {
    const tx = new Transaction();

    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.id),
      bankB: tx.object(this.bankB.id),
      witness: args.witness,
      registry: args.registry,
      swapFeeBps: args.swapFeeBps,
      inner: args.inner,
      offset: args.offset,
    };

    const pool =
      callArgs.offset === (0 || tx.pure.u64(0))
        ? newWithOffset(tx, this.rawTypeArgs(), callArgs)
        : new_(tx, this.rawTypeArgs(), callArgs);

    tx.shareObject(pool, this.poolType());

    return tx;
  }

  public intentSwap(
    args: CpIntentSwapArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      amountIn: args.amountIn,
      a2B: args.a2b,
    };

    intentSwap(tx, this.rawTypeArgs(), callArgs);
  }

  public executeSwap(
    args: CpExecuteSwapArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      self: tx.object(this.pool.id),
      bankA: tx.object(this.bankA.id),
      bankB: tx.object(this.bankB.id),
      intent: args.intent,
      coinA: args.coinA,
      coinB: args.coinB,
      minAmountOut: args.minAmountOut,
    };

    executeSwap(tx, this.rawTypeArgsWithP(), callArgs);
  }

  public quoteSwap(args: CpPoolQuoteSwap, tx: Transaction = new Transaction()) {
    const callArgs = {
      self: tx.object(this.pool.id),
      amountIn: args.amountIn,
      a2B: args.a2b,
    };

    quoteSwap(tx, this.rawTypeArgs(), callArgs);
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
    const [typeP, _] = this.bankA.$typeArgs;
    return [`${typeA}`, `${typeB}`, `${typeW}`, `${typeP}`];
  }
}
