local k = import './main.libsonnet';

{
  container: k.core.v1.container.withName('myContainer')
             + k.core.v1.container.withImage('nginx'),
  pod: k.core.v1.pod.new('myPod')
       + k.core.v1.pod.spec.withContainers(
         [self.container]
       ),
  deployment: k.apps.v1.deployment.new('myDeployment')
              + k.apps.v1.deployment.spec.withPaused('false'),
}
