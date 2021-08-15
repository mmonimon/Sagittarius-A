# Sagittarius A

Sagittarius A is the final resulting Machine Translation model created as part of a project exam for the Univerity of Potsdam in 2021.

## Dependencies

1) Preprocessing:
- split-sentences.perl
- normalize-punctuation.perl
- tokenizer.perl
- convert-gch.perl
- sentence_align.py
- convert-hunalign.perl
- train-truecaser.perl
- truecase.perl

2) Training:
- onmt_train
    - configargparse
    - torchtext==0.4
    - torch

3) Prediction:
- onmt_translate

4) Postprocessing:
- detokenizer.perl
- multi-bleu-detok.perl

5) Training

Sample commands:

```
time ./MTwrapper.sh -p -s en -t de -i newstest2019-ende-src.en.txt -o newstest2019-ende-src.en.txt -d . -l 2000 -c "configs/default"
time ./translate.sh -p -s en -t de -i newstest2019-ende-src.en.txt -o newstest2019-ende-ref.de.txt -d . -g -c "default"

```
