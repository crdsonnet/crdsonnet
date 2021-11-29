local gen = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local swagger = import 'kubernetes-spec/swagger.json';

std.foldl(
  function(acc, m)
    local items = std.reverse(std.split(m, '.'));
    if std.startsWith(m, 'io.k8s.api.')
    then
      acc + gen.fromSchema(
        items[2],
        items[2],
        items[1],
        items[0],
        swagger.definitions[m],
        swagger.definitions,
      )
    else acc,
  std.objectFields(swagger.definitions),
  {}
)
