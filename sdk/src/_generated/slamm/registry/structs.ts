import * as reified from "../../_framework/reified";
import {TypeName} from "../../_dependencies/source/0x1/type-name/structs";
import {ID, UID} from "../../_dependencies/source/0x2/object/structs";
import {Table} from "../../_dependencies/source/0x2/table/structs";
import {PhantomReified, Reified, StructClass, ToField, ToTypeStr, decodeFromFields, decodeFromFieldsWithTypes, decodeFromJSONField, phantom, ToTypeStr as ToPhantom} from "../../_framework/reified";
import {FieldsWithTypes, composeSuiType, compressSuiType} from "../../_framework/util";
import {PKG_V1} from "../index";
import {bcs} from "@mysten/sui/bcs";
import {SuiClient, SuiObjectData, SuiParsedData} from "@mysten/sui/client";
import {fromB64} from "@mysten/sui/utils";

/* ============================== Registry =============================== */

export function isRegistry(type: string): boolean { type = compressSuiType(type); return type === `${PKG_V1}::registry::Registry`; }

export interface RegistryFields { id: ToField<UID>; version: ToField<"u16">; amms: ToField<Table<ToPhantom<TypeName>, ToPhantom<ID>>>; banks: ToField<Table<ToPhantom<TypeName>, ToPhantom<ID>>> }

export type RegistryReified = Reified< Registry, RegistryFields >;

export class Registry implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::registry::Registry`; static readonly $numTypeParams = 0; static readonly $isPhantom = [] as const;

 readonly $typeName = Registry.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::registry::Registry`; readonly $typeArgs: []; readonly $isPhantom = Registry.$isPhantom;

 readonly id: ToField<UID>; readonly version: ToField<"u16">; readonly amms: ToField<Table<ToPhantom<TypeName>, ToPhantom<ID>>>; readonly banks: ToField<Table<ToPhantom<TypeName>, ToPhantom<ID>>>

 private constructor(typeArgs: [], fields: RegistryFields, ) { this.$fullTypeName = composeSuiType( Registry.$typeName, ...typeArgs ) as `${typeof PKG_V1}::registry::Registry`; this.$typeArgs = typeArgs;

 this.id = fields.id;; this.version = fields.version;; this.amms = fields.amms;; this.banks = fields.banks; }

 static reified( ): RegistryReified { return { typeName: Registry.$typeName, fullTypeName: composeSuiType( Registry.$typeName, ...[] ) as `${typeof PKG_V1}::registry::Registry`, typeArgs: [ ] as [], isPhantom: Registry.$isPhantom, reifiedTypeArgs: [], fromFields: (fields: Record<string, any>) => Registry.fromFields( fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => Registry.fromFieldsWithTypes( item, ), fromBcs: (data: Uint8Array) => Registry.fromBcs( data, ), bcs: Registry.bcs, fromJSONField: (field: any) => Registry.fromJSONField( field, ), fromJSON: (json: Record<string, any>) => Registry.fromJSON( json, ), fromSuiParsedData: (content: SuiParsedData) => Registry.fromSuiParsedData( content, ), fromSuiObjectData: (content: SuiObjectData) => Registry.fromSuiObjectData( content, ), fetch: async (client: SuiClient, id: string) => Registry.fetch( client, id, ), new: ( fields: RegistryFields, ) => { return new Registry( [], fields ) }, kind: "StructClassReified", } }

 static get r() { return Registry.reified() }

 static phantom( ): PhantomReified<ToTypeStr<Registry>> { return phantom(Registry.reified( )); } static get p() { return Registry.phantom() }

 static get bcs() { return bcs.struct("Registry", {

 id: UID.bcs, version: bcs.u16(), amms: Table.bcs, banks: Table.bcs

}) };

 static fromFields( fields: Record<string, any> ): Registry { return Registry.reified( ).new( { id: decodeFromFields(UID.reified(), fields.id), version: decodeFromFields("u16", fields.version), amms: decodeFromFields(Table.reified(reified.phantom(TypeName.reified()), reified.phantom(ID.reified())), fields.amms), banks: decodeFromFields(Table.reified(reified.phantom(TypeName.reified()), reified.phantom(ID.reified())), fields.banks) } ) }

 static fromFieldsWithTypes( item: FieldsWithTypes ): Registry { if (!isRegistry(item.type)) { throw new Error("not a Registry type");

 }

 return Registry.reified( ).new( { id: decodeFromFieldsWithTypes(UID.reified(), item.fields.id), version: decodeFromFieldsWithTypes("u16", item.fields.version), amms: decodeFromFieldsWithTypes(Table.reified(reified.phantom(TypeName.reified()), reified.phantom(ID.reified())), item.fields.amms), banks: decodeFromFieldsWithTypes(Table.reified(reified.phantom(TypeName.reified()), reified.phantom(ID.reified())), item.fields.banks) } ) }

 static fromBcs( data: Uint8Array ): Registry { return Registry.fromFields( Registry.bcs.parse(data) ) }

 toJSONField() { return {

 id: this.id,version: this.version,amms: this.amms.toJSONField(),banks: this.banks.toJSONField(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField( field: any ): Registry { return Registry.reified( ).new( { id: decodeFromJSONField(UID.reified(), field.id), version: decodeFromJSONField("u16", field.version), amms: decodeFromJSONField(Table.reified(reified.phantom(TypeName.reified()), reified.phantom(ID.reified())), field.amms), banks: decodeFromJSONField(Table.reified(reified.phantom(TypeName.reified()), reified.phantom(ID.reified())), field.banks) } ) }

 static fromJSON( json: Record<string, any> ): Registry { if (json.$typeName !== Registry.$typeName) { throw new Error("not a WithTwoGenerics json object") };

 return Registry.fromJSONField( json, ) }

 static fromSuiParsedData( content: SuiParsedData ): Registry { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isRegistry(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a Registry object`); } return Registry.fromFieldsWithTypes( content ); }

 static fromSuiObjectData( data: SuiObjectData ): Registry { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isRegistry(data.bcs.type)) { throw new Error(`object at is not a Registry object`); }

 return Registry.fromBcs( fromB64(data.bcs.bcsBytes) ); } if (data.content) { return Registry.fromSuiParsedData( data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch( client: SuiClient, id: string ): Promise<Registry> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching Registry object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isRegistry(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a Registry object`); }

 return Registry.fromSuiObjectData( res.data ); }

 }
