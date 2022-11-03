{
  tanka+: { v1alpha1+: {
    environment+: {
      withApiVersion(value): { apiVersion: value },
      withData(value): { data: value },
      withDataMixin(value): { data+: value },
      withKind(value): { kind: value },
      withMetadata(value): { metadata: value },
      withMetadataMixin(value): { metadata+: value },
      metadata+: {
        withLabels(value): { metadata+: { labels: value } },
        withLabelsMixin(value): { metadata+: { labels+: value } },
        withName(value): { metadata+: { name: value } },
        withNamespace(value): { metadata+: { namespace: value } },
      },
      withSpec(value): { spec: value },
      withSpecMixin(value): { spec+: value },
      spec+: {
        withApiServer(value): { spec+: { apiServer: value } },
        withApplyStrategy(value): { spec+: { applyStrategy: value } },
        contextNames+: { newString(value): value },
        withContextNames(value): { spec+: { contextNames: if std.isArray(value) then value else [value] } },
        withContextNamesMixin(value): { spec+: { contextNames+: if std.isArray(value) then value else [value] } },
        withDiffStrategy(value): { spec+: { diffStrategy: value } },
        withExpectVersions(value): { spec+: { expectVersions: value } },
        withExpectVersionsMixin(value): { spec+: { expectVersions+: value } },
        expectVersions+: {
          withTanka(value): { spec+: { expectVersions+: { tanka: value } } },
        },
        withInjectLabels(value): { spec+: { injectLabels: value } },
        withNamespace(value): { spec+: { namespace: value } },
        withResourceDefaults(value): { spec+: { resourceDefaults: value } },
        withResourceDefaultsMixin(value): { spec+: { resourceDefaults+: value } },
        resourceDefaults+: {
          withAnnotations(value): { spec+: { resourceDefaults+: { annotations: value } } },
          withAnnotationsMixin(value): { spec+: { resourceDefaults+: { annotations+: value } } },
          withLabels(value): { spec+: { resourceDefaults+: { labels: value } } },
          withLabelsMixin(value): { spec+: { resourceDefaults+: { labels+: value } } },
        },
      },
    },
  } },
} {
  tanka+: { v1alpha1+: { environment+: {
    new(name):
      self.withApiVersion('tanka.dev/v1alpha1')
      + self.withKind('environment')
      + self.metadata.withName(name),
  } } },
}
