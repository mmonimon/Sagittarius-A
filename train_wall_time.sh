#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
BASE=$(basename "$0")
BASE_DIR_CONV=$(dirname "$(readlink $0)")

if [[ $# == 0 ]] ; then
    printf "\e[31m%s\e[39m %s\n" "[ERROR]" "$BASE: You didn't provide any arguments. Please provide arguments or execute $BASE -h for usage. "
    exit 0
fi

usage="$BASE [-h] [-d <working_directory>] [-c <config>] -- get training wall time from log file

where:
    -h  show this help text
    -d  full path to working directory
    -c  path to config

V0.1"
while getopts ':hd:c:' option; do
    case "$option" in
    h)
        echo "$usage"
        exit
        ;;
    d)
        working_directory=$OPTARG
        ;;
    c)
        config_file=$OPTARG
        ;;
    :)
        printf "missing argument for -%s\n" "$OPTARG" >&2
        echo "$usage" >&2
        exit 1
        ;;
    \?)
        printf "illegal option: -%s\n" "$OPTARG" >&2
        echo "$usage" >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

cd "${working_directory}"

source "configs/${config_file}"

#[2021-08-04 21:48:37,204 INFO] Building model...
time_1=$(date -d "$(grep -Po '(?<=^\[).*(?= INFO\] Building model...)' log_${config_file})" +%s)
#[2021-08-04 23:08:15,853 INFO] Saving checkpoint models/model-en-de-rhea_step_100000.pt
time_2=$(date -d "$(grep -Po '(?<=^\[).*(?= INFO\] Saving checkpoint .*_'${train_step_size}'.pt)' log_${config_file})" +%s)

echo "${config_file} training wall time: $(( time_2 - time_1 )) s"
