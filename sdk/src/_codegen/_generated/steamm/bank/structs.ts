import * as reified from "../../_framework/reified";
import {Option} from "../../_dependencies/source/0x1/option/structs";
import {Balance, Supply} from "../../_dependencies/source/0x2/balance/structs";
import {UID} from "../../_dependencies/source/0x2/object/structs";
import {ObligationOwnerCap} from "../../_dependencies/source/0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf/lending-market/structs";
import {PhantomReified, PhantomToTypeStr, PhantomTypeArgument, Reified, StructClass, ToField, ToPhantomTypeArgument, ToTypeStr, assertFieldsWithTypesArgsMatch, assertReifiedTypeArgsMatch, decodeFromFields, decodeFromFieldsWithTypes, decodeFromJSONField, extractType, fieldToJSON, phantom, ToTypeStr as ToPhantom} from "../../_framework/reified";
import {FieldsWithTypes, composeSuiType, compressSuiType, parseTypeName} from "../../_framework/util";
import {PKG_V1} from "../index";
import {Version} from "../version/structs";
import {bcs} from "@mysten/sui/bcs";
import {SuiClient, SuiObjectData, SuiParsedData} from "@mysten/sui/client";
import {fromB64} from "@mysten/sui/utils";

/* ============================== BToken =============================== */

export function isBToken(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::bank::BToken` + '<'); }

export interface BTokenFields<P extends PhantomTypeArgument, T extends PhantomTypeArgument> { dummyField: ToField<"bool"> }

export type BTokenReified<P extends PhantomTypeArgument, T extends PhantomTypeArgument> = Reified< BToken<P, T>, BTokenFields<P, T> >;

export class BToken<P extends PhantomTypeArgument, T extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::bank::BToken`; static readonly $numTypeParams = 2; static readonly $isPhantom = [true,true,] as const;

 readonly $typeName = BToken.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::bank::BToken<${PhantomToTypeStr<P>}, ${PhantomToTypeStr<T>}>`; readonly $typeArgs: [PhantomToTypeStr<P>, PhantomToTypeStr<T>]; readonly $isPhantom = BToken.$isPhantom;

 readonly dummyField: ToField<"bool">

 private constructor(typeArgs: [PhantomToTypeStr<P>, PhantomToTypeStr<T>], fields: BTokenFields<P, T>, ) { this.$fullTypeName = composeSuiType( BToken.$typeName, ...typeArgs ) as `${typeof PKG_V1}::bank::BToken<${PhantomToTypeStr<P>}, ${PhantomToTypeStr<T>}>`; this.$typeArgs = typeArgs;

 this.dummyField = fields.dummyField; }

 static reified<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( P: P, T: T ): BTokenReified<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return { typeName: BToken.$typeName, fullTypeName: composeSuiType( BToken.$typeName, ...[extractType(P), extractType(T)] ) as `${typeof PKG_V1}::bank::BToken<${PhantomToTypeStr<ToPhantomTypeArgument<P>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<T>>}>`, typeArgs: [ extractType(P), extractType(T) ] as [PhantomToTypeStr<ToPhantomTypeArgument<P>>, PhantomToTypeStr<ToPhantomTypeArgument<T>>], isPhantom: BToken.$isPhantom, reifiedTypeArgs: [P, T], fromFields: (fields: Record<string, any>) => BToken.fromFields( [P, T], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => BToken.fromFieldsWithTypes( [P, T], item, ), fromBcs: (data: Uint8Array) => BToken.fromBcs( [P, T], data, ), bcs: BToken.bcs, fromJSONField: (field: any) => BToken.fromJSONField( [P, T], field, ), fromJSON: (json: Record<string, any>) => BToken.fromJSON( [P, T], json, ), fromSuiParsedData: (content: SuiParsedData) => BToken.fromSuiParsedData( [P, T], content, ), fromSuiObjectData: (content: SuiObjectData) => BToken.fromSuiObjectData( [P, T], content, ), fetch: async (client: SuiClient, id: string) => BToken.fetch( client, [P, T], id, ), new: ( fields: BTokenFields<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>>, ) => { return new BToken( [extractType(P), extractType(T)], fields ) }, kind: "StructClassReified", } }

 static get r() { return BToken.reified }

 static phantom<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( P: P, T: T ): PhantomReified<ToTypeStr<BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>>>> { return phantom(BToken.reified( P, T )); } static get p() { return BToken.phantom }

 static get bcs() { return bcs.struct("BToken", {

 dummy_field: bcs.bool()

}) };

 static fromFields<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], fields: Record<string, any> ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return BToken.reified( typeArgs[0], typeArgs[1], ).new( { dummyField: decodeFromFields("bool", fields.dummy_field) } ) }

 static fromFieldsWithTypes<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], item: FieldsWithTypes ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (!isBToken(item.type)) { throw new Error("not a BToken type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return BToken.reified( typeArgs[0], typeArgs[1], ).new( { dummyField: decodeFromFieldsWithTypes("bool", item.fields.dummy_field) } ) }

 static fromBcs<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], data: Uint8Array ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return BToken.fromFields( typeArgs, BToken.bcs.parse(data) ) }

 toJSONField() { return {

 dummyField: this.dummyField,

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], field: any ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return BToken.reified( typeArgs[0], typeArgs[1], ).new( { dummyField: decodeFromJSONField("bool", field.dummyField) } ) }

 static fromJSON<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], json: Record<string, any> ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (json.$typeName !== BToken.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(BToken.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return BToken.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], content: SuiParsedData ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isBToken(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a BToken object`); } return BToken.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], data: SuiObjectData ): BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isBToken(data.bcs.type)) { throw new Error(`object at is not a BToken object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 2) { throw new Error(`type argument mismatch: expected 2 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 2; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return BToken.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return BToken.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [P, T], id: string ): Promise<BToken<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching BToken object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isBToken(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a BToken object`); }

 return BToken.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== Bank =============================== */

export function isBank(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::bank::Bank` + '<'); }

export interface BankFields<P extends PhantomTypeArgument, T extends PhantomTypeArgument> { id: ToField<UID>; fundsAvailable: ToField<Balance<T>>; lending: ToField<Option<Lending<P>>>; minTokenBlockSize: ToField<"u64">; btokenSupply: ToField<Supply<ToPhantom<BToken<P, T>>>>; version: ToField<Version> }

export type BankReified<P extends PhantomTypeArgument, T extends PhantomTypeArgument> = Reified< Bank<P, T>, BankFields<P, T> >;

export class Bank<P extends PhantomTypeArgument, T extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::bank::Bank`; static readonly $numTypeParams = 2; static readonly $isPhantom = [true,true,] as const;

 readonly $typeName = Bank.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::bank::Bank<${PhantomToTypeStr<P>}, ${PhantomToTypeStr<T>}>`; readonly $typeArgs: [PhantomToTypeStr<P>, PhantomToTypeStr<T>]; readonly $isPhantom = Bank.$isPhantom;

 readonly id: ToField<UID>; readonly fundsAvailable: ToField<Balance<T>>; readonly lending: ToField<Option<Lending<P>>>; readonly minTokenBlockSize: ToField<"u64">; readonly btokenSupply: ToField<Supply<ToPhantom<BToken<P, T>>>>; readonly version: ToField<Version>

 private constructor(typeArgs: [PhantomToTypeStr<P>, PhantomToTypeStr<T>], fields: BankFields<P, T>, ) { this.$fullTypeName = composeSuiType( Bank.$typeName, ...typeArgs ) as `${typeof PKG_V1}::bank::Bank<${PhantomToTypeStr<P>}, ${PhantomToTypeStr<T>}>`; this.$typeArgs = typeArgs;

 this.id = fields.id;; this.fundsAvailable = fields.fundsAvailable;; this.lending = fields.lending;; this.minTokenBlockSize = fields.minTokenBlockSize;; this.btokenSupply = fields.btokenSupply;; this.version = fields.version; }

 static reified<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( P: P, T: T ): BankReified<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return { typeName: Bank.$typeName, fullTypeName: composeSuiType( Bank.$typeName, ...[extractType(P), extractType(T)] ) as `${typeof PKG_V1}::bank::Bank<${PhantomToTypeStr<ToPhantomTypeArgument<P>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<T>>}>`, typeArgs: [ extractType(P), extractType(T) ] as [PhantomToTypeStr<ToPhantomTypeArgument<P>>, PhantomToTypeStr<ToPhantomTypeArgument<T>>], isPhantom: Bank.$isPhantom, reifiedTypeArgs: [P, T], fromFields: (fields: Record<string, any>) => Bank.fromFields( [P, T], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => Bank.fromFieldsWithTypes( [P, T], item, ), fromBcs: (data: Uint8Array) => Bank.fromBcs( [P, T], data, ), bcs: Bank.bcs, fromJSONField: (field: any) => Bank.fromJSONField( [P, T], field, ), fromJSON: (json: Record<string, any>) => Bank.fromJSON( [P, T], json, ), fromSuiParsedData: (content: SuiParsedData) => Bank.fromSuiParsedData( [P, T], content, ), fromSuiObjectData: (content: SuiObjectData) => Bank.fromSuiObjectData( [P, T], content, ), fetch: async (client: SuiClient, id: string) => Bank.fetch( client, [P, T], id, ), new: ( fields: BankFields<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>>, ) => { return new Bank( [extractType(P), extractType(T)], fields ) }, kind: "StructClassReified", } }

 static get r() { return Bank.reified }

 static phantom<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( P: P, T: T ): PhantomReified<ToTypeStr<Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>>>> { return phantom(Bank.reified( P, T )); } static get p() { return Bank.phantom }

 static get bcs() { return bcs.struct("Bank", {

 id: UID.bcs, funds_available: Balance.bcs, lending: Option.bcs(Lending.bcs), min_token_block_size: bcs.u64(), btoken_supply: Supply.bcs, version: Version.bcs

}) };

 static fromFields<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], fields: Record<string, any> ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return Bank.reified( typeArgs[0], typeArgs[1], ).new( { id: decodeFromFields(UID.reified(), fields.id), fundsAvailable: decodeFromFields(Balance.reified(typeArgs[1]), fields.funds_available), lending: decodeFromFields(Option.reified(Lending.reified(typeArgs[0])), fields.lending), minTokenBlockSize: decodeFromFields("u64", fields.min_token_block_size), btokenSupply: decodeFromFields(Supply.reified(reified.phantom(BToken.reified(typeArgs[0], typeArgs[1]))), fields.btoken_supply), version: decodeFromFields(Version.reified(), fields.version) } ) }

 static fromFieldsWithTypes<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], item: FieldsWithTypes ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (!isBank(item.type)) { throw new Error("not a Bank type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return Bank.reified( typeArgs[0], typeArgs[1], ).new( { id: decodeFromFieldsWithTypes(UID.reified(), item.fields.id), fundsAvailable: decodeFromFieldsWithTypes(Balance.reified(typeArgs[1]), item.fields.funds_available), lending: decodeFromFieldsWithTypes(Option.reified(Lending.reified(typeArgs[0])), item.fields.lending), minTokenBlockSize: decodeFromFieldsWithTypes("u64", item.fields.min_token_block_size), btokenSupply: decodeFromFieldsWithTypes(Supply.reified(reified.phantom(BToken.reified(typeArgs[0], typeArgs[1]))), item.fields.btoken_supply), version: decodeFromFieldsWithTypes(Version.reified(), item.fields.version) } ) }

 static fromBcs<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], data: Uint8Array ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return Bank.fromFields( typeArgs, Bank.bcs.parse(data) ) }

 toJSONField() { return {

 id: this.id,fundsAvailable: this.fundsAvailable.toJSONField(),lending: fieldToJSON<Option<Lending<P>>>(`${Option.$typeName}<${Lending.$typeName}<${this.$typeArgs[0]}>>`, this.lending),minTokenBlockSize: this.minTokenBlockSize.toString(),btokenSupply: this.btokenSupply.toJSONField(),version: this.version.toJSONField(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], field: any ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { return Bank.reified( typeArgs[0], typeArgs[1], ).new( { id: decodeFromJSONField(UID.reified(), field.id), fundsAvailable: decodeFromJSONField(Balance.reified(typeArgs[1]), field.fundsAvailable), lending: decodeFromJSONField(Option.reified(Lending.reified(typeArgs[0])), field.lending), minTokenBlockSize: decodeFromJSONField("u64", field.minTokenBlockSize), btokenSupply: decodeFromJSONField(Supply.reified(reified.phantom(BToken.reified(typeArgs[0], typeArgs[1]))), field.btokenSupply), version: decodeFromJSONField(Version.reified(), field.version) } ) }

 static fromJSON<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], json: Record<string, any> ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (json.$typeName !== Bank.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(Bank.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return Bank.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], content: SuiParsedData ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isBank(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a Bank object`); } return Bank.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( typeArgs: [P, T], data: SuiObjectData ): Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isBank(data.bcs.type)) { throw new Error(`object at is not a Bank object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 2) { throw new Error(`type argument mismatch: expected 2 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 2; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return Bank.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return Bank.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<P extends PhantomReified<PhantomTypeArgument>, T extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [P, T], id: string ): Promise<Bank<ToPhantomTypeArgument<P>, ToPhantomTypeArgument<T>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching Bank object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isBank(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a Bank object`); }

 return Bank.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== Lending =============================== */

export function isLending(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::bank::Lending` + '<'); }

export interface LendingFields<P extends PhantomTypeArgument> { ctokens: ToField<"u64">; targetUtilisationBps: ToField<"u16">; utilisationBufferBps: ToField<"u16">; reserveArrayIndex: ToField<"u64">; obligationCap: ToField<ObligationOwnerCap<P>> }

export type LendingReified<P extends PhantomTypeArgument> = Reified< Lending<P>, LendingFields<P> >;

export class Lending<P extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::bank::Lending`; static readonly $numTypeParams = 1; static readonly $isPhantom = [true,] as const;

 readonly $typeName = Lending.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::bank::Lending<${PhantomToTypeStr<P>}>`; readonly $typeArgs: [PhantomToTypeStr<P>]; readonly $isPhantom = Lending.$isPhantom;

 readonly ctokens: ToField<"u64">; readonly targetUtilisationBps: ToField<"u16">; readonly utilisationBufferBps: ToField<"u16">; readonly reserveArrayIndex: ToField<"u64">; readonly obligationCap: ToField<ObligationOwnerCap<P>>

 private constructor(typeArgs: [PhantomToTypeStr<P>], fields: LendingFields<P>, ) { this.$fullTypeName = composeSuiType( Lending.$typeName, ...typeArgs ) as `${typeof PKG_V1}::bank::Lending<${PhantomToTypeStr<P>}>`; this.$typeArgs = typeArgs;

 this.ctokens = fields.ctokens;; this.targetUtilisationBps = fields.targetUtilisationBps;; this.utilisationBufferBps = fields.utilisationBufferBps;; this.reserveArrayIndex = fields.reserveArrayIndex;; this.obligationCap = fields.obligationCap; }

 static reified<P extends PhantomReified<PhantomTypeArgument>>( P: P ): LendingReified<ToPhantomTypeArgument<P>> { return { typeName: Lending.$typeName, fullTypeName: composeSuiType( Lending.$typeName, ...[extractType(P)] ) as `${typeof PKG_V1}::bank::Lending<${PhantomToTypeStr<ToPhantomTypeArgument<P>>}>`, typeArgs: [ extractType(P) ] as [PhantomToTypeStr<ToPhantomTypeArgument<P>>], isPhantom: Lending.$isPhantom, reifiedTypeArgs: [P], fromFields: (fields: Record<string, any>) => Lending.fromFields( P, fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => Lending.fromFieldsWithTypes( P, item, ), fromBcs: (data: Uint8Array) => Lending.fromBcs( P, data, ), bcs: Lending.bcs, fromJSONField: (field: any) => Lending.fromJSONField( P, field, ), fromJSON: (json: Record<string, any>) => Lending.fromJSON( P, json, ), fromSuiParsedData: (content: SuiParsedData) => Lending.fromSuiParsedData( P, content, ), fromSuiObjectData: (content: SuiObjectData) => Lending.fromSuiObjectData( P, content, ), fetch: async (client: SuiClient, id: string) => Lending.fetch( client, P, id, ), new: ( fields: LendingFields<ToPhantomTypeArgument<P>>, ) => { return new Lending( [extractType(P)], fields ) }, kind: "StructClassReified", } }

 static get r() { return Lending.reified }

 static phantom<P extends PhantomReified<PhantomTypeArgument>>( P: P ): PhantomReified<ToTypeStr<Lending<ToPhantomTypeArgument<P>>>> { return phantom(Lending.reified( P )); } static get p() { return Lending.phantom }

 static get bcs() { return bcs.struct("Lending", {

 ctokens: bcs.u64(), target_utilisation_bps: bcs.u16(), utilisation_buffer_bps: bcs.u16(), reserve_array_index: bcs.u64(), obligation_cap: ObligationOwnerCap.bcs

}) };

 static fromFields<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, fields: Record<string, any> ): Lending<ToPhantomTypeArgument<P>> { return Lending.reified( typeArg, ).new( { ctokens: decodeFromFields("u64", fields.ctokens), targetUtilisationBps: decodeFromFields("u16", fields.target_utilisation_bps), utilisationBufferBps: decodeFromFields("u16", fields.utilisation_buffer_bps), reserveArrayIndex: decodeFromFields("u64", fields.reserve_array_index), obligationCap: decodeFromFields(ObligationOwnerCap.reified(typeArg), fields.obligation_cap) } ) }

 static fromFieldsWithTypes<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, item: FieldsWithTypes ): Lending<ToPhantomTypeArgument<P>> { if (!isLending(item.type)) { throw new Error("not a Lending type");

 } assertFieldsWithTypesArgsMatch(item, [typeArg]);

 return Lending.reified( typeArg, ).new( { ctokens: decodeFromFieldsWithTypes("u64", item.fields.ctokens), targetUtilisationBps: decodeFromFieldsWithTypes("u16", item.fields.target_utilisation_bps), utilisationBufferBps: decodeFromFieldsWithTypes("u16", item.fields.utilisation_buffer_bps), reserveArrayIndex: decodeFromFieldsWithTypes("u64", item.fields.reserve_array_index), obligationCap: decodeFromFieldsWithTypes(ObligationOwnerCap.reified(typeArg), item.fields.obligation_cap) } ) }

 static fromBcs<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, data: Uint8Array ): Lending<ToPhantomTypeArgument<P>> { return Lending.fromFields( typeArg, Lending.bcs.parse(data) ) }

 toJSONField() { return {

 ctokens: this.ctokens.toString(),targetUtilisationBps: this.targetUtilisationBps,utilisationBufferBps: this.utilisationBufferBps,reserveArrayIndex: this.reserveArrayIndex.toString(),obligationCap: this.obligationCap.toJSONField(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, field: any ): Lending<ToPhantomTypeArgument<P>> { return Lending.reified( typeArg, ).new( { ctokens: decodeFromJSONField("u64", field.ctokens), targetUtilisationBps: decodeFromJSONField("u16", field.targetUtilisationBps), utilisationBufferBps: decodeFromJSONField("u16", field.utilisationBufferBps), reserveArrayIndex: decodeFromJSONField("u64", field.reserveArrayIndex), obligationCap: decodeFromJSONField(ObligationOwnerCap.reified(typeArg), field.obligationCap) } ) }

 static fromJSON<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, json: Record<string, any> ): Lending<ToPhantomTypeArgument<P>> { if (json.$typeName !== Lending.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(Lending.$typeName, extractType(typeArg)), json.$typeArgs, [typeArg], )

 return Lending.fromJSONField( typeArg, json, ) }

 static fromSuiParsedData<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, content: SuiParsedData ): Lending<ToPhantomTypeArgument<P>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isLending(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a Lending object`); } return Lending.fromFieldsWithTypes( typeArg, content ); }

 static fromSuiObjectData<P extends PhantomReified<PhantomTypeArgument>>( typeArg: P, data: SuiObjectData ): Lending<ToPhantomTypeArgument<P>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isLending(data.bcs.type)) { throw new Error(`object at is not a Lending object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 1) { throw new Error(`type argument mismatch: expected 1 type argument but got '${gotTypeArgs.length}'`); }; const gotTypeArg = compressSuiType(gotTypeArgs[0]); const expectedTypeArg = compressSuiType(extractType(typeArg)); if (gotTypeArg !== compressSuiType(extractType(typeArg))) { throw new Error(`type argument mismatch: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); };

 return Lending.fromBcs( typeArg, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return Lending.fromSuiParsedData( typeArg, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<P extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArg: P, id: string ): Promise<Lending<ToPhantomTypeArgument<P>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching Lending object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isLending(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a Lending object`); }

 return Lending.fromSuiObjectData( typeArg, res.data ); }

 }
