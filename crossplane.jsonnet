local gen = import './gen.libsonnet';
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local kustomize = tanka.kustomize.new(std.thisFile);

{
  manifests:: kustomize.build('.'),
  crossplane:
    std.foldl(
      function(acc, m)
        local manifest = self.manifests[m];
        acc +
        if manifest != null
           && std.objectHas(manifest, 'kind')
           && manifest.kind == 'CustomResourceDefinition'
        then gen(manifest)
        else {},
      std.objectFields(self.manifests),
      {}
    ),
}
