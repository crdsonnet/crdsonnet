local crdsonnet = import '../main.libsonnet';

local schema = import './example_schema.json';

local staticProcessor =
  crdsonnet.processor.new()
  + crdsonnet.processor.withRenderEngineType('jsonnet');

crdsonnet.schema.render('customer', schema, staticProcessor)
