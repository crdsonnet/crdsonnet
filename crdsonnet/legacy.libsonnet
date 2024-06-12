// Legacy API endpoints

// These endpoints aren't very flexible and require more arguments to add features, this is an anti-pattern. They have been reimplemented to use modular setup and serve as an example and to verify the modular pattern works. These functions are covered by unit tests.

local helpers = import './helpers.libsonnet';
local main = import './main.libsonnet';
local processor = import './processor.libsonnet';

{
  local defaultRender = 'dynamic',

  fromSchema(name, schema, schemaDB={}, render=defaultRender):
    assert std.trace('CRDsonnet - DEPRECATION NOTICE - please use the new functions', true);
    if name == ''
    then error "name can't be an empty string"
    else
      local _processor =
        processor.new()
        + processor.withSchemaDB(schemaDB)
        + processor.withRenderEngineType(render);
      main.schema.render(name, schema, _processor),

  fromCRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    assert std.trace('CRDsonnet - DEPRECATION NOTICE - please use the new functions', true);
    local _processor =
      processor.new()
      + processor.withSchemaDB(schemaDB)
      + processor.withRenderEngineType(render);
    main.crd.render(definition, groupSuffix, _processor),

  // XRD: Crossplane CompositeResourceDefinition
  fromXRD(definition, groupSuffix, schemaDB={}, render=defaultRender):
    assert std.trace('CRDsonnet - DEPRECATION NOTICE - please use the new functions', true);
    local _processor =
      processor.new()
      + processor.withSchemaDB(schemaDB)
      + processor.withRenderEngineType(render);
    main.xrd.render(definition, groupSuffix, _processor),

  fromOpenAPI(name, component, schema, schemaDB={}, render=defaultRender):
    assert std.trace('CRDsonnet - DEPRECATION NOTICE - please use the new functions', true);
    if name == ''
    then error "name can't be an empty string"
    else
      local _processor =
        processor.new()
        + processor.withSchemaDB(schemaDB)
        + processor.withRenderEngineType(render);
      main.openapi.render(name, component, schema, _processor),

  // expects schema as rendered by `kubectl get --raw /openapi/v2`
  fromKubernetesOpenAPI(schema, render=defaultRender):
    assert std.trace('CRDsonnet - DEPRECATION NOTICE - please use the new functions', true);
    local _processor =
      processor.new()
      + processor.withRenderEngineType(render);
    local renderEngine = _processor.renderEngine;
    renderEngine.toObject(
      std.foldl(
        function(acc, d)
          local items = std.reverse(std.split(d, '.'));
          local component = schema.definitions[d];
          local name = helpers.camelCaseKind(items[0]);
          acc
          + renderEngine.nestInParents(
            [items[2], items[1]],
            main.fromOpenAPI(name, component, schema, render=render),
          ),
        std.objectFields(schema.definitions),
        renderEngine.nilvalue
      ),
    ),
}
