{
  dashboard+: {
    withTemplates(templates):
      super.templating.withList(templates),
    withTemplatesMixin(templates):
      super.templating.withListMixin(templates),
  },

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
          super.matcher.withId(id)
          + super.matcher.withOptions(options)
          + super.withProperties(properties),

        addProperty(id, value):
          super.withPropertiesMixin([
            super.properties.withId(id)
            + super.properties.withValue(value),
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
