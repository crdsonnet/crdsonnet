local gen = import '../gen.libsonnet';
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local kustomize = tanka.kustomize.new(std.thisFile);
local manifests = kustomize.build('.');

local cert_manager = std.foldl(
  function(acc, m)
    local manifest = manifests[m];
    acc +
    if manifest.kind == 'CustomResourceDefinition'
    then gen.fromCRD(manifest, 'cert-manager.io')
    else {},
  std.objectFields(manifests),
  {}
);


gen.inspect('cert_manager', cert_manager)
//cert_manager.nogroup.v1.certificate.new('a')

