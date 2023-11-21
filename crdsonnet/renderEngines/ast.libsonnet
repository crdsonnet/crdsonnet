local helpers = import '../helpers.libsonnet';
local j = import 'github.com/Duologic/jsonnet-libsonnet/main.libsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  local this = self,

  nilvalue:: [],

  // jsonnet-libsonnet provides some formatting with indentation and linebreaks, this customField removes that formatting, ideally this type of formatting should be configurable but I haven't found a good interface for that yet.
  local customField = {
    field(fieldname, expr, additive=false, hidden=false):
      j.field.field(fieldname, expr, additive, hidden)
      + {
        toString(indent='', break=''):
          j.field.field(fieldname, expr, additive, hidden).toString(),
      },
    func(fieldname, expr, params=[], hidden=false):
      j.field.func(fieldname, expr, params, hidden)
      + {
        toString(indent='', break=''):
          j.field.func(fieldname, expr, params, hidden).toString(),
      },
  },

  nestInParents(name, parents, field)::
    j.object.members([
      std.foldr(
        function(p, acc)
          if p == name
          then acc
          else
            customField.field(
              j.fieldname.string(p),
              j.object.members([
                acc,
              ]),
              additive=true,
            ),
        parents,
        field,
      ),
    ]),

  functionName(name)::
    local n = xtd.camelcase.toCamelCase(name);
    'with' + std.asciiUpper(n[0]) + n[1:],

  objectSubpackage(schema):: [
    customField.field(
      j.fieldname.string('#'),
      j.literal(
        d.package.newSub(schema._name, '')
      )
    ),
  ],

  functionHelp(functionName, schema)::
    customField.field(
      j.fieldname.string('#' + functionName),
      j.literal(  // render docsonnet as literal to avoid docsonnet dependency
        d.fn(
          help=std.get(schema, 'description', ''),
          args=(
            if 'const' in schema
            then []
            else [
              d.arg(
                'value',
                type=helpers.getSchemaTypes(schema),
                default=(
                  if 'default' in schema
                  then schema.default
                  else null
                ),
                enums=(
                  if 'enum' in schema
                  then schema.enum
                  else null
                )
              ),
            ]
          )
        ),
      )
    ),

  withFunction(schema):: [
    self.functionHelp(
      this.functionName(schema._name),
      schema,
    ),
    customField.func(
      j.fieldname.id(this.functionName(schema._name)),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        customField.field(
          j.fieldname.string(schema._name),
          j.id('value')
        ),
      ),
      params=[
        if 'default' in schema
        then
          j.param.expr(
            j.id('value'),
            (if std.isString(schema.default)
             then j.string(schema.default)
             else j.literal(schema.default))
          )
        else j.param.id('value'),
      ],
    ),
  ],

  withConstant(schema):: [
    self.functionHelp(
      this.functionName(schema._name),
      schema,
    ),
    customField.func(
      j.fieldname.id(this.functionName(schema._name)),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        customField.field(
          j.fieldname.string(schema._name),
          if std.isString(schema.const)
          then j.string(schema.const)
          else j.literal(schema.const)
        ),
      ),
    ),
  ],

  withBoolean(schema):: [
    self.functionHelp(
      this.functionName(schema._name),
      schema + { default: true },
    ),
    customField.func(
      j.fieldname.id(this.functionName(schema._name)),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        customField.field(
          j.fieldname.string(schema._name),
          j.id('value')
        ),
      ),
      params=[
        j.param.expr(
          j.id('value'),
          j['true'],
        ),
      ],
    ),
  ],

  mixinFunction(schema):: [
    self.functionHelp(
      this.functionName(schema._name) + 'Mixin',
      schema,
    ),
    customField.func(
      j.fieldname.id(this.functionName(schema._name) + 'Mixin'),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        customField.field(
          j.fieldname.string(schema._name),
          j.id('value'),
          additive=true,
        ),
      ),
      params=[
        j.param.id('value'),
      ],
    ),
  ],

  arrayFunctions(schema)::
    local conditional =
      j.conditional(
        ifexpr=j.functioncall(
          j.fieldaccess(
            [j.id('std')],
            j.id('isArray'),
          ),
          args=[j.id('value')],
        ),
        thenexpr=j.id('value'),
        elseexpr=j.array.items([j.id('value')]),
      );
    [
      self.functionHelp(
        this.functionName(schema._name),
        schema,
      ),
      customField.func(
        j.fieldname.id(this.functionName(schema._name)),
        expr=this.nestInParents(
          schema._name,
          schema._parents,
          customField.field(
            j.fieldname.string(schema._name),
            conditional
          ),
        ),
        params=[
          j.param.id('value'),
        ],
      ),
      self.functionHelp(
        this.functionName(schema._name) + 'Mixin',
        schema,
      ),
      customField.func(
        j.fieldname.id(this.functionName(schema._name) + 'Mixin'),
        expr=this.nestInParents(
          schema._name,
          schema._parents,
          customField.field(
            j.fieldname.string(schema._name),
            conditional,
            additive=true,
          ),
        ),
        params=[
          j.param.id('value'),
        ],
      ),
    ],

  named(name, expr):: [
    j.field.field(
      j.string(name),
      expr,
      additive=true
    ),
  ],

  toObject(members)::
    j.object.members(members),

  newFunction(parents):: [
    local params = [j.id('name')];
    customField.func(
      j.id('new'),
      j.binary(
        '+',
        [
          j.functioncall(j.fieldaccess([j.id('self')], j.id('withApiVersion'))),
          j.functioncall(j.fieldaccess([j.id('self')], j.id('withKind'))),
          j.functioncall(
            j.fieldaccess(
              [
                j.id('self'),
                j.id('metadata'),
              ],
              j.id('withName')
            ),
            args=params
          ),
        ],
        params=params,
      )
    ),
  ],
}
