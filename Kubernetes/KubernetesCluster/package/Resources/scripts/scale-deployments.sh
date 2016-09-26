#!/bin/bash

# $1 - Deployments name
# $2 - new size

/opt/bin/kubectl scale deployments "${1}" --replicas="${2}"
