local parser = import './parser.libsonnet';
local renderer = import './render.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local defaultRender = 'dynamic';

local camelCaseKind(kind) =
  local s = xtd.camelcase.split(kind);
  std.asciiLower(s[0]) + std.join('', s[1:]);

local getGroupKey(group, suffix) =
  // If no dedicated API group, then use 'nogroup' key for consistency
  if suffix == group
  then 'nogroup'
  else std.split(std.strReplace(
    group,
    '.' + suffix,
    ''
  ), '.')[0];

local metadataRefSchemaDB = { 'https://objectmeta/schema': import 'objectmeta.json' };

local properties = {
  // foldStart
  withMetadataRef(): {
    // foldStart
    properties+: {
      metadata+: {
        '$ref': 'https://objectmeta/schema#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta',
      },
    },
  },
  // foldEnd

  withGroupVersionKind(group, version, kind): {
    // foldStart
    properties+: {
      apiVersion+: {
        const:
          if group == ''
          then version
          else group
               + '/'
               + version,
      },
      kind+: {
        const: kind,
      },
    },
  },
  // foldEnd

  withCompositeResource(): {
    // foldStart
    properties+: {
      spec+: {
        properties+: {
          compositionRef: {
            properties: { name: { type: 'string' } },
            required: ['name'],
            type: 'object',
          },
          compositionRevisionRef: {
            properties: { name: { type: 'string' } },
            required: ['name'],
            type: 'object',
          },
          compositionSelector: {
            properties: {
              matchLabels: {
                additionalProperties: { type: 'string' },
                type: 'object',
              },
            },
            required: ['matchLabels'],
            type: 'object',
          },
          compositionUpdatePolicy: {
            enum: [
              'Automatic',
              'Manual',
            ],
            type: 'string',
          },
          writeConnectionSecretToRef: {
            properties: { name: { type: 'string' } },
            required: ['name'],
            type: 'object',
          },
        },
      },
    },
  },
  // foldEnd
};
// foldEnd

{
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
      renderer[render].render(parsed[name]),
  // foldEnd

  fromCRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    // foldStart
    local grouping = getGroupKey(definition.spec.group, groupSuffix);
    local name = camelCaseKind(definition.spec.names.kind);

    local parsedVersions = [
      local schema =
        version.schema.openAPIV3Schema
        + properties.withMetadataRef()
        + properties.withGroupVersionKind(
          definition.spec.group,
          version.name,
          definition.spec.names.kind,
        );

      parser.parseSchema(
        name,
        schema,
        schema,
        schemaDB + metadataRefSchemaDB
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
        + renderer[render].toObject(
          renderer[render].nestInParents(
            [grouping, version._name],
            renderer[render].schema(
              version[name]
            )
          )
        )
        + renderer[render].newFunction(
          [grouping, version._name, name]
        )
      ,
      parsedVersions,
      renderer[render].nilvalue,
    );

    output,
  // foldEnd

  // XRD: Crossplane CompositeResourceDefinition
  fromXRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    // foldStart
    local grouping = getGroupKey(definition.spec.group, groupSuffix);

    local kind =
      if std.objectHas(definition.spec, 'claimNames')
      then definition.spec.claimNames.kind
      else definition.spec.names.kind;

    local name = camelCaseKind(kind);

    local parsedVersions = [
      local schema =
        version.schema.openAPIV3Schema
        + properties.withCompositeResource()
        + properties.withMetadataRef()
        + properties.withGroupVersionKind(
          definition.spec.group,
          version.name,
          definition.spec.names.kind,
        );

      parser.parseSchema(
        name,
        schema,
        schema,
        schemaDB + metadataRefSchemaDB
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
        + renderer[render].toObject(
          renderer[render].nestInParents(
            [grouping, version._name],
            renderer[render].schema(
              version[name]
            )
          )
        )
        + renderer[render].newFunction(
          [grouping, version._name, name]
        )
      ,
      parsedVersions,
      renderer[render].nilvalue,
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
             properties.withGroupVersionKind(gvk.group, gvk.version, gvk.kind)
           else {});

      local parsed = parser.parseSchema(
        name,
        extendComponent,
        schema,
        schemaDB
      ) + { [name]+: { _name: name } };

      renderer[render].render(parsed[name])
      + (if 'x-kubernetes-group-version-kind' in component
         then renderer[render].newFunction([name])
         else renderer[render].nilvalue),
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
               properties.withGroupVersionKind(gvk.group, gvk.version, gvk.kind)
             else {});

        local name = camelCaseKind(items[0]);
        local parsed = parser.parseSchema(
          name,
          extendComponent,
          schema,
        ) + { [name]+: { _name: name } };

        acc
        + renderer[render].toObject(
          renderer[render].nestInParents(
            [items[2], items[1]],
            renderer[render].schema(parsed[name])
          )
        )
        + (if 'x-kubernetes-group-version-kind' in component
           then renderer[render].newFunction([items[2], items[1], name])
           else renderer[render].nilvalue),
      std.objectFields(schema.definitions),
      renderer[render].nilvalue
    ),
  // foldEnd
}

// vim: foldmethod=marker foldmarker=foldStart,foldEnd foldlevel=0
