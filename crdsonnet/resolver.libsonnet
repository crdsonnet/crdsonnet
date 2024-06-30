local schemadb_util = import './schemadb.libsonnet';

{
  local url = {
    // Similar to Python's urllib.urlsplit()
    // <scheme>://<net_loc>/<path>?<query>#<fragment>
    split(url):
      local hasFragment = std.length(std.findSubstr('#', url)) > 0;
      local fragmentSplit = std.splitLimit(url, '#', 1);

      local hasQuery = std.length(std.findSubstr('?', fragmentSplit[0])) > 0;
      local querySplit = std.splitLimit(fragmentSplit[0], '?', 1);

      local hasScheme = std.length(std.findSubstr(':', querySplit[0])) > 0;
      local schemeSplit = std.splitLimit(querySplit[0], ':', 1);

      local postSchemeURL =
        if hasScheme
        then schemeSplit[1]
        else schemeSplit[0];
      local hasNetLoc = std.startsWith(postSchemeURL, '//');
      local netLocSplit = std.splitLimit(postSchemeURL, '//', 1);

      local postNetLocURL =
        if hasNetLoc
        then netLocSplit[1]
        else netLocSplit[0];
      local pathSplit = std.splitLimit(postNetLocURL, '/', 1);
      local hasPath =
        (hasNetLoc && std.length(std.findSubstr('/', postNetLocURL)) > 0)
        || (!hasNetLoc && std.startsWith(postNetLocURL, '/'));
      {
        [if hasScheme then 'scheme']: schemeSplit[0],
        [if hasNetLoc then 'net_loc']: pathSplit[0],
        [if hasPath then 'path']: pathSplit[1],
        [if hasQuery then 'query']: querySplit[1],
        [if hasFragment then 'fragment']: fragmentSplit[1],
      },

    join(splitObj):
      std.join('', [
        if 'scheme' in splitObj then splitObj.scheme + ':' else '',
        if 'net_loc' in splitObj then '//' + splitObj.net_loc else '',
        if 'path' in splitObj then '/' + splitObj.path else '',
        if 'query' in splitObj then '?' + splitObj.query else '',
        if 'fragment' in splitObj then '#' + splitObj.fragment else '',
      ]),
  },

  resolveRef(obj, schema, schemaDB):
    if '$ref' in obj
    then
      std.mergePatch(
        std.mergePatch(obj, { '$ref': null }),  // Remove $ref
        self.resolve(obj['$ref'], schema, schemaDB)  // Merge with sibling keywords (=>draft-2019-09)
      )
    else obj,

  resolve(ref, schema, schemaDB):
    local splitRef = url.split(ref);
    local splitID = url.split(schemadb_util.getID(schema));

    local findSchema =
      if self.urlWithPath(splitRef) == self.urlWithPath(splitID)  // same as schema
      then schema

      else if 'net_loc' in splitRef  // absolute
      then self.getSchemaFromDB(
        self.urlWithPath(splitRef),
        schemaDB,
      )

      else if 'path' in splitRef  // relative
      then self.getSchemaFromDB(
        self.urlWithPath(splitID + splitRef),
        schemaDB,
      )

      else if 'fragment' in splitRef  // fragment
      then schema

      else {};  // no schema found

    self.findFragment(
      std.get(splitRef, 'fragment', ''),
      findSchema,
      schemaDB,
    ),

  urlWithPath(parsedURL):
    url.join({
      [if 'scheme' in parsedURL then 'scheme']: parsedURL.scheme,
      [if 'net_loc' in parsedURL then 'net_loc']: parsedURL.net_loc,
      [if 'path' in parsedURL then 'path']: parsedURL.path,
    }),

  getSchemaFromDB(id, schemaDB):
    local found = schemadb_util.get(
      schemaDB,
      id,
    );
    self.resolveRef(
      found,
      found,
      schemaDB
    ),

  findFragment(fragment, schema, schemaDB={}):
    local keys = std.split(fragment, '/')[1:];
    std.foldl(
      function(acc, key)
        self.resolveRef(
          std.get(acc, key, {}),
          schema,
          schemaDB,
        ),
      keys,
      schema
    ),
}
