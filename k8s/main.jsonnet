local gen = import '../gen.libsonnet';
local kapi = import 'kubernetes-spec-v1.23/api__v1_openapi.json';

local k8s = std.foldl(
  function(acc, m)
    local items = std.reverse(std.split(m, '.'));
    if std.startsWith(m, 'io.k8s.api.core')
    then
      acc + gen.fromSchema(
        items[2],
        items[1],
        items[0],
        kapi.components.schemas[m]
      )
    else acc,
  std.objectFields(kapi.components.schemas),
  {}
);


gen.inspect('k8s', k8s)
