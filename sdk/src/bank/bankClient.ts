import { SuiClient } from "@mysten/sui/client";
import { Transaction, TransactionArgument } from "@mysten/sui/transactions";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui/utils";
import {
  CTokenAmountArgs,
  InitLendingArgs,
  MigrateAsGlobalAdminArgs,
  SetUtilisationBpsArgs,
} from "./bankClientArgs";
import {
  Bank,
  BankFunctions,
  LendingMarket,
  phantom,
  PhantomReified,
  PhantomTypeArgument,
} from "..";

export abstract class BankClient<
  T extends PhantomTypeArgument,
  P extends PhantomTypeArgument
> {
  public client: SuiClient;
  public bank: Bank<P, T>;
  public lendingMarket: LendingMarket<P>;

  constructor(
    client: SuiClient,
    bank: Bank<P, T>,
    lendingMarket: LendingMarket<P>
  ) {
    this.client = client;
    this.bank = bank;
    this.lendingMarket = lendingMarket;
  }

  protected static async fetchState<
    T extends PhantomTypeArgument,
    P extends PhantomTypeArgument
  >(
    coinType: T,
    lendingMarketType: P,
    bankId: string,
    lendingMarketId: string,
    client: SuiClient
  ): Promise<[Bank<P, T>, LendingMarket<P>]> {
    const bankTypeArgs: [PhantomReified<P>, PhantomReified<T>] = [
      phantom(lendingMarketType),
      phantom(coinType),
    ];

    const bank = await Bank.fetch(client, bankTypeArgs, bankId);

    const lendingMarket = await LendingMarket.fetch(
      client,
      phantom(lendingMarketType),
      lendingMarketId
    );

    return [bank, lendingMarket];
  }

  public initLending(
    args: InitLendingArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      bank: tx.object(this.bank.id),
      globalAdmin: args.globalAdmin,
      lendingMarket: tx.object(this.lendingMarket.id),
      targetUtilisationBps: args.targetUtilisationBps,
      utilisationBufferBps: args.utilisationBufferBps,
    };

    BankFunctions.initLending(tx, this.typeArgs(), callArgs);
  }

  public rebalance(tx: Transaction = new Transaction()) {
    const callArgs = {
      bank: tx.object(this.bank.id),
      lendingMarket: tx.object(this.lendingMarket.id),
      clock: tx.object(SUI_CLOCK_OBJECT_ID),
    };

    BankFunctions.rebalance(tx, this.typeArgs(), callArgs);
  }

  public cTokenAmount(
    args: CTokenAmountArgs,
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    const callArgs = {
      bank: tx.object(this.bank.id),
      lendingMarket: tx.object(this.lendingMarket.id),
      amount: args.amount,
    };

    return BankFunctions.ctokenAmount(tx, this.typeArgs(), callArgs);
  }

  public setUtilisationBps(
    args: SetUtilisationBpsArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      bank: tx.object(this.bank.id),
      globalAdmin: args.globalAdmin,
      targetUtilisationBps: args.targetUtilisationBps,
      utilisationBufferBps: args.utilisationBufferBps,
    };

    BankFunctions.setUtilisationBps(tx, this.typeArgs(), callArgs);
  }

  public migrateAsGlobalAdmin(
    args: MigrateAsGlobalAdminArgs,
    tx: Transaction = new Transaction()
  ) {
    const callArgs = {
      bank: tx.object(this.bank.id),
      admin: args.admin,
    };

    BankFunctions.migrateAsGlobalAdmin(tx, this.typeArgs(), callArgs);
  }

  // Getters

  public viewLending(tx: Transaction = new Transaction()): TransactionArgument {
    return BankFunctions.lending(tx, this.typeArgs(), tx.object(this.bank.id));
  }

  public viewTotalFunds(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.totalFunds(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewEffectiveUtilisationBps(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.effectiveUtilisationBps(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewFundsDeployed(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.fundsDeployed(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewFundsAvailable(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.fundsAvailable(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewTargetUtilisationBps(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.targetUtilisationBps(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewUtilisationBufferBps(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.utilisationBufferBps(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewFundsDeployedUnchecked(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.fundsDeployedUnchecked(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewTargetUtilisationBpsUnchecked(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.targetUtilisationBpsUnchecked(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewUtilisationBufferBpsUnchecked(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.utilisationBufferBpsUnchecked(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }

  public viewReserveArrayIndex(
    tx: Transaction = new Transaction()
  ): TransactionArgument {
    return BankFunctions.reserveArrayIndex(
      tx,
      this.typeArgs(),
      tx.object(this.bank.id)
    );
  }
  public typeArgs(): [string, string] {
    const [lendingMarketType, cointType] = this.bank.$typeArgs;
    return [`${lendingMarketType}`, `${cointType}`];
  }

  public static createBank(
    pType: string,
    tType: string,
    registryID: string,
    tx: Transaction = new Transaction()
  ) {
    const registry = tx.object(registryID);

    BankFunctions.createBankAndShare(tx, [pType, tType], registry);
  }
}
