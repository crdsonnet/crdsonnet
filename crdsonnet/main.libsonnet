// vim: fdm=indent
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  local this = self,
  debug:: false,
  render:: (import './dynamic.libsonnet'),

  local infoMessage(message, return) =
    if this.debug
    then std.trace('INFO: ' + message, return)
    else return,

  handleObject(name, parents, object, refs={})::
    (
      if parents != []
      then this.render.withFunction(name, parents)
           + this.render.mixinFunction(name, parents)
      else this.render.nilvalue
    )
    + (
      if std.objectHas(object, 'properties')
      then this.render.named(name, this.handleProperties(name, parents, object.properties, refs))
      else this.render.nilvalue
    )
    + (
      if std.objectHas(object, 'items')
      then this.render.named(name, this.parse(name, parents, object.items, refs))
      else this.render.nilvalue
    )
    + (
      if std.objectHas(object, 'allOf')
         || std.objectHas(object, 'oneOf')
         || std.objectHas(object, 'anyOf')
      then this.handleComposite(name, parents, object, refs)
      else this.render.nilvalue
    )
    + (
      if !std.objectHas(object, 'properties')
         && !std.objectHas(object, 'items')
         && !std.objectHas(object, 'allOf')
         && !std.objectHas(object, 'oneOf')
         && !std.objectHas(object, 'anyOf')
      then
        if name == 'metadata'
        then
          local objectmeta = import './objectmeta.json';
          this.render.named(
            name, this.handleProperties(
              name,
              parents,
              objectmeta.definitions['io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta'].properties,
              objectmeta.definitions,
            ),
          )
        else this.handleOther(name, parents, object)
      else this.render.nilvalue
    ),

  handleArray(name, parents, array, refs={})::
    (
      if std.objectHas(array, 'items') && this.getObjectType(array.items) != ''
      then this.parse(name, [], array.items, refs)
      else this.render.nilvalue
    )
    + (
      if std.objectHas(array, 'allOf')
         || std.objectHas(array, 'oneOf')
         || std.objectHas(array, 'anyOf')
      then this.render.named(name, this.handleComposite(name, parents, array, refs))
      else this.render.nilvalue
    )
    + this.render.arrayFunctions(name, parents),

  handleConstant(name, parents, object)::
    this.render.withConstant(name, parents, object.const),

  handleOther(name, parents, object)::
    if std.objectHas(object, 'type') && parents == []
    then
      // Provide constructor for simple root schemas
      local typename = std.asciiUpper(object.type[0]) + object.type[1:];
      this.render.otherFunction(name, this.camelCaseKind('new' + typename))

    else if !std.member(
      ['object', 'array', 'composite', 'ref'],
      this.getObjectType(object)
    )
    then this.render.withFunction(name, parents)
    else this.render.nilvalue,

  handleComposite(name, parents, object, refs={})::
    local handle(composite) = std.foldl(
      function(acc, c)
        if this.getObjectType(c) != ''
        then
          local parsed = this.parse(
            name,
            parents,
            c,
            refs,
          );
          acc + (
            if std.objectHas(c, '$ref')
            then
              local refname = this.camelCaseKind(this.getRefName(c));
              this.render.compositeRef(name, refname, parsed[name])
            else parsed
          )
        else acc,
      composite,
      this.render.nilvalue
    );
    (
      if std.objectHas(object, 'allOf')
      then handle(object.allOf)
      else this.render.nilvalue
    )
    + (
      if std.objectHas(object, 'oneOf')
      then handle(object.oneOf)
      else this.render.nilvalue
    )
    + (
      if std.objectHas(object, 'anyOf')
      then handle(object.anyOf)
      else this.render.nilvalue
    ),

  getRefName(object)::
    std.reverse(std.split(object['$ref'], '/'))[0],

  handleRef(name, parents, object, refs={})::
    local ref = this.getRefName(object);
    if refs != {} && std.objectHas(refs, ref)
    then this.parse(name, parents, refs[ref], refs)
    else this.handleOther(name, parents, object)
  ,

  handleProperties(name, parents, properties, refs={})::
    this.render.properties(
      std.foldl(
        function(acc, p)
          acc + this.parse(
            p,
            parents + [p],
            properties[p],
            refs,
          ),
        std.objectFields(properties),
        this.render.nilvalue
      )
    ),

  getObjectType(object)::
    if std.objectHas(object, 'type')
    then object.type

    else if std.objectHas(object, 'allOf')
            || std.objectHas(object, 'oneOf')
            || std.objectHas(object, 'anyOf')
    then 'composite'

    else if std.objectHas(object, '$ref')
    then 'ref'

    else if std.objectHas(object, 'const')
    then 'const'

    else '',

  parse(name, parents, property, refs={})::
    local type =
      local t = this.getObjectType(property);
      if t != ''
      then t
      else infoMessage(
        'Unsupported property %s with fields %s' % [
          std.join('.', parents),
          std.toString(std.objectFields(property)),
        ],
        ''
      );

    (
      if type == 'object'
      then this.handleObject(name, parents, property, refs)

      else if type == 'array'
      then this.handleArray(name, parents, property, refs)

      else if type == 'ref'
      then this.handleRef(name, parents, property, refs)

      else if type == 'const'
      then this.handleConstant(name, parents, property)

      else if type == 'composite'
      then this.handleComposite(name, parents, property, refs)

      else this.handleOther(name, parents, property)
    ),

  camelCaseKind(kind)::
    local s = xtd.camelcase.split(kind);
    std.asciiLower(s[0]) + std.join('', s[1:]),

  fromSchema(grouping, group, version, kind, schema, refs={}, withMixin=false)::
    local kindname = this.camelCaseKind(kind);

    this.render.fromSchema(
      grouping,
      version,
      this.parse(kindname, [], schema, refs)
    )
    + (
      if withMixin
      then this.render.withMixin(kindname, [])
      else this.render.nilvalue
    )
    + (if std.objectHas(schema, 'x-kubernetes-group-version-kind')
       then
         local gvk = schema['x-kubernetes-group-version-kind'];
         local gv =
           if gvk[0].group == ''
           then gvk[0].version
           else gvk[0].group + '/' + gvk[0].version;
         this.render.newFunction(
           gv,
           kind,
           [grouping, version, kindname]
         )
       else if std.objectHas(schema, 'properties')
               && std.objectHas(schema.properties, 'kind')
       then this.render.newFunction(
         group + '/' + version,
         kind,
         [grouping, version, kindname]
       )
       else this.render.nilvalue),

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

  // fromCRD accepts a CustomResourceDefinition
  fromCRD(definition, group_suffix)::
    local grouping =
      // If no dedicated API group, then use nogroup key for consistency
      if group_suffix == definition.spec.group
      then 'nogroup'
      else std.split(std.strReplace(definition.spec.group, '.' + group_suffix, ''), '.')[0];

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
      this.render.nilvalue
    ),

  // fromXRD accepts a Crossplane CompositeResourceDefinition
  fromXRD(definition, group_suffix)::
    local kind =
      if std.objectHas(definition.spec, 'claimNames')
      then definition.spec.claimNames.kind
      else definition.spec.names.kind;

    local grouping =
      // If no dedicated API group, then use nogroup key for consistency
      if group_suffix == definition.spec.group
      then 'nogroup'
      else std.split(std.strReplace(definition.spec.group, '.' + group_suffix, ''), '.')[0];

    // These properties are added when Crossplane turns the XRD into a CRD.
    // This adds them to the library specification for generating the RDs.
    local XRDProperties = {
      properties+: {
        spec+: {
          properties+: {
            compositionRef: {
              properties: { name: { type: 'string' } },
              required: ['name'],
              type: 'object',
            },
            compositionRevisionRef: {
              properties: { name: { type: 'string' } },
              required: ['name'],
              type: 'object',
            },
            compositionSelector: {
              properties: {
                matchLabels: {
                  additionalProperties: { type: 'string' },
                  type: 'object',
                },
              },
              required: ['matchLabels'],
              type: 'object',
            },
            compositionUpdatePolicy: {
              enum: [
                'Automatic',
                'Manual',
              ],
              type: 'string',
            },
            writeConnectionSecretToRef: {
              properties: { name: { type: 'string' } },
              required: ['name'],
              type: 'object',
            },
          },
        },
      },
    };

    std.foldl(
      function(acc, v)
        acc
        + this.fromSchema(
          grouping,
          definition.spec.group,
          v,
          kind,
          getVersionInDefinition(definition, v).schema.openAPIV3Schema + XRDProperties,
        ),
      [
        version.name
        for version in definition.spec.versions
      ],
      this.render.nilvalue
    ),
}
