import {PhantomReified, PhantomToTypeStr, PhantomTypeArgument, Reified, StructClass, ToField, ToPhantomTypeArgument, ToTypeStr, assertFieldsWithTypesArgsMatch, assertReifiedTypeArgsMatch, decodeFromFields, decodeFromFieldsWithTypes, decodeFromJSONField, extractType, phantom} from "../../_framework/reified";
import {FieldsWithTypes, composeSuiType, compressSuiType, parseTypeName} from "../../_framework/util";
import {PKG_V1} from "../index";
import {Version} from "../version/structs";
import {bcs} from "@mysten/sui/bcs";
import {SuiClient, SuiObjectData, SuiParsedData} from "@mysten/sui/client";
import {fromB64} from "@mysten/sui/utils";

/* ============================== CpQuoter =============================== */

export function isCpQuoter(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::cpmm::CpQuoter` + '<'); }

export interface CpQuoterFields<W extends PhantomTypeArgument> { version: ToField<Version>; offset: ToField<"u64"> }

export type CpQuoterReified<W extends PhantomTypeArgument> = Reified< CpQuoter<W>, CpQuoterFields<W> >;

export class CpQuoter<W extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::cpmm::CpQuoter`; static readonly $numTypeParams = 1; static readonly $isPhantom = [true,] as const;

 readonly $typeName = CpQuoter.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::cpmm::CpQuoter<${PhantomToTypeStr<W>}>`; readonly $typeArgs: [PhantomToTypeStr<W>]; readonly $isPhantom = CpQuoter.$isPhantom;

 readonly version: ToField<Version>; readonly offset: ToField<"u64">

 private constructor(typeArgs: [PhantomToTypeStr<W>], fields: CpQuoterFields<W>, ) { this.$fullTypeName = composeSuiType( CpQuoter.$typeName, ...typeArgs ) as `${typeof PKG_V1}::cpmm::CpQuoter<${PhantomToTypeStr<W>}>`; this.$typeArgs = typeArgs;

 this.version = fields.version;; this.offset = fields.offset; }

 static reified<W extends PhantomReified<PhantomTypeArgument>>( W: W ): CpQuoterReified<ToPhantomTypeArgument<W>> { return { typeName: CpQuoter.$typeName, fullTypeName: composeSuiType( CpQuoter.$typeName, ...[extractType(W)] ) as `${typeof PKG_V1}::cpmm::CpQuoter<${PhantomToTypeStr<ToPhantomTypeArgument<W>>}>`, typeArgs: [ extractType(W) ] as [PhantomToTypeStr<ToPhantomTypeArgument<W>>], isPhantom: CpQuoter.$isPhantom, reifiedTypeArgs: [W], fromFields: (fields: Record<string, any>) => CpQuoter.fromFields( W, fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => CpQuoter.fromFieldsWithTypes( W, item, ), fromBcs: (data: Uint8Array) => CpQuoter.fromBcs( W, data, ), bcs: CpQuoter.bcs, fromJSONField: (field: any) => CpQuoter.fromJSONField( W, field, ), fromJSON: (json: Record<string, any>) => CpQuoter.fromJSON( W, json, ), fromSuiParsedData: (content: SuiParsedData) => CpQuoter.fromSuiParsedData( W, content, ), fromSuiObjectData: (content: SuiObjectData) => CpQuoter.fromSuiObjectData( W, content, ), fetch: async (client: SuiClient, id: string) => CpQuoter.fetch( client, W, id, ), new: ( fields: CpQuoterFields<ToPhantomTypeArgument<W>>, ) => { return new CpQuoter( [extractType(W)], fields ) }, kind: "StructClassReified", } }

 static get r() { return CpQuoter.reified }

 static phantom<W extends PhantomReified<PhantomTypeArgument>>( W: W ): PhantomReified<ToTypeStr<CpQuoter<ToPhantomTypeArgument<W>>>> { return phantom(CpQuoter.reified( W )); } static get p() { return CpQuoter.phantom }

 static get bcs() { return bcs.struct("CpQuoter", {

 version: Version.bcs, offset: bcs.u64()

}) };

 static fromFields<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, fields: Record<string, any> ): CpQuoter<ToPhantomTypeArgument<W>> { return CpQuoter.reified( typeArg, ).new( { version: decodeFromFields(Version.reified(), fields.version), offset: decodeFromFields("u64", fields.offset) } ) }

 static fromFieldsWithTypes<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, item: FieldsWithTypes ): CpQuoter<ToPhantomTypeArgument<W>> { if (!isCpQuoter(item.type)) { throw new Error("not a CpQuoter type");

 } assertFieldsWithTypesArgsMatch(item, [typeArg]);

 return CpQuoter.reified( typeArg, ).new( { version: decodeFromFieldsWithTypes(Version.reified(), item.fields.version), offset: decodeFromFieldsWithTypes("u64", item.fields.offset) } ) }

 static fromBcs<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, data: Uint8Array ): CpQuoter<ToPhantomTypeArgument<W>> { return CpQuoter.fromFields( typeArg, CpQuoter.bcs.parse(data) ) }

 toJSONField() { return {

 version: this.version.toJSONField(),offset: this.offset.toString(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, field: any ): CpQuoter<ToPhantomTypeArgument<W>> { return CpQuoter.reified( typeArg, ).new( { version: decodeFromJSONField(Version.reified(), field.version), offset: decodeFromJSONField("u64", field.offset) } ) }

 static fromJSON<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, json: Record<string, any> ): CpQuoter<ToPhantomTypeArgument<W>> { if (json.$typeName !== CpQuoter.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(CpQuoter.$typeName, extractType(typeArg)), json.$typeArgs, [typeArg], )

 return CpQuoter.fromJSONField( typeArg, json, ) }

 static fromSuiParsedData<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, content: SuiParsedData ): CpQuoter<ToPhantomTypeArgument<W>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isCpQuoter(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a CpQuoter object`); } return CpQuoter.fromFieldsWithTypes( typeArg, content ); }

 static fromSuiObjectData<W extends PhantomReified<PhantomTypeArgument>>( typeArg: W, data: SuiObjectData ): CpQuoter<ToPhantomTypeArgument<W>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isCpQuoter(data.bcs.type)) { throw new Error(`object at is not a CpQuoter object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 1) { throw new Error(`type argument mismatch: expected 1 type argument but got '${gotTypeArgs.length}'`); }; const gotTypeArg = compressSuiType(gotTypeArgs[0]); const expectedTypeArg = compressSuiType(extractType(typeArg)); if (gotTypeArg !== compressSuiType(extractType(typeArg))) { throw new Error(`type argument mismatch: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); };

 return CpQuoter.fromBcs( typeArg, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return CpQuoter.fromSuiParsedData( typeArg, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<W extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArg: W, id: string ): Promise<CpQuoter<ToPhantomTypeArgument<W>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching CpQuoter object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isCpQuoter(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a CpQuoter object`); }

 return CpQuoter.fromSuiObjectData( typeArg, res.data ); }

 }
