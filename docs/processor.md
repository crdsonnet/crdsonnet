# processor

`processor` provides an interface to configure the parser and render engine, returns a parser() and render() function.


## Index

* [`fn new()`](#fn-new)
* [`fn withCamelCaseFields()`](#fn-withcamelcasefields)
* [`fn withRenderEngine(engine)`](#fn-withrenderengine)
* [`fn withRenderEngineType(engineType)`](#fn-withrenderenginetype)
* [`fn withSchemaDB(db)`](#fn-withschemadb)
* [`fn withValidation()`](#fn-withvalidation)

## Fields

### fn new

```jsonnet
new()
```


`new` initializes the processor with sane defaults, returning a parser() and render() function.

### fn withCamelCaseFields

```jsonnet
withCamelCaseFields()
```


`withCamelCaseFields` configures the render engine to use camelCase field names.

### fn withRenderEngine

```jsonnet
withRenderEngine(engine)
```

PARAMETERS:

* **engine** (`object`)

`withRenderEngine` configures an alternative render engine. This can be created with `crdsonnet.renderEngine`.

### fn withRenderEngineType

```jsonnet
withRenderEngineType(engineType)
```

PARAMETERS:

* **engineType** (`string`)
   - valid values: `"ast"`, `"dynamic"`, `"static"`

`withRenderEngineType` is a shortcut to configure an alternative render engine type.

### fn withSchemaDB

```jsonnet
withSchemaDB(db)
```

PARAMETERS:

* **db** (`object`)

`withSchemaDB` adds additional schema databases. These can be created with `crdsonnet.schemaDB`.

### fn withValidation

```jsonnet
withValidation()
```


`withValidation` turns on schema validation for render engine 'dynamic'. The `with*()` functions will validate the inputs against the given schema.

NOTE: This uses validate-libsonnet, it can validate the most common JSON Schema attributes however some features are not yet implemented, most notably it is missing support for features that require regular expressions (not supported in Jsonnet yet).

Example:

```jsonnet
local crdsonnet = import 'github.com/crdsonnet/crdsonnet/crdsonnet/main.libsonnet';

local schema = {
  type: 'object',
  properties: {
    name: {
      type: 'string',
    },
  },
};

local validateProcessor =
  crdsonnet.processor.new()
  + crdsonnet.processor.withValidation();

local lib = crdsonnet.schema.render('person', schema, validateProcessor);

lib.person.withName(100)  // invalid input

```

Output:

```console
TRACE: vendor/github.com/crdsonnet/validate-libsonnet/main.libsonnet:94 
Invalid parameters:
  Parameter name is invalid:
    Value 100 MUST match schema:
      {
        "type": "string"
      }
RUNTIME ERROR: Assertion failed
	renderEngines/dynamic.libsonnet:(72:12)-(73:88)	
	example/json_schema_very_simple_validate.libsonnet:18:1-25	$
	During evaluation	


```
