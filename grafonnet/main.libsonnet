local gen = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local spec = import 'grafana-spec/dashboard.json';

std.foldl(
  function(acc, m)
    local items =
      local s = std.reverse(std.split(m, '.'));
      if s == ['Family']
      then ['Dashboard']
      else s;

    acc + gen.parse(
      gen.camelCaseKind(items[0]),
      [],
      spec.components.schemas[m],
      spec.components.schemas,
    ),
  std.objectFields(spec.components.schemas),
  {}
)
+ {
  panel+: {
    new(type, title):
      super.withType(type)
      + super.withTitle(title),

    gridPos(h, w, x, y):
      super.gridPos.withH(h)
      + super.gridPos.withW(w)
      + super.gridPos.withX(x)
      + super.gridPos.withY(y),

    fieldConfig+: {
      overrides+: {
        new(id, options, properties=[]):
          super.fieldConfig.overrides.matcher.withId(id)
          + super.fieldConfig.overrides.matcher.withOptions(options)
          + super.fieldConfig.overrides.withProperties(properties),

        addProperty(id, value):
          super.fieldConfig.overrides.withPropertiesMixin([
            super.fieldConfig.overrides.properties.withId(id)
            + super.fieldConfig.overrides.properties.withValue(value),
          ]),
      },
    },
  },

  thresholdsConfig+: {
    new(mode, steps):
      super.withMode('absolute')
      + super.withSteps(steps),
  },

  transformation+: {
    new(id, options={})::
      super.withId(id)
      + super.withOptions(options),
  },
}
