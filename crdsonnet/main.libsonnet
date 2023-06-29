local helpers = import './helpers.libsonnet';
local parser = import './parser.libsonnet';
local render = import './render.libsonnet';

local defaultRenderEngine = 'dynamic';

{
  parse(name, schema, schemaDB={}):
    parser.parseSchema(
      name,
      schema,
      schema,
      schemaDB
    ) + { [name]+: { _name: name } },

  schema: {
    new(name, schema): {
      local this = self,
      name: name,
      schema: schema,
      schemaDB: {},
      renderEngine: render.new('dynamic'),

      parsedSchema: parser.parseSchema(
        self.name,
        self.schema,
        self.schema,
        self.schemaDB
      ) + { [self.name]+: { _name: this.name } },

      render: self.renderEngine.render(self.parsedSchema[self.name]),
    },
    withSchemaDB(db): {
      schemaDB: db,
    },
    withRenderEngine(engine): {
      renderEngine: render.new(engine),
    },
  },

  fromSchema(name, schema, schemaDB={}, renderEngine=defaultRenderEngine):
    // foldStart
    if name == ''
    then error "name can't be an empty string"
    else (
      self.schema.new(name, schema)
      + self.schema.withSchemaDB(schemaDB)
      + self.schema.withRenderEngine(renderEngine)
    ).render,
  // foldEnd

  fromCRD(definition, groupSuffix, schemaDB={}, renderEngine=defaultRenderEngine):
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
        + render.new(renderEngine).toObject(
          render.new(renderEngine).nestInParents(
            [grouping, version._name],
            render.new(renderEngine).schema(
              version[name]
            )
          )
        )
        + render.new(renderEngine).newFunction(
          [grouping, version._name, name]
        )
      ,
      parsedVersions,
      render.new(renderEngine).nilvalue,
    );

    output,
  // foldEnd

  // XRD: Crossplane CompositeResourceDefinition
  fromXRD(definition, groupSuffix, schemaDB={}, renderEngine=defaultRenderEngine):
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
        + render.new(renderEngine).toObject(
          render.new(renderEngine).nestInParents(
            [grouping, version._name],
            render.new(renderEngine).schema(
              version[name]
            )
          )
        )
        + render.new(renderEngine).newFunction(
          [grouping, version._name, name]
        )
      ,
      parsedVersions,
      render.new(renderEngine).nilvalue,
    );

    output,
  // foldEnd

  fromOpenAPI(name, component, schema, schemaDB={}, renderEngine=defaultRenderEngine):
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

      render.new(renderEngine).render(parsed[name])
      + (if 'x-kubernetes-group-version-kind' in component
         then render.new(renderEngine).newFunction([name])
         else render.new(renderEngine).nilvalue),
  // foldEnd

  // expects schema as rendered by `kubectl get --raw /openapi/v2`
  fromKubernetesOpenAPI(schema, renderEngine=defaultRenderEngine):
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
        + render.new(renderEngine).toObject(
          render.new(renderEngine).nestInParents(
            [items[2], items[1]],
            render.new(renderEngine).schema(parsed[name])
          )
        )
        + (if 'x-kubernetes-group-version-kind' in component
           then render.new(renderEngine).newFunction([items[2], items[1], name])
           else render.new(renderEngine).nilvalue),
      std.objectFields(schema.definitions),
      render.new(renderEngine).nilvalue
    ),
  // foldEnd
}

// vim: foldmethod=marker foldmarker=foldStart,foldEnd foldlevel=0
