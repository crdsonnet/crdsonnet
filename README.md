# CRDsonnet

Generate a *runtime* Jsonnet library directly from JSON Schemas, CRDs or OpenAPI
components.

> This project has moved from POC to an alpha status. It can be consider it in a usable
> state for production projects however there are no guarantees for a stable API.

## Install

```console
jb install https://github.com/crdsonnet/crdsonnet/crdsonnet
```

## Usage

Generate a library from a CustomResourceDefinition:

```jsonnet
// main.libsonnet
local crdsonnet = import 'github.com/crdsonnet/crdsonnet/crdsonnet/main.libsonnet';

crdsonnet.fromCRD(
  someCustomResourceDefinition,
  'example.io'
)
```

Then use it:

```jsonnet
// example.libsonnet
local example = './main.libsonnet';

example.core.v1.someObject.new(name='example')
```

### Static rendering

The library can render a static library, this can be useful when rendering them in-memory
becomes too slow or for debugging purposes. The static rendering will represent the
jsonnet as a string, however this kind of string manipulation is quite hard in jsonnet
and the output can be quite ugly.

To do this, first set the `render` to 'static':

```jsonnet
// static.libsonnet
local crdsonnet = import 'github.com/crdsonnet/crdsonnet/crdsonnet/main.libsonnet';

local example =
  crdsonnet.fromCRD(
    someCustomResourceDefinition,
    'example.io',
    render='static'
  );

example
```

Then tell jsonnet to expect a string as output:


```console
jsonnet -S -J vendor static.libsonnet
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

The dynamic rendering comes with documentation included. It leverages
[docsonnet](https://github.com/jsonnet-libs/docsonnet).

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

This project is marked as alpha status. It can be consider it in a usable state for
production projects however there are no guarantees for a stable API.

### Testing

There are unit tests under `test/`, these can be run with `make test`, please make sure
these succeed. When changing test cases, then please follow test-driven development and
modify the test cases in separate commits that come before functional changes.

### Documentation

The code hasn't been documented yet, the aim is to primarily document the functions in
`main.libsonnet` as an entry point to the lib. Other files/functions are currently
considered 'internal' and might change without notice.
