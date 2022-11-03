local crdsonnet = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';

local cert_manager = import './main.libsonnet';

cert_manager.nogroup.v1.issuer.new('myIssuer')
+ cert_manager.nogroup.v1.issuer.metadata.withLabels({ exampleIssuer: 'true' })
