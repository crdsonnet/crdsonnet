local helpers = import 'crdsonnet/helpers.libsonnet';
local crdsonnet = import 'crdsonnet/main.libsonnet';
local processor = import 'crdsonnet/processor.libsonnet';
local test = import 'github.com/jsonnet-libs/testonnet/main.libsonnet';

// A `spec` nested in `spec.config`, so a parent has the same name as the field.
local schema = {
  type: 'object',
  properties: {
    spec: {
      type: 'object',
      properties: {
        config: {
          type: 'object',
          properties: {
            spec: { type: 'object' },
            name: { type: 'string' },
          },
        },
      },
    },
  },
};

local render(engine) = crdsonnet.schema.render('example', schema, processor.new(engine));
local contains(haystack, needle) = std.length(std.findSubstr(needle, haystack)) == 1;

test.new(std.thisFile)
+ test.case.new(
  name='outerParents drops only the field itself',
  test=test.expect.eq(
    actual=helpers.outerParents('spec', ['spec', 'config', 'spec']),
    expected=['spec', 'config']
  )
)
+ test.case.new(
  name='outerParents keeps parents if the field is not the last one',
  test=test.expect.eq(
    actual=helpers.outerParents('spec', ['spec', 'config']),
    expected=['spec', 'config']
  )
)
+ test.case.new(
  name='outerParents keeps an empty path',
  test=test.expect.eq(
    actual=helpers.outerParents('', []),
    expected=[]
  )
)
+ test.case.new(
  name='dynamic: field named like a parent',
  test=test.expect.eq(
    actual=render('dynamic').example.spec.config.withSpec({ x: 1 }),
    expected={ spec: { config: { spec: { x: 1 } } } }
  )
)
+ test.case.new(
  name='dynamic: mixin named like a parent',
  test=test.expect.eq(
    actual=render('dynamic').example.spec.config.withSpecMixin({ x: 1 }),
    expected={ spec: { config: { spec+: { x: 1 } } } }
  )
)
+ test.case.new(
  name='dynamic: field not named like a parent',
  test=test.expect.eq(
    actual=render('dynamic').example.spec.config.withName('a'),
    expected={ spec: { config: { name: 'a' } } }
  )
)
+ test.case.new(
  name='ast: field named like a parent',
  test=test.expect.eq(
    actual=contains(
      render('ast').toString(),
      "withSpec(value):{\n'spec'+:{\n'config'+:{\n'spec':value\n}\n}\n}"
    ),
    expected=true
  )
)
+ test.case.new(
  name='static: field named like a parent',
  test=test.expect.eq(
    actual=contains(
      render('static'),
      'withSpec(value): { "spec"+: { "config"+: { "spec": value } } }'
    ),
    expected=true
  )
)
