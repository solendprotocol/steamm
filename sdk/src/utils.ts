import {
  PhantomReified,
  StructClass,
  ToPhantomTypeArgument,
  ToTypeStr,
} from ".";

export type GenericHookType<T extends StructClass> = ToPhantomTypeArgument<
  PhantomReified<ToTypeStr<T>>
>;

export interface PoolTypes<A, B, HookType, W, State, P> {
  aType: A;
  bType: B;
  hookType: HookType;
  wit: W;
  state: State;
  pType: P;
}

export interface ObjectIds {
  poolId: string;
  bankAId: string;
  bankBId: string;
  lendingMarketId: string;
}
