#!/bin/bash
cd /app/alltalk_tts

# DeepSpeed installieren (falls nicht vorhanden, kompiliert gegen CUDA 11.8)
if ! pip show deepspeed > /dev/null; then
    export CUDA_HOME=/usr/local/cuda
    pip install deepspeed
fi

# Starte Finetuning (oder Server, je nach Arg)
if [ "$1" = "finetune" ]; then
    python finetune.py
else
    python server.py --host 0.0.0.0 --port 7851
fi
