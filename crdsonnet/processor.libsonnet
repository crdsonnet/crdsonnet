local parser = import './parser.libsonnet';
local renderEngine = import './render.libsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';

{
  '#': d.package.newSub(
    'processor',
    |||
      `processor` provides an interface to configure the parser and render engine, returns a parser() and render() function.
    |||
  ),

  '#new': d.fn(
    |||
      `new` initializes the processor with sane defaults, returning a parser() and render() function.
    |||,
  ),
  new(): {
    schemaDB: {},
    renderEngine: renderEngine.new('dynamic'),
    parse(name, schema):
      parser.parseSchema(
        name,
        schema,
        schema,
        self.schemaDB
      ) + { [name]+: { _name: name } },
    render(name, schema):
      local parsedSchema = self.parse(name, schema);
      self.renderEngine.render(parsedSchema[name]),
  },
  '#withSchemaDB': d.fn(
    |||
      `withSchemaDB` adds additional schema databases. These can be created with `crdsonnet.schemaDB`.
    |||,
    args=[d.arg('db', d.T.object)],
  ),
  withSchemaDB(db): {
    schemaDB+: db,
  },
  '#withRenderEngine': d.fn(
    |||
      `withRenderEngine` configures an alternative render engine. This can be created with `crdsonnet.renderEngine`.
    |||,
    args=[d.arg('engine', d.T.object)],
  ),
  withRenderEngine(engine): {
    renderEngine: engine,
  },
  '#withRenderEngineType': d.fn(
    |||
      `withRenderEngineType` is a shortcut to configure an alternative render engine type.
    |||,
    args=[d.arg('engineType', d.T.string, enums=['dynamic', 'static'])],
  ),
  withRenderEngineType(engineType):
    self.withRenderEngine(renderEngine.new(engineType)),
}
