# schemaDB

`schemaDB` provides an interface to describe a schemaDB.

## Index

* [`fn add(schema)`](#fn-add)
* [`fn get(db, name)`](#fn-get)
* [`fn getID(schema)`](#fn-getid)

## Fields

### fn add

```jsonnet
add(schema)
```

PARAMETERS:

* **schema** (`object`)

`add` adds a schema to a 'db', expects a schema to have either am `$id` or `id` field.
### fn get

```jsonnet
get(db, name)
```

PARAMETERS:

* **db** (`object`)
* **name** (`string`)

`get` gets a schema from a 'db'.
### fn getID

```jsonnet
getID(schema)
```

PARAMETERS:

* **schema** (`object`)

`getID` gets the ID from a schema, either `$id` or `id` are returned.