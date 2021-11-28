local gen = import '../gen.libsonnet';
local kapi = import 'kubernetes-spec-v1.23/api__v1_openapi.json';

local spec = [
  import 'kubernetes-spec-v1.23/api_openapi.json',
  import 'kubernetes-spec-v1.23/apis__admissionregistration.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__admissionregistration.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__apiextensions.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__apiextensions.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__apps_openapi.json',
  import 'kubernetes-spec-v1.23/apis__apps__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__authentication.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__authentication.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__authorization.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__authorization.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__autoscaling_openapi.json',
  import 'kubernetes-spec-v1.23/apis__autoscaling__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__autoscaling__v2beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__autoscaling__v2beta2_openapi.json',
  import 'kubernetes-spec-v1.23/apis__autoscaling__v2_openapi.json',
  import 'kubernetes-spec-v1.23/apis__batch_openapi.json',
  import 'kubernetes-spec-v1.23/apis__batch__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__batch__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__certificates.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__certificates.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__coordination.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__coordination.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__discovery.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__discovery.k8s.io__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__discovery.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__events.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__events.k8s.io__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__events.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__flowcontrol.apiserver.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__flowcontrol.apiserver.k8s.io__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__flowcontrol.apiserver.k8s.io__v1beta2_openapi.json',
  import 'kubernetes-spec-v1.23/apis__internal.apiserver.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__internal.apiserver.k8s.io__v1alpha1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__networking.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__networking.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__node.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__node.k8s.io__v1alpha1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__node.k8s.io__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__node.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis_openapi.json',
  import 'kubernetes-spec-v1.23/apis__policy_openapi.json',
  import 'kubernetes-spec-v1.23/apis__policy__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__policy__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__rbac.authorization.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__rbac.authorization.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__scheduling.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__scheduling.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__storage.k8s.io_openapi.json',
  import 'kubernetes-spec-v1.23/apis__storage.k8s.io__v1alpha1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__storage.k8s.io__v1beta1_openapi.json',
  import 'kubernetes-spec-v1.23/apis__storage.k8s.io__v1_openapi.json',
  import 'kubernetes-spec-v1.23/api__v1_openapi.json',
  import 'kubernetes-spec-v1.23/logs_openapi.json',
  import 'kubernetes-spec-v1.23/openid__v1__jwks_openapi.json',
  import 'kubernetes-spec-v1.23/version_openapi.json',
];

local k8s =
  std.foldl(
    function(acc, f)
      acc +
      (
        if std.objectHas(f, 'components') && std.objectHas(f.components, 'schemas')
        then
          std.foldl(
            function(acc, m)
              local items = std.reverse(std.split(m, '.'));
              if std.startsWith(m, 'io.k8s.api.')
              then
                acc + gen.fromSchema(
                  items[2],
                  items[2],
                  items[1],
                  items[0],
                  f.components.schemas[m],
                  f.components.schemas,
                )
              else acc,
            std.objectFields(f.components.schemas),
            {}
          )
        else {}
      ),
    spec,
    {}
  );

gen.inspect(k8s, 4)
