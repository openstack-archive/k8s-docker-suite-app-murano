#!/bin/bash

WORKSPACE="${WORKSPACE:-${1}}"
APP_DIRS="${APP_DIRS:-${2}}"
# SC2001: See if you can use ${variable//search/replace} instead.
#  Occasionally a more complex sed substitution is required, so lets igone
#  this warning
skip_list='SC2001'

function help_m() {
    cat <<-EOF
	***********************************************************************
	Shellcheck script help message:
        Scripts work with files under \${WORKSPACE}/\${APP_DIRS}
	Please use env variable:
	- Set directory for scan:
	export WORKSPACE='/dir/with/sh/files/to/scan'
        export APP_DIRS="Applications DockerInterfacesLibrary DockerStandaloneHost Kubernetes"
	- or directly:
	./shellcheck.sh "/dir/with/sh/files/to/scan" "Applications DockerInterfacesLibrary DockerStandaloneHost Kubernetes"
	***********************************************************************
	EOF
}

function run_check() {
    local e_count=0

    for w_dir in ${APP_DIRS}; do
        cat <<-EOF
		***********************************************************************
		*
		*   Starting shellcheck against dir:"${WORKSPACE}/${w_dir}"
		*
		***********************************************************************
		EOF
        while read -d '' -r script; do
            unset RESULT
            shellcheck "${script}" -e "${skip_list}"
            RESULT=$?
            if [ ${RESULT} != 0 ]; then
                ((e_count++))
            fi
        done < <(find "${WORKSPACE}/${w_dir}" -name '*.sh' -print0)
    done
    cat <<-EOF
	***********************************************************************
	*
	*   shellcheck finished with ${e_count} errors.
	*
	***********************************************************************
	EOF
    if [ "${e_count}" -gt 0 ] ; then
        exit 1
    fi
}

### Body:

if [[ -z "${WORKSPACE}" ]]; then
   echo 'ERROR: WORKSPACE variable is not set!'
   help_m
   exit 1
fi
if [[ -z "${APP_DIRS}" ]]; then
   echo 'ERROR: APP_DIRS variable is not set!'
   help_m
   exit 1
fi
run_check
