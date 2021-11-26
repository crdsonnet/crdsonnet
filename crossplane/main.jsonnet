local gen = import '../gen.libsonnet';
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local kustomize = tanka.kustomize.new(std.thisFile);
local manifests = kustomize.build('.');

std.foldl(
  function(acc, m)
    local manifest = manifests[m];
    acc +
    if manifest != null
       && std.objectHas(manifest, 'kind')
       && manifest.kind == 'CustomResourceDefinition'
    then gen(manifest)
    else {},
  std.objectFields(manifests),
  {}
)
