local crdsonnet = import './main.libsonnet';
local parser = import './parser.libsonnet';
local schemaDB = import './schemadb.libsonnet';

{
  local root = self,

  // shortcut to return true if key does not exist
  local ifexpr(key, schema, expression=function(x) true) =
    if key in schema
    then expression(schema[key])
    else true,

  local notImplemented(key, schema) =
    ifexpr(
      key,
      schema,
      function(v)
        std.trace('JSON Schema attribute `%s` not implemented.' % key, true)
    ),

  validate(object, schema, trace=true)::
    // foldStart
    if std.isBoolean(schema)
    then schema
    else if schema == {}
    then true
    else
      local expressions = [
        ifexpr('enum', schema, function(enum) std.member(enum, object)),
        ifexpr('const', schema, function(const) object == const),

        notImplemented('allOf', schema),
        notImplemented('anyOf', schema),
        notImplemented('oneOf', schema),
        notImplemented('not', schema),

        ifexpr(
          'if',
          schema,
          function(ifval)
            if self.validate(
              object,
              std.mergePatch(schema { 'if': true, 'then': true }, ifval)
            )
            then ifexpr(
              'then',
              schema,
              function(thenval)
                self.validate(
                  object,
                  std.mergePatch(schema { 'if': true, 'then': true }, thenval)
                )
            )
            else ifexpr(
              'else',
              schema,
              function(elseval)
                self.validate(
                  object,
                  std.mergePatch(schema { 'if': true, 'then': true }, elseval)
                )
            )
        ),

        ifexpr(
          'type',
          schema,
          function(type)
            if std.isBoolean(type)
            then object != null

            else if std.isArray(type)
            then std.any([
              self.types[t](object, schema)
              for t in type
            ])

            else self.types[type](object, schema)
        ),
      ];
      std.all([
        if trace
        then
          std.trace(|||
            #/%s
            This object:
            %s
            Does not match:
            %s
          ||| % [
            std.join('/', schema._parents),
            std.manifestJson(object),
            std.manifestJson(schema),
          ], false)
        else false
        for expression in expressions
        if !expression
      ]),
  // foldEnd

  types: {
    boolean(object, schema): std.isBoolean(object),
    'null'(object, schema): std.type(object) == 'null',

    string(object, schema)::
      // foldStart
      std.all([
        std.isString(object),
        ifexpr('minLength', schema, function(v) std.length(object) >= v),
        ifexpr('maxLength', schema, function(v) std.length(object) <= v),
        notImplemented('pattern', schema),
        //notImplemented('format', schema), // vocabulary specific
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
        notImplemented('patternProperties', schema),
        notImplemented('dependentRequired', schema),
        notImplemented('unevaluatedProperties', schema),
        ifexpr(
          'properties',
          schema,
          function(properties)
            std.all([
              root.validate(object[property], properties[property])
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
              )
        ),
        ifexpr(
          'required',
          schema,
          function(required)
            std.all([
              std.member(std.objectFields(object), property)
              for property in required
            ]),
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
        notImplemented('unevaluatedItems', schema),
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
                root.validate(object[i], prefixItems[i])
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
                  std.length(prefixItems) == std.length(object)
              )
            else
              if std.length(object) == 0
              then true
              else
                std.all([
                  root.validate(item, items)
                  for item in object
                ]),
        ),
        ifexpr(
          'contains',
          schema,
          function(contains)
            local items = [
              root.validate(item, contains, trace=false)
              for item in object
            ];
            std.any(std.trace(std.manifestJson(items), items))
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
  },
}

// vim: foldmethod=marker foldmarker=foldStart,foldEnd foldlevel=0
