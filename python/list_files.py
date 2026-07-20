#!/usr/bin/env python3
"""Lists Terraform folder"""
import os


class listFiles:
    def __init__(self):
        pass

    def list_files(self)->str:
        cwd           = os.getcwd()
        parent_dir    = os.path.abspath(os.path.join(cwd, os.pardir))
        terraform_dir = os.path.abspath(os.path.join(parent_dir, "terraform"))
        tfmodules     = os.path.abspath(os.path.join(terraform_dir, 'base_modules'))
        base_infra    = os.path.abspath(os.path.join(terraform_dir, 'base_infra'))
        return terraform_dir, tfmodules, base_infra
