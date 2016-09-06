# Copyright (c) 2016 Mirantis Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import base


class MuranoK8sTest(base.MuranoTestsBase):

    def test_deploy_scale_k8s(self):
        environment = self.create_env()
        session = self.create_session(environment)

        k8s_cluster_json = self.create_k8s_cluster(
            {
                'initial_nodes': 1,
                'max_nodes': 2,
                'initial_gateways': 1,
                'max_gateways': 1,
                'cadvisor': True,
                'keypair_name': self.keyname,
                'flavor': self.flavor,
                'kubernetes_image': self.k8s_image
            }
        )

        k8s_cluster = self.create_service(
            environment,
            session,
            k8s_cluster_json
        )

        k8s_pod_json = self.create_k8s_pod(
            k8s_cluster,
            {
                'labels': 'testkey=testvalue',
                'replicas': 2,
            }
        )

        self.create_service(environment, session, k8s_pod_json)

        self.deploy_env(environment, session)

        environment = self.get_env(environment)

        check_services = {
            'com.mirantis.docker.kubernetes.KubernetesCluster': {
                'ports': [8080, 22],
                'url': 'api/',
                'url_port': 8080
            }
        }

        self.deployment_success_check(environment, check_services)

        minions_ips = self.get_k8s_instances(environment)['minions']
        self.assertEqual(1, len(minions_ips))

        for ip in minions_ips:
            self.check_ports_open(ip, 4194)

        self.run_k8s_action(
            environment=environment,
            action='scaleNodesUp'
        )

        self.wait_for_environment_deploy(environment)

        environment = self.get_env(environment)

        minions_ips = self.get_k8s_instances(environment)['minions']
        self.assertEqual(2, len(minions_ips))

        for ip in minions_ips:
            self.check_ports_open(ip, 4194)