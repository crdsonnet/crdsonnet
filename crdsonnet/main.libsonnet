local helpers = import './helpers.libsonnet';
local parser = import './parser.libsonnet';
local renderEngine = import './render.libsonnet';

local defaultRender = 'dynamic';

{
  local root = self,

  schemadb: import './schemadb.libsonnet',

  processor: {
    new(): {
      schemaDB: {},
      renderEngine: renderEngine.new('dynamic'),
      parse(name, schema):
        parser.parseSchema(
          name,
          schema,
          schema,
          self.schemaDB
        ) + { [name]+: { _name: name } },
      render(name, schema):
        local parsedSchema = self.parse(name, schema);
        self.renderEngine.render(parsedSchema[name]),
    },
    withSchemaDB(db): {
      schemaDB+: db,
    },
    withRenderEngine(engine): {
      renderEngine: engine,
    },
    withRenderEngineType(engineType): {
      renderEngine: renderEngine.new(engineType),
    },
  },

  schema: {
    render(
      name,
      schema,
      processor=root.processor.new(),
    ):
      processor.render(name, schema),
  },

  crd: {
    local this = self,
    render(
      definition,
      groupSuffix,
      processor=root.processor.new(),
    ):
      local _processor =
        processor
        + root.processor.withSchemaDB(helpers.metadataRefSchemaDB);
      local renderEngine = _processor.renderEngine;
      local grouping = helpers.getGroupKey(definition.spec.group, groupSuffix);
      local name = helpers.camelCaseKind(this.getKind(definition));
      std.foldl(
        function(acc, version)
          local schema = this.getSchemaForVersion(definition, version);
          acc
          + renderEngine.toObject(
            renderEngine.nestInParents(
              [grouping, version.name],
              _processor.render(name, schema)
            )
          )
          + renderEngine.newFunction(
            [grouping, version.name, name]
          )
        ,
        definition.spec.versions,
        renderEngine.nilvalue,
      ),
    getKind(definition):
      definition.spec.names.kind,
    getSchemaForVersion(definition, version):
      version.schema.openAPIV3Schema
      + helpers.properties.withMetadataRef()
      + helpers.properties.withGroupVersionKind(
        definition.spec.group,
        version.name,
        this.getKind(definition)
      ),
  },

  // XRD: Crossplane CompositeResourceDefinition
  // XRDs are very similar to CRDs, processing them requires slightly different behavior.
  xrd:
    self.crds
    + {
      getKind(definition):
        if std.objectHas(definition.spec, 'claimNames')
        then definition.spec.claimNames.kind
        else definition.spec.names.kind,
      getSchemaForVersion(definition, version):
        super.getSchemaForVersion(definition, version)
        + helpers.properties.withCompositeResource(),
    },

  fromSchema(name, schema, schemaDB={}, render=defaultRender):
    if name == ''
    then error "name can't be an empty string"
    else
      local processor =
        self.processor.new()
        + self.processor.withSchemaDB(schemaDB)
        + self.processor.withRenderEngineType(render);
      self.schema.render(name, schema, processor),

  fromCRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    local processor =
      self.processor.new()
      + self.processor.withSchemaDB(schemaDB)
      + self.processor.withRenderEngineType(render);
    self.crd.render(definition, groupSuffix, processor),

  // XRD: Crossplane CompositeResourceDefinition
  fromXRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    local processor =
      self.processor.new()
      + self.processor.withSchemaDB(schemaDB)
      + self.processor.withRenderEngineType(render);
    self.xrd.render(definition, groupSuffix, processor),

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

      renderEngine.new(render).render(parsed[name])
      + (if 'x-kubernetes-group-version-kind' in component
         then renderEngine.new(render).newFunction([name])
         else renderEngine.new(render).nilvalue),
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
        + renderEngine.new(render).toObject(
          renderEngine.new(render).nestInParents(
            [items[2], items[1]],
            renderEngine.new(render).schema(parsed[name])
          )
        )
        + (if 'x-kubernetes-group-version-kind' in component
           then renderEngine.new(render).newFunction([items[2], items[1], name])
           else renderEngine.new(render).nilvalue),
      std.objectFields(schema.definitions),
      renderEngine.new(render).nilvalue
    ),
  // foldEnd
}
