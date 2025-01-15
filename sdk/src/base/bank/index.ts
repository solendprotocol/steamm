import {
  Transaction,
  TransactionArgument,
  TransactionResult,
} from "@mysten/sui/transactions";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui/utils";
import {
  BurnBTokensArgs,
  CTokenAmountArgs,
  InitLendingArgs,
  MigrateBankArgs,
  MintBTokensArgs,
  SetUtilisationBpsArgs,
} from "./bankArgs";
import { BankFunctions } from "../..";
import { BankInfo } from "../../types";

export * from "./bankArgs";
export * from "./bankMath";

export class Bank {
  public packageId: string;
  public bankInfo: BankInfo;

  constructor(packageId: string, bankInfo: BankInfo) {
    this.bankInfo = bankInfo;
    this.packageId = packageId;
  }

  public mintBTokens(
    args: MintBTokensArgs,
    tx: Transaction = new Transaction()
  ): TransactionResult {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      coins: args.coins,
      coinAmount: args.coinAmount,
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    const coinA = BankFunctions.mintBtokens(tx, this.typeArgs(), callArgs);
    return coinA;
  }

  public burnBTokens(
    args: BurnBTokensArgs,
    tx: Transaction = new Transaction()
  ): TransactionResult {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      btokens: args.btokens,
      btokenAmount: args.btokenAmount,
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    const coinA = BankFunctions.burnBtokens(tx, this.typeArgs(), callArgs);
    return coinA;
  }

  public initLending(
    args: InitLendingArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      globalAdmin: args.globalAdmin,
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      targetUtilisationBps: args.targetUtilisationBps,
      utilisationBufferBps: args.utilisationBufferBps,
    };

    BankFunctions.initLending(tx, this.typeArgs(), callArgs);
  }

  public rebalance(tx: Transaction = new Transaction()) {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    BankFunctions.rebalance(tx, this.typeArgs(), callArgs);
  }

  public cTokenAmount(
    args: CTokenAmountArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      amount: args.amount,
    };

    return BankFunctions.ctokenAmount(tx, this.typeArgs(), callArgs);
  }

  public setUtilisationBps(
    args: SetUtilisationBpsArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      globalAdmin: args.globalAdmin,
      targetUtilisationBps: args.targetUtilisationBps,
      utilisationBufferBps: args.utilisationBufferBps,
    };

    BankFunctions.setUtilisationBps(tx, this.typeArgs(), callArgs);
  }

  public migrate(args: MigrateBankArgs, tx: Transaction = new Transaction()) {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      admin: args.admin,
    };

    BankFunctions.migrate(tx, this.typeArgs(), callArgs);
  }

  // Client-side logic

  public needsRebalance(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    return BankFunctions.needsRebalance(tx, this.typeArgs(), callArgs);
  }

  // Getters

  public viewLending(tx: Transaction = new Transaction()): TransactionArgument {
    return BankFunctions.lending(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }

  public viewTotalFunds(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      bank: tx.object(this.bankInfo.bankId),
      lendingMarket: tx.object(this.bankInfo.lendingMarketId),
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    return BankFunctions.totalFunds(tx, this.typeArgs(), callArgs);
  }

  public viewFundsAvailable(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.fundsAvailable(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }

  public viewTargetUtilisationBps(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.targetUtilisationBps(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }

  public viewUtilisationBufferBps(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.utilisationBufferBps(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }

  public viewTargetUtilisationBpsUnchecked(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.targetUtilisationBpsUnchecked(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }

  public viewUtilisationBufferBpsUnchecked(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.utilisationBufferBpsUnchecked(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }

  public viewReserveArrayIndex(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.reserveArrayIndex(
      tx,
      this.typeArgs(),
      tx.object(this.bankInfo.bankId)
    );
  }
  public typeArgs(): [string, string, string] {
    return [
      this.bankInfo.lendingMarketType,
      this.bankInfo.coinType,
      this.bankInfo.btokenType,
    ];
  }
}

// public createBank(
//   pType: string,
//   tType: string,
//   registryID: string,
//   tx: Transaction = new Transaction()
// ) {
//   const registry = tx.object(registryID);

//   BankFunctions.createBankAndShare(tx, [pType, tType], registry);
// }
