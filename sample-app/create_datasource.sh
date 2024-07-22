#!/usr/bin/env bash

set -euo pipefail

function processCmdLine() {
  local -n args="${1}"
  shift

  while getopts "e:n:j:" arg; do
    case $arg in
    e) args[search_endpoint]=${OPTARG} ;;
    n) args[datasource_name]=${OPTARG} ;;
    j) args[datasource_json]=${OPTARG} ;;
    *) usage && exit 1                 ;;
    esac
  done
}

function checkArgs() {
  # shellcheck disable=SC2178
  local -nr args="${1}"

  # if no defaults, and no args on CLI
  if [[ ${#args[@]} -eq 0 ]]; then
    echo "args unset"
    usage
    exit 1
  elif [[ ! -v args[search_endpoint] || ${#args[search_endpoint]} -eq 0 ]]; then
    echo "Problem with -e search_endpoint argument"
    usage
    exit 1
  elif [[ ! -v args[datasource_name] || ${#args[datasource_name]} -eq 0 ]]; then
    echo "Problem with -n datasource_name argument"
    usage
    exit 1
  elif [[ ! -v args[datasource_json] || ${#args[datasource_json]} -eq 0 ]]; then
    echo "Problem with -j datasource_json argument"
    usage
    exit 1
  fi

  # shellcheck disable=SC2129
  echo "Final values are"
  echo "search_endpoint = ${args[search_endpoint]}"
  echo "datasource_name = ${args[datasource_name]}"
  echo "datasource_json = '${args[datasource_json]}'"
}

function usage() {
  # shellcheck disable=SC2129
  echo "required arguments are"
  echo "  -e <search_endpoint> : URL of the Azure AI Search instance"
  echo "  -n <datasource_name> : Name of the datasource in the Azure AI Search instance"
  echo "  -j <datasource_json> : JSON config of the datasource in the Azure AI Search instance"
}

function run () {
  # shellcheck disable=SC2178
  local -n args="${1}"

  #  echo "Logging in"
  az login --service-principal --username "${ARM_CLIENT_ID}" --password "${ARM_CLIENT_SECRET}" --tenant "${ARM_TENANT_ID}"

  bearer=$(az account get-access-token --scope https://search.azure.com/.default | jq -r '.accessToken')

  local result

  echo "curl -v --location --request PUT ${args[search_endpoint]}/datasources('${args[datasource_name]}')?api-version=2023-11-01 \
              --header 'Content-Type: application/json' \
              --header Authorization: Bearer ${bearer} \
              --data ${args[datasource_json]}"

  result=$(curl -v --location --request PUT "${args[search_endpoint]}/datasources('${args[datasource_name]}')?api-version=2023-11-01" \
                --header 'Content-Type: application/json' \
                --header "Authorization: Bearer ${bearer}" \
                --data "${args[datasource_json]}"
  )

  echo "Display the result"

  echo "result == ${result}"

  return 0
}

echo $@

exit 0

# shellcheck disable=SC2034
declare -A arguments

processCmdLine arguments "$@"

echo "check argument validity"
checkArgs arguments

echo "configure a new datasource"
run arguments

exit 0
