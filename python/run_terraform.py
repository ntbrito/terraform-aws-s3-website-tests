#!/usr/bin/env python3
"""Run terraform commands."""
import python_terraform

class runTf():
    def __init__(self, path, resource):
        self.path     = path
        self.resource = resource
    
    def terraform_init(self)->None:
        tfwd = f'{self.path}/{self.resource}'
        terra = python_terraform.Terraform(working_dir = tfwd)
        ret, stdout, stderr = terra.init(reconfigure=True)

    def terraform_plan(self)->None:
        terra = python_terraform.Terraform(working_dir = self.path)
        ret, stdout, stderr = terra.plan(refresh=True)

    def terraform_test(self)->None:
        terra = python_terraform.Terraform(working_dir = self.path)
        stdout = terra.test
        print(stdout)

# In case you want to run this as a standalone for troubleshooting
def get_args()->None:
    """ Routine to parse the required arguments """
    valid_commands = ("init", "plan", "apply", "test")
    parser = argparse.ArgumentParser()
    parser.add_argument('project',
                        help='The name of the project to build.')
    parser.add_argument('command',
                        help='Terraform command to run.')
    args = parser.parse_args()

if __name__ == '__main__':
    get_args()
