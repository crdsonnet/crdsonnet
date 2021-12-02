# CRDsonnet

Generate a *runtime* Jsonnet library directly from a CRD or OpenAPI v3 spec.

> Note: This is not a polished project yet, I would not even consider it alpha, rather a
> POC to demonstrate the idea.

## Install

```console
jb install https://github.com/Duologic/crdsonnet/crdsonnet
```

## Usage

```jsonnet
local gen = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';
local example = gen.fromCRD(someCustomResourceDefinition, 'example.io');

{
  example_object: example.core.v1.someObject.new(name='example'),
}
```

### Debug

Use the `inspect` function to view the rendered tree and turn the `debug` option on to see
debug messages:

```jsonnet
local gen =
  (import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet')
  + { debug: true };

local example = gen.fromCRD(someCustomResourceDefinition, 'example.io');

{
  inspect: gen.inspect(example, maxDepth=10),
}
```

## Demo

The demos output a JSON represetation of the runtime library using the `inspect` function,
try it:

```
cd <cert-manager|k8s|grafonnet>
jb install
jsonnet -J vendor inspect.libsonnet
```

The `crossplane` demo depends on Tanka and Kustomize:

```
cd crossplane
jb install
tk eval crossplane/inspect.libsonnet
```
