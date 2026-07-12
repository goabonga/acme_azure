# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

BLACK=$(tput -Txterm setaf 0)
RED=$(tput -Txterm setaf 1)
GREEN=$(tput -Txterm setaf 2)
YELLOW=$(tput -Txterm setaf 3)
LIGHTPURPLE=$(tput -Txterm setaf 4)
PURPLE=$(tput -Txterm setaf 5)
BLUE=$(tput -Txterm setaf 6)
WHITE=$(tput -Txterm setaf 7)
RESET=$(tput -Txterm sgr0)

export ENV=dev

function switch_env(){
	if [[ -z "${1}" ]]
	then
		echo "usage: switch_env [environment]"
		return 1
	fi
	if [[ ! -f "configs/config.${1}.yaml" ]]
	then
		echo "${RED}Error: file \"configs/config.${1}.yaml\" not founds.${RESET}"
		return 1
	fi
	subscription_id=$(cat configs/config.${1}.yaml | yq -r .subscription.id)

	clean --silent
	echo "${WHITE}Swith to environment${RESET} ${PURPLE}${1}${RESET}"
	az account set --subscription ${subscription_id}
	export ENV=${1}
}

# terraform like function
#
# Terragrunt's CLI redesign (>= v0.73) renamed the global flags
# (--terragrunt-non-interactive -> --non-interactive,
# --terragrunt-working-dir -> --working-dir), replaced `run-all <cmd>`
# with `run --all <cmd>`, and stopped forwarding bare OpenTofu commands -
# single-unit commands now go through `run -- <cmd>`. Everything after
# `--` is passed straight to OpenTofu/Terraform.

function init(){
	if [[ -z "${1}" ]]
	then
		echo "usage: init ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- init -reconfigure
}

function providers(){
	if [[ -z "${1}" ]]
	then
		echo "usage: providers ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run -- providers ${2}
}

function import(){
	if [[ -z "${1}" ]]
	then
		echo "usage: import ./path/service resource uuid"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run -- import ${2} ${3}
}

function state(){
	if [[ -z "${1}" ]]
	then
		echo "usage: state ./path/service "
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run -- state ${2} ${3}
}

function apply(){
	if [[ -z "${1}" ]]
	then
		echo "usage: apply ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- apply
}

function plan(){
	if [[ -z "${1}" ]]
	then
		echo "usage: plan ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- plan ${2}
}

function output(){
	if [[ -z "${1}" ]]
	then
		echo "usage: output ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- output ${2} 2> /dev/null
}

function show(){
	if [[ -z "${1}" ]]
	then
		echo "usage: show ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run -- show ${2}
}

function graph(){
	if [[ -z "${1}" ]]
	then
		echo "usage: graph ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- graph
}

function refresh(){
	if [[ -z "${1}" ]]
	then
		echo "usage: refresh ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- refresh
}

function destroy(){
	if [[ -z "${1}" ]]
	then
		echo "usage: destroy ./path/service"
		return 1
	fi
	terragrunt --non-interactive --working-dir "${1}" \
		run --all -- destroy
}

function clean(){
	if [[ ! "$@" =~ .*"--silent".* ]]; then
		echo "${GREEN}Clean directory${RESET}"
	fi
	rm -Rf graph
	find ./ -type d -name ".terragrunt-cache" \
	-o -type f -name ".terraform.lock.hcl" \
	-o -type d -name ".terraform" \
	-o -type f -name "generated_*.tf" | \
	xargs rm -Rf
}
