import { PUBLISHED_AT } from "..";
import { obj, pure } from "../../_framework/util";
import {
  Transaction,
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";

export interface CtokenAmountArgs {
  bank: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  amount: bigint | TransactionArgument;
}

export function ctokenAmount(
  tx: Transaction,
  typeArgs: [string, string],
  args: CtokenAmountArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::ctoken_amount`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      obj(tx, args.lendingMarket),
      pure(tx, args.amount, `u64`),
    ],
  });
}

export interface DepositArgs {
  bank: TransactionObjectInput;
  balance: TransactionObjectInput;
}

export function deposit(
  tx: Transaction,
  typeArgs: [string, string],
  args: DepositArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::deposit`,
    typeArguments: typeArgs,
    arguments: [obj(tx, args.bank), obj(tx, args.balance)],
  });
}

export interface WithdrawArgs {
  bank: TransactionObjectInput;
  amount: bigint | TransactionArgument;
}

export function withdraw(
  tx: Transaction,
  typeArgs: [string, string],
  args: WithdrawArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::withdraw`,
    typeArguments: typeArgs,
    arguments: [obj(tx, args.bank), pure(tx, args.amount, `u64`)],
  });
}

export function reserveArrayIndex(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::reserve_array_index`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function lendingMarket(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::lending_market`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export interface MigrateAsGlobalAdminArgs {
  self: TransactionObjectInput;
  admin: TransactionObjectInput;
}

export function migrateAsGlobalAdmin(
  tx: Transaction,
  typeArgs: [string, string],
  args: MigrateAsGlobalAdminArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::migrate_as_global_admin`,
    typeArguments: typeArgs,
    arguments: [obj(tx, args.self), obj(tx, args.admin)],
  });
}

export function fundsAvailable(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::funds_available`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function fundsDeployed(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::funds_deployed`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function assertUtilisation(
  tx: Transaction,
  typeArgs: [string, string],
  bank: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::assert_utilisation`,
    typeArguments: typeArgs,
    arguments: [obj(tx, bank)],
  });
}

export function createBankAndShare(
  tx: Transaction,
  typeArgs: [string, string],
  registry: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::create_bank_and_share`,
    typeArguments: typeArgs,
    arguments: [obj(tx, registry)],
  });
}

export interface CtokenAmount_Args {
  bank: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  amount: bigint | TransactionArgument;
}

export function ctokenAmount_(
  tx: Transaction,
  typeArgs: [string, string],
  args: CtokenAmount_Args
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::ctoken_amount_`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      obj(tx, args.lendingMarket),
      pure(tx, args.amount, `u64`),
    ],
  });
}

export interface DeployArgs {
  bank: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  amountToDeploy: bigint | TransactionArgument;
  clock: TransactionObjectInput;
}

export function deploy(
  tx: Transaction,
  typeArgs: [string, string],
  args: DeployArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::deploy`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      obj(tx, args.lendingMarket),
      pure(tx, args.amountToDeploy, `u64`),
      obj(tx, args.clock),
    ],
  });
}

export function effectiveUtilisationRate(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::effective_utilisation_rate`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function fundsDeployedUnchecked(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::funds_deployed_unchecked`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export interface InitLendingArgs {
  self: TransactionObjectInput;
  globalAdmin: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  targetUtilisationBps: number | TransactionArgument;
  utilisationBufferBps: number | TransactionArgument;
}

export function initLending(
  tx: Transaction,
  typeArgs: [string, string],
  args: InitLendingArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::init_lending`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.self),
      obj(tx, args.globalAdmin),
      obj(tx, args.lendingMarket),
      pure(tx, args.targetUtilisationBps, `u16`),
      pure(tx, args.utilisationBufferBps, `u16`),
    ],
  });
}

export function lending(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::lending`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export interface NeedsLendingActionArgs {
  bank: TransactionObjectInput;
  amount: bigint | TransactionArgument;
  isInput: boolean | TransactionArgument;
}

export function needsLendingAction(
  tx: Transaction,
  typeArgs: [string, string],
  args: NeedsLendingActionArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::needs_lending_action`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      pure(tx, args.amount, `u64`),
      pure(tx, args.isInput, `bool`),
    ],
  });
}

export interface NeedsLendingAction_Args {
  fundsAvailable: bigint | TransactionArgument;
  fundsDeployed: bigint | TransactionArgument;
  targetUtilisation: bigint | TransactionArgument;
  utilisationBuffer: bigint | TransactionArgument;
  amount: bigint | TransactionArgument;
  isInput: boolean | TransactionArgument;
}

export function needsLendingAction_(
  tx: Transaction,
  args: NeedsLendingAction_Args
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::needs_lending_action_`,
    arguments: [
      pure(tx, args.fundsAvailable, `u64`),
      pure(tx, args.fundsDeployed, `u64`),
      pure(tx, args.targetUtilisation, `u64`),
      pure(tx, args.utilisationBuffer, `u64`),
      pure(tx, args.amount, `u64`),
      pure(tx, args.isInput, `bool`),
    ],
  });
}

export function utilisationBuffer(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::utilisation_buffer`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export interface PrepareBankForPendingWithdraw_Args {
  bank: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  withdrawAmount: bigint | TransactionArgument;
  clock: TransactionObjectInput;
}

export function prepareBankForPendingWithdraw_(
  tx: Transaction,
  typeArgs: [string, string],
  args: PrepareBankForPendingWithdraw_Args
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::prepare_bank_for_pending_withdraw_`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      obj(tx, args.lendingMarket),
      pure(tx, args.withdrawAmount, `u64`),
      obj(tx, args.clock),
    ],
  });
}

export interface RebalanceArgs {
  bank: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  clock: TransactionObjectInput;
}

export function rebalance(
  tx: Transaction,
  typeArgs: [string, string],
  args: RebalanceArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::rebalance`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      obj(tx, args.lendingMarket),
      obj(tx, args.clock),
    ],
  });
}

export interface RecallArgs {
  bank: TransactionObjectInput;
  lendingMarket: TransactionObjectInput;
  amountToRecall: bigint | TransactionArgument;
  clock: TransactionObjectInput;
}

export function recall(
  tx: Transaction,
  typeArgs: [string, string],
  args: RecallArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::recall`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.bank),
      obj(tx, args.lendingMarket),
      pure(tx, args.amountToRecall, `u64`),
      obj(tx, args.clock),
    ],
  });
}

export interface SetUtilisationRateArgs {
  self: TransactionObjectInput;
  globalAdmin: TransactionObjectInput;
  targetUtilisationBps: number | TransactionArgument;
  utilisationBufferBps: number | TransactionArgument;
}

export function setUtilisationRate(
  tx: Transaction,
  typeArgs: [string, string],
  args: SetUtilisationRateArgs
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::set_utilisation_rate`,
    typeArguments: typeArgs,
    arguments: [
      obj(tx, args.self),
      obj(tx, args.globalAdmin),
      pure(tx, args.targetUtilisationBps, `u16`),
      pure(tx, args.utilisationBufferBps, `u16`),
    ],
  });
}

export function targetUtilisationRate(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::target_utilisation_rate`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function targetUtilisationRateUnchecked(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::target_utilisation_rate_unchecked`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function totalFunds(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::total_funds`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}

export function utilisationBufferUnchecked(
  tx: Transaction,
  typeArgs: [string, string],
  self: TransactionObjectInput
) {
  return tx.moveCall({
    target: `${PUBLISHED_AT}::bank::utilisation_buffer_unchecked`,
    typeArguments: typeArgs,
    arguments: [obj(tx, self)],
  });
}
