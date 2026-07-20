#!/usr/bin/env python3
"""This starts up the module based on the values in the project json parameters file"""
import argparse
from string import Template
from list_files import listFiles
from read_config import readConfig
from setup_terraform import terraformTF
from run_terraform import runTf

class setupModule:
    def __init__(self, project):
        self.project = project
        self.tf_dir, self.tf_modules, self.base_infra = listFiles().list_files()
        ## self.project_params = readConfig(self.project).read_config()
        self.environment_type = readConfig(self.project).read_config()['environment_type']
        self.resources = readConfig(self.project).read_config()['resources']

    def initiate_module(self)->None:
        """Initialize resource_vars and add shared variables."""
        resource_vars = {}
        resource_vars['environment_type'] = self.environment_type
        resource_vars['project_name'] = self.project
        for key_resource in self.resources.keys():
            for k, v in self.resources[key_resource].items():
                resource_vars[k] = v
            with open(f'{self.tf_modules}/{key_resource}/variables.tpl') as template:
                template_vars = Template(template.read())
            output = template_vars.substitute(**resource_vars)
            with open(f'{self.base_infra}/{key_resource}/variables.tf', 'w') as varsfile:
                varsfile.write(output)
            runTf(self.base_infra, key_resource).terraform_init()

    def test_module(self)->None:
        """This function tests the module."""
        resource_vars = {}
        resource_vars['environment_type'] = self.environment_type
        resource_vars['project_name'] = self.project
        for key_resource in self.resources.keys():
            for k, v in self.resources[key_resource].items():
                resource_vars[k] = v
            with open(f'{self.tf_modules}/{key_resource}/variables.tpl') as template:
                template_vars = Template(template.read())
            output = template_vars.substitute(**resource_vars)
            with open(f'{self.tf_modules}/{key_resource}/variables.tf', 'w') as varsfile:
                varsfile.write(output)
            runTf(self.base_infra, key_resource).terraform_test()

def get_args()->None:
    """ Routine to parse the required arguments """
    parser = argparse.ArgumentParser()
    parser.add_argument('project',
                        help='The name of the project to build.')
    args = parser.parse_args()
    terraformTF(args.project).create_tffile()
    setupModule(args.project).initiate_module()
    setupModule(args.project).test_module()

if __name__ == '__main__':
    get_args()
