local crdsonnet = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local spec = import 'grafana-spec/dashboard.json';

local replaceRefs(object, refs={}) =
  std.foldl(
    function(acc, p)
      acc + (
        if p == '$ref'
        then
          local ref = crdsonnet.getRefName(object);
          if std.objectHas(refs, ref)
          then replaceRefs(refs[ref], refs)
          else {
            type: 'object',
            name: { type: 'string' },
            kind: { type: 'string' },
            group: { type: 'string' },
          }
        else if std.isArray(object[p])
        then { [p]: [
          if std.isObject(q)
          then replaceRefs(q, refs)
          else q
          for q in object[p]
        ] }
        else if std.isObject(object[p])
        then { [p]: replaceRefs(object[p], refs) }
        else { [p]: object[p] }
      ),
    std.objectFields(object),
    {}
  );

local crd(name, plural, schema, group='grafana.com', refs={}) = {
  apiVersion: 'apiextensions.k8s.io/v1',
  kind: 'CustomResourceDefinition',
  metadata: {
    name: std.asciiLower(name) + '.' + group,
  },
  spec: {
    group: group,
    versions: [
      {
        name: 'v1alpha1',
        served: true,
        storage: true,
        schema: {
          openAPIV3Schema: replaceRefs(schema, refs),
        },
      },
    ],
    scope: 'Namespaced',
    names: {
      plural: plural,
      singular: std.asciiLower(name),
      kind: name,
    },
  },
};


crd(
  'Dashboard',
  'dashboards',
  spec.components.schemas.Family,
  refs=spec.components.schemas,
)
