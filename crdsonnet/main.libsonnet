local parser = import './parser.libsonnet';
local renderer = import './render.libsonnet';
local testdata = import './testdata.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  local root = self,

  fromSchema(name, schema, schemaDB={}, render='static'):
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
      renderer[render].render(parsed[name]),

  local getVersionInDefinition(definition, version) =
    local versions = [
      v
      for v in definition.spec.versions
      if v.name == version
    ];
    if std.length(versions) == 0
    then error 'version %s in definition %s not found' % [version, definition.metadata.name]
    else if std.length(versions) > 1
    then error 'multiple versions match %s in definition' % [version, definition.metadata.name]
    else versions[0],

  local camelCaseKind(kind) =
    local s = xtd.camelcase.split(kind);
    std.asciiLower(s[0]) + std.join('', s[1:]),


  fromCRD(definition, groupSuffix, schemaDB={}, render='static'):
    local grouping =
      // If no dedicated API group, then use 'nogroup' key for consistency
      if groupSuffix == definition.spec.group
      then 'nogroup'
      else std.split(std.strReplace(
        definition.spec.group,
        '.' + groupSuffix,
        ''
      ), '.')[0];

    local kind = camelCaseKind(definition.spec.names.kind);

    local versions = [
      version.name
      for version in definition.spec.versions
    ];

    local schema(version) =
      getVersionInDefinition(definition, version).schema.openAPIV3Schema;

    local parsed = std.foldl(
      function(acc, version)
        acc
        + renderer[render].properties(
          renderer[render].nestInParents(
            [grouping, version],
            renderer[render].schema(
              (
                parser.parseSchema(
                  kind,
                  schema(version),
                  schema(version),
                  schemaDB
                ) + { [kind]+: { _name: kind } }
              )[kind]
            )
          )
        ),
      versions,
      renderer[render].nilvalue,
    );
    parsed,


  parsed: self.fromCRD(testdata.crd, 'cert-manager.io'),

  //local schema = testdata.db['https://example.com/schemas/customer'],
  // local schema = testdata.testSchemas[0],
  //parsed: root.fromSchema(
  //  //parser.getRefName(schema['$ref']),
  //  parser.getRefName(parser.getID(schema)),
  //  schema,
  //  testdata.db
  //),
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
