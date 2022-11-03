local schemaObject = {
  local valid_types = [
    'array',
    'boolean',
    'number',
    'object',
    'string',
  ],

  new(name, type='string', default=null, description=''): {
    name:: name,
    type:
      if std.member(valid_types, type)
      then type
      else error '`type` was %s must be one of following type %s' % [type, valid_types],

    [if default != null then 'default']:
      if std.type(default) == type
      then default
      else error '`default` value does not match object type',

    [if description != '' then 'description']: description,

    [if type == 'array' then 'items']: error '`items` is required for type array',
  },

  newArrayString(name, description=''):
    self.new(name, 'array', description=description)
    + self.items.new(schemaObject.new('', 'string')),

  newObjectString(name, description=''):
    self.new(name, 'object', description=description)
    + self.additionalProperties.new(schemaObject.new('', 'string')),

  items: {
    new(schema): {
      items: schema,
    },
  },

  additionalProperties: {
    new(schema): {
      additionalProperties+: schema,
    },
  },

  nullable(value=true): { nullable: value },

  addProperty(property, required=false): {
    properties+: {
      [property.name]: property,
    },
    required+:
      if required
      then [property.name]
      else [],
  },
};

local metadata =
  schemaObject.new(
    'metadata',
    'object',
  )
  + schemaObject.addProperty(
    schemaObject.new('name')
  )
  + schemaObject.addProperty(
    schemaObject.new('namespace')
  )
  + schemaObject.addProperty(
    schemaObject.newObjectString('labels')
  )
;

local spec =
  schemaObject.new(
    'spec',
    'object',
  )
  + schemaObject.addProperty(schemaObject.new('apiServer'))
  + schemaObject.addProperty(
    schemaObject.newArrayString('contextNames')
  )
  + schemaObject.addProperty(
    schemaObject.new('namespace', default='default'),
    required=true,
  )
  + schemaObject.addProperty(schemaObject.new('diffStrategy'))
  + schemaObject.addProperty(schemaObject.new('applyStrategy'))
  + schemaObject.addProperty(schemaObject.new('injectLabels', 'boolean'))
  + schemaObject.addProperty(
    schemaObject.new('resourceDefaults', 'object')
    + schemaObject.addProperty(
      schemaObject.newObjectString('annotations')
    )
    + schemaObject.addProperty(
      schemaObject.newObjectString('labels')
    )
  )
  + schemaObject.addProperty(
    schemaObject.new('expectVersions', 'object')
    + schemaObject.addProperty(
      schemaObject.new('tanka')
    )
  )
;

schemaObject.new('v1alpha1', 'object')
+ schemaObject.addProperty(
  schemaObject.new(
    'apiVersion',
    default='tanka.dev/v1alpha1',
  ),
  required=true,
)
+ schemaObject.addProperty(
  schemaObject.new(
    'kind',
    default='Environment',
  ),
  required=true,
)
+ schemaObject.addProperty(
  metadata,
  required=true,
)
+ schemaObject.addProperty(
  spec,
  required=true,
)
+ schemaObject.addProperty(
  schemaObject.new('data', 'object'),
)
