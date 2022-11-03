local parser = import './parser.libsonnet';

{
  get(db, name):
    if name in db
    then db[name]
    else {},

  add(schema):
    local id = parser.getID(schema);
    if id == ''
    then error "Can't add schema without id"
    else { [id]: schema },
}
