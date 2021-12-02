local gen = import 'github.com/Duologic/crdsonnet/crdsonnet/main.libsonnet';

local k = import './main.libsonnet';

k.core.v1.pod.new('myPod')
+ k.core.v1.pod.spec.withContainers(
  k.core.v1.container.withName('myContainer')
  + k.core.v1.container.withImage('nginx')
  + k.core.v1.container.resources.withLimits({ a: 'b' })
)
