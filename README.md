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

> Note: This library does lots of recursions, notice the `--max-stack`.

```
jsonnet --max-stack 1000 -J k8s/vendor k8s/inspect.libsonnet
jsonnet -J cert-manager/vendor cert-manager/inspect.libsonnet
```

The `crossplane` example depends on Tanka and Kustomize:

```
tk eval crossplane/inspect.libsonnet
```

