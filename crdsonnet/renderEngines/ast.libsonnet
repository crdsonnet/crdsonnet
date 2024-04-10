local helpers = import '../helpers.libsonnet';
local a = import 'github.com/crdsonnet/astsonnet/main.libsonnet';
local astutils = import 'github.com/crdsonnet/astsonnet/utils.libsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  local this = self,

  nilvalue:: [],

  nestInParents(name, parents, field)::
    local startParents =
      if astutils.isObject(field)
      then parents[:std.length(parents) - 1]
      else parents;
    local startField =
      if astutils.isField(field) || astutils.isFieldFunction(field)
      then field
      else if astutils.isObject(field)
      then
        a.field.new(
          a.string.new(parents[std.length(parents) - 1]),
          field,
        )
        + a.field.withAdditive()
      else error '`field` is of type %s, must be a field type' % astutils.type(field);
    [
      std.foldr(
        function(p, acc)
          if p == name
          then acc
          else
            a.field.new(
              a.string.new(p),
              a.object.new([acc]),
            )
            + a.field.withAdditive(),
        startParents,
        startField,
      ),
    ],

  functionName(name)::
    local n = xtd.camelcase.toCamelCase(name);
    'with' + std.asciiUpper(n[0]) + n[1:],

  objectSubpackage(schema):: [
    a.field.new(
      a.string.new('#'),
      a.literal.new(
        d.package.newSub(schema._name, '')
      )
    ),
  ],

  functionHelp(functionName, schema)::
    a.field.new(
      a.string.new('#' + functionName),
      a.literal.new(  // render docsonnet as literal to avoid docsonnet dependency
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
    a.field_function.new(
      a.id.new(this.functionName(schema._name)),
      this.toObject(
        this.nestInParents(
          schema._name,
          schema._parents,
          a.field.new(
            a.string.new(schema._name),
            a.id.new('value')
          ),
        )
      ),
    )
    + a.field_function.withParams(
      a.params.new([
        a.param.new(a.id.new('value'))
        + (if 'default' in schema
           then
             a.param.withExpr(
               (if std.isString(schema.default)
                then a.string.new(schema.default)
                else a.literal.new(schema.default))
             )
           else {}),
      ]),
    ),
  ],

  withConstant(schema):: [
    self.functionHelp(
      this.functionName(schema._name),
      schema,
    ),
    a.field_function.new(
      a.id.new(this.functionName(schema._name)),
      this.toObject(
        this.nestInParents(
          schema._name,
          schema._parents,
          a.field.new(
            a.string.new(schema._name),
            if std.isString(schema.const)
            then a.string.new(schema.const)
            else a.literal.new(schema.const)
          ),
        )
      ),
    ),
  ],

  withBoolean(schema):: [
    self.functionHelp(
      this.functionName(schema._name),
      schema + { default: true },
    ),
    a.field_function.new(
      a.id.new(this.functionName(schema._name)),
      this.toObject(
        this.nestInParents(
          schema._name,
          schema._parents,
          a.field.new(
            a.string.new(schema._name),
            a.id.new('value')
          ),
        )
      ),
    )
    + a.field_function.withParams(
      a.params.new([
        a.param.new(a.id.new('value'))
        + a.param.withExpr(
          a.literal.new('true')
        ),
      ]),
    ),
  ],

  mixinFunction(schema):: [
    self.functionHelp(
      this.functionName(schema._name) + 'Mixin',
      schema,
    ),
    a.field_function.new(
      a.id.new(this.functionName(schema._name) + 'Mixin'),
      this.toObject(
        this.nestInParents(
          schema._name,
          schema._parents,
          a.field.new(
            a.string.new(schema._name),
            a.id.new('value'),
          )
          + a.field.withAdditive(),
        )
      ),
    )
    + a.field_function.withParams(
      a.params.new([
        a.id.new('value'),
      ]),
    ),
  ],

  arrayFunctions(schema)::
    local conditional =
      a.parenthesis.new(
        a.conditional.new(
          if_expr=a.functioncall.new(
                    a.fieldaccess.new(
                      [a.id.new('std')],
                      a.id.new('isArray'),
                    ),
                  )
                  + a.functioncall.withArgs(
                    [a.id.new('value')],
                  ),
          then_expr=a.id.new('value'),
        )
        + a.conditional.withElseExpr(
          a.array.new([a.id.new('value')])
        )
      );
    [
      self.functionHelp(
        this.functionName(schema._name),
        schema,
      ),
      a.field_function.new(
        a.id.new(this.functionName(schema._name)),
        this.toObject(
          this.nestInParents(
            schema._name,
            schema._parents,
            a.field.new(
              a.string.new(schema._name),
              conditional
            ),
          )
        ),
      )
      + a.field_function.withParams(
        a.params.new([
          a.id.new('value'),
        ]),
      ),
      self.functionHelp(
        this.functionName(schema._name) + 'Mixin',
        schema,
      ),
      a.field_function.new(
        a.id.new(this.functionName(schema._name) + 'Mixin'),
        this.toObject(
          this.nestInParents(
            schema._name,
            schema._parents,
            a.field.new(
              a.string.new(schema._name),
              conditional,
            )
            + a.field.withAdditive(),
          )
        ),
      )
      + a.field_function.withParams(
        a.params.new([
          a.id.new('value'),
        ]),
      ),
    ],

  named(name, expr):: [
    a.field.new(
      a.string.new(name),
      expr,
    )
    + a.field.withAdditive(),
  ],

  toObject(members)::
    a.object.new(members),

  newFunction(parents)::
    this.nestInParents(
      '',
      parents,
      self.toObject([
        a.field.new(
          a.string.new('#new'),
          a.literal.new(
            d.func.new(
              '`new` creates a new instance',
              [d.arg('name', d.T.string)],
            ),
          ),
        ),
        local params = [a.id.new('name')];
        a.field_function.new(
          a.id.new('new'),
          a.binary_sum.new([
            a.functioncall.new(a.fieldaccess.new([a.id.new('self')], a.id.new('withApiVersion'))),
            a.functioncall.new(a.fieldaccess.new([a.id.new('self')], a.id.new('withKind'))),
            a.functioncall.new(
              a.fieldaccess.new(
                [
                  a.id.new('self'),
                  a.id.new('metadata'),
                ],
                a.id.new('withName')
              ),
            )
            + a.functioncall.withArgs(params),
          ]),
        )
        + a.field_function.withParams(
          a.params.new(params),
        ),
      ])
    ),
}
