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
        """Check that it is possible to deploy K8s application and scale it

        Scenario:
            1. Create murano environment
            2. Create session for create environment.
            3. Initialize k8s cluster parameters and add app to env.
            4. Initialize k8s pod parameters and add app to env.
            5. Deploy session.
            7. Check env status and port availability on k8s master node.
            8. Get k8s minions' ips and check that correct initial number
            of them was created and k8s api port is available on them.
            9. Run 'scaleNodesUp' action for k8s minions.
            10. Check that number of minions was increased and
            k8s api port is available on all of them
            11. Run 'scaleNodesDown' action for k8s minions.
            12. Check that number of minions was decreased and
            k8s api port is available on all of them
        """

        # Create murano environment
        environment = self.create_env()

        # Create session for create environment.
        session = self.create_session(environment)

        # Initialize k8s cluster parameters and add app to env
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

        # Initialize k8s pod parameters and add app to env.
        k8s_pod_json = self.create_k8s_pod(
            k8s_cluster,
            {
                'labels': 'testkey=testvalue',
                'replicas': 2,
            }
        )
        self.create_service(environment, session, k8s_pod_json)

        # Deploy session.
        self.deploy_env(environment, session)

        # Check env status and port availability on k8s master node.
        environment = self.get_env(environment)

        check_services = {
            'com.mirantis.docker.kubernetes.KubernetesCluster': {
                'ports': [8080, 22],
                'url': 'api/',
                'url_port': 8080
            }
        }
        self.deployment_success_check(environment, check_services)

        # Get k8s minions' ips and check that correct initial number
        # of them was created and k8s api port is available on them.
        minions_ips = self.get_k8s_instances(environment)['minions']
        self.assertEqual(1, len(minions_ips))

        for ip in minions_ips:
            self.check_ports_open(ip, [4194])

        # Run 'scaleNodesUp' action for k8s minions.
        self.run_k8s_action(
            environment=environment,
            action='scaleNodesUp'
        )
        self.wait_for_environment_deploy(environment)

        # Check that number of minions was increased and
        # k8s api port is available on all of them
        environment = self.get_env(environment)

        minions_ips = self.get_k8s_instances(environment)['minions']
        self.assertEqual(2, len(minions_ips))

        for ip in minions_ips:
            self.check_ports_open(ip, [4194])

        # Run 'scaleNodesDown' action for k8s minions.
        self.run_k8s_action(
            environment=environment,
            action='scaleNodesDown'
        )
        self.wait_for_environment_deploy(environment)

        # Check that number of minions was increased and
        # k8s api port is available on all of them
        environment = self.get_env(environment)

        minions_ips = self.get_k8s_instances(environment)['minions']
        self.assertEqual(1, len(minions_ips))

        for ip in minions_ips:
            self.check_ports_open(ip, [4194])
