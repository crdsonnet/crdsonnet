local helpers = import '../helpers.libsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  local this = self,

  nilvalue:: {},

  validate(schema, value):: true,

  nestInParents(name, parents, object)::
    std.foldr(
      function(p, acc)
        if p == name
        then acc
        else { [p]+: acc }
      ,
      parents,
      object
    ),

  functionName(name)::
    local n = xtd.camelcase.toCamelCase(name);
    'with' + std.asciiUpper(n[0]) + n[1:],

  objectSubpackage(schema):: {
    '#':: d.package.newSub(schema._name, ''),
  },

  functionHelp(functionName, schema):: {
    ['#%s' % functionName]::
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
  },

  withFunction(schema)::
    this.functionHelp(this.functionName(schema._name), schema)
    + (if 'default' in schema
       then {
         [this.functionName(schema._name)](value=schema.default):
           assert this.validate(schema, value);
           this.nestInParents(schema._name, schema._parents, { [schema._name]: value }),
       }
       else {
         [this.functionName(schema._name)](value):
           assert this.validate(schema, value);
           this.nestInParents(schema._name, schema._parents, { [schema._name]: value }),
       }),

  withConstant(schema)::
    this.functionHelp(this.functionName(schema._name), schema)
    + {
      [this.functionName(schema._name)]():
        this.nestInParents(schema._name, schema._parents, { [schema._name]: schema.const }),
    },

  withBoolean(schema)::
    this.functionHelp(
      this.functionName(schema._name),
      schema + { default: true },
    )
    + {
      [this.functionName(schema._name)](value=true):
        assert this.validate(schema, value);
        this.nestInParents(schema._name, schema._parents, { [schema._name]: value }),
    },

  mixinFunction(schema)::
    this.functionHelp(this.functionName(schema._name) + 'Mixin', schema)
    + {
      [this.functionName(schema._name) + 'Mixin'](value):
        assert this.validate(schema, value);
        this.nestInParents(schema._name, schema._parents, { [schema._name]+: value }),
    },

  arrayFunctions(schema)::
    this.functionHelp(this.functionName(schema._name), schema)
    + this.functionHelp(this.functionName(schema._name) + 'Mixin', schema)
    + {
      [this.functionName(schema._name)](value):
        assert this.validate(schema, value);
        this.nestInParents(
          schema._name,
          schema._parents,
          this.named(schema._name, if std.isArray(value) then value else [value])
        ),

      [this.functionName(schema._name) + 'Mixin'](value):
        assert this.validate(schema, value);
        this.nestInParents(
          schema._name,
          schema._parents,
          this.named(schema._name, if std.isArray(value) then value else [value])
        ),
    },

  named(name, object):: {
    [name]+: object,
  },

  toObject(object)::
    object,

  newFunction(parents)::
    this.nestInParents(
      'new',
      parents,
      {
        new(name):
          self.withApiVersion()
          + self.withKind()
          + self.metadata.withName(name),
      },
    ),
}
