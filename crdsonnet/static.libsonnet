{
  local this = self,

  nilvalue:: '',

  nestInParents(name, parents, object)::
    std.foldr(
      function(p, acc)
        if p == name
        then acc
        else p + '+: { ' + acc + ' }',
      parents,
      object
    ),

  functionName(name)::
    'with' + std.asciiUpper(name[0]) + name[1:],

  withFunction(name, parents)::
    |||
      %s(value): { %s },
    ||| % [
      this.functionName(name),
      this.nestInParents(name, parents, name + ': value'),
    ],

  withConstant(name, parents, value)::
    |||
      %s(): { %s },
    ||| % [
      this.functionName(name),
      this.nestInParents(name, parents, name + ": '" + value + "'"),
    ],

  mixinFunction(name, parents)::
    |||
      %sMixin(value): { %s },
    ||| % [
      this.functionName(name),
      this.nestInParents(name, parents, name + '+: value'),
    ],

  arrayFunctions(name, parents)::
    |||
      %s(value): { %s },
      %sMixin(value): { %s },
    ||| % [
      this.functionName(name),
      this.nestInParents(
        name,
        parents,
        ' %s: if std.isArray(value) then value else [value] ' % name,
      ),
      this.functionName(name),
      this.nestInParents(
        name,
        parents,
        ' %s+: if std.isArray(value) then value else [value] ' % name,
      ),
    ],

  otherFunction(name, functionname)::
    '%s+: { %s(value): value },' % [
      name,
      functionname,
    ],

  named(name, object)::
    |||
      %s+: %s,
    ||| % [
      name,
      object,
    ],

  // Don't process refs in composite
  compositeRef(name, refname, parsed):: '',
  //|||
  //  ['%s']+: { ['%s']+: { %s } },
  //||| % [
  //  name,
  //  refname,
  //  parsed,
  //],

  properties(object)::
    '{ %s }' % object,

  withMixin(name, parents)::
    this.nestInParents(
      name,
      parents,
      '{ mixin: self }'
    ),

  newFunction(apiVersion, kind, parents)::
    '{\n %s \n}' %
    this.nestInParents(
      'new',
      parents,
      |||
        new(name):
          self.withApiVersion('%(apiVersion)s')
          + self.withKind('%(kind)s')
          + self.metadata.withName(name),
      ||| % {
        apiVersion: apiVersion,
        kind: kind,
      },
    ),

  fromSchema(grouping, version, parsed)::
    '{\n %s \n}' %
    this.nestInParents(
      '',
      [grouping, version],
      parsed,
    ),
}
