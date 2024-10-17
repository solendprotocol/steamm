// // Suppose you want to add a method to a third-party class "Transaction"

// import { SerializedBcs } from "@mysten/bcs";
// import {
//   Transaction,
//   TransactionArgument,
// } from "@mysten/sui/dist/cjs/transactions";

// declare module "@mysten/sui/dist/cjs/transactions" {
//   interface Transaction {
//     shareObject(
//       object: TransactionArgument | SerializedBcs<any>,
//       typeArgs: string[]
//     ): void;
//   }
// }

// Transaction.prototype.shareObject = function (
//   object: TransactionArgument | SerializedBcs<any>,
//   typeArgs: string[]
// ) {
//   this.moveCall({
//     target: `0x2::transfer::public_share_object`,
//     arguments: [object],
//     typeArguments: typeArgs,
//   });
// };
