# CRDsonnet

Generate a *runtime* Jsonnet library directly from JSON Schemas, CRDs or OpenAPI components.

> This project is actively used in several projects, most notably [Grafonnet](https://github.com/grafana/grafonnet). It can be consider in a usable state for production projects however the API should be considered in alpha status.

## Install

```console
jb install https://github.com/crdsonnet/crdsonnet/crdsonnet
```

## Usage

Generate a library from a JSON Schema:

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

### Static rendering

The library can render a static library, this can be useful when rendering them in-memory becomes too slow or for debugging purposes. The static rendering will represent the jsonnet as a string, however this kind of string manipulation is quite hard in jsonnet and the output can be quite ugly.

> NOTE: This render engine isn't well tested and may not always work. Contributions to improve this are more than welcome.

To do this, first set the `render` to 'static':

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

local staticProcessor =
  crdsonnet.processor.new()
  + crdsonnet.processor.withRenderEngineType('static');

crdsonnet.schema.render('person', schema, staticProcessor)
```

Then tell jsonnet to expect a string as output and format it for a readable output:


```console
> jsonnet -S -J vendor static.libsonnet | jsonnetfmt -
```

Output:

```jsonnet
{
  person+: {
    withName(value): { name: value },
  },
}
```

### Debug

Use the `xtd.inspect` package to view the rendered tree:

```jsonnet
// inspect.libsonnet
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local example = './main.libsonnet';

xtd.inspect.inspect(example, 10)
```

### Documentation

The dynamic rendering comes with documentation included. It leverages [docsonnet](https://github.com/jsonnet-libs/docsonnet).

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

## Development

This project is marked as alpha status. It can be consider it in a usable state for production projects however there are no guarantees for a stable API.

### Testing

There are unit tests under `test/`, these can be run with `make test`, please make sure these succeed. When changing test cases, then please follow test-driven development and modify the test cases in separate commits that come before functional changes.
