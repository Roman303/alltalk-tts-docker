#!/bin/bash
set -e  # Stop bei Fehlern

echo "Starting AllTalk TTS Setup..."

# Basis dependencies
apt update
apt install -y git build-essential python3 python3-pip ffmpeg \
    libmecab-dev libsndfile1-dev libaio-dev mecab mecab-ipadic-utf8

# Workspace setup
cd /root/workspace

# Clone repositories
if [ ! -d "alltalk_tts" ]; then
    git clone -b alltalkbeta https://github.com/erew123/alltalk_tts.git
fi

cd alltalk_tts

# Run setup
chmod +x atsetup.sh
./atsetup.sh --auto --standalone --deepspeed

# Data preparation
if [ ! -d "data" ]; then
    git clone https://github.com/roman303/alltalk-tts-docker.git data
    cp -r data/data/* finetune/put-voice-samples-in-here/
fi

# Conda environment setup
source alltalk_environment/conda/bin/activate alltalk_environment/env
conda install -c conda-forge "ffmpeg>=6.0" "x264>=0.164" "openh264" -y

# CUDA link
ln -sf /lib/x86_64-linux-gnu/libcuda.so.1 /lib/x86_64-linux-gnu/libcuda.so

echo "Setup completed successfully!"
echo "To start the service:"
echo "cd /root/workspace/alltalk_tts && source alltalk_environment/conda/bin/activate alltalk_environment/env && python app.py"
