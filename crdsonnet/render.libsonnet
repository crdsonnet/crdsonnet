{
  static: self.new(import 'static.libsonnet'),
  dynamic: self.new(import 'dynamic.libsonnet'),
  new(r): {
    local this = self,

    render(schema):
      r.properties(this.schema(schema)),

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
      // The parents check prevents that these functions get created on the root object.
      // However this might not be very correct as the functions in this library can also
      // be used to render a part of a schema.
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
        then this.schema(schema.items)
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
}

// vim: foldmethod=marker foldmarker=foldStart,foldEnd
