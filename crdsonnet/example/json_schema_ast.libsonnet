local crdsonnet = import '../main.libsonnet';

local schema = import './example_schema.json';

local staticProcessor = crdsonnet.processor.new('ast');

crdsonnet.schema.render('customer', schema, staticProcessor).toString()
