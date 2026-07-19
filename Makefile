SHELL := /bin/bash
.ONESHELL:
.SILENT:
.SHELLFLAGS = -ec

export RED := \033[1;31m
export GREEN := \033[1;32m
export CYAN := \033[0;36m
export NO_COLOR := \033[0m
export NOTE := \033[1;33m
export BOLD := \033[1m
export REGULAR := \e[0m

#: Generic vars
export PROJECT_SCRIPTS := ./scripts
export RESOURCE_PATH := ./azure
export PLAN_FILE := tf_100.plan

export AZ_FUNCTIONS_OUTPUT_BASE := ./az-functions-src-output

#: Repo vars
export REPO_NAME := RMAS_Platform_BaseInfra

#: Find .env file
define resolve_env
	ENV_FILE=$$(find ./config-vars -type f -name "$(word 2,$(MAKECMDGOALS))" | head -n 1); \
	if [[ -n "$$ENV_FILE" ]]; then \
		SUBSCRIPTION=$$(grep SUBSCRIPTION_ID $$ENV_FILE | cut -d'=' -f2 | tr -d '"'); \
		echo $$SUBSCRIPTION > $(RESOURCE_PATH)/subscription; \
	else \
		echo -e "$(RED)Error: Env file not found: $(word 2,$(MAKECMDGOALS))$(NO_COLOR)"; \
		exit 1; \
	fi
endef

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Variable not set in the environment: $1$(if $2, ($2))))

create_az_functions_output_folder:
	mkdir -p $(AZ_FUNCTIONS_OUTPUT_BASE)

#: Display help on common tasks
all: help

#: Clean up files left from make plan
clean:
	echo -e "$(CYAN)Clean up files left by terraform plan.$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/cleanup.sh

#: Display help on common tasks
help:
	echo -e "$(CYAN)Below are the available make targets:$(NO_COLOR)\n"
	# https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile/59087509#59087509
	HELP_TEXT="$$(grep -B1 -E "^[a-zA-Z0-9_%-]+\:([^\=]|$$)" Makefile \
	| grep -v -- -- \
	| sed 'N;s/\n/###/' \
	| sed -n 's/^#: \(.*\)###\(.*\):.*/\$(GREEN)\2\$(NO_COLOR)###\1/p' \
	| column -t -s '###')"
	echo -e "$$HELP_TEXT"

#: Creates a python virtual env. The folder name needs to be passed at the end with python version: make create_python_virtual_env__configure_db PYTHON_VERSION=3.12
create_python_virtual_env__%:
	$(call check_defined, PYTHON_VERSION)
	echo -e "$(CYAN)Creating python virtual environment for: \"$(*)\"$(NO_COLOR)"
	python$(PYTHON_VERSION) -m venv az-functions-src/python/$(*)/venv-$(*)

#: Shows the command to activate python virtual env.The folder name needs to be passed at the end. The complete command needs to be passed in the terminal
activate_python_virtual_env__%:
	echo -e "$(CYAN)Creating command for activating python virtual environment shell for: \"$(*)\". Run this in your shell to activate virtual env$(NO_COLOR)"
	@echo "source az-functions-src/python/$*/venv-$(*)/bin/activate"

#: Installs all python lambda package dependencies in local laptop
install_dependencies:
	echo -e "--- $(GREEN)Installing dependencies in environment ...$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/install-deps.sh

#: Starting local testing for azure functions. Example make az_func_local_test__configure_db LOCAL_TEST_STATE=(start or stop)
az_func_local_test__%:
	$(call check_defined, LOCAL_TEST_STATE)
	echo -e "$(CYAN)Local testing for azure functions for: \"$(*)\"$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/az-func-local-test.sh $(*)

#: Formats Terraform files in all folders
format_all: format__sec_groups \
	format__acr \
	format__aks \
	format__app_insights \
	format__application_gateway \
	format__dns \
	format__eventhub_namespace \
	format__key_vault \
	format__modules \
	format__resource_group \
	format__storage \
	format__vpn \
	format__vnet \
	format__vwan \
	format__vmachine

#: Runs Terraform plan.
plan__%: create_az_functions_output_folder
	$(call resolve_env)
	echo -e "$(CYAN)Running Terraform plan for service: \"$(*)\"$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/tf-base.sh $(*) $$ENV_FILE

#: Runs Terraform show.
show__%: create_az_functions_output_folder
	echo -e "$(CYAN)Running apply for service: \"$(*)\"$(NO_COLOR)"
	terraform -chdir=$(RESOURCE_PATH)/$(*) show $(PLAN_FILE)

#: Runs Terraform apply.
deploy__%: create_az_functions_output_folder
	echo -e "$(CYAN)Running apply for service: \"$(*)\"$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/tf-apply.sh $(*)

#: Runs Terraform destroy - run with FLAG="plan" for destroy plan.
destroy__%: create_az_functions_output_folder
	echo -e "$(CYAN)Running destroy for service: \"$(*)\"$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/tf-destroy.sh $(*) $(FLAG)

#: Runs Terraform validate.
validate__%: create_az_functions_output_folder
	echo -e "$(CYAN)Running validate for service: \"$(*)\"$(NO_COLOR)"
	terraform -chdir=$(RESOURCE_PATH)/$(*) validate

#: Runs Terraform format.
format__%: 
	echo -e "$(CYAN)Running format for service: \"$(*)\"$(NO_COLOR)"
	terraform -chdir=$(RESOURCE_PATH)/$(*) fmt

#: Pushes errored tf state to resolve TF backend persist errors.
push_errored_state__%:
	echo -e "$(CYAN)Pushing errored terraform state for service: \"$(*)\"$(NO_COLOR)"
	terraform -chdir=$(RESOURCE_PATH)/$(*) state push errored.tfstate

#: Encrypt config var files. make encrypt_vars file-name.env
encrypt_vars:
	$(call resolve_env)
	$(call check_defined, BASEINFRA_ENCRYPTION_KEY)
	echo -e "$(CYAN)Encrypting app config vars file$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/shared/encrypt-decrypt.sh $(BASEINFRA_ENCRYPTION_KEY) "encrypt" $$ENV_FILE

#: Decrypt config var files. make decrypt_vars file-name.env
decrypt_vars:
	$(call resolve_env)
	$(call check_defined, BASEINFRA_ENCRYPTION_KEY)
	echo -e "$(CYAN)Decrypting app config vars file$(NO_COLOR)"
	$(PROJECT_SCRIPTS)/shared/encrypt-decrypt.sh $(BASEINFRA_ENCRYPTION_KEY) "decrypt" $$ENV_FILE

#: example: make state_unlock__aks LOCK_ID=<lock-id>
#: Unlocks Terraform statefile forcefully.
state_unlock__%:
	$(call check_defined, LOCK_ID)
	echo -e "$(CYAN)Unlocking Terraform statefile for service: \"$(*)\"$(NO_COLOR)"
	terraform -chdir=$(RESOURCE_PATH)/$(*) force-unlock -force "${LOCK_ID}"

#: Builds an image to deploy custom VMs - run with "vars=vars_file.hcl"
build_ami:
	$(call resolve_env)
	$(PROJECT_SCRIPTS)/build-ami.sh $$ENV_FILE

#: Create documentation for Terraform modules. Needs to have a README.md first with delimiters mentioned below
create_tf_module_docs:
	$(call check_defined, TF_MODULE_PATH)
	docker run --rm \
		-v $(TF_MODULE_PATH):/data \
		-w /data \
		-e DELIM_START='<!-- AUTOMATED DOC GENERATION STARTS FROM HERE. DONT UPDATE MANUALLY -->' \
		-e DELIM_CLOSE='<!-- AUTOMATED DOC GENERATION ENDS HERE. DONT UPDATE MANUALLY  -->' \
		cytopia/terraform-docs:0.16.0 terraform-docs-replace-012 md README.md

#: Dummy rule to prevent 'No rule to make target' error for env file argument
%.env:
	@true
