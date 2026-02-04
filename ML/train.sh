#!/bin/bash
# FocusSense Drowsiness Detection Training

cd "$(dirname "$0")"

python training/train.py \
    --data_dir ./data/drowsiness_kaggle/train \
    --val_split 0.2 \
    --model default \
    --pretrained \
    --epochs 50 \
    --batch_size 32 \
    --lr 1e-4 \
    --num_workers 4 \
    --save_dir ./checkpoints
