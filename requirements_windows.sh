#!/bin/sh

# Prerequisites for Windows
# - install MinGW64 (you can use Git Bash as well)
# - install CUDA
# - run this script in MinGW64 Shell

pip install torch==1.9.0+cu111 -f https://download.pytorch.org/whl/torch_stable.html
pip install -r requirements.yml
