# Adjustable parameters outside of training
bpe_split='0'
beam='5'
# --train_steps, --save_checkpoint_steps and --valid_steps:
#   determine how many passes through the training data the model makes, how many 
#   intermediate model it saves, and how often it applies the validation data. 
#   The training process takes a batch of sentences for each training step and uses them to learn how to translate. 
#   Every 2,000 steps, the toolkit will save a model on your working directory. 
#   The last one (10,000) in our case will be most likely the optimal model. 
train_step_size='10000'
cp_step_size='2000'
valid_step_size='2000'

# --global_attention, --input_feed, --dropout are related to the model type. 
#   This time, we use a simple encoder--decoder model as seen in class. 
#   We will experiment with other model types later.
global_attention='none'
input_feed='0'
dropout='0.0'

# --world_size and --gpu_ranks determine how many GPUs to use. These settings should not be changed.
world_size='1'
gpu_ranks='0'

# --layers determines the number of recurrent layers in the model. 
# --rnn_size determines the number of dimensions of each recurrent layer, and 
# --word_vec_size determines the number of dimensions of the embedding layer (the first, non--recurrent layer of the model). 
layers='1'
rnn_size='256'
word_vec_size='256'
