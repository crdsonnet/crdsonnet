# Jsonnet CRD generator

This is a POC to generate a Jsonnet library at runtime from a CRD. The current script
simply outputs a JSON representation of how the library would look like.

The demo depends on Tanka and Kustomize, try it:

```
tk eval crossplane/main.jsonnet
tk eval cert-manager/main.jsonnet
```
