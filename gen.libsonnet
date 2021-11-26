local getVersionInDefinition(definition, version) =
  local versions = [
    v
    for v in definition.spec.versions
    if v.name == version
  ];
  if std.length(versions) == 0
  then error 'version %s in definition %s not found' % [version, definition.metadata.name]
  else if std.length(versions) > 1
  then error 'multiple versions match %s in definition' % [version, definition.metadata.name]
  else versions[0];

local createFunction(name, parents) =
  {
    ['with' + std.asciiUpper(name[0]) + name[1:]]:  //(value):
      std.foldr(
        function(p, acc)
          if p == name
          then acc
          else { [p]+: acc }
        ,
        parents,
        { [name]: '' }
      ),
  };

local appendFunction(name, parents) =
  {
    ['with' + std.asciiUpper(name[0]) + name[1:] + 'Mixin']:  //(value):
      std.foldr(
        function(p, acc)
          if p == name
          then acc
          else { [p]+: acc }
        ,
        parents,
        { [name]+: [''] }
      ),
  };

local propertyToValue(name, parents, property) =
  local handleObject(name, parents, properties) =
    std.foldl(
      function(acc, p)
        acc {
          [name]+: propertyToValue(
            p,
            parents + [p],
            properties[p]
          ),
        },
      std.objectFields(properties),
      {}
    );

  local type =
    if std.objectHas(property, 'type')
    then property.type

    // TODO: figure out how to handle allOf, oneOf or anyOf properly,
    // would we expect 'array' or 'object' here?
    else if std.objectHas(property, 'allOf')
            || std.objectHas(property, 'oneOf')
            || std.objectHas(property, 'anyOf')
    then 'xOf'

    else error "can't find type"
  ;

  createFunction(name, parents)
  + (
    if type == 'array'
    then appendFunction(name, parents)

    else if type == 'object'
            && std.objectHas(property, 'properties')
    then handleObject(name, parents, property.properties)

    else {}
  ) + (
    if std.objectHas(property, 'items')
       && std.member(['array', 'object'], property.items.type)
    then handleObject(name, parents, property.items.properties)
    else {}
  );

function(definition)
  std.foldl(
    function(acc, v)
      acc {
        [v]+: {
          [definition.spec.names.kind]:
            local schema =
              getVersionInDefinition(definition, v).schema.openAPIV3Schema;
            std.foldl(
              function(acc, p)
                acc + propertyToValue(
                  p,
                  [p],
                  schema.properties[p]
                ),
              std.objectFields(schema.properties),
              {}
            )
            + {
              new:  //(name):
                self.withApiVersion(definition.spec.group + '/' + v)
                + self.withKind(definition.spec.names.kind)
                + self.metadata.withName('a'),

              withApiVersion(value):: {
                apiVersion: value,
              },
              withKind(value):: {
                kind: value,
              },
              metadata: {
                withName(value):: {
                  metadata: { name: value },
                },
                withNamespace(value):: {
                  metadata: { namespace: value },
                },
              },
            },
        },
      },
    [
      version.name
      for version in definition.spec.versions
    ],
    {}
  )
