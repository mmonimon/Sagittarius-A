#!/bin/bash

for i in titan; do
  time ./MTwrapper.sh -s en -t de -i corpus.en -o corpus.de -d . -c "configs/$i" 2>&1 | tee "log_$i"
  time ./translate.sh -s en -t de -i newstest2019-ende-src.en.txt -o newstest2019-ende-ref.de.txt -d . -g -c "$i" 2>&1 | tee -a "log_$i"
  time ./translate.sh -s en -t de -i test.en -o test.de -d . -g -c "$i" 2>&1 | tee -a "log_$i"
  mkdir -p "${i}/models"
  cp -r models/model-en-de-${i}* "${i}/models"
  cp -r {translated_data,results_$i,log_$i} "${i}"
done
