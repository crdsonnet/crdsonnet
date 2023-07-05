# crdsonnet

Generate a *runtime* Jsonnet library directly from JSON Schemas, CRDs or OpenAPI components.

## Install

```
jb install https://github.com/crdsonnet/crdsonnet/crdsonnet@master
```

## Usage

```jsonnet
local crdsonnet = import 'github.com/crdsonnet/crdsonnet/crdsonnet/main.libsonnet';

local schema = import './example_schema.json';

local lib = crdsonnet.schema.render('customer', schema);
local c = lib.customer;

c.withFirstName('John')
+ c.withLastName('Doe')

```

## Subpackages

* [processor](crdsonnet/processor.md)
* [renderEngine](crdsonnet/renderEngine.md)
* [schemaDB](crdsonnet/schemaDB.md)

## Index

* [`obj crd`](#obj-crd)
  * [`fn render(definition, groupSuffix, processor="processor.new()")`](#fn-crdrender)
* [`obj openapi`](#obj-openapi)
  * [`fn render(name, component, schema, processor="processor.new()")`](#fn-openapirender)
* [`obj schema`](#obj-schema)
  * [`fn render(name, schema, processor="processor.new()")`](#fn-schemarender)
* [`obj xrd`](#obj-xrd)
  * [`fn render(definition, groupSuffix, processor="processor.new()")`](#fn-xrdrender)

## Fields

### obj crd


#### fn crd.render

```ts
render(definition, groupSuffix, processor="processor.new()")
```

`render` returns a library for a `definition`.

### obj openapi


#### fn openapi.render

```ts
render(name, component, schema, processor="processor.new()")
```

`render` returns a library for a `component` in an OpenAPI `schema`.

### obj schema


#### fn schema.render

```ts
render(name, schema, processor="processor.new()")
```

`render` returns a library for a `schema`.

### obj xrd


#### fn xrd.render

```ts
render(definition, groupSuffix, processor="processor.new()")
```

`render` returns a library for a `definition`.
