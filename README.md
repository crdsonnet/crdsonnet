# CRDsonnet

Generate a *runtime* Jsonnet library directly from JSON Schemas, CRDs or OpenAPI
components.

> This project has moved from POC to an alpha status. I consider it in a usable state for
> production projects however there are no guarantees for a stable API.

## Install

```console
jb install https://github.com/Duologic/crdsonnet/crdsonnet
```

## Usage

```jsonnet
local crdsonnet = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local example = crdsonnet.fromCRD(someCustomResourceDefinition, 'example.io');

{
  example_object: example.core.v1.someObject.new(name='example'),
}
```

### Debug

Use the `xtd.inspect` package to view the rendered tree and turn the `debug` option on to
see debug messages:

```jsonnet
local crdsonnet = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local example = crdsonnet.fromCRD(someCustomResourceDefinition, 'example.io');

xtd.inspect.inspect(example, 10)
```
