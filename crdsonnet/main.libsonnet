local helpers = import './helpers.libsonnet';
local legacy = import './legacy.libsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';

{
  '#':
    d.package.new(
      'crdsonnet',
      'https://github.com/crdsonnet/crdsonnet/crdsonnet',
      'Generate a *runtime* Jsonnet library directly from JSON Schemas, CRDs or OpenAPI components.',
      std.thisFile,
      'master',
    )
    + d.package.withUsageTemplate(
      '%(json_schema_simple)s' % {
        json_schema_simple: std.strReplace(
          importstr './example/json_schema_ast.libsonnet',
          '../main.libsonnet',
          'github.com/crdsonnet/crdsonnet/crdsonnet/main.libsonnet',
        ),
      }
    ),

  local root = self,
  schemaDB: import './schemadb.libsonnet',
  renderEngine: import './render.libsonnet',
  processor: import './processor.libsonnet',

  schema: {
    '#render': d.fn(
      '`render` returns a library for a `schema`.',
      args=[
        d.arg('name', d.T.string),
        d.arg('schema', d.T.object),
        d.arg('processor', d.T.object, default='processor.new()'),
      ],
    ),
    render(
      name,
      schema,
      processor=root.processor.new(),
    ):
      processor.render(name, schema),
  },

  crd: {
    local this = self,
    '#render': d.fn(
      '`render` returns a library for a `definition`.',
      args=[
        d.arg('definition', d.T.object),
        d.arg('groupSuffix', d.T.string),
        d.arg('processor', d.T.object, default='processor.new()'),
      ],
    ),
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
      renderEngine.toObject(
        std.foldl(
          function(acc, version)
            local schema = this.getSchemaForVersion(definition, version);
            renderEngine.mergeFields(
              acc
              + renderEngine.newFunction(
                [grouping, version.name, name]
              )
              + renderEngine.nestInParents(
                [grouping, version.name],
                _processor.render(name, schema)
              )
            ),
          definition.spec.versions,
          renderEngine.nilvalue,
        )
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
    self.crd
    + {
      getKind(definition):
        if std.objectHas(definition.spec, 'claimNames')
        then definition.spec.claimNames.kind
        else definition.spec.names.kind,
      getSchemaForVersion(definition, version):
        super.getSchemaForVersion(definition, version)
        + helpers.properties.withCompositeResource(),
    },

  openapi: {
    '#render': d.fn(
      '`render` returns a library for a `component` in an OpenAPI `schema`.',
      args=[
        d.arg('name', d.T.string),
        d.arg('component', d.T.object),
        d.arg('schema', d.T.object),
        d.arg('processor', d.T.object, default='processor.new()'),
      ],
    ),
    render(
      name,
      component,
      schema,
      processor=root.processor.new(),
      addNewFunction=true,
    ):
      local extendSchema =
        std.mergePatch(
          schema,
          component
          + (if 'x-kubernetes-group-version-kind' in component
             then
               // not sure why this is a list, grabbing the first item
               local gvk = component['x-kubernetes-group-version-kind'][0];
               helpers.properties.withGroupVersionKind(gvk.group, gvk.version, gvk.kind)
             else {})
        );
      if addNewFunction
      then
        // FIXME: this part doesn't work with AST render engine
        processor.render(name, extendSchema)
        + processor.renderEngine.toObject(
          if 'x-kubernetes-group-version-kind' in component
          then processor.renderEngine.newFunction([name])
          else processor.renderEngine.nilvalue
        )
      else processor.render(name, extendSchema),
  },
}
+ legacy
