#!/usr/bin/env python3
"""Not in use."""
"""Reads the project configuration json file and returns the resouces."""
import os
import json

class readConfig:
    def __init__(self, project):
        self.project = project

    def read_config(self)->object:
        """ Reads project configuration json, returns the resources"""
        parent_dir = os.path.abspath(os.path.join(os.getcwd(), os.pardir))
        config_file = f'{parent_dir}/infra_config/{self.project}/parameters.json'
        with open(config_file, 'r') as config:
            project_config = json.load(config)
        project_params = project_config[self.project]
        return project_params
