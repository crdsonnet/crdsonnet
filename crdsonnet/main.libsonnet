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

      parsedSchema:
        parser.parseSchema(
          self.name,
          self.schema,
          schemaDB=self.schemaDB
        )
        + { [self.name]+: { _name: this.name } },

      library: self.renderEngine.render(self.parsedSchema[self.name]),
    },
    withSchemaDB(db): {
      schemaDB: db,
    },
    withRenderEngine(engine): {
      renderEngine: render.new(engine),
    },
    withValidation(): {
      renderEngine+: render.withValidation(),
    },
  },

  crd: {
    local this = self,
    new(definiton, groupSuffix): {
      definition: definiton,
      groupSuffix: groupSuffix,

      schemaDB: helpers.metadataRefSchemaDB,
      renderEngine: render.new('dynamic'),

      local grouping = helpers.getGroupKey(self.definition.spec.group, groupSuffix),
      local name = helpers.camelCaseKind(this.getKind(self.definition)),

      parsedVersions:
        [
          local schema = this.getSchemaForVersion(self.definition, version);
          parser.parseSchema(
            name,
            schema,
            schema,
            self.schemaDB
          )
          + {
            [name]+: { _name: name },
            _name: version.name,
          }
          for version in self.definition.spec.versions
        ],

      library:
        std.foldl(
          function(acc, version)
            acc
            + self.renderEngine.toObject(
              self.renderEngine.nestInParents(
                [grouping, version._name],
                self.renderEngine.schema(
                  version[name]
                )
              )
            )
            + self.renderEngine.newFunction(
              [grouping, version._name, name]
            )
          ,
          self.parsedVersions,
          self.renderEngine.nilvalue,
        ),
    },

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

    withSchemaDB(db): {
      schemaDB+: db,
    },
    withRenderEngine(engine): {
      renderEngine: render.new(engine),
    },
    withValidation(): {
      renderEngine+: render.withValidation(),
    },
  },

  // XRD: Crossplane CompositeResourceDefinition
  // XRDs are very similar to CRDs, processing them requires slightly different behavior.
  xrd:
    self.crds
    {
      getKind(definition):
        if std.objectHas(definition.spec, 'claimNames')
        then definition.spec.claimNames.kind
        else definition.spec.names.kind,

      getSchemaForVersion(definition, version):
        super.getSchemaForVersion(definition, version)
        + helpers.properties.withCompositeResource(),
    },

  // Below this are shortcuts for common patterns.
  // These work but are not very flexible, they won't receive new feature updates because
  // of this, if you want to use new features then use above composable setups instead.
  // These shortcuts will not be further documented either.

  fromSchema(name, schema, schemaDB={}, renderEngine=defaultRenderEngine):
    if name == ''
    then error "name can't be an empty string"
    else (
      self.schema.new(name, schema)
      + self.schema.withSchemaDB(schemaDB)
      + self.schema.withRenderEngine(renderEngine)
    ).library,

  fromCRD(definition, groupSuffix, schemaDB={}, renderEngine=defaultRenderEngine):
    (self.crd.new(definition, groupSuffix)
     + self.crd.withSchemaDB(schemaDB)
     + self.crd.withRenderEngine(renderEngine)).library,

  fromXRD(definition, groupSuffix, schemaDB={}, renderEngine=defaultRenderEngine):
    (self.xrd.new(definition, groupSuffix)
     + self.xrd.withSchemaDB(schemaDB)
     + self.xrd.withRenderEngine(renderEngine)).library,

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
        local name = helpers.camelCaseKind(items[0]);
        local component = schema.definitions[d];

        acc
        + render.new(renderEngine).toObject(
          render.new(renderEngine).nestInParents(
            [items[2], items[1]],
            self.fromOpenAPI(name, component, schema, renderEngine=renderEngine)
          )
        ),
      std.objectFields(schema.definitions),
      render.new(renderEngine).nilvalue
    ),
  // foldEnd
}
