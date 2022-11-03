local input = import './input.libsonnet';
local crdsonnet = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';

local metadataProperty =
  {
    local versions = super.spec.versions,
    spec+: {
      versions: [
        v { schema+: { openAPIV3Schema+: { properties+: {
          kind: { type: 'string' },
          metadata: { type: 'object' },
        } } } }
        for v in versions
      ],
    },
  };

std.foldl(
  function(acc, manifest)
    acc +
    if manifest.kind == 'CustomResourceDefinition'
    then crdsonnet.fromCRD(manifest + metadataProperty, 'istio.io')
    else crdsonnet.render.nilvalue,
  input,
  crdsonnet.render.nilvalue,
)
