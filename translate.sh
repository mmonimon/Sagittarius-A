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

preprocessing=false
train_steps=0
gpu=""

usage="$BASE [-h] [-p] [-g] [-i <input_data>] [-o <output_data>] [-s <source_language>] [-t <target_language>]  [-d <working_directory>] [-c <config>] [-n <train_steps> ] -- translates input data and computes BLEU

where:
    -h  show this help text
    -p  run preprocessing on data
    -g  translate using GPU (faster)
    -i  full or relative path to input data in source language
    -o  full or relative path to output (translated) data in target language
    -d  full path to working directory
    -c  path to config
    -n  overwrite number of training steps from config and use this model

V0.1"
while getopts ':hpgs:t:i:o:d:c:n:' option; do
    case "$option" in
    h)
        echo "$usage"
        exit
        ;;
    s)
        source_language=$OPTARG
        ;;
    p)
        preprocessing=true
        ;;
    g)
        gpu="--gpu 0"
        ;;
    t)
        target_language=$OPTARG
        ;;
    i)
        input_data=$OPTARG # $(get_dir_path "$OPTARG" "$BASE")
        ;;
    o)
        output_data=$OPTARG # $(get_dir_path "$OPTARG" "$BASE")
        ;;
    d)
        working_directory=$OPTARG
        ;;
    c) 
        config_file=$OPTARG
        ;;
    n)
        train_steps=$OPTARG
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
config_options=$(grep .*=.* "configs/${config_file}")
if [[ "${train_steps}" < 1 ]]; then
    train_steps=${train_step_size}
fi
suffix="true"
if [[ "${bpe_split}" > 0 ]]; then
    suffix="bpe"
fi

if [ "${preprocessing}" = true ]; then
    #############################
    ## Preprocessing ############
    #############################

    # 1) The normalization step simplifies the punctuation of the text by using re-writing rules 
    # (e.g., remove extra spaces, normalize different types of quotation marks, etc.).
    perl preprocessing_tools/normalize-punctuation.perl -l "${source_language}" < "data/${input_data}" > "data/${input_data%.txt}.norm"

    # 2) The tokenization step splits the sentences in individual tokens, deciding the boundaries 
    # of each word (for example detaching a comma from a word).
    # the tokenizer separates words from punctuation with a white space. Es: hello! → hello !
    perl preprocessing_tools/tokenizer.perl -l "${source_language}" < "data/${input_data%.txt}.norm" > "data/${input_data%.txt}.tok"

    # 3-1 The truecasing step defines the proper capitalization of words. Creates truecasing models
    ## take truecasing model from model??

    # 3-2 Truecasing validation
    perl preprocessing_tools/truecase.perl --model "data/truecasing.${source_language}.model" < "data/${input_data%.txt}.tok" > "data/${input_data%.txt}.true"

    if [[ "${bpe_split}" > 0 ]]; then
        # 3-3 Split bpe
        subword-nmt apply-bpe -c "data/bpe.${source_language}.codes" < "data/${input_data%.txt}.true" > "data/${input_data%.txt}.bpe"
    fi
fi


######################
## Prediction ########
######################
if [[ ! -d translated_data ]]; then
    mkdir translated_data
fi

# translate test files
# compute translation:
# Note: using a higher --batch_size to increase translation speed. Needs to be adjusted to GPU memory.
# Note: add --replace_unk for even better BLEU scores
onmt_translate --model "models/model-${source_language}-${target_language}-${config_file##*/}_step_${train_steps}.pt" --src "data/${input_data%.txt}.${suffix}" --output "translated_data/${input_data%.txt}.pred.${target_language}" ${gpu} --beam_size "${beam}" --batch_size 200
# detok and detrue translations:
if [[ "${bpe_split}" > 0 ]]; then
    sed -r 's/(@@ )|(@@ ?$)//g' < "translated_data/${input_data%.txt}.pred.${target_language}" | perl preprocessing_tools/detokenizer.perl -u -l "${target_language}" > "translated_data/${input_data%.txt}.pred.detok.${target_language}"
else
    perl preprocessing_tools/detokenizer.perl -u -l "${target_language}" < "translated_data/${input_data%.txt}.pred.${target_language}" > "translated_data/${input_data%.txt}.pred.detok.${target_language}"
fi


######################
## BLEU Score ########
######################

# compute BLEU score and save it in a new file:
result_file="results_${config_file##*/}"
if [ ! -f "${result_file}" ]; then
        echo "${config_options}" > "results_${config_file##*/}"
fi
echo "$(date '+%F %T'): ${input_data%.txt} ${train_steps}:" >> "${result_file}"
perl preprocessing_tools/multi-bleu-detok.perl "data/${output_data}" < "translated_data/${input_data%.txt}.pred.detok.${target_language}" >> "${result_file}"
