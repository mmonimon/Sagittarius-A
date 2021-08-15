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

usage="$BASE [-h] [-p] [-s <source_language>] [-t <target_language>] [-i <input_data>] [-l <input_lines>] [-o <output_data>] [-d <working_directory>] [-c <config>]-- preprocessing on input data, splits data into train/val/test sets. trains the model and translates test files.

where:
    -h  show this help text
    -p  run preprocessing on data
    -s  source language e.g. en
    -t  target language e.g. de
    -i  full or relative path to input data in source language
    -l  only use specified number of lines from given input file
    -o  full or relative path to output (translated) data in target language
    -d  full path to working directory
    -c  path to config

V0.1"

preprocessing=false
transformer=false
lines=""
while getopts ':hps:t:i:l:o:d:c:' option; do
    case "$option" in
    h)
        echo "$usage"
        exit
        ;;
    p)
        preprocessing=true
        ;;
    s)
        source_language=$OPTARG
        ;;
    t)
        target_language=$OPTARG
        ;;
    i)
        input_data=$OPTARG # $(get_dir_path "$OPTARG" "$BASE")
        ;;
    l)
        lines=$OPTARG
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

transformer=false
source "${config_file}"
config_options=$(grep .*=.* "${config_file}")
languages=("${source_language}" "${target_language}")
suffix="true"

if [[ "${bpe_split}" > 0 ]]; then
    suffix="bpe"
fi

if [ "${preprocessing}" = true ]; then
    #############################
    ## Data splitting ###########
    #############################

    cd data
    python ../split.py "${input_data}" "${source_language}" "${lines}"
    python ../split.py "${output_data}" "${target_language}" "${lines}"
    cd ..

    #############################
    ## Preprocessing ############
    #############################

    for lang in "${languages[@]}"; do
        echo $lang
        files_to_process=("data/train.${lang}" "data/test.${lang}" "data/val.${lang}")
        for input_file in "${files_to_process[@]}"; do
            echo "${input_file}"
            # # 0) divide document into sentences (uses nonbreaking prefix files: 
            # # contains elements which, if followed by a period and an upper-case word, 
            # # do not indicate an end-of-sentence marker.
            # perl preprocessing_tools/split-sentences.perl -l "${lang}" < "${input_file}" > "${input_file}.split"

            # 1) The normalization step simplifies the punctuation of the text by using re-writing rules 
            # (e.g., remove extra spaces, normalize different types of quotation marks, etc.).
            perl preprocessing_tools/normalize-punctuation.perl -l "${lang}" < "${input_file}" > "${input_file}.norm"

            # 2) The tokenization step splits the sentences in individual tokens, deciding the boundaries 
            # of each word (for example detaching a comma from a word).
            # the tokenizer separates words from punctuation with a white space. Es: hello! → hello !
            perl preprocessing_tools/tokenizer.perl -l "${lang}" < "${input_file}.norm" > "${input_file}.tok"

            # # 2-1 the Gale and Church aligner creates a document and puts each word (also punctuation) in a new line.
            # perl preprocessing_tools/convert-gch.perl < "${input_file}.tok" > "${input_file}.gch"
            # python preprocessing_tools/sentence_align.py "${input_file}.gch" "${input_file}.gch" > "${input_file}.gch.${source_language}-${target_language}"

            # # 2-2 the Hunalign converter creates a new file and puts each sentence in a new line.
            # perl preprocessing_tools/convert-hunalign.perl < "${input_file}.tok" > "${input_file}.hun"
        done
    done

    # 3-1 The truecasing step defines the proper capitalization of words. Creates truecasing models
    perl preprocessing_tools/train-truecaser.perl --corpus "data/train.${source_language}" --model "data/truecasing.${source_language}.model"
    perl preprocessing_tools/train-truecaser.perl --corpus "data/train.${target_language}" --model "data/truecasing.${target_language}.model"

    # 3-2 Truecasing validation
    for lang in "${languages[@]}"; do
        files_to_process=("data/train.${lang}" "data/test.${lang}" "data/val.${lang}")
        for input_file in "${files_to_process[@]}"; do
            perl preprocessing_tools/truecase.perl --model "data/truecasing.${lang}.model" < "${input_file}.tok" > "${input_file}.true"
            # clean up data
            # rm "${input_file}.tok" "${input_file}.norm"
            # rm "${input_file}.gch" "${input_file}.split" "${input_file}.hun"
        done
    done

    if [[ "${bpe_split}" > 0 ]]; then
        # 3-3 Split bpe
        subword-nmt learn-bpe -s "${bpe_split}" < "data/train.${source_language}.true" > "data/bpe.${source_language}.codes"
        subword-nmt learn-bpe -s "${bpe_split}" < "data/train.${target_language}.true" > "data/bpe.${target_language}.codes"

        for lang in "${languages[@]}"; do
            files_to_process=("data/train.${lang}.true" "data/test.${lang}.true" "data/val.${lang}.true")
            for input_file in "${files_to_process[@]}"; do
                subword-nmt apply-bpe -c "data/bpe.${lang}.codes" < "${input_file}" > "${input_file%.true}.bpe"
            done
        done
    fi

    #############################
    ## Data Conversion ##########
    #############################
    if [[ ! -d byte-data ]]; then
        mkdir byte-data
    fi
    # 4) Data conversion into binaary data
    onmt_preprocess --train_src "data/train.${source_language}.${suffix}" --train_tgt "data/train.${target_language}.${suffix}" \
        --valid_src "data/val.${source_language}.${suffix}" --valid_tgt "data/val.${target_language}.${suffix}" \
        --save_data "byte-data/data-${source_language}-${target_language}" --overwrite
fi

######################
## Training ##########
######################
if [[ ! -d models ]]; then
    mkdir models
fi

# --data and --save_model:
#   refer to the file names (without extensions) of the input data and the model files.
if [ "${transformer}" = true ]; then
    onmt_train \
        --data "byte-data/data-${source_language}-${target_language}" \
        --save_model "models/model-${source_language}-${target_language}-${config_file##*/}" \
        --train_steps "${train_step_size}" \
        --save_checkpoint_steps "${cp_step_size}" \
        --valid_steps "${valid_step_size}" \
        --global_attention "${global_attention}" \
        --input_feed "${input_feed}" \
        --dropout "${dropout}" \
        --world_size "${world_size}" \
        --gpu_ranks "${gpu_ranks}" \
        --layers "${layers}" \
        --rnn_size "${rnn_size}" \
        --word_vec_size "${word_vec_size}" \
        --transformer_ff 2048 --heads 8  \
        --encoder_type transformer --decoder_type transformer --position_encoding  \
        --max_generator_batches 2  \
        --batch_size 4096 --batch_type tokens --normalization tokens  --accum_count 2  \
        --optim adam --adam_beta2 0.998 --decay_method noam --warmup_steps 8000 --learning_rate 2  \
        --max_grad_norm 0 --param_init 0 --param_init_glorot  \
        --label_smoothing 0.1
else
    onmt_train \
        --data "byte-data/data-${source_language}-${target_language}" \
        --save_model "models/model-${source_language}-${target_language}-${config_file##*/}" \
        --train_steps "${train_step_size}" \
        --save_checkpoint_steps "${cp_step_size}" \
        --valid_steps "${valid_step_size}" \
        --global_attention "${global_attention}" \
        --input_feed "${input_feed}" \
        --dropout "${dropout}" \
        --world_size "${world_size}" \
        --gpu_ranks "${gpu_ranks}" \
        --layers "${layers}" \
        --rnn_size "${rnn_size}" \
        --word_vec_size "${word_vec_size}"
fi
