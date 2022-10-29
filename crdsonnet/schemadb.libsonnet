local parser = import './parser.libsonnet';

{
  add(schema):
    local id = parser.getID(schema);
    if id == ''
    then error "Can't add schema without id"
    else {
      get(name):
        if name in self.schemas
        then self.schemas[name]
        else {},
      schemas+: { [id]: schema },
    },
}
