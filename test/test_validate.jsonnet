local crdsonnet = import 'crdsonnet/main.libsonnet';
local schemaDB = import 'crdsonnet/schemadb.libsonnet';
local test = import 'github.com/jsonnet-libs/testonnet/main.libsonnet';

local db =
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
      id: { type: 'integer' },
      shipping_address: { '$ref': '/schemas/address' },
      billing_address: { '$ref': '/schemas/address' },
      discount: { const: '10%' },
      deleted: { type: 'boolean', default: false },
      asl: {
        type: 'array',
        prefixItems: [
          { '$anchor': 'age', type: 'number' },
          { '$anchor': 'sex', type: 'string', maxLength: 1, enum: ['m', 'f'] },
          { '$anchor': 'location', '$ref': '/schemas/address' },
        ],
        //contains: { type: 'string' },
        //items: false,
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
        uniqueItems: true,
      },
      tt: {
        anyOf: [
          { '$ref': '/schemas/address' },
          { '$anchor': 'age', type: 'number' },
        ],
      },
    },
    required: ['first_name', 'last_name', 'shipping_address', 'billing_address'],
  });

local customerSchema = db['https://example.com/schemas/customer'];
local addressSchema = db['https://example.com/schemas/address'];
local library =
  crdsonnet.fromSchema('customer', customerSchema, db)
  + crdsonnet.fromSchema('address', addressSchema, db);

local address =
  library.address.withStreetAddress('4B Main Street')
  + library.address.withCountry()
  + library.address.withCity('New')
  + library.address.withState('York');

local object =
  library.customer.withFirstName('John')
  + library.customer.withId(1.0)
  + library.customer.withLastName('Doe')
  + library.customer.withAsl([
    1,
    'm',
    address,
    'extra',
  ])
  + library.customer.withStore([
    {
      name: 'a',
      location: address,
    },
    {
      name: 'b',
      location: address,
    },
  ])
  + library.customer.withShippingAddress(address)
  + library.customer.billing_address.withStreetAddress('4B Main Street')
  + library.customer.billing_address.withCountry()
  + library.customer.billing_address.withCity('New')
  + library.customer.billing_address.withState('York')
  + { test: 'a' };


test.new(std.thisFile)
+ test.case.new(
  name='validate smoke test',
  test=test.expect.eq(
    actual=crdsonnet.validate(object, customerSchema),
    expected=true
  )
)
