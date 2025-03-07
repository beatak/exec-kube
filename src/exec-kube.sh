#!/usr/bin/env bash

function main {
  set -eu
  set -o pipefail

  check_requirements

  local namespace=$(get_namespace "$@")
  if [[ -z "$namespace" ]]; then
    warn "No namespace given"
    usage
    exit 1
  fi

  local pods=$(kubectl get pods --namespace=$namespace -o custom-columns=":metadata.name" --no-headers 2>/dev/null)

  if [[ -z "$pods" ]]; then
    warn "No pods found in namespace '$namespace'."
    exit 1
  fi

  warn "Available pods in namespace '$namespace':"
  local connecting_pod=""
  select pod in $pods; do
    if [[ -n "$pod" ]]; then
      connecting_pod="$pod"
      break
    else
      warn "Invalid selection. Please choose a valid pod."
    fi
  done

  warn "Connecting to pod: $connecting_pod"
  kubectl exec -it -n "$namespace" "$connecting_pod" -- bash

  warn "Exiting"
  exit 0
}

# =====================================

function check_requirements {
  if ! command -v kubectl &>/dev/null; then
    warn "Error: kubectl is not installed or not in PATH."
    exit 1
  fi
}

function get_namespace {
  local namespace=""

  set +u
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -n|--namespace)
      if [[ -n "$2" && ! "$2" =~ ^- ]]; then
        namespace="$2"
        shift 2
      else
        warn "Error: Missing value for $1 option."
        shift 1
      fi
      ;;
    -n=*|--namespace=*)
      namespace="${1#*=}"
      shift 1
      ;;
    *)
      shift 1
      ;;
    esac
  done
  set -u

  echo "$namespace"
}

function usage {
  warn "Usage: $0 -n <namespace>"
  exit 1
}

function warn {
  echo "$1" 1>&2
}

# =====================================

main "$@"
