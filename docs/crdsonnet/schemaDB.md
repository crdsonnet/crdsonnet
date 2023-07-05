# schemaDB

`schemaDB` provides an interface to describe a schemaDB.

## Index

* [`fn add(schema)`](#fn-add)
* [`fn get(db, name)`](#fn-get)
* [`fn getID(schema)`](#fn-getid)

## Fields

### fn add

```ts
add(schema)
```

`add` adds a schema to a 'db', expects a schema to have either am `$id` or `id` field.

### fn get

```ts
get(db, name)
```

`get` gets a schema from a 'db'.

### fn getID

```ts
getID(schema)
```

`getID` gets the ID from a schema, either `$id` or `id` are returned.
