local parser = import 'crdsonnet/parser.libsonnet';
local schemaDB = import 'crdsonnet/schemadb.libsonnet';
local test = import 'github.com/jsonnet-libs/testonnet/main.libsonnet';

test.new(std.thisFile)
+ test.case.new(
  name='Empty schema',
  test=test.expect.eq(
    actual=
    local schema = {};
    parser.parseSchema('test', schema, schema, {}),
    expected={ test: {} }
  )
)
+ test.case.new(
  name='Ref does not exist',
  test=test.expect.eq(
    actual=
    local schema = { '$ref': '/schema/does/not/exist' };
    parser.resolveRef(schema['$ref'], schema, {}),
    expected={}
  )
)
+ test.case.new(
  name='Ref with fragment does not exist',
  test=test.expect.eq(
    actual=
    local schema = { '$ref': '/schema/does/not/exist#/fragment/does/not/exist' };
    parser.resolveRef(schema['$ref'], schema, {}),
    expected={}
  )
)
+ test.case.new(
  name='Fragment exists',
  test=test.expect.eq(
    actual=
    local schema = {
      // Fragment only
      '$ref': '#/properties/first_name',
      properties: {
        first_name: { type: 'string' },
      },
    };
    parser.resolveRef(schema['$ref'], schema, {}),
    expected={ type: 'string' }
  )
)
+ test.case.new(
  name='Relative ref in SchemaDB',
  test=test.expect.eq(
    actual=
    local db = schemaDB.add({
      '$id': 'https://example.com/schemas/person',
      properties: {
        first_name: { type: 'string' },
      },
    });
    local schema = {
      '$id': 'https://example.com/schemas/customer',
      '$ref': '/schemas/person',
    };
    parser.resolveRef(schema['$ref'], schema, db),
    expected={
      '$id': 'https://example.com/schemas/person',
      properties: {
        first_name: { type: 'string' },
      },
    }
  )
)
+ test.case.new(
  name='Relative ref with fragment in SchemaDB',
  test=test.expect.eq(
    actual=
    local db = schemaDB.add({
      '$id': 'https://example.com/schemas/person',
      properties: {
        first_name: { type: 'string' },
      },
    });
    local schema = {
      '$id': 'https://example.com/schemas/customer',
      '$ref': '/schemas/person#/properties/first_name',
    };
    parser.resolveRef(schema['$ref'], schema, db),
    expected={ type: 'string' },
  )
)
+ test.case.new(
  name='Absolute ref in SchemaDB',
  test=test.expect.eq(
    actual=
    local db = schemaDB.add({
      '$id': 'https://example.com/schemas/person',
      properties: {
        first_name: { type: 'string' },
      },
    });
    local schema = {
      '$ref': 'https://example.com/schemas/person',
    };
    parser.resolveRef(schema['$ref'], schema, db),
    expected={
      '$id': 'https://example.com/schemas/person',
      properties: {
        first_name: { type: 'string' },
      },
    }
  )
)
+ test.case.new(
  name='Absolute ref with fragment in SchemaDB',
  test=test.expect.eq(
    actual=
    local db = schemaDB.add({
      '$id': 'https://example.com/schemas/person',
      properties: {
        first_name: { type: 'string' },
      },
    });
    local schema = {
      '$ref': 'https://example.com/schemas/person#/properties/first_name',
    };
    parser.resolveRef(schema['$ref'], schema, db),
    expected={ type: 'string' },
  )
)

// vim: foldmethod=marker foldmarker=(,) foldlevel=1
