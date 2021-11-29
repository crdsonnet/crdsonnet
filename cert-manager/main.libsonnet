local gen = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';

local parseYaml(str) =
  if std.native('parseYaml') != null
  then
    // supported in Tanka
    std.native('parseYaml')(str)
  else
    // supported in standard lib
    // wrap output in array for consistent output
    local i = std.parseYaml(str);
    if std.isArray(i)
    then i
    else [i]
;

local manifests = std.flattenArrays([
  parseYaml(importstr 'cert-manager-crds/crd-certificaterequests.yaml'),
  parseYaml(importstr 'cert-manager-crds/crd-certificates.yaml'),
  parseYaml(importstr 'cert-manager-crds/crd-challenges.yaml'),
  parseYaml(importstr 'cert-manager-crds/crd-clusterissuers.yaml'),
  parseYaml(importstr 'cert-manager-crds/crd-issuers.yaml'),
  parseYaml(importstr 'cert-manager-crds/crd-orders.yaml'),
]);

std.foldl(
  function(acc, manifest)
    acc +
    if manifest.kind == 'CustomResourceDefinition'
    then gen.fromCRD(manifest, 'cert-manager.io')
    else {},
  manifests,
  {}
)
