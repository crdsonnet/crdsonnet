# CRDsonnet

Generate a *runtime* Jsonnet library directly from a CRD.

## Example usage

```jsonnet
local gen = import 'gen.libsonnet';
local example = gen.generate(someCustomResourceDefinition, 'example.io');

{
  example_object: example.core.v1.someObject.new(name='example'),
  inspect: gen.inspect('example', example),
}
```

## Demo

The demo outputs a JSON represetation of the runtime library using the `gen.inspect()`
function, below commands depend on Tanka and Kustomize, try it:

```
tk eval crossplane/main.jsonnet
tk eval cert-manager/main.jsonnet
```
