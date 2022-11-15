local crdsonnet = import './main.libsonnet';
local parser = import './parser.libsonnet';
local schemaDB = import './schemadb.libsonnet';

{
  // shortcut to return true if key does not exist
  local ifexpr(key, schema, expression=function(x) true) =
    if key in schema
    then expression(schema[key])
    else true,

  local unsupported(key, schema) =
    ifexpr(key, schema, function(v) std.trace('%s unsupported' % key, true)),

  // unused right now, would like to give cleaner output on what is wrong
  // might use testonnet instead of the custom std.all/std.any setup
  local valid(expressions, object, schema, trace=true) =
    std.all([
      if trace
      then
        std.trace(|||
          This object:
          %s
          Does not match this schema:
          %s
        ||| % [
          std.manifestJson(object),
          std.manifestJson(schema),
        ], false)
      else false
      for expression in expressions
      if !expression
    ]),

  validate(object, schema)::
    // foldStart
    if std.isBoolean(schema)
    then schema

    else if schema == {}
    then true

    else if 'const' in schema
    then object == schema.const

    else if 'enum' in schema
    then std.member(schema.enum, object)

    else if 'type' in schema
    then
      local validateType(object, type) =
        if type == 'string'
        then self.string(object, schema)

        else if type == 'integer'
        then self.integer(object, schema)

        else if type == 'number'
        then self.number(object, schema)

        else if type == 'object'
        then self.object(object, schema)

        else if type == 'array'
        then self.array(object, schema)

        else if type == 'boolean'
        then std.isBoolean(object)

        else if type == 'null'
        then std.type(object) == 'null'

        // type unknown
        else false;

      if std.isBoolean(schema.type)
      then object != null

      else if std.isArray(schema.type)
      then std.any([
        validateType(object, type)
        for type in schema.type
      ])

      else validateType(object, schema.type)

    //else if 'allOf' in schema
    //        || 'anyOf' in schema
    //        || 'oneOf' in schema
    //then self.xof(schema)  // value can be xOf

    else true
  ,
  // foldEnd

  string(object, schema)::
    // foldStart
    std.all([
      std.isString(object),
      ifexpr('minLength', schema, function(v) std.length >= v),
      ifexpr('maxLength', schema, function(v) std.length <= v),
      unsupported('pattern', schema),
      unsupported('format', schema),
    ]),
  // foldEnd

  number(object, schema)::
    // foldStart
    std.all([
      std.isNumber(object),
      ifexpr('multipleOf', schema, function(v) std.mod(object, v) == 0),
      ifexpr('minimum', schema, function(v) object >= v),
      ifexpr('maximum', schema, function(v) object <= v),
      ifexpr(
        'exclusiveMinimum',
        schema,
        function(v)
          if std.isBoolean(v)  // Draft 4
          then
            if v
            then ifexpr('minimum', schema, function(v) object > v)
            else ifexpr('minimum', schema, function(v) object >= v)
          else object < v
      ),
      ifexpr(
        'exclusiveMaximum',
        schema,
        function(v)
          if std.isBoolean(v)  // Draft 4
          then
            if v
            then ifexpr('maximum', schema, function(v) object < v)
            else ifexpr('maximum', schema, function(v) object <= v)
          else object < v
      ),
    ]),
  // foldEnd

  integer(object, schema)::
    // foldStart
    std.all([
      self.number(object, schema),
      std.mod(object, 1) == 0,
    ]),
  // foldEnd

  object(object, schema)::
    // foldStart
    std.all([
      std.isObject(object),
      unsupported('patternProperties', schema),
      unsupported('unevaluatedProperties', schema),
      ifexpr(
        'properties',
        schema,
        function(properties)
          std.all([
            self.validate(object[property], properties[property])
            for property in std.objectFields(properties)
            if property in object
          ]),
      ),
      ifexpr(
        'additionalProperties',
        schema,
        function(additionalProperties)
          if additionalProperties
          then true
          else
            ifexpr(
              'properties',
              schema,
              function(properties)
                std.all([
                  !std.member(std.objectFields(properties), property)
                  for property in std.objectFields(object)
                ]),
              //{
              //  object: object,
              //  'object has properties': std.objectFields(object),
              //},
              //{ 'allowed properties': std.objectFields(properties) }
              //    )
            )
      ),
      ifexpr(
        'required',
        schema,
        function(required)
          std.all(
            [
              std.member(std.objectFields(object), property)
              for property in required
            ],
            //{
            //  object: object,
            //  'object has properties': std.objectFields(object),
            //},
            //{ 'required properties': required }
          ),
      ),
      ifexpr(
        'propertyNames',
        schema,
        function(propertyNames)
          std.all([
            self.string(property, propertyNames)
            for property in std.objectFields(schema)
          ])
      ),
      ifexpr(
        'minProperties',
        schema,
        function(v)
          std.count(std.objectFields(object)) >= v
      ),
      ifexpr(
        'maxProperties',
        schema,
        function(v)
          std.count(std.objectFields(object)) <= v
      ),
    ]),
  // foldEnd

  array(object, schema)::
    // foldStart
    std.all([
      std.isArray(object),
      ifexpr(
        'minItems',
        schema,
        function(v)
          std.length(object) >= v
      ),
      ifexpr(
        'maxItems',
        schema,
        function(v)
          std.length(object) <= v
      ),
      ifexpr(
        'uniqueItems',
        schema,
        function(v)
          local f = function(x) std.md5(std.manifestJson(x));
          std.set(object, f) == std.sort(object, f)
      ),
      ifexpr(
        'prefixItems',
        schema,
        function(prefixItems)
          if std.length(prefixItems) > 0
          then
            std.all([
              std.length(object) >= std.length(prefixItems),
            ] + [
              self.validate(object[i], prefixItems[i])
              for i in std.range(0, std.length(prefixItems) - 1)
            ])
          else true
      ),
      ifexpr(
        'items',
        schema,
        function(items)
          if std.isBoolean(items)
          then
            if items
            then true
            else ifexpr(
              'prefixItems',
              schema,
              function(prefixItems)
                std.length(prefixItems) == std.length(object),
            )
          else
            if std.length(object) == 0
            then true
            else
              std.all([
                self.validate(item, items)
                for item in object
              ]),
      ),
      ifexpr(
        'contains',
        schema,
        function(contains)
          local items = [
            self.validate(item, contains, trace=false)
            for item in object
          ];
          std.any(items)
          && std.all([
            ifexpr(
              'minContains',
              schema,
              function(v)
                std.length(items) >= v
            ),
            ifexpr(
              'maxContains',
              schema,
              function(v)
                std.length(items) <= v
            ),
          ])
      ),
    ]),
  // foldEnd
}

// vim: foldmethod=marker foldmarker=foldStart,foldEnd foldlevel=0
