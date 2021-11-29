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
local example = gen.fromDefinition(someCustomResourceDefinition, 'example.io');

{
  example_object: example.core.v1.someObject.new(name='example'),
  inspect: gen.inspect(example),
}
```

## Demo

The demo outputs a JSON represetation of the runtime library using the `gen.inspect()`
function, try it:

```
cd cert-manager
jb install
jsonnet -J vendor inspect.libsonnet
```

```
cd k8s
jb install
jsonnet -J vendor inspect.libsonnet
```

The `crossplane` demo depends on Tanka and Kustomize:

```
cd crossplane
jb install
tk eval crossplane/inspect.libsonnet
```

## Debug

