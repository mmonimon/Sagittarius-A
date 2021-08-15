#!/usr/bin/env python3

import sys
import random

with open(sys.argv[1], 'rb') as f:
    file_lines = f.readlines() 

# randomize lines
random.seed(42) # reproducible randomness
random.shuffle(file_lines)

if len(sys.argv) >= 4:
    if len(sys.argv[3]) > 0:
        lines = int(sys.argv[3])
        file_lines = file_lines[:lines]

num_lines = len(file_lines)
split_train = int(0.8 * num_lines) # 80% train
split_test = int(0.9 * num_lines)  # 10 % test and validate

with open('train.' + sys.argv[2], 'wb') as f:
    train_lines = file_lines[:split_train]
    f.writelines(train_lines)

with open('test.' + sys.argv[2], 'wb') as f:
    test_lines = file_lines[split_train:split_test]
    f.writelines(test_lines)

with open('val.' + sys.argv[2], 'wb') as f:
    val_lines = file_lines[split_test:]
    f.writelines(val_lines)
