local schemaDB = import './schemadb.libsonnet';

{
  db:
    schemaDB.add({
      '$id': 'https://example.com/schemas/address',

      type: 'object',
      properties: {
        street_address: { type: 'string' },
        city: { type: 'string' },
        state: { type: 'string' },
        country: {
          default: 'United States of America',
          enum: ['United States of America', 'Canada'],
        },
      },
      'if': {
        properties: { country: { const: 'United States of America' } },
      },
      'then': {
        properties: { postal_code:
          { pattern: '[0-9]{5}(-[0-9]{4})?' } },
      },
      'else': {
        properties:
          { postal_code:
            { pattern:
              '[A-Z][0-9][A-Z][0-9][A-Z][0-9]' } },
      },
      required: ['street_address', 'city', 'state'],
    })

    + schemaDB.add({
      '$id': 'https://example.com/schemas/customer',

      type: 'object',
      properties: {
        first_name: { type: 'string' },
        last_name: { type: 'string' },
        shipping_address: { '$ref': '/schemas/address' },
        billing_address: { '$ref': '/schemas/address' },
        discount: { const: '10%' },
        deleted: { type: 'boolean', default: false },
        asl: {
          type: 'array',
          prefixItems: [
            { '$anchor': 'age', type: 'number' },
            { '$anchor': 'sex', type: 'string', maxLength: 1, enum: ['m', 'f'] },
            { '$anchor': 'location', '$ref': '/schema/address' },
          ],
          items: false,
        },
        store: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              location: { '$ref': '/schemas/address' },
            },
          },
        },
        tt: {
          anyOf: [
            { '$ref': '/schemas/address' },
            { '$anchor': 'age', type: 'number' },
          ],
        },
      },
      required: ['first_name', 'last_name', 'shipping_address', 'billing_address'],
    }),

  testSchemas: [
    {
      // non-existent schema ID
      '$ref': '/schema/does/not/exist',
    },
    {
      // non-existent schema ID with fragment
      '$ref': '/schema/does/not/exist#/fragment/does/not/exist',
    },
    {
      // Fragment only
      '$ref': '#/properties/first_name',
      properties: {
        first_name: { type: 'string' },
      },
    },
    {
      // Relative reference
      '$id': 'https://example.com/schemas/random',
      '$ref': '/schemas/customer',
    },
    {
      // Relative reference with fragment
      '$id': 'https://example.com/schemas/random',
      '$ref': '/schemas/customer#/properties/first_name',
    },
    {
      // Absolute URI
      '$id': 'https://example.com/schemas/random',
      '$ref': 'https://example.com/schemas/customer',
    },
    {
      // Absolute URI, no id
      '$ref': 'https://example.com/schemas/customer',
    },
    {
      // Absolute URI with fragment
      '$id': 'https://example.com/schemas/random',
      '$ref': 'https://example.com/schemas/customer#/properties/shipping_address',
    },
  ],
}
