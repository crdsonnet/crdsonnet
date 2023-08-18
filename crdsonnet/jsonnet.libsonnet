local j = import 'github.com/Duologic/jsonnet-libsonnet/main.libsonnet';

{
  local this = self,

  nilvalue:: [],

  nestInParents(name, parents, field)::
    j.object.members([
      std.foldr(
        function(p, acc)
          if p == name
          then acc
          else
            j.field.field(
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
    local underscores = std.set(std.findSubstr('_', name));
    local n = std.join('', [
      if std.setMember(i - 1, underscores)
      then std.asciiUpper(name[i])
      else name[i]
      for i in std.range(0, std.length(name) - 1)
      if !std.setMember(i, underscores)
    ]);
    'with' + std.asciiUpper(n[0]) + n[1:],

  withFunction(schema):: [
    j.field.func(
      j.fieldname.id(this.functionName(schema._name)),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        j.field.field(
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
    j.field.func(
      j.fieldname.id(this.functionName(schema._name)),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        j.field.field(
          j.fieldname.string(schema._name),
          j.literal(schema.const)
        ),
      ),
    ),
  ],

  withBoolean(schema):: [
    j.field.func(
      j.fieldname.id(this.functionName(schema._name)),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        j.field.field(
          j.fieldname.string(schema._name),
          j.id('value')
        ),
      ),
      params=[
        j.param.expr(
          j.id('value'),
          if 'default' in schema
          then j.literal(schema.default)
          else j['true']
        ),
      ],
    ),
  ],

  mixinFunction(schema):: [
    j.field.func(
      j.fieldname.id(this.functionName(schema._name) + 'Mixin'),
      expr=this.nestInParents(
        schema._name,
        schema._parents,
        j.field.field(
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
      j.field.func(
        j.fieldname.id(this.functionName(schema._name)),
        expr=this.nestInParents(
          schema._name,
          schema._parents,
          j.field.field(
            j.fieldname.string(schema._name),
            conditional
          ),
        ),
        params=[
          j.param.id('value'),
        ],
      ),
      j.field.func(
        j.fieldname.id(this.functionName(schema._name) + 'Mixin'),
        expr=this.nestInParents(
          schema._name,
          schema._parents,
          j.field.field(
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

  newFunction(parents)::
    local params = [j.id('name')];
    j.field.func(
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
}
