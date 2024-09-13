import {
  PhantomReified,
  PhantomToTypeStr,
  PhantomTypeArgument,
  Reified,
  StructClass,
  ToField,
  ToPhantomTypeArgument,
  ToTypeStr,
  assertFieldsWithTypesArgsMatch,
  assertReifiedTypeArgsMatch,
  decodeFromFields,
  decodeFromFieldsWithTypes,
  decodeFromJSONField,
  extractType,
  phantom,
} from "../../_framework/reified";
import {
  FieldsWithTypes,
  composeSuiType,
  compressSuiType,
  parseTypeName,
} from "../../_framework/util";
import { PKG_V1 } from "../index";
import { Version } from "../version/structs";
import { bcs } from "@mysten/sui/bcs";
import { SuiClient, SuiObjectData, SuiParsedData } from "@mysten/sui/client";
import { fromB64 } from "@mysten/sui/utils";

/* ============================== Hook =============================== */

export function isHook(type: string): boolean {
  type = compressSuiType(type);
  return type.startsWith(`${PKG_V1}::cpmm::Hook` + "<");
}

export interface HookFields<W extends PhantomTypeArgument> {
  dummyField: ToField<"bool">;
}

export type HookReified<W extends PhantomTypeArgument> = Reified<
  Hook<W>,
  HookFields<W>
>;

export class Hook<W extends PhantomTypeArgument> implements StructClass {
  __StructClass = true as const;

  static readonly $typeName = `${PKG_V1}::cpmm::Hook`;
  static readonly $numTypeParams = 1;
  static readonly $isPhantom = [true] as const;

  readonly $typeName = Hook.$typeName;
  readonly $fullTypeName: `${typeof PKG_V1}::cpmm::Hook<${PhantomToTypeStr<W>}>`;
  readonly $typeArgs: [PhantomToTypeStr<W>];
  readonly $isPhantom = Hook.$isPhantom;

  readonly dummyField: ToField<"bool">;

  private constructor(typeArgs: [PhantomToTypeStr<W>], fields: HookFields<W>) {
    this.$fullTypeName = composeSuiType(
      Hook.$typeName,
      ...typeArgs
    ) as `${typeof PKG_V1}::cpmm::Hook<${PhantomToTypeStr<W>}>`;
    this.$typeArgs = typeArgs;

    this.dummyField = fields.dummyField;
  }

  static reified<W extends PhantomReified<PhantomTypeArgument>>(
    W: W
  ): HookReified<ToPhantomTypeArgument<W>> {
    return {
      typeName: Hook.$typeName,
      fullTypeName: composeSuiType(
        Hook.$typeName,
        ...[extractType(W)]
      ) as `${typeof PKG_V1}::cpmm::Hook<${PhantomToTypeStr<
        ToPhantomTypeArgument<W>
      >}>`,
      typeArgs: [extractType(W)] as [
        PhantomToTypeStr<ToPhantomTypeArgument<W>>
      ],
      isPhantom: Hook.$isPhantom,
      reifiedTypeArgs: [W],
      fromFields: (fields: Record<string, any>) => Hook.fromFields(W, fields),
      fromFieldsWithTypes: (item: FieldsWithTypes) =>
        Hook.fromFieldsWithTypes(W, item),
      fromBcs: (data: Uint8Array) => Hook.fromBcs(W, data),
      bcs: Hook.bcs,
      fromJSONField: (field: any) => Hook.fromJSONField(W, field),
      fromJSON: (json: Record<string, any>) => Hook.fromJSON(W, json),
      fromSuiParsedData: (content: SuiParsedData) =>
        Hook.fromSuiParsedData(W, content),
      fromSuiObjectData: (content: SuiObjectData) =>
        Hook.fromSuiObjectData(W, content),
      fetch: async (client: SuiClient, id: string) => Hook.fetch(client, W, id),
      new: (fields: HookFields<ToPhantomTypeArgument<W>>) => {
        return new Hook([extractType(W)], fields);
      },
      kind: "StructClassReified",
    };
  }

  static get r() {
    return Hook.reified;
  }

  static phantom<W extends PhantomReified<PhantomTypeArgument>>(
    W: W
  ): PhantomReified<ToTypeStr<Hook<ToPhantomTypeArgument<W>>>> {
    return phantom(Hook.reified(W));
  }
  static get p() {
    return Hook.phantom;
  }

  static get bcs() {
    return bcs.struct("Hook", {
      dummy_field: bcs.bool(),
    });
  }

  static fromFields<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    fields: Record<string, any>
  ): Hook<ToPhantomTypeArgument<W>> {
    return Hook.reified(typeArg).new({
      dummyField: decodeFromFields("bool", fields.dummy_field),
    });
  }

  static fromFieldsWithTypes<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    item: FieldsWithTypes
  ): Hook<ToPhantomTypeArgument<W>> {
    if (!isHook(item.type)) {
      throw new Error("not a Hook type");
    }
    assertFieldsWithTypesArgsMatch(item, [typeArg]);

    return Hook.reified(typeArg).new({
      dummyField: decodeFromFieldsWithTypes("bool", item.fields.dummy_field),
    });
  }

  static fromBcs<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    data: Uint8Array
  ): Hook<ToPhantomTypeArgument<W>> {
    return Hook.fromFields(typeArg, Hook.bcs.parse(data));
  }

  toJSONField() {
    return {
      dummyField: this.dummyField,
    };
  }

  toJSON() {
    return {
      $typeName: this.$typeName,
      $typeArgs: this.$typeArgs,
      ...this.toJSONField(),
    };
  }

  static fromJSONField<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    field: any
  ): Hook<ToPhantomTypeArgument<W>> {
    return Hook.reified(typeArg).new({
      dummyField: decodeFromJSONField("bool", field.dummyField),
    });
  }

  static fromJSON<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    json: Record<string, any>
  ): Hook<ToPhantomTypeArgument<W>> {
    if (json.$typeName !== Hook.$typeName) {
      throw new Error("not a WithTwoGenerics json object");
    }
    assertReifiedTypeArgsMatch(
      composeSuiType(Hook.$typeName, extractType(typeArg)),
      json.$typeArgs,
      [typeArg]
    );

    return Hook.fromJSONField(typeArg, json);
  }

  static fromSuiParsedData<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    content: SuiParsedData
  ): Hook<ToPhantomTypeArgument<W>> {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isHook(content.type)) {
      throw new Error(
        `object at ${(content.fields as any).id} is not a Hook object`
      );
    }
    return Hook.fromFieldsWithTypes(typeArg, content);
  }

  static fromSuiObjectData<W extends PhantomReified<PhantomTypeArgument>>(
    typeArg: W,
    data: SuiObjectData
  ): Hook<ToPhantomTypeArgument<W>> {
    if (data.bcs) {
      if (data.bcs.dataType !== "moveObject" || !isHook(data.bcs.type)) {
        throw new Error(`object at is not a Hook object`);
      }

      const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs;
      if (gotTypeArgs.length !== 1) {
        throw new Error(
          `type argument mismatch: expected 1 type argument but got '${gotTypeArgs.length}'`
        );
      }
      const gotTypeArg = compressSuiType(gotTypeArgs[0]);
      const expectedTypeArg = compressSuiType(extractType(typeArg));
      if (gotTypeArg !== compressSuiType(extractType(typeArg))) {
        throw new Error(
          `type argument mismatch: expected '${expectedTypeArg}' but got '${gotTypeArg}'`
        );
      }

      return Hook.fromBcs(typeArg, fromB64(data.bcs.bcsBytes));
    }
    if (data.content) {
      return Hook.fromSuiParsedData(typeArg, data.content);
    }
    throw new Error(
      "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request."
    );
  }

  static async fetch<W extends PhantomReified<PhantomTypeArgument>>(
    client: SuiClient,
    typeArg: W,
    id: string
  ): Promise<Hook<ToPhantomTypeArgument<W>>> {
    const res = await client.getObject({ id, options: { showBcs: true } });
    if (res.error) {
      throw new Error(
        `error fetching Hook object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.bcs?.dataType !== "moveObject" ||
      !isHook(res.data.bcs.type)
    ) {
      throw new Error(`object at id ${id} is not a Hook object`);
    }

    return Hook.fromSuiObjectData(typeArg, res.data);
  }
}

/* ============================== State =============================== */

export function isState(type: string): boolean {
  type = compressSuiType(type);
  return type === `${PKG_V1}::cpmm::State`;
}

export interface StateFields {
  version: ToField<Version>;
  offset: ToField<"u64">;
}

export type StateReified = Reified<State, StateFields>;

export class State implements StructClass {
  __StructClass = true as const;

  static readonly $typeName = `${PKG_V1}::cpmm::State`;
  static readonly $numTypeParams = 0;
  static readonly $isPhantom = [] as const;

  readonly $typeName = State.$typeName;
  readonly $fullTypeName: `${typeof PKG_V1}::cpmm::State`;
  readonly $typeArgs: [];
  readonly $isPhantom = State.$isPhantom;

  readonly version: ToField<Version>;
  readonly offset: ToField<"u64">;

  private constructor(typeArgs: [], fields: StateFields) {
    this.$fullTypeName = composeSuiType(
      State.$typeName,
      ...typeArgs
    ) as `${typeof PKG_V1}::cpmm::State`;
    this.$typeArgs = typeArgs;

    this.version = fields.version;
    this.offset = fields.offset;
  }

  static reified(): StateReified {
    return {
      typeName: State.$typeName,
      fullTypeName: composeSuiType(
        State.$typeName,
        ...[]
      ) as `${typeof PKG_V1}::cpmm::State`,
      typeArgs: [] as [],
      isPhantom: State.$isPhantom,
      reifiedTypeArgs: [],
      fromFields: (fields: Record<string, any>) => State.fromFields(fields),
      fromFieldsWithTypes: (item: FieldsWithTypes) =>
        State.fromFieldsWithTypes(item),
      fromBcs: (data: Uint8Array) => State.fromBcs(data),
      bcs: State.bcs,
      fromJSONField: (field: any) => State.fromJSONField(field),
      fromJSON: (json: Record<string, any>) => State.fromJSON(json),
      fromSuiParsedData: (content: SuiParsedData) =>
        State.fromSuiParsedData(content),
      fromSuiObjectData: (content: SuiObjectData) =>
        State.fromSuiObjectData(content),
      fetch: async (client: SuiClient, id: string) => State.fetch(client, id),
      new: (fields: StateFields) => {
        return new State([], fields);
      },
      kind: "StructClassReified",
    };
  }

  static get r() {
    return State.reified();
  }

  static phantom(): PhantomReified<ToTypeStr<State>> {
    return phantom(State.reified());
  }
  static get p() {
    return State.phantom();
  }

  static get bcs() {
    return bcs.struct("State", {
      version: Version.bcs,
      offset: bcs.u64(),
    });
  }

  static fromFields(fields: Record<string, any>): State {
    return State.reified().new({
      version: decodeFromFields(Version.reified(), fields.version),
      offset: decodeFromFields("u64", fields.offset),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): State {
    if (!isState(item.type)) {
      throw new Error("not a State type");
    }

    return State.reified().new({
      version: decodeFromFieldsWithTypes(
        Version.reified(),
        item.fields.version
      ),
      offset: decodeFromFieldsWithTypes("u64", item.fields.offset),
    });
  }

  static fromBcs(data: Uint8Array): State {
    return State.fromFields(State.bcs.parse(data));
  }

  toJSONField() {
    return {
      version: this.version.toJSONField(),
      offset: this.offset.toString(),
    };
  }

  toJSON() {
    return {
      $typeName: this.$typeName,
      $typeArgs: this.$typeArgs,
      ...this.toJSONField(),
    };
  }

  static fromJSONField(field: any): State {
    return State.reified().new({
      version: decodeFromJSONField(Version.reified(), field.version),
      offset: decodeFromJSONField("u64", field.offset),
    });
  }

  static fromJSON(json: Record<string, any>): State {
    if (json.$typeName !== State.$typeName) {
      throw new Error("not a WithTwoGenerics json object");
    }

    return State.fromJSONField(json);
  }

  static fromSuiParsedData(content: SuiParsedData): State {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isState(content.type)) {
      throw new Error(
        `object at ${(content.fields as any).id} is not a State object`
      );
    }
    return State.fromFieldsWithTypes(content);
  }

  static fromSuiObjectData(data: SuiObjectData): State {
    if (data.bcs) {
      if (data.bcs.dataType !== "moveObject" || !isState(data.bcs.type)) {
        throw new Error(`object at is not a State object`);
      }

      return State.fromBcs(fromB64(data.bcs.bcsBytes));
    }
    if (data.content) {
      return State.fromSuiParsedData(data.content);
    }
    throw new Error(
      "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request."
    );
  }

  static async fetch(client: SuiClient, id: string): Promise<State> {
    const res = await client.getObject({ id, options: { showBcs: true } });
    if (res.error) {
      throw new Error(
        `error fetching State object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.bcs?.dataType !== "moveObject" ||
      !isState(res.data.bcs.type)
    ) {
      throw new Error(`object at id ${id} is not a State object`);
    }

    return State.fromSuiObjectData(res.data);
  }
}
