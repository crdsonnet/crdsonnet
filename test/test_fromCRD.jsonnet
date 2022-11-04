local crdsonnet = import 'crdsonnet/main.libsonnet';
local test = import 'github.com/jsonnet-libs/testonnet/main.libsonnet';

local crd = std.parseYaml(importstr './crd-issuers.yaml');
local certManager = crdsonnet.fromCRD(crd, 'cert-manager.io');

test.new(std.thisFile)
+ test.case.new(
  name='fromCRD smoke test',
  test=test.expect.eq(
    actual=
    certManager.nogroup.v1.issuer.new('letsencrypt')
    + certManager.nogroup.v1.issuer.spec.acme.withEmail('john@example.com')
    + certManager.nogroup.v1.issuer.spec.acme.withServer('https://acme-v02.api.letsencrypt.org/directory'),
    expected={
      apiVersion: 'cert-manager.io/v1',
      kind: 'Issuer',
      metadata: {
        name: 'letsencrypt',
      },
      spec: {
        acme: {
          email: 'john@example.com',
          server: 'https://acme-v02.api.letsencrypt.org/directory',
        },
      },
    }
  )
)
