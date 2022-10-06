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

  withFunction(name, parents)::
    {
      [this.functionName(name)](value):
        this.nestInParents(name, parents, { [name]: value }),
    },

  withConstant(name, parents, value)::
    {
      [this.functionName(name)]():
        this.nestInParents(name, parents, { [name]: value }),
    },

  mixinFunction(name, parents)::
    {
      [this.functionName(name) + 'Mixin'](value):
        this.nestInParents(name, parents, { [name]+: value }),
    },

  arrayFunctions(name, parents)::
    {
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

  otherFunction(name, functionname)::
    this.named(name, { [functionname](value): value }),

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
