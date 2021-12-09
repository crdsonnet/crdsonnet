(import './main.libsonnet') {
  local this = self,

  nilvalue:: '',

  nestInParents(name, parents, object)::
    std.foldr(
      function(p, acc)
        if p == name
        then acc
        else p + ': { ' + acc + ' }',
      parents,
      object
    ),

  withFunction(name, parents)::
    |||
      %s(value): { %s },
    ||| % [
      this.functionName(name),
      this.nestInParents(name, parents, name + ': value'),
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

  handleProperties(name, parents, properties, refs={})::
    '{ %s }' % super.handleProperties(name, parents, properties, refs),
}
