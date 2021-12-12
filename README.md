# CRDsonnet

Generate a *runtime* Jsonnet library directly from a OpenAPI spec or CRD.

> Note: This is not a polished project yet, I would not even consider it alpha, rather a
> POC to demonstrate the idea.

## Install

```console
jb install https://github.com/Duologic/crdsonnet/crdsonnet
```

### Optional dependency

Optionally you can install the Kubernetes swagger spec to fill in the ObjectMeta for CRDs,
I have not included as a direct dependency as versions may differ and it is very big
(11MB). 

Add this to your `jsonnetfile.json` or manually create a file on `lib/kubernetes-spec`:

```
{
  "version": 1,
  "dependencies": [
    ...
    {
      "source": {
        "git": {
          "remote": "https://github.com/kubernetes/kubernetes.git",
          "subdir": "api/openapi-spec"
        }
      },
      "version": "release-1.23",
      "name": "kubernetes-spec"
    }
  ],
  "legacyImports": true
}
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
local crdsonnet =
  (import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet')
  + { debug: true };

local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local example = crdsonnet.fromCRD(someCustomResourceDefinition, 'example.io');

xtd.inspect.inspect(example, 10)
```

## Demo

The demos output a JSON represetation of the runtime library using the `xtd.inspect`
package, try it:

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
