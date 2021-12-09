local crdsonnet =
  (import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet')
  + { render:: import 'github.com/Duologic/crdsonnet/crdsonnet/static.libsonnet' };
local spec = import 'grafana-spec/dashboard.json';


'{ %s }' %
std.foldl(
  function(acc, m)
    local items =
      local s = std.reverse(std.split(m, '.'));
      if s == ['Family']
      then ['Dashboard']
      else s;

    acc + crdsonnet.parse(
      crdsonnet.camelCaseKind(items[0]),
      [],
      spec.components.schemas[m],
      spec.components.schemas,
    ),
  std.objectFields(spec.components.schemas),
  ''
)
+
(importstr 'shortcuts.libsonnet')
