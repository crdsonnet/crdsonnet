local crdsonnet =
  (import 'crdsonnet/main.libsonnet')
  + { render:: import 'crdsonnet/static.libsonnet' }
;
local schema = import 'schema.jsonnet';

crdsonnet.fromSchema('tanka', 'tanka.dev', 'v1alpha1', 'environment', schema)
