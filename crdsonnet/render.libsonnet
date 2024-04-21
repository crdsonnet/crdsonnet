local helpers = import './helpers.libsonnet';
local engines = import './renderEngines/main.libsonnet';
local astutils = import 'github.com/crdsonnet/astsonnet/utils.libsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  '#': d.package.newSub(
    'renderEngine',
    '`renderEngine` provides an interface to create a renderEngine.',
  ),

  '#new': d.fn(
    '`new` returns a renderEngine.',
    args=[
      d.arg(
        'engineType',
        d.T.string,
        enums=std.objectFields(engines)
      ),
    ],
  ),
  new(engineType): {
    engine: engines[engineType],
    camelCaseFields: false,
    local r = self.engine,

    nilvalue: r.nilvalue,
    toObject: r.toObject,
    nestInParents(parents, object): r.nestInParents('', parents, object),
    newFunction: r.newFunction,
    mergeFields(fields):
      if engineType == 'ast'
      then astutils.deepMergeObjectFields(fields)
      else fields,

    withCamelCaseFields():: {
      camelCaseFields: true,
    },

    render(schema):
      r.toObject(self.schema(schema)),

    schema(schema):
      if 'const' in schema
      then self.const(schema)  // value is a constant

      else if 'type' in schema
      then
        if std.isBoolean(schema.type)
        then
          if schema.type
          then self.other(schema)  // Any value allowed
          else r.nilvalue  // No value allowed

        else if std.isArray(schema.type)
        then self.other(schema)  // Multiple types

        else if schema.type == 'object'
        then self.object(schema)  // type=object

        else if schema.type == 'array'
        then self.array(schema)  // type=array

        else if schema.type == 'boolean'
        then self.boolean(schema)  // type=boolean

        else self.other(schema)  // any other type

      else if 'allOf' in schema
              || 'anyOf' in schema
              || 'oneOf' in schema
      then self.xof(schema)  // value can be xOf

      else self.other(schema)
    ,

    nameParsed(schema, parsed):
      if '_name' in schema
         && parsed != r.nilvalue
      then
        r.named(
          if self.camelCaseFields then
            xtd.camelcase.toCamelCase(schema._name)
          else schema._name,
          r.toObject(
            parsed
          )
        )
      else
        parsed
    ,

    functions(schema):
      if std.length(schema._parents) != 0 && '_name' in schema
      then r.withFunction(schema)
           + r.mixinFunction(schema)
      else r.nilvalue,

    xofParts(schema):
      local handle(schema, k) =
        if k in schema
        then
          std.foldl(
            function(acc, n)
              acc + self.schema(n),
            schema[k],
            r.nilvalue
          )
        else r.nilvalue;
      {
        allOf: handle(schema, 'allOf'),
        anyOf: handle(schema, 'anyOf'),
        oneOf: handle(schema, 'oneOf'),

        combined:
          handle(schema, 'allOf')
          + handle(schema, 'anyOf')
          + handle(schema, 'oneOf'),
      },

    const(schema):
      if '_name' in schema
      then r.withConstant(schema)
      else r.nilvalue,

    boolean(schema):
      if '_name' in schema
      then r.withBoolean(schema)
      else r.nilvalue,

    other(schema):
      if std.length(schema._parents) != 0 && '_name' in schema
      then r.withFunction(schema)
      else r.nilvalue,

    object(schema):
      local properties = (
        if 'properties' in schema
        then
          std.foldl(
            function(acc, p)
              acc + self.schema(schema.properties[p]),
            std.objectFields(schema.properties),
            r.nilvalue
          )
        else r.nilvalue
      );

      local xofParts = self.xofParts(schema + { _parents: super._parents[1:] });

      local merge(parts) =
        if engineType == 'ast'
        then
          [
            member
            for part in parts
            if astutils.type(part) == 'field' && astutils.isObject(part.expr)
            for member in part.expr.members
          ]
        else if engineType == 'dynamic'
        then
          std.foldl(
            function(acc, k)
              acc +
              (if std.isObject(parts[k])
               then parts[k]
               else {}),
            std.objectFields(parts),
            {}
          )
        else parts;  // Can't merge in static mode

      // Merge allOf/anyOf as they can be used in combination with each other
      // Keep oneOf seperate as it they would not be used in combination with each other
      local parsedProperties =
        merge(xofParts.allOf)
        + merge(xofParts.anyOf)
        + xofParts.oneOf
        + properties;

      // Only create package if there are properties
      local packagedProperties =
        (if std.get(schema, '_package', false)
            && parsedProperties != r.nilvalue
         then r.objectSubpackage(schema)
         else r.nilvalue)
        + parsedProperties;

      // Deep merge to prevent duplicate keys
      local parsed =
        if engineType == 'ast'
        then astutils.deepMergeObjectFields(packagedProperties)
        else packagedProperties;

      self.functions(schema)
      + self.nameParsed(schema, parsed),

    array(schema):
      (if '_name' in schema && schema._parents != []
       then r.arrayFunctions(schema)
       else r.nilvalue)
      + (
        if 'items' in schema
           && std.isObject(schema.items)
        then self.schema(schema.items + { _parents: [], _package: true })
        else r.nilvalue
      ),

    xof(schema):
      local parsed = self.xofParts(schema).combined;
      self.functions(schema)
      + self.nameParsed(schema, parsed),
  },

  withValidation(): {
    engine+: {
      validate(schema, value)::
        local validate = import 'github.com/crdsonnet/validate-libsonnet/main.libsonnet';
        validate.checkParameters({
          [schema._name]:
            validate.schemaCheck(
              value,
              schema
            ),
        }),
    },
  },
}
