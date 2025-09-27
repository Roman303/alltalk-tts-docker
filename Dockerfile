# Dockerfile für AllTalk TTS V2 (Beta-Branch, CUDA 11.8, Finetuning-Fokus)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

LABEL maintainer="deinname <email@example.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Systempakete (erweitert für Builds)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    git git-lfs wget curl ca-certificates build-essential \
    ffmpeg libsndfile1 libsndfile1-dev pkg-config \
    unzip zip locales libaio-dev \
    libblas-dev liblapack-dev gfortran libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN locale-gen en_US.UTF-8 || true

WORKDIR /app

# Pip upgrade
RUN python3 -m pip install --upgrade pip setuptools wheel

# PyTorch für CUDA 11.8
RUN python3 -m pip install --no-cache-dir \
    torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# AllTalk TTS V2 klonen (Beta-Branch)
RUN git clone --branch alltalkbeta https://github.com/erew123/alltalk_tts.git /app/alltalk_tts

# Requirements installieren (getrennt, TTS zuerst)
WORKDIR /app/alltalk_tts
RUN python3 -m pip install --no-cache-dir TTS==0.21.3
RUN python3 -m pip install --no-cache-dir -r system/requirements/requirements_standalone.txt
RUN python3 -m pip install --no-cache-dir -r system/requirements/requirements_finetune.txt || true

# Upgrades (fix Downgrades)
RUN python3 -m pip install --no-cache-dir --upgrade \
    numpy>=1.24 \
    pandas>=2.0 \
    scipy \
    gradio \
    transformers \
    datasets \
    tqdm

# XTTS-v2 Modell downloaden
RUN python3 -c "from transformers import pipeline; pipeline('text-to-speech', model='coqui/XTTS-v2', device='cuda')"

# Entry-Point
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
