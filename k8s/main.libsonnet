local gen = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local swagger = import 'kubernetes-spec/swagger.json';

std.foldl(
  function(acc, m)
    local items = std.reverse(std.split(m, '.'));
    if (
      std.startsWith(m, 'io.k8s.api.')
      || std.startsWith(m, 'io.k8s.kube-aggregator.pkg.apis.')
      || std.startsWith(m, 'io.k8s.apiextensions-apiserver.pkg.apis.')
    )
    then
      acc + gen.fromSchema(
        grouping=items[2],
        group=items[2],
        version=items[1],
        kind=items[0],
        schema=swagger.definitions[m],
        refs=swagger.definitions,
        withMixin=true,
      )
    else acc,
  std.objectFields(swagger.definitions),
  {}
)
