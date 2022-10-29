local parser = import './parser.libsonnet';
local renderer = import './render.libsonnet';
local testdata = import './testdata.libsonnet';

{
  local root = self,

  fromSchema(name, schema, schemaDB):
    if name == ''
    then error "name can't be an empty string"
    else
      local parsed = parser.parseSchema(
        name,
        schema,
        schema,
        schemaDB
      ) + { [name]+: { _name: name } };
      //parsed,
      renderer.static.render(parsed[name]),

  //local schema = testdata.db.schemas['https://example.com/schemas/customer'],
  local schema = testdata.testSchemas[0],
  parsed: root.fromSchema(
    parser.getRefName(schema['$ref']),
    //parser.getRefName(parser.getID(schema)),
    schema,
    testdata.db
  ),
  //parsed: [
  //  root.fromSchema(
  //    std.trace(parser.getRefName(parser.getID(schema)), parser.getRefName(parser.getID(schema))),
  //    schema,
  //    testdata.db
  //  )
  //  for schema in testdata.testSchemas
  //  if std.trace(parser.getRefName(parser.getID(schema)), true)
  //],
}.parsed

// vim: foldmethod=marker foldmarker=foldStart,foldEnd
