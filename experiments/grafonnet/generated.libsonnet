{
  dashboard+: {
    withAnnotations(value): { annotations: value },
    withAnnotationsMixin(value): { annotations+: value },
    annotations+: {
      list+: {
        withBuiltIn(value): { builtIn: value },
        withDatasource(value): { datasource: value },
        withEnable(value): { enable: value },
        withHide(value): { hide: value },
        withIconColor(value): { iconColor: value },
        withName(value): { name: value },
        withRawQuery(value): { rawQuery: value },
        withShowIn(value): { showIn: value },
        withType(value): { type: value },
      },
      withList(value): { annotations: { list: if std.isArray(value) then value else [value] } },
      withListMixin(value): { annotations: { list+: if std.isArray(value) then value else [value] } },
    },
    withDescription(value): { description: value },
    withEditable(value): { editable: value },
    withGnetId(value): { gnetId: value },
    withGraphTooltip(value): { graphTooltip: value },
    withId(value): { id: value },
    withPanels(value): { panels: if std.isArray(value) then value else [value] },
    withPanelsMixin(value): { panels+: if std.isArray(value) then value else [value] },
    withRefresh(value): { refresh: value },
    withSchemaVersion(value): { schemaVersion: value },
    withStyle(value): { style: value },
    tags+: { newString(value): value },
    withTags(value): { tags: if std.isArray(value) then value else [value] },
    withTagsMixin(value): { tags+: if std.isArray(value) then value else [value] },
    withTemplating(value): { templating: value },
    withTemplatingMixin(value): { templating+: value },
    templating+: {
      list+: { newObject(value): value },
      withList(value): { templating: { list: if std.isArray(value) then value else [value] } },
      withListMixin(value): { templating: { list+: if std.isArray(value) then value else [value] } },
    },
    withTime(value): { time: value },
    withTimeMixin(value): { time+: value },
    time+: {
      withFrom(value): { time: { from: value } },
      withTo(value): { time: { to: value } },
    },
    withTimepicker(value): { timepicker: value },
    withTimepickerMixin(value): { timepicker+: value },
    timepicker+: {
      withCollapse(value): { timepicker: { collapse: value } },
      withEnable(value): { timepicker: { enable: value } },
      withHidden(value): { timepicker: { hidden: value } },
      refresh_intervals+: { newString(value): value },
      withRefresh_intervals(value): { timepicker: { refresh_intervals: if std.isArray(value) then value else [value] } },
      withRefresh_intervalsMixin(value): { timepicker: { refresh_intervals+: if std.isArray(value) then value else [value] } },
    },
    withTimezone(value): { timezone: value },
    withTitle(value): { title: value },
    withUid(value): { uid: value },
    withVersion(value): { version: value },
  },
  fieldColor+: {
    withFixedColor(value): { fixedColor: value },
    withMode(value): { mode: value },
    withSeriesBy(value): { seriesBy: value },
  },
  fieldColorModeId+: { newString(value): value },
  fieldColorSeriesByMode+: { newString(value): value },
  graphPanel+: {
    withAliasColors(value): { aliasColors: value },
    withAliasColorsMixin(value): { aliasColors+: value },
    withBars(value): { bars: value },
    withDashLength(value): { dashLength: value },
    withDashes(value): { dashes: value },
    withFill(value): { fill: value },
    withFillGradient(value): { fillGradient: value },
    withHiddenSeries(value): { hiddenSeries: value },
    withLegend(value): { legend: value },
    withLegendMixin(value): { legend+: value },
    withLines(value): { lines: value },
    withLinewidth(value): { linewidth: value },
    withNullPointMode(value): { nullPointMode: value },
    withPercentage(value): { percentage: value },
    withPointradius(value): { pointradius: value },
    withPoints(value): { points: value },
    withRenderer(value): { renderer: value },
    seriesOverrides+: { newObject(value): value },
    withSeriesOverrides(value): { seriesOverrides: if std.isArray(value) then value else [value] },
    withSeriesOverridesMixin(value): { seriesOverrides+: if std.isArray(value) then value else [value] },
    withSpaceLength(value): { spaceLength: value },
    withStack(value): { stack: value },
    withSteppedLine(value): { steppedLine: value },
    thresholds+: { newObject(value): value },
    withThresholds(value): { thresholds: if std.isArray(value) then value else [value] },
    withThresholdsMixin(value): { thresholds+: if std.isArray(value) then value else [value] },
    timeRegions+: { newObject(value): value },
    withTimeRegions(value): { timeRegions: if std.isArray(value) then value else [value] },
    withTimeRegionsMixin(value): { timeRegions+: if std.isArray(value) then value else [value] },
    withTooltip(value): { tooltip: value },
    withTooltipMixin(value): { tooltip+: value },
    tooltip+: {
      withShared(value): { tooltip: { shared: value } },
      withSort(value): { tooltip: { sort: value } },
      withValue_type(value): { tooltip: { value_type: value } },
    },
    withType(value): { type: value },
  },
  panel+: {
    withDatasource(value): { datasource: value },
    withDescription(value): { description: value },
    withFieldConfig(value): { fieldConfig: value },
    withFieldConfigMixin(value): { fieldConfig+: value },
    fieldConfig+: {
      withDefaults(value): { fieldConfig: { defaults: value } },
      withDefaultsMixin(value): { fieldConfig: { defaults+: value } },
      defaults+: {
        withColor(value): { fieldConfig: { defaults: { color: value } } },
        withColorMixin(value): { fieldConfig: { defaults: { color+: value } } },
        color+: {
          withFixedColor(value): { fieldConfig: { defaults: { color: { fixedColor: value } } } },
          withMode(value): { fieldConfig: { defaults: { color: { mode: value } } } },
          withSeriesBy(value): { fieldConfig: { defaults: { color: { seriesBy: value } } } },
        },
        withCustom(value): { fieldConfig: { defaults: { custom: value } } },
        withCustomMixin(value): { fieldConfig: { defaults: { custom+: value } } },
        withDecimals(value): { fieldConfig: { defaults: { decimals: value } } },
        withDescription(value): { fieldConfig: { defaults: { description: value } } },
        withDisplayName(value): { fieldConfig: { defaults: { displayName: value } } },
        withDisplayNameFromDS(value): { fieldConfig: { defaults: { displayNameFromDS: value } } },
        withFilterable(value): { fieldConfig: { defaults: { filterable: value } } },
        withLinks(value): { fieldConfig: { defaults: { links: if std.isArray(value) then value else [value] } } },
        withLinksMixin(value): { fieldConfig: { defaults: { links+: if std.isArray(value) then value else [value] } } },
        mappings+: { newObject(value): value },
        withMappings(value): { fieldConfig: { defaults: { mappings: if std.isArray(value) then value else [value] } } },
        withMappingsMixin(value): { fieldConfig: { defaults: { mappings+: if std.isArray(value) then value else [value] } } },
        withMax(value): { fieldConfig: { defaults: { max: value } } },
        withMin(value): { fieldConfig: { defaults: { min: value } } },
        withNoValue(value): { fieldConfig: { defaults: { noValue: value } } },
        withPath(value): { fieldConfig: { defaults: { path: value } } },
        withThresholds(value): { fieldConfig: { defaults: { thresholds: value } } },
        withThresholdsMixin(value): { fieldConfig: { defaults: { thresholds+: value } } },
        thresholds+: {
          withMode(value): { fieldConfig: { defaults: { thresholds: { mode: value } } } },
          steps+: {
            withColor(value): { color: value },
            withState(value): { state: value },
            withValue(value): { value: value },
          },
          withSteps(value): { fieldConfig: { defaults: { thresholds: { steps: if std.isArray(value) then value else [value] } } } },
          withStepsMixin(value): { fieldConfig: { defaults: { thresholds: { steps+: if std.isArray(value) then value else [value] } } } },
        },
        withUnit(value): { fieldConfig: { defaults: { unit: value } } },
        withWriteable(value): { fieldConfig: { defaults: { writeable: value } } },
      },
      overrides+: {
        withMatcher(value): { matcher: value },
        withMatcherMixin(value): { matcher+: value },
        matcher+: {
          withId(value): { matcher: { id: value } },
          withOptions(value): { matcher: { options: value } },
        },
        properties+: {
          withId(value): { id: value },
          withValue(value): { value: value },
        },
        withProperties(value): { properties: if std.isArray(value) then value else [value] },
        withPropertiesMixin(value): { properties+: if std.isArray(value) then value else [value] },
      },
      withOverrides(value): { fieldConfig: { overrides: if std.isArray(value) then value else [value] } },
      withOverridesMixin(value): { fieldConfig: { overrides+: if std.isArray(value) then value else [value] } },
    },
    withGridPos(value): { gridPos: value },
    withGridPosMixin(value): { gridPos+: value },
    gridPos+: {
      withH(value): { gridPos: { h: value } },
      withStatic(value): { gridPos: { static: value } },
      withW(value): { gridPos: { w: value } },
      withX(value): { gridPos: { x: value } },
      withY(value): { gridPos: { y: value } },
    },
    withId(value): { id: value },
    withInterval(value): { interval: value },
    withLinks(value): { links: if std.isArray(value) then value else [value] },
    withLinksMixin(value): { links+: if std.isArray(value) then value else [value] },
    withMaxDataPoints(value): { maxDataPoints: value },
    withOptions(value): { options: value },
    withOptionsMixin(value): { options+: value },
    withPluginVersion(value): { pluginVersion: value },
    withRepeat(value): { repeat: value },
    withRepeatDirection(value): { repeatDirection: value },
    tags+: { newString(value): value },
    withTags(value): { tags: if std.isArray(value) then value else [value] },
    withTagsMixin(value): { tags+: if std.isArray(value) then value else [value] },
    targets+: { newObject(value): value },
    withTargets(value): { targets: if std.isArray(value) then value else [value] },
    withTargetsMixin(value): { targets+: if std.isArray(value) then value else [value] },
    withThresholds(value): { thresholds: if std.isArray(value) then value else [value] },
    withThresholdsMixin(value): { thresholds+: if std.isArray(value) then value else [value] },
    withTimeFrom(value): { timeFrom: value },
    withTimeRegions(value): { timeRegions: if std.isArray(value) then value else [value] },
    withTimeRegionsMixin(value): { timeRegions+: if std.isArray(value) then value else [value] },
    withTimeShift(value): { timeShift: value },
    withTitle(value): { title: value },
    transformations+: {
      withId(value): { id: value },
      withOptions(value): { options: value },
      withOptionsMixin(value): { options+: value },
    },
    withTransformations(value): { transformations: if std.isArray(value) then value else [value] },
    withTransformationsMixin(value): { transformations+: if std.isArray(value) then value else [value] },
    withTransparent(value): { transparent: value },
    withType(value): { type: value },
  },
  rowPanel+: {
    withCollapsed(value): { collapsed: value },
    withDatasource(value): { datasource: value },
    withGridPos(value): { gridPos: value },
    withGridPosMixin(value): { gridPos+: value },
    gridPos+: {
      withH(value): { gridPos: { h: value } },
      withStatic(value): { gridPos: { static: value } },
      withW(value): { gridPos: { w: value } },
      withX(value): { gridPos: { x: value } },
      withY(value): { gridPos: { y: value } },
    },
    withId(value): { id: value },
    withPanels(value): { panels: if std.isArray(value) then value else [value] },
    withPanelsMixin(value): { panels+: if std.isArray(value) then value else [value] },
    withTitle(value): { title: value },
    withType(value): { type: value },
  },
  target+: { newObject(value): value },
  threshold+: {
    withColor(value): { color: value },
    withState(value): { state: value },
    withValue(value): { value: value },
  },
  thresholdsConfig+: {
    withMode(value): { mode: value },
    steps+: {
      withColor(value): { color: value },
      withState(value): { state: value },
      withValue(value): { value: value },
    },
    withSteps(value): { steps: if std.isArray(value) then value else [value] },
    withStepsMixin(value): { steps+: if std.isArray(value) then value else [value] },
  },
  thresholdsMode+: { newString(value): value },
  transformation+: {
    withId(value): { id: value },
    withOptions(value): { options: value },
    withOptionsMixin(value): { options+: value },
  },
} {
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
