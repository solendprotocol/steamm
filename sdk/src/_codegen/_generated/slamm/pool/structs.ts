import * as reified from "../../_framework/reified";
import {Supply} from "../../_dependencies/source/0x2/balance/structs";
import {ID, UID} from "../../_dependencies/source/0x2/object/structs";
import {PhantomReified, PhantomToTypeStr, PhantomTypeArgument, Reified, StructClass, ToField, ToPhantomTypeArgument, ToTypeArgument, ToTypeStr, TypeArgument, assertFieldsWithTypesArgsMatch, assertReifiedTypeArgsMatch, decodeFromFields, decodeFromFieldsWithTypes, decodeFromJSONField, extractType, fieldToJSON, phantom, toBcs, ToTypeStr as ToPhantom} from "../../_framework/reified";
import {FieldsWithTypes, composeSuiType, compressSuiType, parseTypeName} from "../../_framework/util";
import {FeeConfig, Fees} from "../fees/structs";
import {PKG_V1} from "../index";
import {SwapFee, SwapQuote} from "../quote/structs";
import {Version} from "../version/structs";
import {BcsType, bcs} from "@mysten/sui/bcs";
import {SuiClient, SuiObjectData, SuiParsedData} from "@mysten/sui/client";
import {fromB64, fromHEX, toHEX} from "@mysten/sui/utils";

/* ============================== DepositResult =============================== */

export function isDepositResult(type: string): boolean { type = compressSuiType(type); return type === `${PKG_V1}::pool::DepositResult`; }

export interface DepositResultFields { user: ToField<"address">; poolId: ToField<ID>; depositA: ToField<"u64">; depositB: ToField<"u64">; mintLp: ToField<"u64"> }

export type DepositResultReified = Reified< DepositResult, DepositResultFields >;

export class DepositResult implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::DepositResult`; static readonly $numTypeParams = 0; static readonly $isPhantom = [] as const;

 readonly $typeName = DepositResult.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::DepositResult`; readonly $typeArgs: []; readonly $isPhantom = DepositResult.$isPhantom;

 readonly user: ToField<"address">; readonly poolId: ToField<ID>; readonly depositA: ToField<"u64">; readonly depositB: ToField<"u64">; readonly mintLp: ToField<"u64">

 private constructor(typeArgs: [], fields: DepositResultFields, ) { this.$fullTypeName = composeSuiType( DepositResult.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::DepositResult`; this.$typeArgs = typeArgs;

 this.user = fields.user;; this.poolId = fields.poolId;; this.depositA = fields.depositA;; this.depositB = fields.depositB;; this.mintLp = fields.mintLp; }

 static reified( ): DepositResultReified { return { typeName: DepositResult.$typeName, fullTypeName: composeSuiType( DepositResult.$typeName, ...[] ) as `${typeof PKG_V1}::pool::DepositResult`, typeArgs: [ ] as [], isPhantom: DepositResult.$isPhantom, reifiedTypeArgs: [], fromFields: (fields: Record<string, any>) => DepositResult.fromFields( fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => DepositResult.fromFieldsWithTypes( item, ), fromBcs: (data: Uint8Array) => DepositResult.fromBcs( data, ), bcs: DepositResult.bcs, fromJSONField: (field: any) => DepositResult.fromJSONField( field, ), fromJSON: (json: Record<string, any>) => DepositResult.fromJSON( json, ), fromSuiParsedData: (content: SuiParsedData) => DepositResult.fromSuiParsedData( content, ), fromSuiObjectData: (content: SuiObjectData) => DepositResult.fromSuiObjectData( content, ), fetch: async (client: SuiClient, id: string) => DepositResult.fetch( client, id, ), new: ( fields: DepositResultFields, ) => { return new DepositResult( [], fields ) }, kind: "StructClassReified", } }

 static get r() { return DepositResult.reified() }

 static phantom( ): PhantomReified<ToTypeStr<DepositResult>> { return phantom(DepositResult.reified( )); } static get p() { return DepositResult.phantom() }

 static get bcs() { return bcs.struct("DepositResult", {

 user: bcs.bytes(32).transform({ input: (val: string) => fromHEX(val), output: (val: Uint8Array) => toHEX(val), }), pool_id: ID.bcs, deposit_a: bcs.u64(), deposit_b: bcs.u64(), mint_lp: bcs.u64()

}) };

 static fromFields( fields: Record<string, any> ): DepositResult { return DepositResult.reified( ).new( { user: decodeFromFields("address", fields.user), poolId: decodeFromFields(ID.reified(), fields.pool_id), depositA: decodeFromFields("u64", fields.deposit_a), depositB: decodeFromFields("u64", fields.deposit_b), mintLp: decodeFromFields("u64", fields.mint_lp) } ) }

 static fromFieldsWithTypes( item: FieldsWithTypes ): DepositResult { if (!isDepositResult(item.type)) { throw new Error("not a DepositResult type");

 }

 return DepositResult.reified( ).new( { user: decodeFromFieldsWithTypes("address", item.fields.user), poolId: decodeFromFieldsWithTypes(ID.reified(), item.fields.pool_id), depositA: decodeFromFieldsWithTypes("u64", item.fields.deposit_a), depositB: decodeFromFieldsWithTypes("u64", item.fields.deposit_b), mintLp: decodeFromFieldsWithTypes("u64", item.fields.mint_lp) } ) }

 static fromBcs( data: Uint8Array ): DepositResult { return DepositResult.fromFields( DepositResult.bcs.parse(data) ) }

 toJSONField() { return {

 user: this.user,poolId: this.poolId,depositA: this.depositA.toString(),depositB: this.depositB.toString(),mintLp: this.mintLp.toString(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField( field: any ): DepositResult { return DepositResult.reified( ).new( { user: decodeFromJSONField("address", field.user), poolId: decodeFromJSONField(ID.reified(), field.poolId), depositA: decodeFromJSONField("u64", field.depositA), depositB: decodeFromJSONField("u64", field.depositB), mintLp: decodeFromJSONField("u64", field.mintLp) } ) }

 static fromJSON( json: Record<string, any> ): DepositResult { if (json.$typeName !== DepositResult.$typeName) { throw new Error("not a WithTwoGenerics json object") };

 return DepositResult.fromJSONField( json, ) }

 static fromSuiParsedData( content: SuiParsedData ): DepositResult { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isDepositResult(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a DepositResult object`); } return DepositResult.fromFieldsWithTypes( content ); }

 static fromSuiObjectData( data: SuiObjectData ): DepositResult { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isDepositResult(data.bcs.type)) { throw new Error(`object at is not a DepositResult object`); }

 return DepositResult.fromBcs( fromB64(data.bcs.bcsBytes) ); } if (data.content) { return DepositResult.fromSuiParsedData( data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch( client: SuiClient, id: string ): Promise<DepositResult> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching DepositResult object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isDepositResult(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a DepositResult object`); }

 return DepositResult.fromSuiObjectData( res.data ); }

 }

/* ============================== Intent =============================== */

export function isIntent(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::pool::Intent` + '<'); }

export interface IntentFields<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends PhantomTypeArgument> { quote: ToField<SwapQuote> }

export type IntentReified<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends PhantomTypeArgument> = Reified< Intent<A, B, Hook, State>, IntentFields<A, B, Hook, State> >;

export class Intent<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::Intent`; static readonly $numTypeParams = 4; static readonly $isPhantom = [true,true,true,true,] as const;

 readonly $typeName = Intent.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::Intent<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}, ${PhantomToTypeStr<State>}>`; readonly $typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>, PhantomToTypeStr<State>]; readonly $isPhantom = Intent.$isPhantom;

 readonly quote: ToField<SwapQuote>

 private constructor(typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>, PhantomToTypeStr<State>], fields: IntentFields<A, B, Hook, State>, ) { this.$fullTypeName = composeSuiType( Intent.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::Intent<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}, ${PhantomToTypeStr<State>}>`; this.$typeArgs = typeArgs;

 this.quote = fields.quote; }

 static reified<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( A: A, B: B, Hook: Hook, State: State ): IntentReified<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return { typeName: Intent.$typeName, fullTypeName: composeSuiType( Intent.$typeName, ...[extractType(A), extractType(B), extractType(Hook), extractType(State)] ) as `${typeof PKG_V1}::pool::Intent<${PhantomToTypeStr<ToPhantomTypeArgument<A>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<B>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Hook>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<State>>}>`, typeArgs: [ extractType(A), extractType(B), extractType(Hook), extractType(State) ] as [PhantomToTypeStr<ToPhantomTypeArgument<A>>, PhantomToTypeStr<ToPhantomTypeArgument<B>>, PhantomToTypeStr<ToPhantomTypeArgument<Hook>>, PhantomToTypeStr<ToPhantomTypeArgument<State>>], isPhantom: Intent.$isPhantom, reifiedTypeArgs: [A, B, Hook, State], fromFields: (fields: Record<string, any>) => Intent.fromFields( [A, B, Hook, State], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => Intent.fromFieldsWithTypes( [A, B, Hook, State], item, ), fromBcs: (data: Uint8Array) => Intent.fromBcs( [A, B, Hook, State], data, ), bcs: Intent.bcs, fromJSONField: (field: any) => Intent.fromJSONField( [A, B, Hook, State], field, ), fromJSON: (json: Record<string, any>) => Intent.fromJSON( [A, B, Hook, State], json, ), fromSuiParsedData: (content: SuiParsedData) => Intent.fromSuiParsedData( [A, B, Hook, State], content, ), fromSuiObjectData: (content: SuiObjectData) => Intent.fromSuiObjectData( [A, B, Hook, State], content, ), fetch: async (client: SuiClient, id: string) => Intent.fetch( client, [A, B, Hook, State], id, ), new: ( fields: IntentFields<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>>, ) => { return new Intent( [extractType(A), extractType(B), extractType(Hook), extractType(State)], fields ) }, kind: "StructClassReified", } }

 static get r() { return Intent.reified }

 static phantom<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( A: A, B: B, Hook: Hook, State: State ): PhantomReified<ToTypeStr<Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>>>> { return phantom(Intent.reified( A, B, Hook, State )); } static get p() { return Intent.phantom }

 static get bcs() { return bcs.struct("Intent", {

 quote: SwapQuote.bcs

}) };

 static fromFields<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], fields: Record<string, any> ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return Intent.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { quote: decodeFromFields(SwapQuote.reified(), fields.quote) } ) }

 static fromFieldsWithTypes<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], item: FieldsWithTypes ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (!isIntent(item.type)) { throw new Error("not a Intent type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return Intent.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { quote: decodeFromFieldsWithTypes(SwapQuote.reified(), item.fields.quote) } ) }

 static fromBcs<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], data: Uint8Array ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return Intent.fromFields( typeArgs, Intent.bcs.parse(data) ) }

 toJSONField() { return {

 quote: this.quote.toJSONField(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], field: any ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return Intent.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { quote: decodeFromJSONField(SwapQuote.reified(), field.quote) } ) }

 static fromJSON<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], json: Record<string, any> ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (json.$typeName !== Intent.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(Intent.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return Intent.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], content: SuiParsedData ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isIntent(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a Intent object`); } return Intent.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], data: SuiObjectData ): Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isIntent(data.bcs.type)) { throw new Error(`object at is not a Intent object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 4) { throw new Error(`type argument mismatch: expected 4 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 4; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return Intent.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return Intent.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [A, B, Hook, State], id: string ): Promise<Intent<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching Intent object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isIntent(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a Intent object`); }

 return Intent.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== LP =============================== */

export function isLP(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::pool::LP` + '<'); }

export interface LPFields<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument> { dummyField: ToField<"bool"> }

export type LPReified<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument> = Reified< LP<A, B, Hook>, LPFields<A, B, Hook> >;

export class LP<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::LP`; static readonly $numTypeParams = 3; static readonly $isPhantom = [true,true,true,] as const;

 readonly $typeName = LP.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::LP<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}>`; readonly $typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>]; readonly $isPhantom = LP.$isPhantom;

 readonly dummyField: ToField<"bool">

 private constructor(typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>], fields: LPFields<A, B, Hook>, ) { this.$fullTypeName = composeSuiType( LP.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::LP<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}>`; this.$typeArgs = typeArgs;

 this.dummyField = fields.dummyField; }

 static reified<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( A: A, B: B, Hook: Hook ): LPReified<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { return { typeName: LP.$typeName, fullTypeName: composeSuiType( LP.$typeName, ...[extractType(A), extractType(B), extractType(Hook)] ) as `${typeof PKG_V1}::pool::LP<${PhantomToTypeStr<ToPhantomTypeArgument<A>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<B>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Hook>>}>`, typeArgs: [ extractType(A), extractType(B), extractType(Hook) ] as [PhantomToTypeStr<ToPhantomTypeArgument<A>>, PhantomToTypeStr<ToPhantomTypeArgument<B>>, PhantomToTypeStr<ToPhantomTypeArgument<Hook>>], isPhantom: LP.$isPhantom, reifiedTypeArgs: [A, B, Hook], fromFields: (fields: Record<string, any>) => LP.fromFields( [A, B, Hook], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => LP.fromFieldsWithTypes( [A, B, Hook], item, ), fromBcs: (data: Uint8Array) => LP.fromBcs( [A, B, Hook], data, ), bcs: LP.bcs, fromJSONField: (field: any) => LP.fromJSONField( [A, B, Hook], field, ), fromJSON: (json: Record<string, any>) => LP.fromJSON( [A, B, Hook], json, ), fromSuiParsedData: (content: SuiParsedData) => LP.fromSuiParsedData( [A, B, Hook], content, ), fromSuiObjectData: (content: SuiObjectData) => LP.fromSuiObjectData( [A, B, Hook], content, ), fetch: async (client: SuiClient, id: string) => LP.fetch( client, [A, B, Hook], id, ), new: ( fields: LPFields<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>>, ) => { return new LP( [extractType(A), extractType(B), extractType(Hook)], fields ) }, kind: "StructClassReified", } }

 static get r() { return LP.reified }

 static phantom<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( A: A, B: B, Hook: Hook ): PhantomReified<ToTypeStr<LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>>>> { return phantom(LP.reified( A, B, Hook )); } static get p() { return LP.phantom }

 static get bcs() { return bcs.struct("LP", {

 dummy_field: bcs.bool()

}) };

 static fromFields<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], fields: Record<string, any> ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { return LP.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { dummyField: decodeFromFields("bool", fields.dummy_field) } ) }

 static fromFieldsWithTypes<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], item: FieldsWithTypes ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { if (!isLP(item.type)) { throw new Error("not a LP type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return LP.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { dummyField: decodeFromFieldsWithTypes("bool", item.fields.dummy_field) } ) }

 static fromBcs<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], data: Uint8Array ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { return LP.fromFields( typeArgs, LP.bcs.parse(data) ) }

 toJSONField() { return {

 dummyField: this.dummyField,

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], field: any ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { return LP.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { dummyField: decodeFromJSONField("bool", field.dummyField) } ) }

 static fromJSON<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], json: Record<string, any> ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { if (json.$typeName !== LP.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(LP.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return LP.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], content: SuiParsedData ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isLP(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a LP object`); } return LP.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook], data: SuiObjectData ): LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isLP(data.bcs.type)) { throw new Error(`object at is not a LP object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 3) { throw new Error(`type argument mismatch: expected 3 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 3; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return LP.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return LP.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [A, B, Hook], id: string ): Promise<LP<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching LP object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isLP(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a LP object`); }

 return LP.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== NewPoolResult =============================== */

export function isNewPoolResult(type: string): boolean { type = compressSuiType(type); return type === `${PKG_V1}::pool::NewPoolResult`; }

export interface NewPoolResultFields { creator: ToField<"address">; poolId: ToField<ID> }

export type NewPoolResultReified = Reified< NewPoolResult, NewPoolResultFields >;

export class NewPoolResult implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::NewPoolResult`; static readonly $numTypeParams = 0; static readonly $isPhantom = [] as const;

 readonly $typeName = NewPoolResult.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::NewPoolResult`; readonly $typeArgs: []; readonly $isPhantom = NewPoolResult.$isPhantom;

 readonly creator: ToField<"address">; readonly poolId: ToField<ID>

 private constructor(typeArgs: [], fields: NewPoolResultFields, ) { this.$fullTypeName = composeSuiType( NewPoolResult.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::NewPoolResult`; this.$typeArgs = typeArgs;

 this.creator = fields.creator;; this.poolId = fields.poolId; }

 static reified( ): NewPoolResultReified { return { typeName: NewPoolResult.$typeName, fullTypeName: composeSuiType( NewPoolResult.$typeName, ...[] ) as `${typeof PKG_V1}::pool::NewPoolResult`, typeArgs: [ ] as [], isPhantom: NewPoolResult.$isPhantom, reifiedTypeArgs: [], fromFields: (fields: Record<string, any>) => NewPoolResult.fromFields( fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => NewPoolResult.fromFieldsWithTypes( item, ), fromBcs: (data: Uint8Array) => NewPoolResult.fromBcs( data, ), bcs: NewPoolResult.bcs, fromJSONField: (field: any) => NewPoolResult.fromJSONField( field, ), fromJSON: (json: Record<string, any>) => NewPoolResult.fromJSON( json, ), fromSuiParsedData: (content: SuiParsedData) => NewPoolResult.fromSuiParsedData( content, ), fromSuiObjectData: (content: SuiObjectData) => NewPoolResult.fromSuiObjectData( content, ), fetch: async (client: SuiClient, id: string) => NewPoolResult.fetch( client, id, ), new: ( fields: NewPoolResultFields, ) => { return new NewPoolResult( [], fields ) }, kind: "StructClassReified", } }

 static get r() { return NewPoolResult.reified() }

 static phantom( ): PhantomReified<ToTypeStr<NewPoolResult>> { return phantom(NewPoolResult.reified( )); } static get p() { return NewPoolResult.phantom() }

 static get bcs() { return bcs.struct("NewPoolResult", {

 creator: bcs.bytes(32).transform({ input: (val: string) => fromHEX(val), output: (val: Uint8Array) => toHEX(val), }), pool_id: ID.bcs

}) };

 static fromFields( fields: Record<string, any> ): NewPoolResult { return NewPoolResult.reified( ).new( { creator: decodeFromFields("address", fields.creator), poolId: decodeFromFields(ID.reified(), fields.pool_id) } ) }

 static fromFieldsWithTypes( item: FieldsWithTypes ): NewPoolResult { if (!isNewPoolResult(item.type)) { throw new Error("not a NewPoolResult type");

 }

 return NewPoolResult.reified( ).new( { creator: decodeFromFieldsWithTypes("address", item.fields.creator), poolId: decodeFromFieldsWithTypes(ID.reified(), item.fields.pool_id) } ) }

 static fromBcs( data: Uint8Array ): NewPoolResult { return NewPoolResult.fromFields( NewPoolResult.bcs.parse(data) ) }

 toJSONField() { return {

 creator: this.creator,poolId: this.poolId,

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField( field: any ): NewPoolResult { return NewPoolResult.reified( ).new( { creator: decodeFromJSONField("address", field.creator), poolId: decodeFromJSONField(ID.reified(), field.poolId) } ) }

 static fromJSON( json: Record<string, any> ): NewPoolResult { if (json.$typeName !== NewPoolResult.$typeName) { throw new Error("not a WithTwoGenerics json object") };

 return NewPoolResult.fromJSONField( json, ) }

 static fromSuiParsedData( content: SuiParsedData ): NewPoolResult { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isNewPoolResult(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a NewPoolResult object`); } return NewPoolResult.fromFieldsWithTypes( content ); }

 static fromSuiObjectData( data: SuiObjectData ): NewPoolResult { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isNewPoolResult(data.bcs.type)) { throw new Error(`object at is not a NewPoolResult object`); }

 return NewPoolResult.fromBcs( fromB64(data.bcs.bcsBytes) ); } if (data.content) { return NewPoolResult.fromSuiParsedData( data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch( client: SuiClient, id: string ): Promise<NewPoolResult> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching NewPoolResult object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isNewPoolResult(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a NewPoolResult object`); }

 return NewPoolResult.fromSuiObjectData( res.data ); }

 }

/* ============================== Pool =============================== */

export function isPool(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::pool::Pool` + '<'); }

export interface PoolFields<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends TypeArgument> { id: ToField<UID>; inner: ToField<State>; totalFundsA: ToField<TotalFunds<A>>; totalFundsB: ToField<TotalFunds<B>>; lpSupply: ToField<Supply<ToPhantom<LP<A, B, Hook>>>>; protocolFees: ToField<Fees<A, B>>; poolFeeConfig: ToField<FeeConfig>; redemptionFees: ToField<Fees<A, B>>; tradingData: ToField<TradingData>; lockGuard: ToField<"bool">; version: ToField<Version> }

export type PoolReified<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends TypeArgument> = Reified< Pool<A, B, Hook, State>, PoolFields<A, B, Hook, State> >;

export class Pool<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends TypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::Pool`; static readonly $numTypeParams = 4; static readonly $isPhantom = [true,true,true,false,] as const;

 readonly $typeName = Pool.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::Pool<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}, ${ToTypeStr<State>}>`; readonly $typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>, ToTypeStr<State>]; readonly $isPhantom = Pool.$isPhantom;

 readonly id: ToField<UID>; readonly inner: ToField<State>; readonly totalFundsA: ToField<TotalFunds<A>>; readonly totalFundsB: ToField<TotalFunds<B>>; readonly lpSupply: ToField<Supply<ToPhantom<LP<A, B, Hook>>>>; readonly protocolFees: ToField<Fees<A, B>>; readonly poolFeeConfig: ToField<FeeConfig>; readonly redemptionFees: ToField<Fees<A, B>>; readonly tradingData: ToField<TradingData>; readonly lockGuard: ToField<"bool">; readonly version: ToField<Version>

 private constructor(typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>, ToTypeStr<State>], fields: PoolFields<A, B, Hook, State>, ) { this.$fullTypeName = composeSuiType( Pool.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::Pool<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}, ${ToTypeStr<State>}>`; this.$typeArgs = typeArgs;

 this.id = fields.id;; this.inner = fields.inner;; this.totalFundsA = fields.totalFundsA;; this.totalFundsB = fields.totalFundsB;; this.lpSupply = fields.lpSupply;; this.protocolFees = fields.protocolFees;; this.poolFeeConfig = fields.poolFeeConfig;; this.redemptionFees = fields.redemptionFees;; this.tradingData = fields.tradingData;; this.lockGuard = fields.lockGuard;; this.version = fields.version; }

 static reified<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( A: A, B: B, Hook: Hook, State: State ): PoolReified<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { return { typeName: Pool.$typeName, fullTypeName: composeSuiType( Pool.$typeName, ...[extractType(A), extractType(B), extractType(Hook), extractType(State)] ) as `${typeof PKG_V1}::pool::Pool<${PhantomToTypeStr<ToPhantomTypeArgument<A>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<B>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Hook>>}, ${ToTypeStr<ToTypeArgument<State>>}>`, typeArgs: [ extractType(A), extractType(B), extractType(Hook), extractType(State) ] as [PhantomToTypeStr<ToPhantomTypeArgument<A>>, PhantomToTypeStr<ToPhantomTypeArgument<B>>, PhantomToTypeStr<ToPhantomTypeArgument<Hook>>, ToTypeStr<ToTypeArgument<State>>], isPhantom: Pool.$isPhantom, reifiedTypeArgs: [A, B, Hook, State], fromFields: (fields: Record<string, any>) => Pool.fromFields( [A, B, Hook, State], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => Pool.fromFieldsWithTypes( [A, B, Hook, State], item, ), fromBcs: (data: Uint8Array) => Pool.fromBcs( [A, B, Hook, State], data, ), bcs: Pool.bcs(toBcs(State)), fromJSONField: (field: any) => Pool.fromJSONField( [A, B, Hook, State], field, ), fromJSON: (json: Record<string, any>) => Pool.fromJSON( [A, B, Hook, State], json, ), fromSuiParsedData: (content: SuiParsedData) => Pool.fromSuiParsedData( [A, B, Hook, State], content, ), fromSuiObjectData: (content: SuiObjectData) => Pool.fromSuiObjectData( [A, B, Hook, State], content, ), fetch: async (client: SuiClient, id: string) => Pool.fetch( client, [A, B, Hook, State], id, ), new: ( fields: PoolFields<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>>, ) => { return new Pool( [extractType(A), extractType(B), extractType(Hook), extractType(State)], fields ) }, kind: "StructClassReified", } }

 static get r() { return Pool.reified }

 static phantom<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( A: A, B: B, Hook: Hook, State: State ): PhantomReified<ToTypeStr<Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>>>> { return phantom(Pool.reified( A, B, Hook, State )); } static get p() { return Pool.phantom }

 static get bcs() { return <State extends BcsType<any>>(State: State) => bcs.struct(`Pool<${State.name}>`, {

 id: UID.bcs, inner: State, total_funds_a: TotalFunds.bcs, total_funds_b: TotalFunds.bcs, lp_supply: Supply.bcs, protocol_fees: Fees.bcs, pool_fee_config: FeeConfig.bcs, redemption_fees: Fees.bcs, trading_data: TradingData.bcs, lock_guard: bcs.bool(), version: Version.bcs

}) };

 static fromFields<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], fields: Record<string, any> ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { return Pool.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { id: decodeFromFields(UID.reified(), fields.id), inner: decodeFromFields(typeArgs[3], fields.inner), totalFundsA: decodeFromFields(TotalFunds.reified(typeArgs[0]), fields.total_funds_a), totalFundsB: decodeFromFields(TotalFunds.reified(typeArgs[1]), fields.total_funds_b), lpSupply: decodeFromFields(Supply.reified(reified.phantom(LP.reified(typeArgs[0], typeArgs[1], typeArgs[2]))), fields.lp_supply), protocolFees: decodeFromFields(Fees.reified(typeArgs[0], typeArgs[1]), fields.protocol_fees), poolFeeConfig: decodeFromFields(FeeConfig.reified(), fields.pool_fee_config), redemptionFees: decodeFromFields(Fees.reified(typeArgs[0], typeArgs[1]), fields.redemption_fees), tradingData: decodeFromFields(TradingData.reified(), fields.trading_data), lockGuard: decodeFromFields("bool", fields.lock_guard), version: decodeFromFields(Version.reified(), fields.version) } ) }

 static fromFieldsWithTypes<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], item: FieldsWithTypes ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { if (!isPool(item.type)) { throw new Error("not a Pool type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return Pool.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { id: decodeFromFieldsWithTypes(UID.reified(), item.fields.id), inner: decodeFromFieldsWithTypes(typeArgs[3], item.fields.inner), totalFundsA: decodeFromFieldsWithTypes(TotalFunds.reified(typeArgs[0]), item.fields.total_funds_a), totalFundsB: decodeFromFieldsWithTypes(TotalFunds.reified(typeArgs[1]), item.fields.total_funds_b), lpSupply: decodeFromFieldsWithTypes(Supply.reified(reified.phantom(LP.reified(typeArgs[0], typeArgs[1], typeArgs[2]))), item.fields.lp_supply), protocolFees: decodeFromFieldsWithTypes(Fees.reified(typeArgs[0], typeArgs[1]), item.fields.protocol_fees), poolFeeConfig: decodeFromFieldsWithTypes(FeeConfig.reified(), item.fields.pool_fee_config), redemptionFees: decodeFromFieldsWithTypes(Fees.reified(typeArgs[0], typeArgs[1]), item.fields.redemption_fees), tradingData: decodeFromFieldsWithTypes(TradingData.reified(), item.fields.trading_data), lockGuard: decodeFromFieldsWithTypes("bool", item.fields.lock_guard), version: decodeFromFieldsWithTypes(Version.reified(), item.fields.version) } ) }

 static fromBcs<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], data: Uint8Array ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { return Pool.fromFields( typeArgs, Pool.bcs( toBcs(typeArgs[3]) ).parse(data) ) }

 toJSONField() { return {

 id: this.id,inner: fieldToJSON<State>(this.$typeArgs[3], this.inner),totalFundsA: this.totalFundsA.toJSONField(),totalFundsB: this.totalFundsB.toJSONField(),lpSupply: this.lpSupply.toJSONField(),protocolFees: this.protocolFees.toJSONField(),poolFeeConfig: this.poolFeeConfig.toJSONField(),redemptionFees: this.redemptionFees.toJSONField(),tradingData: this.tradingData.toJSONField(),lockGuard: this.lockGuard,version: this.version.toJSONField(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], field: any ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { return Pool.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { id: decodeFromJSONField(UID.reified(), field.id), inner: decodeFromJSONField(typeArgs[3], field.inner), totalFundsA: decodeFromJSONField(TotalFunds.reified(typeArgs[0]), field.totalFundsA), totalFundsB: decodeFromJSONField(TotalFunds.reified(typeArgs[1]), field.totalFundsB), lpSupply: decodeFromJSONField(Supply.reified(reified.phantom(LP.reified(typeArgs[0], typeArgs[1], typeArgs[2]))), field.lpSupply), protocolFees: decodeFromJSONField(Fees.reified(typeArgs[0], typeArgs[1]), field.protocolFees), poolFeeConfig: decodeFromJSONField(FeeConfig.reified(), field.poolFeeConfig), redemptionFees: decodeFromJSONField(Fees.reified(typeArgs[0], typeArgs[1]), field.redemptionFees), tradingData: decodeFromJSONField(TradingData.reified(), field.tradingData), lockGuard: decodeFromJSONField("bool", field.lockGuard), version: decodeFromJSONField(Version.reified(), field.version) } ) }

 static fromJSON<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], json: Record<string, any> ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { if (json.$typeName !== Pool.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(Pool.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return Pool.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], content: SuiParsedData ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isPool(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a Pool object`); } return Pool.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( typeArgs: [A, B, Hook, State], data: SuiObjectData ): Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isPool(data.bcs.type)) { throw new Error(`object at is not a Pool object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 4) { throw new Error(`type argument mismatch: expected 4 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 4; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return Pool.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return Pool.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends Reified<TypeArgument, any>>( client: SuiClient, typeArgs: [A, B, Hook, State], id: string ): Promise<Pool<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToTypeArgument<State>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching Pool object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isPool(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a Pool object`); }

 return Pool.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== PoolCap =============================== */

export function isPoolCap(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::pool::PoolCap` + '<'); }

export interface PoolCapFields<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends PhantomTypeArgument> { id: ToField<UID>; poolId: ToField<ID> }

export type PoolCapReified<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends PhantomTypeArgument> = Reified< PoolCap<A, B, Hook, State>, PoolCapFields<A, B, Hook, State> >;

export class PoolCap<A extends PhantomTypeArgument, B extends PhantomTypeArgument, Hook extends PhantomTypeArgument, State extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::PoolCap`; static readonly $numTypeParams = 4; static readonly $isPhantom = [true,true,true,true,] as const;

 readonly $typeName = PoolCap.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::PoolCap<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}, ${PhantomToTypeStr<State>}>`; readonly $typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>, PhantomToTypeStr<State>]; readonly $isPhantom = PoolCap.$isPhantom;

 readonly id: ToField<UID>; readonly poolId: ToField<ID>

 private constructor(typeArgs: [PhantomToTypeStr<A>, PhantomToTypeStr<B>, PhantomToTypeStr<Hook>, PhantomToTypeStr<State>], fields: PoolCapFields<A, B, Hook, State>, ) { this.$fullTypeName = composeSuiType( PoolCap.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::PoolCap<${PhantomToTypeStr<A>}, ${PhantomToTypeStr<B>}, ${PhantomToTypeStr<Hook>}, ${PhantomToTypeStr<State>}>`; this.$typeArgs = typeArgs;

 this.id = fields.id;; this.poolId = fields.poolId; }

 static reified<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( A: A, B: B, Hook: Hook, State: State ): PoolCapReified<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return { typeName: PoolCap.$typeName, fullTypeName: composeSuiType( PoolCap.$typeName, ...[extractType(A), extractType(B), extractType(Hook), extractType(State)] ) as `${typeof PKG_V1}::pool::PoolCap<${PhantomToTypeStr<ToPhantomTypeArgument<A>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<B>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Hook>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<State>>}>`, typeArgs: [ extractType(A), extractType(B), extractType(Hook), extractType(State) ] as [PhantomToTypeStr<ToPhantomTypeArgument<A>>, PhantomToTypeStr<ToPhantomTypeArgument<B>>, PhantomToTypeStr<ToPhantomTypeArgument<Hook>>, PhantomToTypeStr<ToPhantomTypeArgument<State>>], isPhantom: PoolCap.$isPhantom, reifiedTypeArgs: [A, B, Hook, State], fromFields: (fields: Record<string, any>) => PoolCap.fromFields( [A, B, Hook, State], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => PoolCap.fromFieldsWithTypes( [A, B, Hook, State], item, ), fromBcs: (data: Uint8Array) => PoolCap.fromBcs( [A, B, Hook, State], data, ), bcs: PoolCap.bcs, fromJSONField: (field: any) => PoolCap.fromJSONField( [A, B, Hook, State], field, ), fromJSON: (json: Record<string, any>) => PoolCap.fromJSON( [A, B, Hook, State], json, ), fromSuiParsedData: (content: SuiParsedData) => PoolCap.fromSuiParsedData( [A, B, Hook, State], content, ), fromSuiObjectData: (content: SuiObjectData) => PoolCap.fromSuiObjectData( [A, B, Hook, State], content, ), fetch: async (client: SuiClient, id: string) => PoolCap.fetch( client, [A, B, Hook, State], id, ), new: ( fields: PoolCapFields<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>>, ) => { return new PoolCap( [extractType(A), extractType(B), extractType(Hook), extractType(State)], fields ) }, kind: "StructClassReified", } }

 static get r() { return PoolCap.reified }

 static phantom<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( A: A, B: B, Hook: Hook, State: State ): PhantomReified<ToTypeStr<PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>>>> { return phantom(PoolCap.reified( A, B, Hook, State )); } static get p() { return PoolCap.phantom }

 static get bcs() { return bcs.struct("PoolCap", {

 id: UID.bcs, pool_id: ID.bcs

}) };

 static fromFields<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], fields: Record<string, any> ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return PoolCap.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { id: decodeFromFields(UID.reified(), fields.id), poolId: decodeFromFields(ID.reified(), fields.pool_id) } ) }

 static fromFieldsWithTypes<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], item: FieldsWithTypes ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (!isPoolCap(item.type)) { throw new Error("not a PoolCap type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return PoolCap.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { id: decodeFromFieldsWithTypes(UID.reified(), item.fields.id), poolId: decodeFromFieldsWithTypes(ID.reified(), item.fields.pool_id) } ) }

 static fromBcs<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], data: Uint8Array ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return PoolCap.fromFields( typeArgs, PoolCap.bcs.parse(data) ) }

 toJSONField() { return {

 id: this.id,poolId: this.poolId,

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], field: any ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { return PoolCap.reified( typeArgs[0], typeArgs[1], typeArgs[2], typeArgs[3], ).new( { id: decodeFromJSONField(UID.reified(), field.id), poolId: decodeFromJSONField(ID.reified(), field.poolId) } ) }

 static fromJSON<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], json: Record<string, any> ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (json.$typeName !== PoolCap.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(PoolCap.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return PoolCap.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], content: SuiParsedData ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isPoolCap(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a PoolCap object`); } return PoolCap.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( typeArgs: [A, B, Hook, State], data: SuiObjectData ): PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isPoolCap(data.bcs.type)) { throw new Error(`object at is not a PoolCap object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 4) { throw new Error(`type argument mismatch: expected 4 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 4; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return PoolCap.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return PoolCap.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<A extends PhantomReified<PhantomTypeArgument>, B extends PhantomReified<PhantomTypeArgument>, Hook extends PhantomReified<PhantomTypeArgument>, State extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [A, B, Hook, State], id: string ): Promise<PoolCap<ToPhantomTypeArgument<A>, ToPhantomTypeArgument<B>, ToPhantomTypeArgument<Hook>, ToPhantomTypeArgument<State>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching PoolCap object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isPoolCap(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a PoolCap object`); }

 return PoolCap.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== RedeemResult =============================== */

export function isRedeemResult(type: string): boolean { type = compressSuiType(type); return type === `${PKG_V1}::pool::RedeemResult`; }

export interface RedeemResultFields { user: ToField<"address">; poolId: ToField<ID>; withdrawA: ToField<"u64">; withdrawB: ToField<"u64">; feesA: ToField<"u64">; feesB: ToField<"u64">; burnLp: ToField<"u64"> }

export type RedeemResultReified = Reified< RedeemResult, RedeemResultFields >;

export class RedeemResult implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::RedeemResult`; static readonly $numTypeParams = 0; static readonly $isPhantom = [] as const;

 readonly $typeName = RedeemResult.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::RedeemResult`; readonly $typeArgs: []; readonly $isPhantom = RedeemResult.$isPhantom;

 readonly user: ToField<"address">; readonly poolId: ToField<ID>; readonly withdrawA: ToField<"u64">; readonly withdrawB: ToField<"u64">; readonly feesA: ToField<"u64">; readonly feesB: ToField<"u64">; readonly burnLp: ToField<"u64">

 private constructor(typeArgs: [], fields: RedeemResultFields, ) { this.$fullTypeName = composeSuiType( RedeemResult.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::RedeemResult`; this.$typeArgs = typeArgs;

 this.user = fields.user;; this.poolId = fields.poolId;; this.withdrawA = fields.withdrawA;; this.withdrawB = fields.withdrawB;; this.feesA = fields.feesA;; this.feesB = fields.feesB;; this.burnLp = fields.burnLp; }

 static reified( ): RedeemResultReified { return { typeName: RedeemResult.$typeName, fullTypeName: composeSuiType( RedeemResult.$typeName, ...[] ) as `${typeof PKG_V1}::pool::RedeemResult`, typeArgs: [ ] as [], isPhantom: RedeemResult.$isPhantom, reifiedTypeArgs: [], fromFields: (fields: Record<string, any>) => RedeemResult.fromFields( fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => RedeemResult.fromFieldsWithTypes( item, ), fromBcs: (data: Uint8Array) => RedeemResult.fromBcs( data, ), bcs: RedeemResult.bcs, fromJSONField: (field: any) => RedeemResult.fromJSONField( field, ), fromJSON: (json: Record<string, any>) => RedeemResult.fromJSON( json, ), fromSuiParsedData: (content: SuiParsedData) => RedeemResult.fromSuiParsedData( content, ), fromSuiObjectData: (content: SuiObjectData) => RedeemResult.fromSuiObjectData( content, ), fetch: async (client: SuiClient, id: string) => RedeemResult.fetch( client, id, ), new: ( fields: RedeemResultFields, ) => { return new RedeemResult( [], fields ) }, kind: "StructClassReified", } }

 static get r() { return RedeemResult.reified() }

 static phantom( ): PhantomReified<ToTypeStr<RedeemResult>> { return phantom(RedeemResult.reified( )); } static get p() { return RedeemResult.phantom() }

 static get bcs() { return bcs.struct("RedeemResult", {

 user: bcs.bytes(32).transform({ input: (val: string) => fromHEX(val), output: (val: Uint8Array) => toHEX(val), }), pool_id: ID.bcs, withdraw_a: bcs.u64(), withdraw_b: bcs.u64(), fees_a: bcs.u64(), fees_b: bcs.u64(), burn_lp: bcs.u64()

}) };

 static fromFields( fields: Record<string, any> ): RedeemResult { return RedeemResult.reified( ).new( { user: decodeFromFields("address", fields.user), poolId: decodeFromFields(ID.reified(), fields.pool_id), withdrawA: decodeFromFields("u64", fields.withdraw_a), withdrawB: decodeFromFields("u64", fields.withdraw_b), feesA: decodeFromFields("u64", fields.fees_a), feesB: decodeFromFields("u64", fields.fees_b), burnLp: decodeFromFields("u64", fields.burn_lp) } ) }

 static fromFieldsWithTypes( item: FieldsWithTypes ): RedeemResult { if (!isRedeemResult(item.type)) { throw new Error("not a RedeemResult type");

 }

 return RedeemResult.reified( ).new( { user: decodeFromFieldsWithTypes("address", item.fields.user), poolId: decodeFromFieldsWithTypes(ID.reified(), item.fields.pool_id), withdrawA: decodeFromFieldsWithTypes("u64", item.fields.withdraw_a), withdrawB: decodeFromFieldsWithTypes("u64", item.fields.withdraw_b), feesA: decodeFromFieldsWithTypes("u64", item.fields.fees_a), feesB: decodeFromFieldsWithTypes("u64", item.fields.fees_b), burnLp: decodeFromFieldsWithTypes("u64", item.fields.burn_lp) } ) }

 static fromBcs( data: Uint8Array ): RedeemResult { return RedeemResult.fromFields( RedeemResult.bcs.parse(data) ) }

 toJSONField() { return {

 user: this.user,poolId: this.poolId,withdrawA: this.withdrawA.toString(),withdrawB: this.withdrawB.toString(),feesA: this.feesA.toString(),feesB: this.feesB.toString(),burnLp: this.burnLp.toString(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField( field: any ): RedeemResult { return RedeemResult.reified( ).new( { user: decodeFromJSONField("address", field.user), poolId: decodeFromJSONField(ID.reified(), field.poolId), withdrawA: decodeFromJSONField("u64", field.withdrawA), withdrawB: decodeFromJSONField("u64", field.withdrawB), feesA: decodeFromJSONField("u64", field.feesA), feesB: decodeFromJSONField("u64", field.feesB), burnLp: decodeFromJSONField("u64", field.burnLp) } ) }

 static fromJSON( json: Record<string, any> ): RedeemResult { if (json.$typeName !== RedeemResult.$typeName) { throw new Error("not a WithTwoGenerics json object") };

 return RedeemResult.fromJSONField( json, ) }

 static fromSuiParsedData( content: SuiParsedData ): RedeemResult { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isRedeemResult(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a RedeemResult object`); } return RedeemResult.fromFieldsWithTypes( content ); }

 static fromSuiObjectData( data: SuiObjectData ): RedeemResult { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isRedeemResult(data.bcs.type)) { throw new Error(`object at is not a RedeemResult object`); }

 return RedeemResult.fromBcs( fromB64(data.bcs.bcsBytes) ); } if (data.content) { return RedeemResult.fromSuiParsedData( data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch( client: SuiClient, id: string ): Promise<RedeemResult> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching RedeemResult object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isRedeemResult(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a RedeemResult object`); }

 return RedeemResult.fromSuiObjectData( res.data ); }

 }

/* ============================== SwapResult =============================== */

export function isSwapResult(type: string): boolean { type = compressSuiType(type); return type === `${PKG_V1}::pool::SwapResult`; }

export interface SwapResultFields { user: ToField<"address">; poolId: ToField<ID>; amountIn: ToField<"u64">; amountOut: ToField<"u64">; outputFees: ToField<SwapFee>; a2B: ToField<"bool"> }

export type SwapResultReified = Reified< SwapResult, SwapResultFields >;

export class SwapResult implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::SwapResult`; static readonly $numTypeParams = 0; static readonly $isPhantom = [] as const;

 readonly $typeName = SwapResult.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::SwapResult`; readonly $typeArgs: []; readonly $isPhantom = SwapResult.$isPhantom;

 readonly user: ToField<"address">; readonly poolId: ToField<ID>; readonly amountIn: ToField<"u64">; readonly amountOut: ToField<"u64">; readonly outputFees: ToField<SwapFee>; readonly a2B: ToField<"bool">

 private constructor(typeArgs: [], fields: SwapResultFields, ) { this.$fullTypeName = composeSuiType( SwapResult.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::SwapResult`; this.$typeArgs = typeArgs;

 this.user = fields.user;; this.poolId = fields.poolId;; this.amountIn = fields.amountIn;; this.amountOut = fields.amountOut;; this.outputFees = fields.outputFees;; this.a2B = fields.a2B; }

 static reified( ): SwapResultReified { return { typeName: SwapResult.$typeName, fullTypeName: composeSuiType( SwapResult.$typeName, ...[] ) as `${typeof PKG_V1}::pool::SwapResult`, typeArgs: [ ] as [], isPhantom: SwapResult.$isPhantom, reifiedTypeArgs: [], fromFields: (fields: Record<string, any>) => SwapResult.fromFields( fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => SwapResult.fromFieldsWithTypes( item, ), fromBcs: (data: Uint8Array) => SwapResult.fromBcs( data, ), bcs: SwapResult.bcs, fromJSONField: (field: any) => SwapResult.fromJSONField( field, ), fromJSON: (json: Record<string, any>) => SwapResult.fromJSON( json, ), fromSuiParsedData: (content: SuiParsedData) => SwapResult.fromSuiParsedData( content, ), fromSuiObjectData: (content: SuiObjectData) => SwapResult.fromSuiObjectData( content, ), fetch: async (client: SuiClient, id: string) => SwapResult.fetch( client, id, ), new: ( fields: SwapResultFields, ) => { return new SwapResult( [], fields ) }, kind: "StructClassReified", } }

 static get r() { return SwapResult.reified() }

 static phantom( ): PhantomReified<ToTypeStr<SwapResult>> { return phantom(SwapResult.reified( )); } static get p() { return SwapResult.phantom() }

 static get bcs() { return bcs.struct("SwapResult", {

 user: bcs.bytes(32).transform({ input: (val: string) => fromHEX(val), output: (val: Uint8Array) => toHEX(val), }), pool_id: ID.bcs, amount_in: bcs.u64(), amount_out: bcs.u64(), output_fees: SwapFee.bcs, a2b: bcs.bool()

}) };

 static fromFields( fields: Record<string, any> ): SwapResult { return SwapResult.reified( ).new( { user: decodeFromFields("address", fields.user), poolId: decodeFromFields(ID.reified(), fields.pool_id), amountIn: decodeFromFields("u64", fields.amount_in), amountOut: decodeFromFields("u64", fields.amount_out), outputFees: decodeFromFields(SwapFee.reified(), fields.output_fees), a2B: decodeFromFields("bool", fields.a2b) } ) }

 static fromFieldsWithTypes( item: FieldsWithTypes ): SwapResult { if (!isSwapResult(item.type)) { throw new Error("not a SwapResult type");

 }

 return SwapResult.reified( ).new( { user: decodeFromFieldsWithTypes("address", item.fields.user), poolId: decodeFromFieldsWithTypes(ID.reified(), item.fields.pool_id), amountIn: decodeFromFieldsWithTypes("u64", item.fields.amount_in), amountOut: decodeFromFieldsWithTypes("u64", item.fields.amount_out), outputFees: decodeFromFieldsWithTypes(SwapFee.reified(), item.fields.output_fees), a2B: decodeFromFieldsWithTypes("bool", item.fields.a2b) } ) }

 static fromBcs( data: Uint8Array ): SwapResult { return SwapResult.fromFields( SwapResult.bcs.parse(data) ) }

 toJSONField() { return {

 user: this.user,poolId: this.poolId,amountIn: this.amountIn.toString(),amountOut: this.amountOut.toString(),outputFees: this.outputFees.toJSONField(),a2B: this.a2B,

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField( field: any ): SwapResult { return SwapResult.reified( ).new( { user: decodeFromJSONField("address", field.user), poolId: decodeFromJSONField(ID.reified(), field.poolId), amountIn: decodeFromJSONField("u64", field.amountIn), amountOut: decodeFromJSONField("u64", field.amountOut), outputFees: decodeFromJSONField(SwapFee.reified(), field.outputFees), a2B: decodeFromJSONField("bool", field.a2B) } ) }

 static fromJSON( json: Record<string, any> ): SwapResult { if (json.$typeName !== SwapResult.$typeName) { throw new Error("not a WithTwoGenerics json object") };

 return SwapResult.fromJSONField( json, ) }

 static fromSuiParsedData( content: SuiParsedData ): SwapResult { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isSwapResult(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a SwapResult object`); } return SwapResult.fromFieldsWithTypes( content ); }

 static fromSuiObjectData( data: SuiObjectData ): SwapResult { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isSwapResult(data.bcs.type)) { throw new Error(`object at is not a SwapResult object`); }

 return SwapResult.fromBcs( fromB64(data.bcs.bcsBytes) ); } if (data.content) { return SwapResult.fromSuiParsedData( data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch( client: SuiClient, id: string ): Promise<SwapResult> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching SwapResult object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isSwapResult(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a SwapResult object`); }

 return SwapResult.fromSuiObjectData( res.data ); }

 }

/* ============================== TotalFunds =============================== */

export function isTotalFunds(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::pool::TotalFunds` + '<'); }

export interface TotalFundsFields<T extends PhantomTypeArgument> { pos0: ToField<"u64"> }

export type TotalFundsReified<T extends PhantomTypeArgument> = Reified< TotalFunds<T>, TotalFundsFields<T> >;

export class TotalFunds<T extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::TotalFunds`; static readonly $numTypeParams = 1; static readonly $isPhantom = [true,] as const;

 readonly $typeName = TotalFunds.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::TotalFunds<${PhantomToTypeStr<T>}>`; readonly $typeArgs: [PhantomToTypeStr<T>]; readonly $isPhantom = TotalFunds.$isPhantom;

 readonly pos0: ToField<"u64">

 private constructor(typeArgs: [PhantomToTypeStr<T>], fields: TotalFundsFields<T>, ) { this.$fullTypeName = composeSuiType( TotalFunds.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::TotalFunds<${PhantomToTypeStr<T>}>`; this.$typeArgs = typeArgs;

 this.pos0 = fields.pos0; }

 static reified<T extends PhantomReified<PhantomTypeArgument>>( T: T ): TotalFundsReified<ToPhantomTypeArgument<T>> { return { typeName: TotalFunds.$typeName, fullTypeName: composeSuiType( TotalFunds.$typeName, ...[extractType(T)] ) as `${typeof PKG_V1}::pool::TotalFunds<${PhantomToTypeStr<ToPhantomTypeArgument<T>>}>`, typeArgs: [ extractType(T) ] as [PhantomToTypeStr<ToPhantomTypeArgument<T>>], isPhantom: TotalFunds.$isPhantom, reifiedTypeArgs: [T], fromFields: (fields: Record<string, any>) => TotalFunds.fromFields( T, fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => TotalFunds.fromFieldsWithTypes( T, item, ), fromBcs: (data: Uint8Array) => TotalFunds.fromBcs( T, data, ), bcs: TotalFunds.bcs, fromJSONField: (field: any) => TotalFunds.fromJSONField( T, field, ), fromJSON: (json: Record<string, any>) => TotalFunds.fromJSON( T, json, ), fromSuiParsedData: (content: SuiParsedData) => TotalFunds.fromSuiParsedData( T, content, ), fromSuiObjectData: (content: SuiObjectData) => TotalFunds.fromSuiObjectData( T, content, ), fetch: async (client: SuiClient, id: string) => TotalFunds.fetch( client, T, id, ), new: ( fields: TotalFundsFields<ToPhantomTypeArgument<T>>, ) => { return new TotalFunds( [extractType(T)], fields ) }, kind: "StructClassReified", } }

 static get r() { return TotalFunds.reified }

 static phantom<T extends PhantomReified<PhantomTypeArgument>>( T: T ): PhantomReified<ToTypeStr<TotalFunds<ToPhantomTypeArgument<T>>>> { return phantom(TotalFunds.reified( T )); } static get p() { return TotalFunds.phantom }

 static get bcs() { return bcs.struct("TotalFunds", {

 pos0: bcs.u64()

}) };

 static fromFields<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, fields: Record<string, any> ): TotalFunds<ToPhantomTypeArgument<T>> { return TotalFunds.reified( typeArg, ).new( { pos0: decodeFromFields("u64", fields.pos0) } ) }

 static fromFieldsWithTypes<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, item: FieldsWithTypes ): TotalFunds<ToPhantomTypeArgument<T>> { if (!isTotalFunds(item.type)) { throw new Error("not a TotalFunds type");

 } assertFieldsWithTypesArgsMatch(item, [typeArg]);

 return TotalFunds.reified( typeArg, ).new( { pos0: decodeFromFieldsWithTypes("u64", item.fields.pos0) } ) }

 static fromBcs<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, data: Uint8Array ): TotalFunds<ToPhantomTypeArgument<T>> { return TotalFunds.fromFields( typeArg, TotalFunds.bcs.parse(data) ) }

 toJSONField() { return {

 pos0: this.pos0.toString(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, field: any ): TotalFunds<ToPhantomTypeArgument<T>> { return TotalFunds.reified( typeArg, ).new( { pos0: decodeFromJSONField("u64", field.pos0) } ) }

 static fromJSON<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, json: Record<string, any> ): TotalFunds<ToPhantomTypeArgument<T>> { if (json.$typeName !== TotalFunds.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(TotalFunds.$typeName, extractType(typeArg)), json.$typeArgs, [typeArg], )

 return TotalFunds.fromJSONField( typeArg, json, ) }

 static fromSuiParsedData<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, content: SuiParsedData ): TotalFunds<ToPhantomTypeArgument<T>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isTotalFunds(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a TotalFunds object`); } return TotalFunds.fromFieldsWithTypes( typeArg, content ); }

 static fromSuiObjectData<T extends PhantomReified<PhantomTypeArgument>>( typeArg: T, data: SuiObjectData ): TotalFunds<ToPhantomTypeArgument<T>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isTotalFunds(data.bcs.type)) { throw new Error(`object at is not a TotalFunds object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 1) { throw new Error(`type argument mismatch: expected 1 type argument but got '${gotTypeArgs.length}'`); }; const gotTypeArg = compressSuiType(gotTypeArgs[0]); const expectedTypeArg = compressSuiType(extractType(typeArg)); if (gotTypeArg !== compressSuiType(extractType(typeArg))) { throw new Error(`type argument mismatch: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); };

 return TotalFunds.fromBcs( typeArg, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return TotalFunds.fromSuiParsedData( typeArg, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<T extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArg: T, id: string ): Promise<TotalFunds<ToPhantomTypeArgument<T>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching TotalFunds object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isTotalFunds(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a TotalFunds object`); }

 return TotalFunds.fromSuiObjectData( typeArg, res.data ); }

 }

/* ============================== TradingData =============================== */

export function isTradingData(type: string): boolean { type = compressSuiType(type); return type === `${PKG_V1}::pool::TradingData`; }

export interface TradingDataFields { swapAInAmount: ToField<"u128">; swapBOutAmount: ToField<"u128">; swapAOutAmount: ToField<"u128">; swapBInAmount: ToField<"u128">; protocolFeesA: ToField<"u64">; protocolFeesB: ToField<"u64">; redemptionFeesA: ToField<"u64">; redemptionFeesB: ToField<"u64">; poolFeesA: ToField<"u64">; poolFeesB: ToField<"u64"> }

export type TradingDataReified = Reified< TradingData, TradingDataFields >;

export class TradingData implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::pool::TradingData`; static readonly $numTypeParams = 0; static readonly $isPhantom = [] as const;

 readonly $typeName = TradingData.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::pool::TradingData`; readonly $typeArgs: []; readonly $isPhantom = TradingData.$isPhantom;

 readonly swapAInAmount: ToField<"u128">; readonly swapBOutAmount: ToField<"u128">; readonly swapAOutAmount: ToField<"u128">; readonly swapBInAmount: ToField<"u128">; readonly protocolFeesA: ToField<"u64">; readonly protocolFeesB: ToField<"u64">; readonly redemptionFeesA: ToField<"u64">; readonly redemptionFeesB: ToField<"u64">; readonly poolFeesA: ToField<"u64">; readonly poolFeesB: ToField<"u64">

 private constructor(typeArgs: [], fields: TradingDataFields, ) { this.$fullTypeName = composeSuiType( TradingData.$typeName, ...typeArgs ) as `${typeof PKG_V1}::pool::TradingData`; this.$typeArgs = typeArgs;

 this.swapAInAmount = fields.swapAInAmount;; this.swapBOutAmount = fields.swapBOutAmount;; this.swapAOutAmount = fields.swapAOutAmount;; this.swapBInAmount = fields.swapBInAmount;; this.protocolFeesA = fields.protocolFeesA;; this.protocolFeesB = fields.protocolFeesB;; this.redemptionFeesA = fields.redemptionFeesA;; this.redemptionFeesB = fields.redemptionFeesB;; this.poolFeesA = fields.poolFeesA;; this.poolFeesB = fields.poolFeesB; }

 static reified( ): TradingDataReified { return { typeName: TradingData.$typeName, fullTypeName: composeSuiType( TradingData.$typeName, ...[] ) as `${typeof PKG_V1}::pool::TradingData`, typeArgs: [ ] as [], isPhantom: TradingData.$isPhantom, reifiedTypeArgs: [], fromFields: (fields: Record<string, any>) => TradingData.fromFields( fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => TradingData.fromFieldsWithTypes( item, ), fromBcs: (data: Uint8Array) => TradingData.fromBcs( data, ), bcs: TradingData.bcs, fromJSONField: (field: any) => TradingData.fromJSONField( field, ), fromJSON: (json: Record<string, any>) => TradingData.fromJSON( json, ), fromSuiParsedData: (content: SuiParsedData) => TradingData.fromSuiParsedData( content, ), fromSuiObjectData: (content: SuiObjectData) => TradingData.fromSuiObjectData( content, ), fetch: async (client: SuiClient, id: string) => TradingData.fetch( client, id, ), new: ( fields: TradingDataFields, ) => { return new TradingData( [], fields ) }, kind: "StructClassReified", } }

 static get r() { return TradingData.reified() }

 static phantom( ): PhantomReified<ToTypeStr<TradingData>> { return phantom(TradingData.reified( )); } static get p() { return TradingData.phantom() }

 static get bcs() { return bcs.struct("TradingData", {

 swap_a_in_amount: bcs.u128(), swap_b_out_amount: bcs.u128(), swap_a_out_amount: bcs.u128(), swap_b_in_amount: bcs.u128(), protocol_fees_a: bcs.u64(), protocol_fees_b: bcs.u64(), redemption_fees_a: bcs.u64(), redemption_fees_b: bcs.u64(), pool_fees_a: bcs.u64(), pool_fees_b: bcs.u64()

}) };

 static fromFields( fields: Record<string, any> ): TradingData { return TradingData.reified( ).new( { swapAInAmount: decodeFromFields("u128", fields.swap_a_in_amount), swapBOutAmount: decodeFromFields("u128", fields.swap_b_out_amount), swapAOutAmount: decodeFromFields("u128", fields.swap_a_out_amount), swapBInAmount: decodeFromFields("u128", fields.swap_b_in_amount), protocolFeesA: decodeFromFields("u64", fields.protocol_fees_a), protocolFeesB: decodeFromFields("u64", fields.protocol_fees_b), redemptionFeesA: decodeFromFields("u64", fields.redemption_fees_a), redemptionFeesB: decodeFromFields("u64", fields.redemption_fees_b), poolFeesA: decodeFromFields("u64", fields.pool_fees_a), poolFeesB: decodeFromFields("u64", fields.pool_fees_b) } ) }

 static fromFieldsWithTypes( item: FieldsWithTypes ): TradingData { if (!isTradingData(item.type)) { throw new Error("not a TradingData type");

 }

 return TradingData.reified( ).new( { swapAInAmount: decodeFromFieldsWithTypes("u128", item.fields.swap_a_in_amount), swapBOutAmount: decodeFromFieldsWithTypes("u128", item.fields.swap_b_out_amount), swapAOutAmount: decodeFromFieldsWithTypes("u128", item.fields.swap_a_out_amount), swapBInAmount: decodeFromFieldsWithTypes("u128", item.fields.swap_b_in_amount), protocolFeesA: decodeFromFieldsWithTypes("u64", item.fields.protocol_fees_a), protocolFeesB: decodeFromFieldsWithTypes("u64", item.fields.protocol_fees_b), redemptionFeesA: decodeFromFieldsWithTypes("u64", item.fields.redemption_fees_a), redemptionFeesB: decodeFromFieldsWithTypes("u64", item.fields.redemption_fees_b), poolFeesA: decodeFromFieldsWithTypes("u64", item.fields.pool_fees_a), poolFeesB: decodeFromFieldsWithTypes("u64", item.fields.pool_fees_b) } ) }

 static fromBcs( data: Uint8Array ): TradingData { return TradingData.fromFields( TradingData.bcs.parse(data) ) }

 toJSONField() { return {

 swapAInAmount: this.swapAInAmount.toString(),swapBOutAmount: this.swapBOutAmount.toString(),swapAOutAmount: this.swapAOutAmount.toString(),swapBInAmount: this.swapBInAmount.toString(),protocolFeesA: this.protocolFeesA.toString(),protocolFeesB: this.protocolFeesB.toString(),redemptionFeesA: this.redemptionFeesA.toString(),redemptionFeesB: this.redemptionFeesB.toString(),poolFeesA: this.poolFeesA.toString(),poolFeesB: this.poolFeesB.toString(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField( field: any ): TradingData { return TradingData.reified( ).new( { swapAInAmount: decodeFromJSONField("u128", field.swapAInAmount), swapBOutAmount: decodeFromJSONField("u128", field.swapBOutAmount), swapAOutAmount: decodeFromJSONField("u128", field.swapAOutAmount), swapBInAmount: decodeFromJSONField("u128", field.swapBInAmount), protocolFeesA: decodeFromJSONField("u64", field.protocolFeesA), protocolFeesB: decodeFromJSONField("u64", field.protocolFeesB), redemptionFeesA: decodeFromJSONField("u64", field.redemptionFeesA), redemptionFeesB: decodeFromJSONField("u64", field.redemptionFeesB), poolFeesA: decodeFromJSONField("u64", field.poolFeesA), poolFeesB: decodeFromJSONField("u64", field.poolFeesB) } ) }

 static fromJSON( json: Record<string, any> ): TradingData { if (json.$typeName !== TradingData.$typeName) { throw new Error("not a WithTwoGenerics json object") };

 return TradingData.fromJSONField( json, ) }

 static fromSuiParsedData( content: SuiParsedData ): TradingData { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isTradingData(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a TradingData object`); } return TradingData.fromFieldsWithTypes( content ); }

 static fromSuiObjectData( data: SuiObjectData ): TradingData { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isTradingData(data.bcs.type)) { throw new Error(`object at is not a TradingData object`); }

 return TradingData.fromBcs( fromB64(data.bcs.bcsBytes) ); } if (data.content) { return TradingData.fromSuiParsedData( data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch( client: SuiClient, id: string ): Promise<TradingData> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching TradingData object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isTradingData(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a TradingData object`); }

 return TradingData.fromSuiObjectData( res.data ); }

 }
