local resolver = import './resolver.libsonnet';
{
  local this = self,

  resolveRef: resolver.resolve,

  getRefName(ref): std.reverse(std.split(ref, '/'))[0],

  parseSchema(key, schema, currentSchema, schemaDB={}, parents=[]):
    if std.isBoolean(schema)
    then { [key]+: schema }
    else if !std.isObject(schema)
    then error 'Schema is not an object or boolean'
    else
      local schemaToParse =
        resolver.resolveRef(
          schema,
          currentSchema,
          schemaDB
        );

      // shortcut to make it more readable below
      // requires the parseSchema* functions to have the same signature
      local parse(k, f) =
        (if k in schemaToParse
         then
           local parsed = f(
             key,
             schemaToParse[k],
             currentSchema,
             schemaDB,
             parents,
           );
           if parsed != null
           then { [k]: parsed }
           else {}
         else {});

      {
        [key]+:
          schemaToParse
          + parse('properties', this.parseSchemaMap)
          + parse('patternProperties', this.parseSchemaMap)
          + parse('items', this.parseSchemaItems)
          + parse('then', this.parseSchemaSingle)
          + parse('else', this.parseSchemaSingle)
          + parse('prefixItems', this.parseSchemaList)
          + parse('allOf', this.parseSchemaList)
          + parse('anyOf', this.parseSchemaList)
          + parse('oneOf', this.parseSchemaList)
          + { _parents:: parents },
      }
  ,

  parseSchemaItems(key, schema, currentSchema, schemaDB, parents):
    self.parseSchemaSingle(key, schema, currentSchema, schemaDB, []),

  parseSchemaSingle(key, schema, currentSchema, schemaDB, parents):
    local i =
      if std.length(parents) > 0
      then std.length(parents) - 1
      else 0;

    local parsed =
      this.parseSchema(
        key,
        schema,
        currentSchema,
        schemaDB,
        parents[0:i]
      );
    if parsed != null
    then
      if std.isObject(parsed[key])
      then parsed[key] + { _name:: key }
      else parsed[key]
    else {},

  parseSchemaMap(key, map, currentSchema, schemaDB, parents):
    std.foldl(
      function(acc, k)
        acc
        + this.parseSchema(
          k,
          map[k],
          currentSchema,
          schemaDB,
          parents + [k],
        )
        + { [k]+: { _name:: k } },
      std.objectFields(map),
      {}
    ),

  parseSchemaList(key, list, currentSchema, schemaDB, parents):
    [
      local parsed =
        this.parseSchema(
          key,
          item,
          currentSchema,
          schemaDB,
          parents,
        )[key];

      // Due to the nature of list items in JSON they don't have a key we can use as
      // a name. However we can deduct the name from $ref or use $anchor if those are
      // available. The name can later be used to create proper functions.
      local name =
        if std.isObject(item)
           && '$anchor' in item
        then item['$anchor']
        else if std.isObject(item)
                && '$ref' in item
        then this.getRefName(item['$ref'])
        else '';

      // Because order may matter (for example for prefixItems), we return a list.
      parsed + { [if name != '' then '_name']:: name }
      for item in list
    ],
}
