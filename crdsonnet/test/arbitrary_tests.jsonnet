local crdsonnet = import './main.libsonnet';
local testdata = import './testdata.libsonnet';

//local schema = import 'testschema.json';
//crdsonnet.fromKubernetesOpenAPI(schema)

//local component = schema.definitions['io.k8s.api.core.v1.Pod'];
//crdsonnet.fromOpenAPI('pod', component, schema)

//local lib = crdsonnet.fromCRD(testdata.crd, 'cert-manager.io', render='dynamic');
//lib.nogroup.v1.certificate.new('n')

//local schema = testdata.db['https://example.com/schemas/customer'];
//local schema = testdata.testSchemas[0];
//crdsonnet.fromSchema(
//  'customer',
//  schema,
//  testdata.db
//)

local parser = import './parser.libsonnet';
[
  parser.parseSchema(
    'test',
    schema,
    schema,
    testdata.db
  )
  for schema in testdata.testSchemas
  if std.trace(parser.getRefName(parser.getID(schema)), true)
]
