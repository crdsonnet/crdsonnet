local helpers = import './helpers.libsonnet';
local parser = import './parser.libsonnet';
local renders = import './render.libsonnet';

local defaultRender = 'dynamic';

{
  parse(name, schema, schemaDB={}):
    parser.parseSchema(
      name,
      schema,
      schema,
      schemaDB
    ) + { [name]+: { _name: name } },

  fromSchema(name, schema, schemaDB={}, render=defaultRender):
    // foldStart
    if name == ''
    then error "name can't be an empty string"
    else
      local parsed = parser.parseSchema(
        name,
        schema,
        schema,
        schemaDB
      ) + { [name]+: { _name: name } };
      renders[render].render(parsed[name]),
  // foldEnd

  fromCRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    // foldStart
    local grouping = helpers.getGroupKey(definition.spec.group, groupSuffix);
    local name = helpers.camelCaseKind(definition.spec.names.kind);

    local parsedVersions = [
      local schema =
        version.schema.openAPIV3Schema
        + helpers.properties.withMetadataRef()
        + helpers.properties.withGroupVersionKind(
          definition.spec.group,
          version.name,
          definition.spec.names.kind,
        );

      parser.parseSchema(
        name,
        schema,
        schema,
        schemaDB + helpers.metadataRefSchemaDB
      )
      + {
        [name]+: { _name: name },
        _name: version.name,
      }
      for version in definition.spec.versions
    ];

    local output = std.foldl(
      function(acc, version)
        acc
        + renders[render].toObject(
          renders[render].nestInParents(
            [grouping, version._name],
            renders[render].schema(
              version[name]
            )
          )
        )
        + renders[render].newFunction(
          [grouping, version._name, name]
        )
      ,
      parsedVersions,
      renders[render].nilvalue,
    );

    output,
  // foldEnd

  // XRD: Crossplane CompositeResourceDefinition
  fromXRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    // foldStart
    local grouping = helpers.getGroupKey(definition.spec.group, groupSuffix);

    local kind =
      if std.objectHas(definition.spec, 'claimNames')
      then definition.spec.claimNames.kind
      else definition.spec.names.kind;

    local name = helpers.camelCaseKind(kind);

    local parsedVersions = [
      local schema =
        version.schema.openAPIV3Schema
        + helpers.properties.withCompositeResource()
        + helpers.properties.withMetadataRef()
        + helpers.properties.withGroupVersionKind(
          definition.spec.group,
          version.name,
          kind,
        );

      parser.parseSchema(
        name,
        schema,
        schema,
        schemaDB + helpers.metadataRefSchemaDB
      )
      + {
        [name]+: { _name: name },
        _name: version.name,
      }
      for version in definition.spec.versions
    ];

    local output = std.foldl(
      function(acc, version)
        acc
        + renders[render].toObject(
          renders[render].nestInParents(
            [grouping, version._name],
            renders[render].schema(
              version[name]
            )
          )
        )
        + renders[render].newFunction(
          [grouping, version._name, name]
        )
      ,
      parsedVersions,
      renders[render].nilvalue,
    );

    output,
  // foldEnd

  fromOpenAPI(name, component, schema, schemaDB={}, render=defaultRender):
    // foldStart
    if name == ''
    then error "name can't be an empty string"
    else
      local extendComponent =
        component
        + (if 'x-kubernetes-group-version-kind' in component
           then
             // not sure why this is a list, grabbing the first item
             local gvk = component['x-kubernetes-group-version-kind'][0];
             helpers.properties.withGroupVersionKind(gvk.group, gvk.version, gvk.kind)
           else {});

      local parsed = parser.parseSchema(
        name,
        extendComponent,
        schema,
        schemaDB
      ) + { [name]+: { _name: name } };

      renders[render].render(parsed[name])
      + (if 'x-kubernetes-group-version-kind' in component
         then renders[render].newFunction([name])
         else renders[render].nilvalue),
  // foldEnd

  // expects schema as rendered by `kubectl get --raw /openapi/v2`
  fromKubernetesOpenAPI(schema, render=defaultRender):
    // foldStart
    std.foldl(
      function(acc, d)
        local items = std.reverse(std.split(d, '.'));
        local component = schema.definitions[d];
        local extendComponent =
          component
          + (if 'x-kubernetes-group-version-kind' in component
             then
               // not sure why this is a list, grabbing the first item
               local gvk = component['x-kubernetes-group-version-kind'][0];
               helpers.properties.withGroupVersionKind(gvk.group, gvk.version, gvk.kind)
             else {});

        local name = helpers.camelCaseKind(items[0]);
        local parsed = parser.parseSchema(
          name,
          extendComponent,
          schema,
        ) + { [name]+: { _name: name } };

        acc
        + renders[render].toObject(
          renders[render].nestInParents(
            [items[2], items[1]],
            renders[render].schema(parsed[name])
          )
        )
        + (if 'x-kubernetes-group-version-kind' in component
           then renders[render].newFunction([items[2], items[1], name])
           else renders[render].nilvalue),
      std.objectFields(schema.definitions),
      renders[render].nilvalue
    ),
  // foldEnd
}

// vim: foldmethod=marker foldmarker=foldStart,foldEnd foldlevel=0
