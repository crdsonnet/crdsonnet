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

local staticProcessor = crdsonnet.processor.new('ast');

crdsonnet.schema.render('customer', schema, staticProcessor).toString()

```


## Subpackages

* [processor](processor.md)
* [renderEngine](renderEngine.md)
* [schemaDB](schemaDB.md)

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

```jsonnet
crd.render(definition, groupSuffix, processor="processor.new()")
```

PARAMETERS:

* **definition** (`object`)
* **groupSuffix** (`string`)
* **processor** (`object`)
   - default value: `"processor.new()"`

`render` returns a library for a `definition`.
### obj openapi


#### fn openapi.render

```jsonnet
openapi.render(name, component, schema, processor="processor.new()")
```

PARAMETERS:

* **name** (`string`)
* **component** (`object`)
* **schema** (`object`)
* **processor** (`object`)
   - default value: `"processor.new()"`

`render` returns a library for a `component` in an OpenAPI `schema`.
### obj schema


#### fn schema.render

```jsonnet
schema.render(name, schema, processor="processor.new()")
```

PARAMETERS:

* **name** (`string`)
* **schema** (`object`)
* **processor** (`object`)
   - default value: `"processor.new()"`

`render` returns a library for a `schema`.
### obj xrd


#### fn xrd.render

```jsonnet
xrd.render(definition, groupSuffix, processor="processor.new()")
```

PARAMETERS:

* **definition** (`object`)
* **groupSuffix** (`string`)
* **processor** (`object`)
   - default value: `"processor.new()"`

`render` returns a library for a `definition`.