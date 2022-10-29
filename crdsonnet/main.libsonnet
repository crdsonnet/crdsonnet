{
  local root = self,

  local getID(schema) =
    if '$id' in schema
    then schema['$id']
    else if 'id' in schema
    then schema.id
    else '',  //std.trace("Can't find '$id' (or 'id') in schema", ''),

  local getRefName(ref) =
    std.reverse(std.split(ref, '/'))[0],

  parser:: {
    local this = self,

    fromSchema(name, schema, schemaDB):
      local parsed = this.parseSchema(
        name,
        schema,
        schema,
        schemaDB
      ) + { [name]+: { _name: name } };
      r.properties(root.render.schema(parsed[name])),

    parseSchema(key, schema, currentSchema, schemaDB, parents=[]):
      // foldStart
      if std.isBoolean(schema)
      then { [key]+: schema }
      else if !std.isObject(schema)
      then error 'Schema is not an object or boolean'
      else
        local schemaToParse =
          if '$ref' in schema
          then this.resolveRef(
            schema['$ref'],
            currentSchema,
            schemaDB
          )
          else schema;

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
            + parse('items', this.parseSchemaSingle)
            + parse('then', this.parseSchemaSingle)
            + parse('else', this.parseSchemaSingle)
            + parse('prefixItems', this.parseSchemaList)
            + parse('allOf', this.parseSchemaList)
            + parse('anyOf', this.parseSchemaList)
            + parse('oneOf', this.parseSchemaList)
            + { _parents: parents },
        }
    ,
    // foldEnd

    parseSchemaSingle(key, schema, currentSchema, schemaDB, parents):
      // foldStart
      local parsed =
        this.parseSchema(
          key,
          schema,
          currentSchema,
          schemaDB,
          parents[0:std.length(parents) - 1]
        );
      if parsed != null
      then
        if std.isObject(parsed[key])
        then parsed[key] { _name: key }
        else parsed[key]
      else {},
    // foldEnd

    parseSchemaMap(key, map, currentSchema, schemaDB, parents):
      // foldStart
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
          + { [k]+: { _name: k } },
        std.objectFields(map),
        {}
      ),
    // foldEnd

    parseSchemaList(key, list, currentSchema, schemaDB, parents):
      // foldStart
      [
        local a =
          if std.isObject(item)
             && '$ref' in item
          then parents + [getRefName(item['$ref'])]
          else parents;

        local parsed =
          this.parseSchema(
            key,
            item,
            currentSchema,
            schemaDB,
            a,
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
          then getRefName(item['$ref'])
          else '';

        // Because order may matter (for example for prefixItems), we return a list.
        parsed { [if name != '' then '_name']: name }
        for item in list
      ],
    // foldEnd

    resolveRef(ref, currentSchema, schemaDB):
      // foldStart
      local getFragment(baseURI, ref) =
        local split = std.splitLimit(ref, '#', 2);
        local schema = schemaDB.get(baseURI + split[0]);
        if schema != {}
        then
          this.resolveRef(
            '#' + split[1],
            schemaDB.get(baseURI + split[0]),
            schemaDB,
          )
        else {};

      // Absolute URI
      if std.startsWith(ref, 'https://')
      then
        local baseURI = std.join('/', std.splitLimit(ref, '/', 5)[0:3]);
        local path = '/' + std.join('/', std.splitLimit(ref, '/', 5)[3:]);
        if std.member(ref, '#')
        // Absolute URI with fragment
        then getFragment(baseURI, path)
        // Absolute URI
        else schemaDB.get(baseURI + path)

      // Relative reference
      else if std.startsWith(ref, '/')
      then
        local baseURI = std.join('/', std.splitLimit(getID(currentSchema), '/', 5)[0:3]);
        if std.member(ref, '#')
        // Relative reference with fragment
        then getFragment(baseURI, ref)
        // Relative reference
        else schemaDB.get(baseURI + ref)

      // Fragment only
      else if std.startsWith(ref, '#')
      then
        local split = std.split(ref, '/')[1:];
        local find(schema, keys) =
          local key = keys[0];
          if std.length(keys) == 1
          then schema[key]
          else find(schema[key], keys[1:]);
        find(currentSchema, split)

      else {},
    // foldEnd
  },

  local r = import 'static.libsonnet',

  render:: {
    local this = self,

    schema(schema):
      // foldStart
      if 'type' in schema
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

      else if 'const' in schema
      then self.const(schema)  // value is a constant

      else if 'enum' in schema
      then self.other(schema)  // value is one of a list

      else if 'allOf' in schema
              || 'anyOf' in schema
              || 'oneOf' in schema
      then
        self.functions(schema)
        + self.complex(schema)  // value can be xOf

      else self.other(schema)
    ,
    // foldEnd

    other(schema): r.withFunction(schema._name, schema._parents, schema),

    const(schema): r.withConstant(schema._name, schema._parents, schema),

    boolean(schema): r.withBoolean(schema._name, schema._parents, schema),

    functions(schema):
      // foldStart
      if std.length(schema._parents) != 0
      then r.withFunction(schema._name, schema._parents, schema)
           + r.mixinFunction(schema._name, schema._parents, schema)
      else r.nilvalue,
    // foldEnd

    object(schema):
      // foldStart
      self.functions(schema)
      + (
        if 'properties' in schema
        then
          r.named(
            schema._name,
            r.properties(
              std.foldl(
                function(acc, p)
                  acc + this.schema(schema.properties[p]),
                std.objectFields(schema.properties),
                r.nilvalue
              )
            )
          )
      )
      + self.complex(schema),
    // foldEnd

    array(schema):
      // foldStart
      r.arrayFunctions(schema._name, schema._parents, schema)
      + (
        if 'items' in schema && std.isObject(schema.items)
        then self.schema(schema.items)
        else r.nilvalue
      ),
    // foldEnd

    complex(schema):
      // foldStart
      local handle(schema, k) =
        if k in schema
        then
          local parsed =
            std.foldl(
              function(acc, n)
                acc
                + (if '_name' in n
                   then r.named(n._name, r.properties(this.schema(n)))
                   else r.nilvalue),
              schema[k],
              r.nilvalue
            );
          r.named(
            schema._name,
            r.properties(
              r.named(
                k,  // expose under 'xOf' to express intent
                r.properties(
                  parsed
                )
              )
              + r.named(
                'types',  // expose under 'types' for backwards compat
                r.properties(
                  parsed
                )
              )
            )
          )
        else r.nilvalue;
      handle(schema, 'allOf')
      + handle(schema, 'anyOf')
      + handle(schema, 'oneOf'),
    // foldEnd
  },

  schemaDB:: {
    add(schema):
      local id = getID(schema);
      if id == ''
      then error "Can't add schema without id"
      else {
        get(name):
          if name in self.schemas
          then self.schemas[name]
          else {},
        schemas+: { [id]: schema },
      },
  },

  local schemaDB =
    root.schemaDB.add({
      '$id': 'https://example.com/schemas/address',

      type: 'object',
      properties: {
        street_address: { type: 'string' },
        city: { type: 'string' },
        state: { type: 'string' },
        country: {
          default: 'United States of America',
          enum: ['United States of America', 'Canada'],
        },
      },
      'if': {
        properties: { country: { const: 'United States of America' } },
      },
      'then': {
        properties: { postal_code:
          { pattern: '[0-9]{5}(-[0-9]{4})?' } },
      },
      'else': {
        properties:
          { postal_code:
            { pattern:
              '[A-Z][0-9][A-Z][0-9][A-Z][0-9]' } },
      },
      required: ['street_address', 'city', 'state'],
    })

    + root.schemaDB.add({
      '$id': 'https://example.com/schemas/customer',

      type: 'object',
      properties: {
        first_name: { type: 'string' },
        last_name: { type: 'string' },
        shipping_address: { '$ref': '/schemas/address' },
        billing_address: { '$ref': '/schemas/address' },
        discount: { const: '10%' },
        deleted: { type: 'boolean', default: false },
        asl: {
          type: 'array',
          prefixItems: [
            { '$anchor': 'age', type: 'number' },
            { '$anchor': 'sex', type: 'string', maxLength: 1, enum: ['m', 'f'] },
            { '$anchor': 'location', '$ref': '/schema/address' },
          ],
          items: false,
        },
        store: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              location: { '$ref': '/schemas/address' },
            },
          },
        },
        tt: {
          anyOf: [
            { '$ref': '/schemas/address' },
            { '$anchor': 'age', type: 'number' },
          ],
        },
      },
      required: ['first_name', 'last_name', 'shipping_address', 'billing_address'],
    }),

  local testSchemas = [
    {
      // non-existent schema ID
      '$ref': '/schema/does/not/exist',
    },
    {
      // non-existent schema ID with fragment
      '$ref': '/schema/does/not/exist#/fragment/does/not/exist',
    },
    {
      // Fragment only
      '$ref': '#/properties/first_name',
      properties: {
        first_name: { type: 'string' },
      },
    },
    {
      // Relative reference
      '$id': 'https://example.com/schemas/random',
      '$ref': '/schemas/customer',
    },
    {
      // Relative reference with fragment
      '$id': 'https://example.com/schemas/random',
      '$ref': '/schemas/customer#/properties/first_name',
    },
    {
      // Absolute URI
      '$id': 'https://example.com/schemas/random',
      '$ref': 'https://example.com/schemas/customer',
    },
    {
      // Absolute URI, no id
      '$ref': 'https://example.com/schemas/customer',
    },
    {
      // Absolute URI with fragment
      '$id': 'https://example.com/schemas/random',
      '$ref': 'https://example.com/schemas/customer#/properties/first_name',
    },
  ],

  local schema = schemaDB.schemas['https://example.com/schemas/customer'],
  parsed: root.parser.fromSchema(
    getRefName(getID(schema)),
    schema,
    schemaDB
  ),
  //  parsed: [
  //    root.parser.fromSchema(schema, schemaDB)
  //    for schema in testSchemas
  //  ],
}.parsed

// vim: foldmethod=marker foldmarker=foldStart,foldEnd
