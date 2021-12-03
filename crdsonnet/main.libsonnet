// vim: fdm=indent
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';
local k8s = import 'kubernetes-spec/swagger.json';

{
  local this = self,
  debug:: false,

  local infoMessage(message, return) =
    if this.debug
    then std.trace('INFO: ' + message, return)
    else return,

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
    'with' + std.asciiUpper(name[0]) + name[1:],

  withFunction(name, parents)::
    {
      [this.functionName(name)](value):
        this.nestInParents(name, parents, { [name]: value }),
    },

  mixinFunction(name, parents)::
    {
      [this.functionName(name) + 'Mixin'](value):
        this.nestInParents(name, parents, { [name]+: value }),
    },

  handleObject(name, parents, object, refs={})::
    (
      if parents != []
      then this.withFunction(name, parents)
           + this.mixinFunction(name, parents)
      else {}
    )
    + (
      if std.objectHas(object, 'properties')
      then { [name]+: this.handleProperties(name, parents, object.properties, refs) }
      else {}
    )
    + (
      if std.objectHas(object, 'items')
      then { [name]+: this.parse(name, parents, object.items, refs) }
      else {}
    )
    + (
      if std.objectHas(object, 'allOf')
         || std.objectHas(object, 'oneOf')
         || std.objectHas(object, 'anyOf')
      then this.handleComposite(name, parents, object, refs)
      else {}
    )
    + (
      if !std.objectHas(object, 'properties')
         && !std.objectHas(object, 'items')
         && !std.objectHas(object, 'allOf')
         && !std.objectHas(object, 'oneOf')
         && !std.objectHas(object, 'anyOf')
      then
        if name == 'metadata'
        then {
          [name]+: this.handleProperties(
            name,
            parents,
            k8s.definitions['io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta'].properties,
            refs,
          ),
        }
        else if parents == []
        then {
          [name]+: this.withFunction(name, parents)
                   + this.mixinFunction(name, parents),
        }
        else {}
      else {}
    ),

  handleArray(name, parents, array, refs={})::
    (
      if std.objectHas(array, 'items')
      then this.parse(name, parents, array.items, refs)
      else {}
    )
    + (
      if std.objectHas(array, 'allOf')
         || std.objectHas(array, 'oneOf')
         || std.objectHas(array, 'anyOf')
      then { [name]+: this.handleComposite(name, parents, array, refs) }
      else {}
    )
    + {
      [this.functionName(name)](value):
        this.nestInParents(
          name,
          parents,
          { [name]: if std.isArray(value) then value else [value] }
        ),

      [this.functionName(name) + 'Mixin'](value):
        this.nestInParents(
          name,
          parents,
          { [name]+: if std.isArray(value) then value else [value] }
        ),
    },

  handleOther(name, parents)::
    if parents == []
    then { [name]+: this.withFunction(name, parents) }
    else this.withFunction(name, parents),

  handleComposite(name, parents, object, refs={})::
    local handle(composite) = std.foldl(
      function(acc, c)
        local parsed = this.parse(
          name,
          parents,
          c,
          refs,
        );
        acc + (
          if std.objectHas(c, '$ref')
          then {
            local refname =
              local s = xtd.camelcase.split(this.getRefName(c));
              std.asciiLower(s[0]) + std.join('', s[1:]),
            // Expose composite types in a nested `types` field
            [name]+: {
              types+: {
                [refname]+: parsed,
              },
            },
          }
          else parsed
        ),
      composite,
      {}
    );
    (
      if std.objectHas(object, 'allOf')
      then handle(object.allOf)
      else {}
    )
    + (
      if std.objectHas(object, 'oneOf')
      then handle(object.oneOf)
      else {}
    )
    + (
      if std.objectHas(object, 'anyOf')
      then handle(object.anyOf)
      else {}
    ),

  getRefName(object)::
    std.reverse(std.split(object['$ref'], '/'))[0],

  handleRef(name, parents, object, refs={})::
    local ref = this.getRefName(object);
    if refs != {} && std.objectHas(refs, ref)
    then this.parse(name, parents, refs[ref], refs)
    else this.handleOther(name, parents)
  ,

  handleProperties(name, parents, properties, refs={})::
    std.foldl(
      function(acc, p)
        acc + this.parse(
          p,
          parents + [p],
          properties[p],
          refs,
        ),
      std.objectFields(properties),
      {}
    ),

  parse(name, parents, property, refs={})::
    local type =
      if std.objectHas(property, 'type')
      then property.type

      else if std.objectHas(property, 'allOf')
              || std.objectHas(property, 'oneOf')
              || std.objectHas(property, 'anyOf')
      then 'composite'

      else if std.objectHas(property, '$ref')
      then 'ref'

      else infoMessage(
        'Unsupported property %s with fields %s' % [
          std.join('.', parents),
          std.toString(std.objectFields(property)),
        ],
        ''
      )
    ;

    (
      if type == 'object'
      then this.handleObject(name, parents, property, refs)

      else if type == 'array'
      then this.handleArray(name, parents, property, refs)

      else if type == 'ref'
      then this.handleRef(name, parents, property, refs)

      else if type == 'composite'
      then this.handleComposite(name, parents, property, refs)

      else this.handleOther(name, parents)
    ),

  camelCaseKind(kind)::
    local s = xtd.camelcase.split(kind);
    std.asciiLower(s[0]) + std.join('', s[1:]),

  fromSchema(grouping, group, version, kind, schema, refs={}, withMixin=false)::
    {
      local kindname = this.camelCaseKind(kind),

      [grouping]+:: {
        [version]+:
          this.parse(kindname, [], schema, refs)
          + {
            [kindname]+:
              (if withMixin then { mixin: self } else {})
              + (if std.objectHas(schema, 'x-kubernetes-group-version-kind')
                 then {
                   new(name):
                     local gvk = schema['x-kubernetes-group-version-kind'];
                     local gv =
                       if gvk[0].group == ''
                       then gvk[0].version
                       else gvk[0].group + '/' + gvk[0].version;

                     self.withApiVersion(gv)
                     + self.withKind(kind)
                     + self.metadata.withName(name),
                 }
                 else if std.objectHas(schema, 'properties')
                         && std.objectHas(schema.properties, 'kind')
                 then {
                   new(name):
                     self.withApiVersion(group + '/' + version)
                     + self.withKind(kind)
                     + self.metadata.withName(name),
                 }
                 else {}),
          },
      },
    },

  fromCRD(definition, group_suffix)::
    local grouping =
      // If no dedicated API group, then use nogroup key for consistency
      if group_suffix == definition.spec.group
      then 'nogroup'
      else std.split(std.strReplace(definition.spec.group, '.' + group_suffix, ''), '.')[0];

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
      else versions[0];

    std.foldl(
      function(acc, v)
        acc
        + this.fromSchema(
          grouping,
          definition.spec.group,
          v,
          definition.spec.names.kind,
          getVersionInDefinition(definition, v).schema.openAPIV3Schema,
        ),
      [
        version.name
        for version in definition.spec.versions
      ],
      {}
    ),

  // limit recursion depth with maxDepth
  inspect(fields, maxDepth=10, depth=0)::
    std.foldl(
      function(acc, p)
        acc + (
          if std.isObject(fields[p])
             && depth != maxDepth
          then { [p]+:
            this.inspect(
              fields[p],
              maxDepth,
              depth + 1
            ) }
          else if std.isFunction(fields[p])
          then { functions+: [p] }
          else { fields+: [p] }
        ),
      std.objectFields(fields),
      {}
    ),
}
