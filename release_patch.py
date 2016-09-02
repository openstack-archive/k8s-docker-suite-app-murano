import os
import yaml
import argparse

def build_packages():
    pass

def upload_packages():
    pass

def increase_version(old_name, new_ver):


def update_app_catalog(assets_path):
    if not os.path.isabs(assets_path):
        raise ValueError('Path is not absolute, please specify absolute path.')
    if not os.path.isfile(assets_path):
        msg = 'Path is not point on file, please specify correct path.'
        raise ValueError(msg)
    with open(assets_path, 'r') as f:
        try:
            artifacts = yaml.load(f)
            assets =  artifacts['assets']
            k8s_artifacts = [val for val in assets
                             if 'Kubernetes' in val['name']]
            import pdb; pdb.set_trace()
        except yaml.YAMLError as exc:
            print(exc)


def main():
    path = ('/home/skraynev/Work/PaaS/app-catalog/openstack_catalog/web/'
            'static/assets.yaml')
    update_app_catalog(path)

main()
