local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  local this = self,

  nilvalue:: {},

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
    local underscores = std.set(std.findSubstr('_', name));
    local n = std.join('', [
      if std.setMember(i - 1, underscores)
      then std.asciiUpper(name[i])
      else name[i]
      for i in std.range(0, std.length(name) - 1)
      if !std.setMember(i, underscores)
    ]);
    'with' + std.asciiUpper(n[0]) + n[1:],

  functionHelp(name, object):: {
    ['#%s' % name]::
      d.fn(
        help=(if 'description' in object
              then object.description
              else ''),
        args=[d.arg(
          'value',
          (if 'type' in object
           then object.type
           else 'string')
        )]
      ),
  },

  withFunction(name, parents, object)::
    this.functionHelp(this.functionName(name), object)
    + (if 'default' in object
       then {
         [this.functionName(name)](value=object.default):
           this.nestInParents(name, parents, { [name]: value }),
       }
       else {
         [this.functionName(name)](value):
           this.nestInParents(name, parents, { [name]: value }),
       }),

  withConstant(name, parents, object)::
    this.functionHelp(this.functionName(name), object)
    + {
      [this.functionName(name)]():
        this.nestInParents(name, parents, { [name]: object.const }),
    },

  withBoolean(name, parents, object)::
    this.functionHelp(this.functionName(name), object)
    + {
      [this.functionName(name)](value=true):
        this.nestInParents(name, parents, { [name]: value }),
    },

  mixinFunction(name, parents, object)::
    this.functionHelp(this.functionName(name) + 'Mixin', object)
    + {
      [this.functionName(name) + 'Mixin'](value):
        this.nestInParents(name, parents, { [name]+: value }),
    },

  arrayFunctions(name, parents, object)::
    this.functionHelp(this.functionName(name), object)
    + this.functionHelp(this.functionName(name) + 'Mixin', object)
    + {
      [this.functionName(name)](value):
        this.nestInParents(
          name,
          parents,
          this.named(name, if std.isArray(value) then value else [value])
        ),

      [this.functionName(name) + 'Mixin'](value):
        this.nestInParents(
          name,
          parents,
          this.named(name, if std.isArray(value) then value else [value])
        ),
    },

  otherFunction(name, functionname, object)::
    this.named(
      name,
      this.functionHelp(functionname, object)
      + { [functionname](value): value }
    ),

  named(name, object)::
    {
      [name]+: object,
    },

  compositeRef(name, refname, parsed)::
    {
      // Expose composite types in a nested `types` field
      [name]+: {
        types+: {
          [refname]+: parsed,
        },
      },
    },

  properties(object)::
    object,

  withMixin(name, parents)::
    this.nestInParents(
      name,
      parents,
      { mixin: self },
    ),

  newFunction(apiVersion, kind, parents)::
    this.nestInParents(
      'new',
      parents,
      {
        new(name):
          self.withApiVersion(apiVersion)
          + self.withKind(kind)
          + self.metadata.withName(name),
      },
    ),

  fromSchema(grouping, version, parsed)::
    this.nestInParents(
      '',
      [grouping, version],
      parsed,
    ),
}
