#!/usr/bin/env python3

with open('data/news-commentary-v15.de-en.tsv', mode='r', encoding='utf8') as data:
    with open('data/news-commentary-corpus.de', mode='w', encoding='utf8') as de:
        with open('data/news-commentary-corpus.en', mode='w', encoding='utf8') as en:
            for line in data:
                splitted_line = line.strip().split('\t')
                if len(splitted_line) != 2: continue
                if len(splitted_line[0]) == 0 or len(splitted_line[1]) == 0: continue
                de.write(splitted_line[0]+'\n')
                en.write(splitted_line[1]+'\n')
