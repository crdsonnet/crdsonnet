# CRDsonnet

Generate a *runtime* Jsonnet library directly from JSON Schemas, CRDs or OpenAPI components.

> This project is actively used in several projects, most notably [Grafonnet](https://github.com/grafana/grafonnet). It can be consider in a usable state for production projects.

## Install

```console
jb install https://github.com/crdsonnet/crdsonnet/crdsonnet
```

## Usage

### Static rendering

The static render engine generates the Jsonnet AST representation, calling `toString()` on the result will return the actual Jsonnet:

```jsonnet
// static.libsonnet
local crdsonnet = import 'github.com/crdsonnet/crdsonnet/crdsonnet/main.libsonnet';

local schema = {
  type: 'object',
  properties: {
    name: {
      type: 'string',
    },
  },
};

local processor = crdsonnet.processor.new('ast');

crdsonnet.schema.render('person', schema, processor).toString()
```

Use the `-S` flag to treat the output as a string and pipe it into `jsonnetfmt` for a clean output:


```console
> jsonnet -S -J vendor static.libsonnet | jsonnetfmt -
```

The output looks like this:

```jsonnet
{
  person+:
    {
      '#withName': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withName(value): {
        name: value,
      },
    },
}
```

### Dynamic rendering

Dynamic rendering can generate an in-memory runtime library. This can be useful when quickly iterating on a schema and don't want to make a static rendering on each change. However it makes debugging harder and it can become slow on big schemas.

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

local lib = crdsonnet.schema.render('person', schema);

lib.person.withName('John')
```


### Generate documentation

CRDsonnet generates libraries with documentation included. It leverages [docsonnet](https://github.com/jsonnet-libs/docsonnet).

To render the docs, a top-level package needs to be defined:

```jsonnet
// docs.libsonnet
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';

local example =
  (import './main.libsonnet')
  + {
    '#':
      d.package.new(
        'example',
        'github.com/example/example',
        'Jsonnet library for example',
        'main.libsonnet',
      ),
  };

d.render(example)
```

```console
jsonnet -J vendor -S -c -m docs docs.libsonnet
```
