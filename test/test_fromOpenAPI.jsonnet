local crdsonnet = import 'crdsonnet/main.libsonnet';
local test = import 'github.com/jsonnet-libs/testonnet/main.libsonnet';

local schema = import 'testschema.json';

test.new(std.thisFile)
+ test.case.new(
  name='fromOpenAPI smoke test',
  test=test.expect.eq(
    actual=
    local component = schema.definitions['io.k8s.api.core.v1.Pod'];
    local library = crdsonnet.fromOpenAPI('pod', component, schema);
    library.pod.new('test'),
    expected={
      apiVersion: 'v1',
      kind: 'Pod',
      metadata: { name: 'test' },
    }
  )
)
+ test.case.new(
  name='fromKubernetesOpenAPI smoke test',
  test=test.expect.eq(
    actual=
    local library = crdsonnet.fromKubernetesOpenAPI(schema);
    library.core.v1.pod.new('test'),
    expected={
      apiVersion: 'v1',
      kind: 'Pod',
      metadata: { name: 'test' },
    }
  )
)
