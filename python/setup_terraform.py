#!/usr/bin/env python3
"""This sets up the variables files based on the project json parameters file"""
import argparse
from string import Template
from list_files import listFiles
from read_config import readConfig

class terraformTF:
    def __init__(self, project):
        self.project = project
        self.tf_dir, self.tf_modules, self.base_infra = listFiles().list_files()
        self.project_params = readConfig(self.project).read_config()

    def create_tffile(self)->None:
        environment_type = self.project_params['environment_type']
        resource_vars = {}
        resource_vars['environment_type'] = environment_type
        resource_vars['project_name'] = self.project
        resources = self.project_params['resources']
        with open(f'{self.tf_dir}/templates/terraform.tf') as template:
            template_vars = Template(template.read())
            output = template_vars.substitute(**resource_vars)
            for key_resource in resources.keys():
                with open(f'{self.base_infra}/{key_resource}/terraform.tf', 'w') as tf_file:
                    tf_file.write(output)

def get_args()->None:
    """ Routine to parse the required arguments """
    parser = argparse.ArgumentParser()
    parser.add_argument('project',
                        help='The name of the project to build.')
    args = parser.parse_args()
    terraformTF(args.project).create_tffile()

if __name__ == '__main__':
    get_args()
